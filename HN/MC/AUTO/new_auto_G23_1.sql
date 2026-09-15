-- ============================================================================
-- 脚本名称: new_auto_G23_1.sql
-- 层级:     ADS
-- 业务域:   海南正堂/车贷担保报送
-- 功能描述: 车贷 G23_1 担保业务风险分担情况月度报送
--           （比例字段暂人工固定：机构自身 100%，其余各方 0；后续在项目维表维护）
-- 源表:     prod_dw_01.dwd_auto_oapi_loan_incr_delta（车贷放款信息表，映射 005，pt=yyyymm 月分区）
--           hain_effective_data_interval（海南有效数据区间配置表，prod_bs_dw，映射 004）
-- 目标表:   ads_hain_g23_1_risk_share（Delta 事务主键分区表，主键 (cont_no,ddate)，分区 pt=yyyymm，映射 008）
-- 写入模式: INSERT INTO 动态分区（按月追加）
-- 调度周期: 月度（每月初跑上月数据，放款时间取上月 1 号至上月末）
-- 负责人:   <name>
-- 创建日期: 2026-09-14
-- ============================================================================

SET odps.sql.reshuffle.dynamicpt = true;

INSERT INTO TABLE ads_hain_g23_1_risk_share PARTITION(pt)
(
    dbank_id, ddate, xh, cont_no, biz_no, project_name,
    org_ratio, natl_fund_ratio, prov_fund_ratio, prov_gov_ratio, prov_comp_ratio,
    city_fund_ratio, city_gov_ratio, city_comp_ratio,
    county_gov_ratio, county_comp_ratio,
    pbank_ratio, big4_ratio, joint_stock_ratio, city_bank_ratio,
    rural_fin_ratio, ins_ratio, other_ratio, total_ratio,
    pt
)
SELECT
    CAST('DEFAULT_BANK' AS STRING)                            AS dbank_id,    -- 机构代码
    CAST(LAST_DAY(l.loan_day) AS DATE)                        AS ddate,       -- 报表日期：放款月月末
    ROW_NUMBER() OVER (ORDER BY l.bill_app_no)                AS xh,          -- 序号
    l.bill_app_no                                             AS cont_no,     -- 合同编号
    l.bill_app_no                                             AS biz_no,      -- 业务编号
    e.project_name                                            AS project_name,-- 项目名称

    -- 以下风险承担比例暂人工固定，后续改为项目/产品维表取值
    CAST(1 AS DECIMAL(20,6))                                  AS org_ratio,           -- 机构自身风险承担比例
    CAST(0 AS DECIMAL(20,6))                                  AS natl_fund_ratio,     -- 国家级担保基金
    CAST(0 AS DECIMAL(20,6))                                  AS prov_fund_ratio,     -- 省级担保基金
    CAST(0 AS DECIMAL(20,6))                                  AS prov_gov_ratio,      -- 省级人民政府
    CAST(0 AS DECIMAL(20,6))                                  AS prov_comp_ratio,     -- 省级融资担保公司
    CAST(0 AS DECIMAL(20,6))                                  AS city_fund_ratio,     -- 市级担保基金
    CAST(0 AS DECIMAL(20,6))                                  AS city_gov_ratio,      -- 市级人民政府
    CAST(0 AS DECIMAL(20,6))                                  AS city_comp_ratio,     -- 市级融资担保公司
    CAST(0 AS DECIMAL(20,6))                                  AS county_gov_ratio,    -- 县级人民政府
    CAST(0 AS DECIMAL(20,6))                                  AS county_comp_ratio,   -- 县级融资担保公司
    CAST(0 AS DECIMAL(20,6))                                  AS pbank_ratio,         -- 国开行及政策性银行
    CAST(0 AS DECIMAL(20,6))                                  AS big4_ratio,          -- 四大国有商业银行
    CAST(0 AS DECIMAL(20,6))                                  AS joint_stock_ratio,   -- 股份制商业银行
    CAST(0 AS DECIMAL(20,6))                                  AS city_bank_ratio,     -- 城市商业银行
    CAST(0 AS DECIMAL(20,6))                                  AS rural_fin_ratio,     -- 农村合作金融机构
    CAST(0 AS DECIMAL(20,6))                                  AS ins_ratio,           -- 保险公司
    CAST(0 AS DECIMAL(20,6))                                  AS other_ratio,         -- 其他各类机构
    CAST(1 AS DECIMAL(20,6))                                  AS total_ratio,         -- 合计

    TO_CHAR(CAST(LAST_DAY(l.loan_day) AS DATE), 'yyyymm')     AS pt           -- 报表月份分区
FROM prod_dw_01.dwd_auto_oapi_loan_incr_delta l
JOIN hain_effective_data_interval e
  ON l.product_no = e.project_code
 AND l.loan_day BETWEEN e.start_date AND e.end_date
WHERE l.product_no IN ('ZT-LH-SS10-2512', 'ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
  -- 放款时间：上月 1 号至上月末
  AND l.loan_day BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
  AND l.pt = TO_CHAR(DATEADD(GETDATE(), -1, 'mm'), 'yyyymm')
  AND e.is_use = 'Y'
;
