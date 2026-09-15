/*
  需要在项目信息表中添加并手动维护上面的字段。
  报表日期逻辑待确认
  
  1.一个项目可能会有多个担保方，在此场景下，需要区分出哪个担保公司对应的风险占比是对应的机构自身的风险承担比例。？？
  （要报送的都是单个担保公司，目前只取机构自身的比例）

*/
INSERT INTO `test_zxbs_db`.`ads_hain_g23_1_risk_share` (
    dbank_id,
    ddate,
    xh,
    cont_no,
    biz_no,
    project_name,
    org_ratio,
    natl_fund_ratio,
    prov_fund_ratio,
    prov_gov_ratio,
    prov_comp_ratio,
    city_fund_ratio,
    city_gov_ratio,
    city_comp_ratio,
    county_gov_ratio,
    county_comp_ratio,
    pbank_ratio,
    big4_ratio,
    joint_stock_ratio,
    city_bank_ratio,
    rural_fin_ratio,
    ins_ratio,
    other_ratio,
    total_ratio
)
SELECT  
    'DEFAULT_BANK' AS dbank_id,                    -- 机构代码
    last_day(l.loan_day) AS ddate,
    CAST(ROW_NUMBER() OVER (ORDER BY l.bill_app_no) AS INTEGER) AS xh,
    l.bill_app_no AS cont_no,             -- 合同编号
    l.bill_app_no AS biz_no               -- 业务编号
	,e.project_name

    -- -- 以下比例字段需要在项目维表或产品维表中人工维护
    , 1 AS org_ratio			-- 机构自身风险承担比例
    , 0 AS natl_fund_ratio
    , 0 AS prov_fund_ratio
    , 0 AS prov_gov_ratio
    , 0 AS prov_comp_ratio
    , 0 AS city_fund_ratio
    , 0 AS city_gov_ratio
    , 0 AS city_comp_ratio
    , 0 AS county_gov_ratio
    , 0 AS county_comp_ratio
    , 0 AS pbank_ratio
    , 0 AS big4_ratio
    , 0 AS joint_stock_ratio
    , 0 AS city_bank_ratio
    , 0 AS rural_fin_ratio
    , 0 AS ins_ratio
    , 0 AS other_ratio
    , 1 AS total_ratio

FROM `prd_spark_db`.dwd_auto_oapi_loan_d l
  -- ON prod.product_no = l.product_no
JOIN `test_zxbs_db`.hain_effective_data_interval e
  ON l.product_no = e.project_code
    AND l.loan_day BETWEEN e.start_date AND e.end_date
WHERE l.`product_no` IN ('ZT-LH-SS10-2512','ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
  -- AND l.`loan_day` BETWEEN '2026-05-01' AND '2026-06-30'
  -- 注意！！！ 校验放款时间的筛选是否符合需求
  AND l.loan_day BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
;