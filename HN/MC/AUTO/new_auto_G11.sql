-- ============================================================================
-- 脚本名称: new_auto_G11.sql
-- 层级:     ADS
-- 业务域:   海南正堂/车贷担保报送
-- 功能描述: 车贷 G11 融资担保公司客户信息月度增量报送
--           （按上月放款客户，row_hash 比对仅追加新增/变动记录）
-- 源表:     prod_dw_01.dwd_auto_oapi_loan_incr_delta（车贷放款信息表，映射 005）
--           prod_dw_01.dim_base_indiv_info_incr_t（个人客户主档，映射 003）
--           hain_effective_data_interval（海南有效数据区间配置表，prod_bs_dw，映射 004）
-- 目标表:   ads_hain_g11_cust_info（普通 aliorc 表，无分区无主键，prod_bs_dw，映射 006）
-- 写入模式: INSERT INTO（追加写入，保留历史）
-- 调度周期: 月度（每月初跑上月数据，放款时间取上月 1 号至上月末）
-- 负责人:   <name>
-- 创建日期: 2026-09-14
-- ============================================================================

INSERT INTO TABLE ads_hain_g11_cust_info
(
    dbank_id, ddate, xh, cust_id, cust_name, biz_body, cust_type,
    hold_type, cert_type, cert_no, region, industry, ent_scale,
    emp_num, annual_inc, asset_tot, credit_rate, agri_flag, farmer_flag,
    new_agri_flag, dual_innov_flag, grp_uscc, create_time, update_time
)
WITH filter_bill AS (
    -- 上月在有效数据区间内的车贷放款
    SELECT
        l.product_no,
        l.bill_app_no,
        MD5(CONCAT(TRIM(l.id_card), 'hainan')) AS indiv_cust_id,
        l.id_card,
        l.loan_day
    FROM prod_dw_01.dwd_auto_oapi_loan_incr_delta l
    JOIN hain_effective_data_interval i
      ON l.product_no = i.project_code
     AND l.loan_day BETWEEN i.start_date AND i.end_date
    WHERE i.is_use = 'Y'
      AND l.product_no IN ('ZT-LH-SS10-2512', 'ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
      -- 放款时间：上月 1 号至上月末
      AND l.loan_day BETWEEN
            CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
            AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
      AND l.pt = TO_CHAR(DATEADD(GETDATE(), -1, 'mm'), 'yyyymm')
)
, source_data AS (
    -- 关联客户主档，组装 G11 报送字段并计算 row_hash 行指纹
    SELECT
        CAST(dbii.indiv_cust_id AS STRING) AS cust_id,
        name AS cust_name,
        fb.loan_day,
        COALESCE(unit_name, '') AS biz_body,
        'A' AS cust_type,
        CAST(NULL AS STRING) AS hold_type,

        -- 证件类型映射
        CASE
            WHEN id_card_type IN ('01', '10') THEN 'A01'
            WHEN id_card_type = '02' THEN 'A06'
            WHEN id_card_type = '04' THEN 'B01'
            WHEN id_card_type = '03' THEN 'A99'
            ELSE ''
        END AS cert_type,

        dbii.id_card AS cert_no,
        CONCAT(SUBSTR(dbii.id_card, 1, 2), '0000') AS region,   -- 身份证前 2 位 + 0000 映射省份
        'Z' AS industry,
        CAST(NULL AS STRING) AS ent_scale,
        CAST(NULL AS BIGINT) AS emp_num,
        CAST(COALESCE(CAST(annual_income AS DECIMAL(20,2)), CAST(0.00 AS DECIMAL(20,2))) AS DECIMAL(20,2)) AS annual_inc,
        CAST(NULL AS DECIMAL(20,2)) AS asset_tot,
        CAST(NULL AS STRING) AS credit_rate,

        -- 三农主体标识
        CASE
            WHEN UPPER(fb.product_no) = 'DXM' THEN 'Y'
            WHEN COALESCE(dbii.agri_flag, '') = '0' THEN 'Y'
            ELSE 'N'
        END AS agri_flag,

        -- 农户标志
        CASE
            WHEN UPPER(TRIM(fb.product_no)) LIKE 'DXM%' THEN 'Y'
            WHEN COALESCE(dbii.agri_flag, '') = '0' THEN 'Y'
            ELSE 'N'
        END AS farmer_flag,

        'N' AS new_agri_flag,
        'N' AS dual_innov_flag,
        CAST(NULL AS STRING) AS grp_uscc,

        -- MD5 行指纹
        MD5(CONCAT_WS('|',
            COALESCE(CAST(dbii.indiv_cust_id AS STRING), ''),
            COALESCE(name, ''),
            COALESCE(unit_name, ''),
            CASE
                WHEN id_card_type = '01' THEN 'A01'
                WHEN id_card_type = '02' THEN 'A06'
                WHEN id_card_type = '04' THEN 'B01'
                WHEN id_card_type = '03' THEN 'A99'
                ELSE ''
            END,
            COALESCE(dbii.id_card, ''),
            COALESCE(CAST(annual_income AS STRING), '0.00'),
            CASE
                WHEN UPPER(fb.product_no) = 'DXM' THEN 'Y'
                WHEN COALESCE(dbii.agri_flag, '') = '0' THEN 'Y'
                ELSE 'N'
            END
        )) AS row_hash
    FROM prod_dw_01.dim_base_indiv_info_incr_t dbii
    JOIN filter_bill fb ON dbii.id_card = fb.id_card
)
, target_data AS (
    -- 目标表按 cust_id 取最新一条记录重算 row_hash
    SELECT
        cust_id,
        MD5(CONCAT_WS('|',
            COALESCE(CAST(cust_id AS STRING), ''),
            COALESCE(cust_name, ''),
            COALESCE(biz_body, ''),
            COALESCE(cert_type, ''),
            COALESCE(cert_no, ''),
            COALESCE(CAST(annual_inc AS STRING), '0.00'),
            COALESCE(agri_flag, '')
        )) AS row_hash,
        create_time,
        update_time
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY update_time DESC) AS rn
        FROM ads_hain_g11_cust_info
    ) t
    WHERE rn = 1
)
, diff_data AS (
    -- 新增或 row_hash 不一致的客户，重新编排序号
    SELECT
        ROW_NUMBER() OVER (ORDER BY s.cust_id) AS xh,
        s.*
    FROM source_data s
    LEFT JOIN target_data t
      ON s.cust_id = t.cust_id
    WHERE t.row_hash IS NULL OR s.row_hash <> t.row_hash
)
SELECT
    'DEFAULT_BANK'                              AS dbank_id,
    CAST(LAST_DAY(s.loan_day) AS STRING)         AS ddate,
    s.xh,
    s.cust_id,
    s.cust_name,
    s.biz_body,
    s.cust_type,
    s.hold_type,
    s.cert_type,
    s.cert_no,
    s.region,
    s.industry,
    COALESCE(s.ent_scale, 'Z')                   AS ent_scale,
    s.emp_num,
    s.annual_inc,
    s.asset_tot,
    s.credit_rate,
    s.agri_flag,
    s.farmer_flag,
    s.new_agri_flag,
    s.dual_innov_flag,
    s.grp_uscc,
    CASE WHEN t.create_time IS NULL
         THEN CAST(CURRENT_TIMESTAMP() AS STRING)
         ELSE t.create_time
    END                                          AS create_time,
    CAST(CURRENT_TIMESTAMP() AS STRING)          AS update_time
FROM diff_data s
LEFT JOIN target_data t ON s.cust_id = t.cust_id
-- 限定上月放款数据
WHERE s.loan_day BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;
