-- ============================================================================
-- 脚本名称: ads_hain_g23_1_risk_share.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G23-1 担保业务风险分担情况月度报送（按上月放款数据，逐笔生成风险分担记录）
-- 源表:     prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--           prod_dw_01.ods_cons_td_loan_incr_delta
--           hain_effective_data_interval
-- 目标表:   ads_hain_g23_1_risk_share
-- 写入模式: INSERT INTO TABLE PARTITION(pt)（动态分区追加写入）
-- 增量方式: 月度全量（按上月放款区间，直接插入当月报送数据）
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-26
-- 修订记录:
--   2026-08-26  <name>  新建脚本  -  新建脚本，原 DMS old_G23_1.sql 迁移至 MaxCompute
-- 迁移说明（原 old_G23_1.sql → MC）:
--   1. 源表按《表名映射关系.md》替换：
--        prd_spark_db.dwd_cons_loan_payment_info_d → prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--        prd_spark_db.ods_cons_td_loan             → prod_dw_01.ods_cons_td_loan_incr_delta
--        test_zxbs_db.hain_effective_data_interval → hain_effective_data_interval（跨 project 需补 schema 前缀）
--   2. CURDATE() → GETDATE()（MC 不支持 CURDATE）
--   3. DATE_SUB(CURDATE(), INTERVAL 1 MONTH) → DATEADD(GETDATE(), -1, 'mm')
--   4. DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') → CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')（MC 日期格式串用小写）
--   5. last_day(l.loan_day) → CAST(LAST_DAY(l.loan_day) AS DATE)（对齐目标 ddate DATE 类型）
--   6. CAST(... AS INTEGER) → CAST(... AS BIGINT)（xh 序号字段，对齐 DDL BIGINT，防溢出）
--   7. 去除反引号，补行内注释；INSERT 字段补中文注释（读自 new_hainanDDL.sql）
--   8. 改为 PARTITION(pt) 动态分区；pt=TO_CHAR(ddate,'yyyymm')，按 ddate 所在月份取值
--   9. dwd/ods 增量 delta 表新增 pt <= TO_CHAR(GETDATE(),'yyyymmdd') 过滤，排除未来分区
--  10. SELECT 列表按目标表 new_hainanDDL.sql 声明类型逐一 CAST（STRING/DATE/BIGINT/DECIMAL(20,6)）
-- 风险提示:
--   - 目标表为 Delta 事务主键表（主键 cont_no, ddate），INSERT INTO 同月重跑会触发主键冲突，建议重跑前先清理当月分区或改用 MERGE INTO
--   - pt 比较的 GETDATE() 为运行时函数，MC 无法在编译期做分区裁剪，建议改用调度参数 ${bizdate}/${bizmonth}
--   - hain_effective_data_interval 跨 project（prod_bs_dw），若不在当前 project 需补 schema 前缀
--   - 原脚本未写 create_time/update_time，DDL 已移除默认值，这两个字段将为 NULL；如需赋值请在 SELECT 补 GETDATE()
--   - LAST_DAY/DATEADD 为 MC 2.0 扩展函数，若项目未开启 2.0 数据类型需补 SET odps.sql.type.system.odps2=true;
-- 业务说明:
--   - 一个项目可能有多个担保方，本场景只取机构自身的风险承担比例（org_ratio=1, 其余=0, total_ratio=1）
--   - 以下比例字段需在项目维表或产品维表中人工维护，当前硬编码为默认值
-- ============================================================================
-- DataWorks 调度参数配置：
--   bizdate=$bizdate        -- yyyymmdd 业务日期（T-1）
--   bizmonth=$bizmonth      -- yyyymm 业务月（上月）

