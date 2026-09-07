-- ============================================================================
-- 脚本名称: ads_cq_financial_report_business_d_ddl.sql
-- 表名: ads_cq_financial_report_business_d
-- 层级: ADS层（应用数据层）
-- 业务域: 重庆淘然/担保报送
-- 表类型: Delta 主键表（支持 MERGE INTO 增量更新）
-- 分区字段: data_date (STRING, yyyy-MM-dd)
-- 主键: (project_code, contract_number, obs_date) 三字段均加 NOT NULL
-- 源表: test_zxbs_db.ads_cq_financial_report_business_d
-- 描述: 业务数据表（重庆金融局担保业务报送日报）
-- 调度参数: datadt=$bizdate
-- 负责人: <name>
-- 创建日期: 2026-08-17
-- 迁移说明:
--   1. 原 Xihe DDL 转换为 MC Delta 主键表
--   2. data_date 从字段列移至 PARTITIONED BY（分区字段）
--   3. 主键 (project_code, contract_number, obs_date) 三字段加 NOT NULL，移除 NOT ENFORCED
--   4. 移除 DISTRIBUTE BY HASH / STORAGE_POLICY / ENGINE / TABLE_PROPERTIES
--   5. 移除 KEY 索引（MC Delta 表不支持二级索引）
--   6. 移除 DEFAULT 约束（MC Delta 表不支持字段级 DEFAULT）
--   7. 非主键字段移除 NOT NULL 约束（主键字段保留 NOT NULL，MC Delta 主键强制要求）
--   8. 字段名和字段类型保持原样不变
-- ============================================================================

DROP TABLE IF EXISTS ads_cq_financial_report_business_d;

CREATE TABLE IF NOT EXISTS ads_cq_financial_report_business_d (
    `org_code`                  varchar(30)   COMMENT '机构编码',
    `project_code`              varchar(90)   NOT NULL COMMENT '项目编码',
    `cust_type`                 varchar(1)    COMMENT '客户类型（1企业客户 2个人客户）',
    `cust_id`                   varchar(64)   COMMENT '客户编码',
    `cust_name`                 varchar(180)  COMMENT '客户名称',
    `cert_type`                 varchar(1)    COMMENT '证件类型（1军官证 2护照 3身份证 4其他）',
    `cert_number`               varchar(30)   COMMENT '证件编码(企业填法人代表对应的证件编码)',
    `industry_code`             varchar(128)  COMMENT '所属行业编码',
    `industry_name`             varchar(128)  COMMENT '所属行业名称',
    `user_zone_code`            varchar(128)  COMMENT '所属区域编码',
    `user_zone_name`            varchar(128)  COMMENT '所属区域名称',
    `user_scale`                varchar(1)    COMMENT '客户规模编码（1大型企业 2中型企业 3小型企业 4微型企业）',
    `is_relate_agriculture`     varchar(1)    COMMENT '是否涉农 (1-是,2-否)',
    `business_type`             varchar(4)    COMMENT '业务类型（10 融资性担保业务 1001流动资金贷款担保..）',
    `contract_amount`           decimal(20,2) COMMENT '合同金额',
    `loan_amount`               decimal(20,2) COMMENT '已放款金额',
    `loan_rate`                 decimal(7,5)  COMMENT '贷款年利率，利率3.45%  报文传输0.03450',
    `guarantee_sum_rate`        decimal(7,5)  COMMENT '担保综合费率，利率3.45%  报文传输0.03450',
    `loan_date`                 varchar(10)   COMMENT '放款日期 yyyy-MM-dd',
    `contract_end_date`         varchar(10)   COMMENT '合同截止日期 yyyy-MM-dd',
    `repayment_type`            varchar(1)    COMMENT '还款方式(1按月等额本金 2按月等额本息 3按季等额本金 4按季等额本息 5按月付息一次还本 6到期一次性还本付息 7不规则 8其他)',
    `counter_guarantee_measures` varchar(1)   COMMENT '反担保措施(1抵押 2质押 3保证 4信用 5其他(请传入对应的数字)',
    `counter_guarantee_measures_memo` varchar(900) COMMENT '反担保备注',
    `bank_credit_tag`           varchar(32)   COMMENT '银行授信记录标识，填写银行授信记录 id(32 位 UUID)。',
    `project_status`            varchar(2)    COMMENT '项目状态(60保后监管 70项目逾期 80项目代偿 85项目追偿 90项目解保)',
    `surety_man`                varchar(128)  COMMENT '担保人，债权人',
    `counter_guarantee_amount`  decimal(20,2) COMMENT '反担保物价值是算的是总的反担保物价值',
    `is_deposit_pledge`         varchar(1)    COMMENT '是否存单质押（1是 2否）',
    `processing_time`           datetime      COMMENT '受理时间',
    `contract_number`           varchar(90)   NOT NULL COMMENT '合同编码(一个合同编码只能对应一个项目编码)',
    `cust_deposit_received`     decimal(20,2) COMMENT '客户存入保证金',
    `cust_deposits_paid`        decimal(20,2) COMMENT '客户存出保证金',
    `capital_property`          varchar(1)    COMMENT '资本属性(1国有控股 2民营控股 3外资控股(请传入对应的数字))',
    `project_end_date`          varchar(10)   COMMENT '项目结束时间(项目实际解除日期)yyyy-MM-dd',
    `push_status`               varchar(1)    COMMENT '推送状态(0未推送 1推送中 2推送成功 3推送失败)',
    `revoke_flag`               varchar(10)   COMMENT '撤销标识（1撤销）',
    `project_name`              varchar(100)  COMMENT '项目名称',
    `obs_date`                  varchar(10)   NOT NULL COMMENT '推送日期',
    `create_by`                 varchar(64)   COMMENT '创建者',
    `create_Time`               datetime      COMMENT '创建时间',
    `update_by`                 varchar(64)   COMMENT '更新者',
    `update_Time`               datetime      COMMENT '更新时间',
    PRIMARY KEY (`project_code`, `contract_number`, `obs_date`)
)
COMMENT '业务数据表'
PARTITIONED BY (
    `data_date`                 varchar(10)   COMMENT '数据日期 yyyy-MM-dd'
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);
