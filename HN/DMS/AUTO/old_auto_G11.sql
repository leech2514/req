/* 
	车贷G11
*/

-- ==========================================
-- 4. 插入报送表
-- ==========================================
INSERT INTO test_zxbs_db.`ads_hain_g11_cust_info` (
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
            MD5(CONCAT(TRIM(l.id_card), 'hainan')) AS indiv_cust_id,
            l.id_card,
            l.loan_day
        FROM `prd_spark_db`.`dwd_auto_oapi_loan_d` l
        JOIN test_zxbs_db.hain_effective_data_interval i
          ON l.product_no = i.project_code
         AND l.loan_day BETWEEN i.start_date AND i.end_date
        WHERE i.is_use = 'Y' 
              AND `product_no` IN ('ZT-LH-SS10-2512','ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
              -- AND l.`loan_day` BETWEEN '2026-05-01' AND '2026-06-30'
    		  -- 注意！！！ 校验放款时间的筛选是否符合需求
	          AND l.loan_day BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
    
)
,source_data AS (
    SELECT
        CAST(dbii.indiv_cust_id AS CHAR) AS cust_id,
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

        dbii.id_card AS cert_no,
        CONCAT(LEFT(dbii.id_card, 2), '0000') AS region,
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
        -- CASE WHEN fb.product_no = 'DXM' THEN 'Y' ELSE 'N' END AS dual_innov_flag,
        'N' AS dual_innov_flag,
        NULL AS grp_uscc,

        -- 统一 row_hash
        MD5(CONCAT_WS('|',
            COALESCE(CAST(dbii.indiv_cust_id AS CHAR), ''),
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
            COALESCE(CAST(annual_income AS CHAR), '0.00'),
            CASE 
                WHEN UPPER(fb.product_no) = 'DXM' THEN 'Y'
                WHEN COALESCE(dbii.agri_flag,'') = '0' THEN 'Y'
                ELSE 'N'
            END
        )) AS row_hash

    FROM `prd_spark_db`.dim_base_indiv_info dbii
	JOIN filter_bill fb ON dbii.`id_card`  = fb.id_card
),
target_data AS (
    SELECT
        cust_id,
        MD5(CONCAT_WS('|',
            COALESCE(CAST(cust_id AS VARCHAR(100)), '') 
            ,COALESCE(cust_name, '')
            ,COALESCE(biz_body, '')
            ,COALESCE(cert_type, '')
            ,COALESCE(cert_no, '')
            ,COALESCE(CAST(annual_inc AS CHAR), '0.00')
            ,COALESCE(agri_flag, '')
        )) AS row_hash
        ,create_time
        ,update_time
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cust_id ORDER BY update_time DESC) AS rn
        FROM  test_zxbs_db.`ads_hain_g11_cust_info` 
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
	    s.loan_day
       BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))


;