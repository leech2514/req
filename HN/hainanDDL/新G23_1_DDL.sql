-- ============================================================================
-- 脚本名称: 新G23_1_DDL.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G23-1 担保业务风险分担情况信息表（事务表，按报表日期月份分区）
-- 源表:     test_zxbs_db.ads_hain_g23_1_risk_share（原 XUANWU_V2 列存表）
-- 目标表:   ads_hain_g23_1_risk_share
-- 表类型:   Delta 事务主键表（transactional=true，支持 ACID + MERGE INTO）
-- 主键:     (cont_no, ddate)（合同编号 + 报表日期，原复合主键保留不变）
-- 分区字段: pt (STRING, yyyymm，取自 ddate 报表日期所在月份)
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-26
-- 修订记录:
--   2026-08-26  <name>  新建脚本  -  新建脚本，原 XUANWU_V2 列存表迁移为 MaxCompute Delta 事务主键表
-- 迁移说明（原 G23_1.sql → MC）:
--   1. 表名 ads_hain_g23_1_risk_share 保持不变；字段名保持不变；主键 (cont_no, ddate) 保持不变
--   2. varchar(N) → STRING（MC 无 varchar，统一 STRING；长度不影响存储）
--   3. date → DATE（MC 原生支持）
--   4. int → BIGINT（xh 序号字段，按规范用 BIGINT 防溢出）
--   5. decimal(20,6) → DECIMAL(20,6)（保持不变）
--   6. datetime → TIMESTAMP（保留类型；移除 DEFAULT CURRENT_TIMESTAMP 与 ON UPDATE CURRENT_TIMESTAMP，MC 字段级不支持此类默认值，改由 DML 写入 GETDATE()）
--   7. 主键字段 cont_no/ddate 保留 NOT NULL（Delta 主键表强制要求主键字段显式声明 NOT NULL，且不使用 NOT ENFORCED 关键字）
--   8. 保留 dbank_id/ddate/xh/cont_no/biz_no 的 NOT NULL 约束（原表即有，MC 支持）
--   9. 移除 KEY pk_sys_cont_no / pk_sys_ddate 二级索引（MC 不支持二级索引，主键已覆盖 cont_no 查询）
--  10. 移除 DISTRIBUTE BY HASH / STORAGE_POLICY='HOT' / ENGINE='XUANWU_V2' / TABLE_PROPERTIES（MC 不支持，Delta 表内置分桶与存储策略）
--  11. 新增分区字段 pt (STRING, yyyymm)，取自 ddate 报表日期所在月份；分区列自动纳入主键唯一性约束，即 (cont_no, ddate, pt) 联合唯一
--  12. 新增 TBLPROPERTIES('transactional'='true') 开启 ACID；非历史回溯场景配 'cdc.data.retain.hours'='0'、'acid.data.retain.hours'='0' 降低存储
-- 风险提示:
--   - Delta 分区表的主键唯一性为 (cont_no, ddate, pt) 联合：ddate 决定 pt，(cont_no, ddate) 已天然唯一，分区不破坏主键语义
--   - Delta 表不支持 INSERT OVERWRITE，DML 必须用 INSERT INTO 或 MERGE INTO
--   - create_time/update_time 已移除默认值，DML 写入时需显式赋 GETDATE()，否则为 NULL
-- ============================================================================

CREATE TABLE IF NOT EXISTS ads_hain_g23_1_risk_share (
    dbank_id            STRING          NOT NULL    COMMENT '机构代码',
    ddate               DATE            NOT NULL    COMMENT '报表日期',
    xh                  BIGINT          NOT NULL    COMMENT '序号',
    cont_no             STRING          NOT NULL    COMMENT '合同编号',
    biz_no              STRING          NOT NULL    COMMENT '业务编号',
    org_ratio           DECIMAL(20,6)               COMMENT '机构自身风险承担比例',
    natl_fund_ratio     DECIMAL(20,6)               COMMENT '国家级担保基金机构风险承担比例',
    prov_fund_ratio     DECIMAL(20,6)               COMMENT '省级担保基金机构风险承担比例',
    prov_gov_ratio      DECIMAL(20,6)               COMMENT '省级人民政府风险承担比例',
    prov_comp_ratio     DECIMAL(20,6)               COMMENT '省级融资担保公司风险承担比例',
    city_fund_ratio     DECIMAL(20,6)               COMMENT '市级担保基金风险承担比例',
    city_gov_ratio      DECIMAL(20,6)               COMMENT '市级人民政府风险承担比例',
    city_comp_ratio     DECIMAL(20,6)               COMMENT '市级融资担保公司风险承担比例',
    county_gov_ratio    DECIMAL(20,6)               COMMENT '县级人民政府风险承担比例',
    county_comp_ratio   DECIMAL(20,6)               COMMENT '县级融资担保公司风险承担比例',
    pbank_ratio         DECIMAL(20,6)               COMMENT '国家开发银行及政策性银行风险承担比例',
    big4_ratio          DECIMAL(20,6)               COMMENT '四大国有商业银行风险承担比例',
    joint_stock_ratio   DECIMAL(20,6)               COMMENT '股份制商业银行风险承担比例',
    city_bank_ratio     DECIMAL(20,6)               COMMENT '城市商业银行风险承担比例',
    rural_fin_ratio    DECIMAL(20,6)               COMMENT '农村合作金融机构风险承担比例',
    ins_ratio           DECIMAL(20,6)               COMMENT '保险公司机构风险承担比例',
    other_ratio         DECIMAL(20,6)               COMMENT '其他各类机构风险承担比例',
    total_ratio         DECIMAL(20,6)               COMMENT '合计各类机构风险承担比例',
    create_time         TIMESTAMP                   COMMENT '创建时间',
    update_time         TIMESTAMP                   COMMENT '更新时间',
    project_name        STRING                      COMMENT '项目名称',
    PRIMARY KEY (cont_no, ddate)
)
PARTITIONED BY (
    pt STRING COMMENT '报表月份 yyyymm（取自 ddate 报表日期所在月份）'
)
TBLPROPERTIES (
    'transactional'='true',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours'='0',
    'comment'='担保业务风险分担情况信息表'
)
;
