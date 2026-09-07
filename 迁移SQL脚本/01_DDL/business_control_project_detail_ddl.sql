-- ============================================================================
-- 表名: business_control_project_detail
-- 层级: ODS层（原始数据层）
-- 业务域: bc（业务管控域）
-- 源表: f_prd_spark_db.business_control_project_detail
-- 同步方式: 全量（full）
-- 分区类型: 日分区（d）
-- 表类型: 普通分区表（STORED AS aliorc，非事务）
-- 描述: 业务管控项目信息详情表
-- 调度参数: ${bdp.system.bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-14
-- ============================================================================

DROP TABLE IF EXISTS business_control_project_detail;

CREATE TABLE IF NOT EXISTS business_control_project_detail (
    `project_id`              BIGINT        COMMENT '项目详情—主键',
    `project_name`            STRING        COMMENT '项目名称',
    `control_type`            STRING        COMMENT '业务管控类型：1-金融局 2-资方',
    `guarantee_company_id`    BIGINT        COMMENT '担保公司ID: sys_company表中类型为担保公司（855）的ID',
    `asset_company_id`        BIGINT        COMMENT '资产端公司ID: sys_company表中类型为资产方（856）的ID',
    `fund_company_id`         BIGINT        COMMENT '资金端公司ID: sys_company表中类型为资金方（857）的ID',
    `guarantee_type`          STRING        COMMENT '担保类型：1-自有业务担保 2-拓展业务直保 3-拓展业务分保',
    `max_loan_limit`          DECIMAL(38,18) COMMENT '最大在贷限额-单位：元',
    `earnest_money`           DECIMAL(38,18) COMMENT '保证金—单位：元',
    `margin_rate`             DECIMAL(38,18) COMMENT '保证金比例',
    `control_rules_type`      STRING        COMMENT '是否已添加管控规则：1-是 0-否',
    `is_control_flag`         STRING        COMMENT '是否管控中：1-是 0-否',
    `business_control_rule_id` BIGINT       COMMENT '业务管控规则Id（新）',
    `create_time`             TIMESTAMP     COMMENT '首次配置时间',
    `update_time`             TIMESTAMP     COMMENT '最后修改时间',
    `earnest_rate`            DECIMAL(38,18) COMMENT '保证金比例(百分数,5=5%); 应存出保证金=在贷×earnest_rate/100',
    `guarantee_rate`          DECIMAL(38,18) COMMENT '担保费率(百分数,5=5%)',
    `create_status`           STRING        COMMENT '创建状态: 空/NULL=已创建(历史数据), draft=暂存',
    `business_type`           STRING        COMMENT '业务类型(关联business_control_business_type.type_name)',
    `display_page`            STRING        COMMENT '展示页面(字典 business_control_display_page)'
)
COMMENT '业务管控项目信息详情表'
STORED AS aliorc
TBLPROPERTIES (
    'cdc.data.retain.hours'      = '24',
    'acid.cdc.mode.enable'       = 'false',
    'acid.data.retain.hours'     = '24',
    'columnar.nested.type'       = 'true',
    'comment'                    = '业务管控规则表',
    'transactional'              = 'true',
    'write.bucket.num'           = '1'
)
;
