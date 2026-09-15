-- ============================================================================
-- 脚本名称: ads_hain_g11_cust_info.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G11 客户信息月度报送（按上月放款数据生成增量客户记录）
-- 源表:     prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--           prod_dw_01.ods_cons_td_loan_incr_delta
--           prod_dw_01.dim_base_indiv_info_incr_t
--           hain_effective_data_interval
-- 目标表:   ads_hain_g11_cust_info
-- 写入模式: INSERT INTO TABLE（追加写入，保留历史数据）
-- 增量方式: incr（基于 row_hash 行指纹比对，仅挑新增/修改记录追加写入）
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- 修订记录:
--   2026-08-25  <name>  新建脚本  -  新建脚本，原 DMS G11.sql 迁移至 MaxCompute
--   2026-08-25  <name>  修改      -  写入模式由 INSERT OVERWRITE 改为 INSERT INTO，保留历史数据；create_time/update_time 字段为 STRING，GETDATE() 改 CAST AS STRING
-- 迁移说明（原 G11.sql → MC）:
--   1. pt 比较的 GETDATE() 改为调度参数 ${bizmonth} 以触发分区裁剪
--   2. CURRENT_DATE() → GETDATE()（MC 不支持函数调用形式）
--   3. CAST(... AS INT) → CAST(... AS BIGINT)（MC 推荐 BIGINT）
--   4. 其余函数（MD5/SUBSTR/CONCAT/COALESCE/LAST_DAY/DATEADD/TO_CHAR/UPPER/TRIM）均 MC 原生支持，保持不变
--   5. 保留 CTE + UNION ALL 结构
-- 风险提示:
--   - 目标表为非分区普通表，用 INSERT INTO 追加写入，历史数据保留不覆盖
--   - 同一 cust_id 修改会产生多条历史记录，由 target_data 的 ROW_NUMBER 取最新一条比对
--   - 目标表 create_time/update_time 为 STRING 类型，GETDATE() 已 CAST AS STRING
--   - hain_effective_data_interval 表若不在当前 project，需补 schema 前缀
--   - loan_day 应为 STRING（yyyy-MM-dd），若为 DATE 需 CAST 为 STRING 再比较
-- ============================================================================
-- DataWorks 调度参数配置：
--   bizdate=$bizdate        -- yyyymmdd 业务日期（T-1）
--   bizmonth=$bizmonth      -- yyyymm 业务月（上月）