INSERT INTO TABLE ads_hain_g23_1_risk_share PARTITION(pt)
(
    dbank_id,            -- 机构代码
    ddate,               -- 报表日期
    xh,                  -- 序号
    cont_no,             -- 合同编号
    biz_no,              -- 业务编号
    project_name,        -- 项目名称
    org_ratio,           -- 机构自身风险承担比例
    natl_fund_ratio,     -- 国家级担保基金机构风险承担比例
    prov_fund_ratio,     -- 省级担保基金机构风险承担比例
    prov_gov_ratio,      -- 省级人民政府风险承担比例
    prov_comp_ratio,     -- 省级融资担保公司风险承担比例
    city_fund_ratio,     -- 市级担保基金风险承担比例
    city_gov_ratio,      -- 市级人民政府风险承担比例
    city_comp_ratio,     -- 市级融资担保公司风险承担比例
    county_gov_ratio,    -- 县级人民政府风险承担比例
    county_comp_ratio,   -- 县级融资担保公司风险承担比例
    pbank_ratio,         -- 国家开发银行及政策性银行风险承担比例
    big4_ratio,          -- 四大国有商业银行风险承担比例
    joint_stock_ratio,   -- 股份制商业银行风险承担比例
    city_bank_ratio,     -- 城市商业银行风险承担比例
    rural_fin_ratio,     -- 农村合作金融机构风险承担比例
    ins_ratio,           -- 保险公司机构风险承担比例
    other_ratio,         -- 其他各类机构风险承担比例
    total_ratio,         -- 合计各类机构风险承担比例
    pt                   -- 报表月份 yyyymm（动态分区列，按 ddate 所在月份取值）
)
SELECT
    -- 以下每列按目标表 new_hainanDDL.sql 声明类型逐一 CAST
    CAST('DEFAULT_BANK' AS STRING)                                  AS dbank_id,          -- 机构代码
    CAST(LAST_DAY(l.loan_day) AS DATE)                             AS ddate,             -- 报表日期（上月末）
    CAST(ROW_NUMBER() OVER (ORDER BY l.bill_app_no) AS BIGINT)     AS xh,                -- 序号（按合同编号排序）
    CAST(l.bill_app_no AS STRING)                                  AS cont_no,           -- 合同编号
    CAST(l.bill_app_no AS STRING)                                  AS biz_no,           -- 业务编号
    CAST(e.project_name AS STRING)                                 AS project_name,     -- 项目名称
    -- 以下比例字段需在项目维表或产品维表中人工维护，当前硬编码为默认值
    CAST(1 AS DECIMAL(20,6))                                       AS org_ratio,         -- 机构自身风险承担比例
    CAST(0 AS DECIMAL(20,6))                                        AS natl_fund_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS prov_fund_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS prov_gov_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS prov_comp_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS city_fund_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS city_gov_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS city_comp_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS county_gov_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS county_comp_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS pbank_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS big4_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS joint_stock_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS city_bank_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS rural_fin_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS ins_ratio,
    CAST(0 AS DECIMAL(20,6))                                        AS other_ratio,
    CAST(1 AS DECIMAL(20,6))                                       AS total_ratio,      -- 合计各类机构风险承担比例
    -- ========= 动态分区列 pt 必须是 SELECT 列表最后一列 =========
    -- 按 ddate（上月末）的月份取 yyyymm，与 new_hainanDDL "按ddate的月份分区"一致
    CAST(TO_CHAR(CAST(LAST_DAY(l.loan_day) AS DATE), 'yyyymm') AS STRING) AS pt
FROM (
    -- /*---------------- 消金 ----------------------*/
    SELECT product_no, bill_app_no, loan_day
    FROM prod_dw_01.dwd_cons_loan_payment_info_incr_delta
    WHERE pt <= TO_CHAR(GETDATE(), 'yyyymmdd')   -- 排除未来分区

    UNION ALL

    -- /*---------------- 消金简版（通道消金） ----------------------*/
    SELECT product_no, loan_no AS bill_app_no, loan_date AS loan_day
    FROM prod_dw_01.ods_cons_td_loan_incr_delta
) l
JOIN hain_effective_data_interval e
    ON l.product_no = e.project_code
    AND l.loan_day BETWEEN e.start_date AND e.end_date
WHERE l.loan_day BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND
        LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;
