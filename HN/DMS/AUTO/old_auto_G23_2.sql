/*
	
	注意！！！
	  rd_cfund库中的车贷数据单位为分
     
*/

-- 注意！！！！！ 龙环汇丰的不报代偿数据
INSERT  INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
)

SELECT
    'DEFAULT_BANK' AS dbank_id,
    LAST_DAY(a.accept_date) AS ddate,
    uuid() AS xh,
    a.fund_code AS relieve_no,
    a.rent_plan_code AS cont_no,
    a.rent_plan_code AS biz_no,
    e.project_name,
    'A' AS recv_type,
    CAST(a.accept_date AS DATE) AS recv_date,
    -- a.repaid_principal/100 AS recv_amt,
    CAST(a.repaid_principal/100 as decimal(20,2)) AS recv_amt,
    -- ★ 关键逻辑：满足两个条件才为 Y
    CASE
        WHEN rn = 1   
         AND (b.loan_amount - sum_no_cps_print) = 0
        THEN 'Y'
        ELSE 'N'
    END AS settle_flag

FROM (
    SELECT 
        a.*,
        SUM(CASE WHEN a.repay_type NOT IN (5) THEN a.`repaid_principal` ELSE 0 END) 
            OVER (PARTITION BY a.rent_plan_code ORDER BY a.accept_date,period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS sum_no_cps_print,         -- 累计非代偿金额

        ROW_NUMBER() OVER (PARTITION BY a.rent_plan_code ORDER BY a.accept_date DESC, period DESC) AS rn   -- 最后一笔还款
    FROM rd_cfund.zf_rent_plan_info a
    WHERE a.`capital_product_code` IN ('ZT-LH-SS10-2512') AND a.repay_type <> 5
) a

JOIN rd_cfund.oapi_loan b
    ON a.rent_plan_code = b.rent_plan_code
JOIN test_zxbs_db.hain_effective_data_interval e
    ON b.capital_product_code = e.project_code
    AND b.reconciliation_date BETWEEN e.start_date AND e.end_date

WHERE 
	e.is_use = 'Y'
      AND a.capital_product_code IN ('ZT-LH-SS10-2512')
      -- AND b.`loan_date` BETWEEN '2026-04-01' AND '2026-04-30';
      AND a.`accept_date` 
   	 	BETWEEN 
          DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01'), INTERVAL 1 MONTH) 
          AND 
          DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01'), INTERVAL 1 DAY)
;





/*
	
	注意！！！
	  rd_cfund库中的车贷数据单位为分
     
*/


INSERT  INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
)

SELECT
    'DEFAULT_BANK' AS dbank_id,
    LAST_DAY(a.accept_date) AS ddate,
    uuid() AS xh,
    a.fund_code AS relieve_no,
    a.rent_plan_code AS cont_no,
    a.rent_plan_code AS biz_no,
    e.project_name,
    'A' AS recv_type,
    CAST(a.accept_date AS DATE) AS recv_date,
    -- a.repaid_principal/100 AS recv_amt,
    CAST(a.repaid_principal/100 as decimal(20,2)) AS recv_amt,
    -- ★ 关键逻辑：满足两个条件才为 Y
    CASE
        WHEN rn = 1   
         AND (b.loan_amount - sum_no_cps_print) = 0
        THEN 'Y'
        ELSE 'N'
    END AS settle_flag

FROM (
    SELECT 
        a.*,
        SUM(CASE WHEN a.repay_type NOT IN (5) THEN a.`repaid_principal` ELSE 0 END) 
            OVER (PARTITION BY a.rent_plan_code ORDER BY a.accept_date,period ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS sum_no_cps_print,         -- 累计非代偿金额

        ROW_NUMBER() OVER (PARTITION BY a.rent_plan_code ORDER BY a.accept_date DESC, period DESC) AS rn   -- 最后一笔还款
    FROM rd_cfund.zf_rent_plan_info a
    WHERE a.`capital_product_code` IN ('ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608') AND a.repay_type <> 5
) a

JOIN rd_cfund.oapi_loan b
    ON a.rent_plan_code = b.rent_plan_code
JOIN test_zxbs_db.hain_effective_data_interval e
    ON b.capital_product_code = e.project_code
    AND b.reconciliation_date BETWEEN e.start_date AND e.end_date

WHERE 
	e.is_use = 'Y'
      AND a.capital_product_code IN ('ZT-ZR-GY-10-2512')
	  AND a.repay_type <> 4
      -- AND b.`loan_date` BETWEEN '2026-04-01' AND '2026-04-30';
      AND a.`accept_date` 
   	 	BETWEEN 
          DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01'), INTERVAL 1 MONTH) 
          AND 
          DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01'), INTERVAL 1 DAY)
;