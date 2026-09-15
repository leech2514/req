
-- ==========================================
-- 4. 插入报送表
-- ==========================================
INSERT INTO `ads_hain_g11_cust_info` (
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
WITH  filter_bill AS (
        SELECT 
            l.product_no,
            l.bill_app_no,  
            l.indiv_cust_id,
            l.loan_day
        FROM (
            -- /*---------------- 消金简版（通道消金） ----------------------*/
            SELECT product_no,bill_app_no,indiv_cust_id,loan_day
            FROM `prod_dw_01.dwd_cons_loan_payment_info_incr_delta`
            WHERE pt <= TO_CHAR(GETDATE(), 'yyyyMM') 

            UNION ALL

           -- /*---------------- 消金简版（通道消金） ----------------------*/
            SELECT tl.product_no,tl.loan_no AS bill_app_no, CAST(di.indiv_cust_id AS STRING) AS indiv_cust_id,tl.loan_date AS loan_day
            FROM `prod_dw_01.ods_cons_td_loan_incr_delta` tl 
              JOIN `prod_dw_01.dim_base_indiv_info_incr_t` di ON tl.`id_no` = di.`id_card`  
        ) AS l
        JOIN `hain_effective_data_interval` i
            ON l.product_no = i.project_code
            AND l.loan_day BETWEEN i.start_date  AND i.end_date
        WHERE i.is_use = 'Y'
)
,source_data AS (
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
        -- CONCAT(LEFT(id_card, 2), '0000') AS region,
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
            WHEN COALESCE(dbii.agri_flag,'') = '0' THEN 'Y'
            ELSE 'N'
        END AS agri_flag,

        CASE 
            WHEN UPPER(TRIM(fb.product_no)) LIKE 'DXM%' THEN 'Y'
            WHEN COALESCE(dbii.agri_flag,'') = '0' THEN 'Y'
            ELSE 'N'
        END AS farmer_flag,
    
        'N' AS new_agri_flag,
        'N' AS dual_innov_flag,
        NULL AS grp_uscc,

        -- MD5哈希值（使用CONCAT替代CONCAT_WS）
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

    FROM `prod_dw_01.dim_base_indiv_info_incr_t` dbii
	JOIN filter_bill fb ON dbii.indiv_cust_id = fb.indiv_cust_id
),
target_data AS (
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
            ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY update_time DESC) AS rn
        FROM ads_hain_g11_cust_info
    ) t
    WHERE rn = 1
)
-- ==========================================
-- 3. 计算新增或修改数据
-- ==========================================
,diff_data AS (
    SELECT
        CAST(ROW_NUMBER() OVER (ORDER BY t.cust_id) AS INT) AS xh,
        s.*
    FROM source_data s
    LEFT JOIN target_data t
      ON s.cust_id = t.cust_id
    WHERE t.row_hash IS NULL OR s.row_hash <> t.row_hash
)
SELECT
    'DEFAULT_BANK' AS dbank_id,
    last_day(s.loan_day) AS ddate,
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
    CASE WHEN t.create_time IS NULL THEN CURRENT_TIMESTAMP  ELSE t.create_time END AS create_time,
    CURRENT_TIMESTAMP  AS update_time
FROM diff_data s
LEFT JOIN target_data t ON s.cust_id = t.cust_id
WHERE
	-- s.loan_day BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
    -- 最简洁的写法
    s.loan_day BETWEEN 
        CONCAT(SUBSTR(DATEADD(CURRENT_DATE(), -1, 'mm'), 1, 7), '-01')
        AND 
        LAST_DAY(DATEADD(CURRENT_DATE(), -1, 'mm'))
;


