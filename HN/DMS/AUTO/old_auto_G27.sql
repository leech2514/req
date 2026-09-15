INSERT INTO test_zxbs_db.ads_hain_g27_comp_detail (
    xh,
    dbank_id,
    ddate,
    cont_no,
    biz_no,
    project_name,
    comp_type,
    comp_seq,
    comp_date,
    comp_amt,
    comp_int
)
SELECT
    CAST(ROW_NUMBER() OVER (
        ORDER BY t.comp_date, t.comp_seq
    ) AS INTEGER) AS xh,
    t.dbank_id,
    t.ddate,
    t.cont_no,
    t.biz_no,
    t.project_name,
    t.comp_type,
    t.comp_seq,
    t.comp_date,
    t.comp_amt,
    t.comp_int
FROM (
    SELECT
        'DEFAULT_BANK' AS dbank_id,
        LAST_DAY(STR_TO_DATE(r.accept_date, '%Y-%m-%d')) AS ddate,
        r.rent_plan_code AS cont_no,
        r.rent_plan_code AS biz_no,
        fb.project_name,
        'A' AS comp_type,
        r.fund_code AS comp_seq,
        STR_TO_DATE(r.accept_date, '%Y-%m-%d') AS comp_date,
        CAST(r.repaid_principal / 100 AS DECIMAL(20,2)) AS comp_amt,
        CAST(r.repaid_interest  / 100 AS DECIMAL(20,2)) AS comp_int
    FROM rd_cfund.zf_rent_plan_info r
    INNER JOIN (
        SELECT
            l.capital_product_code AS product_no,
            l.rent_plan_code,
            i.project_name
        FROM rd_cfund.zf_rent_plan_info l
        JOIN test_zxbs_db.hain_effective_data_interval i
          ON l.capital_product_code = i.project_code
         AND STR_TO_DATE(l.accept_date,'%Y-%m-%d')
             BETWEEN i.start_date AND i.end_date
        WHERE i.is_use = 'Y'
        GROUP BY
            l.capital_product_code,
            l.rent_plan_code,
            i.project_name
    ) fb
      ON r.rent_plan_code = fb.rent_plan_code
    WHERE 
      -- STR_TO_DATE(r.reconciliation_date,'%Y-%m-%d') >= '2024-10-01' AND
      fb.product_no IN (
          -- 'ZT-LH-SS10-2512',  -- 注意！！！！！ 龙环汇丰的不报代偿数据
          'ZT-ZR-GY-10-2512'
          ,'ZT-LZ-ZY10-2608'
      )
      AND r.repay_type = '4'
      -- AND r.accept_date BETWEEN '2026-04-01' AND '2026-04-30'
      AND r.accept_date 
   	 	BETWEEN 
          DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01'), INTERVAL 1 MONTH) 
          AND 
          DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01'), INTERVAL 1 DAY)
) t;