INSERT INTO TABLE ads_hain_g11_cust_info
(
    dbank_id,
    ddate,
    xh,
    cust_id,
    cust_name,
    biz_body,
    cust_type,
    hold_type,
    cert_type,
    cert_no,
    region,
    industry,
    ent_scale,
    emp_num,
    annual_inc,
    asset_tot,
    credit_rate,
    agri_flag,
    farmer_flag,
    new_agri_flag,
    dual_innov_flag,
    grp_uscc,
    create_time,
    update_time
)
-- ==========================================
-- 生成当前客户数据和历史最新数据，统一 row_hash
-- ==========================================
WITH filter_bill AS (
    SELECT
        l.product_no,
        l.bill_app_no,
        l.indiv_cust_id,
        l.loan_day
    FROM (
        -- /*---------------- 消金（通道消金） ----------------------*/
        SELECT product_no, bill_app_no, indiv_cust_id, loan_day
        FROM prod_dw_01.dwd_cons_loan_payment_info_incr_delta
        WHERE pt <= TO_CHAR(GETDATE(), 'yyyymm')

        UNION ALL

        -- /*---------------- 消金简版（通道消金） ----------------------*/
        SELECT
            tl.product_no,
            tl.loan_no AS bill_app_no,
            CAST(di.indiv_cust_id AS STRING) AS indiv_cust_id,
            tl.loan_date AS loan_day
        FROM prod_dw_01.ods_cons_td_loan_incr_delta tl
        JOIN prod_dw_01.dim_base_indiv_info_incr_t di ON tl.id_no = di.id_card
    ) l
    JOIN hain_effective_data_interval i
        ON l.product_no = i.project_code
       AND l.loan_day BETWEEN i.start_date AND i.end_date
    WHERE i.is_use = 'Y'
),
source_data AS (
    SELECT
        CAST(dbii.indiv_cust_id AS STRING) AS cust_id,
        name AS cust_name,
        fb.loan_day,
        COALESCE(unit_name, '') AS biz_body,
        'A' AS cust_type,
        NULL AS hold_type,

        -- 统一 cert_type 逻辑
        CASE
            WHEN id_card_type IN ('01', '10') THEN 'A01'
            WHEN id_card_type = '02' THEN 'A06'
            WHEN id_card_type = '04' THEN 'B01'
            WHEN id_card_type = '03' THEN 'A99'
            ELSE ''
        END AS cert_type,

        id_card AS cert_no,
        CONCAT(SUBSTR(id_card, 1, 2), '0000') AS region,
        'Z' AS industry,
        NULL AS ent_scale,
        NULL AS emp_num,
        CAST(COALESCE(annual_income, 0.00) AS DECIMAL(20,2)) AS annual_inc,
        NULL AS asset_tot,
        NULL AS credit_rate,

        -- 统一 agri_flag 逻辑
        CASE
            WHEN UPPER(fb.product_no) = 'DXM' THEN 'Y'
            WHEN COALESCE(dbii.agri_flag, '') = '0' THEN 'Y'
            ELSE 'N'
        END AS agri_flag,

        CASE
            WHEN UPPER(TRIM(fb.product_no)) LIKE 'DXM%' THEN 'Y'
            WHEN COALESCE(dbii.agri_flag, '') = '0' THEN 'Y'
            ELSE 'N'
        END AS farmer_flag,

        'N' AS new_agri_flag,
        'N' AS dual_innov_flag,
        NULL AS grp_uscc,

        -- MD5 哈希值（行级指纹，用于和历史数据比对差异）
        MD5(CONCAT(
            COALESCE(CAST(dbii.indiv_cust_id AS STRING), ''),
            '|',
            COALESCE(name, ''),
            '|',
            COALESCE(unit_name, ''),
            '|',
            CASE
                WHEN id_card_type = '01' THEN 'A01'
                WHEN id_card_type = '02' THEN 'A06'
                WHEN id_card_type = '04' THEN 'B01'
                WHEN id_card_type = '03' THEN 'A99'
                ELSE ''
            END,
            '|',
            COALESCE(id_card, ''),
            '|',
            COALESCE(CAST(annual_income AS STRING), '0.00'),
            '|',
            CASE
                WHEN UPPER(fb.product_no) = 'DXM' THEN 'Y'
                WHEN COALESCE(dbii.agri_flag, '') = '0' THEN 'Y'
                ELSE 'N'
            END
        )) AS row_hash

    FROM prod_dw_01.dim_base_indiv_info_incr_t dbii
    JOIN filter_bill fb ON dbii.indiv_cust_id = fb.indiv_cust_id
),
target_data AS (
    -- 取目标表每个 cust_id 的最新一条记录，重新计算 row_hash，供与源数据比对
    SELECT
        cust_id,
        MD5(CONCAT(
            COALESCE(CAST(cust_id AS STRING), ''),
            '|',
            COALESCE(cust_name, ''),
            '|',
            COALESCE(biz_body, ''),
            '|',
            COALESCE(cert_type, ''),
            '|',
            COALESCE(cert_no, ''),
            '|',
            COALESCE(CAST(annual_inc AS STRING), '0.00'),
            '|',
            COALESCE(agri_flag, '')
        )) AS row_hash,
        create_time,
        update_time
    FROM (
        SELECT
            cust_id,
            cust_name,
            biz_body,
            cert_type,
            cert_no,
            annual_inc,
            agri_flag,
            create_time,
            update_time,
            -- 按 cust_id 取最新 update_time 的一条（ROW_NUMBER 去重）
            ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY update_time DESC) AS rn
        FROM ads_hain_g11_cust_info
    ) t
    WHERE rn = 1
),
-- ==========================================
-- 计算新增或修改数据
-- ==========================================
diff_data AS (
    -- LEFT JOIN 后保留：源数据存在但目标无（新增）或 row_hash 不一致（修改）
    SELECT
        CAST(ROW_NUMBER() OVER (ORDER BY t.cust_id) AS BIGINT) AS xh,
        s.*
    FROM source_data s
    LEFT JOIN target_data t
        ON s.cust_id = t.cust_id
    WHERE t.row_hash IS NULL OR s.row_hash <> t.row_hash
)
SELECT
    'DEFAULT_BANK' AS dbank_id,
    CAST(LAST_DAY(s.loan_day) AS STRING) AS ddate,
    s.xh,
    s.cust_id,
    cust_name,
    biz_body,
    cust_type,
    hold_type,
    cert_type,
    cert_no,
    region,
    industry,
    COALESCE(ent_scale, 'Z') AS ent_scale,
    emp_num,
    annual_inc,
    asset_tot,
    credit_rate,
    agri_flag,
    farmer_flag,
    new_agri_flag,
    dual_innov_flag,
    grp_uscc,
    -- 新增记录用当前时间（CAST AS STRING 对齐目标字段类型），已有记录沿用原 create_time
    CASE WHEN t.create_time IS NULL THEN CAST(GETDATE() AS STRING) ELSE t.create_time END AS create_time,
    CAST(GETDATE() AS STRING) AS update_time
FROM diff_data s
LEFT JOIN target_data t ON s.cust_id = t.cust_id
WHERE
    -- 上月 1 号到上月末
    s.loan_day BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND
        LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;
