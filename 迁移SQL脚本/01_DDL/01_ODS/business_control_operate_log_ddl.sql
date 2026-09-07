-- ===================================================
-- 脚本名称: business_control_operate_log_ddl.sql
-- 所属层级: ODS
-- 业务域: 风控/管控域
-- 功能描述: 业务管控规则操作日志日增量入仓（MaxCompute 标准版）
-- 源表: f_prd_spark_db.business_control_operate_log
-- 目标表: business_control_operate_log
-- 调度参数: ${bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-14
-- ===================================================

DROP TABLE IF EXISTS business_control_operate_log;

CREATE TABLE IF NOT EXISTS business_control_operate_log (
    operate_id          BIGINT          COMMENT '业务管控规则操作日志ID（原自增主键）',
    project_rule_id     BIGINT          COMMENT '业务管控规则ID（原 INT，升级为 BIGINT）',
    operate_type        STRING          COMMENT '操作类型：1-新增管控规则；2-计算在贷完成；3-选择装入；4-选择装入不超限部分；5-发起新增规则审核；6-新增规则审核通过；7-新增规则审核不通过；8-撤销新增；9-新增规则装入失败；10-暂停自动导入；11-恢复自动导入；12-自动导入完成（原注释末尾含左括号字符，原样保留）；13-修改管控规则；14-修改计算在贷完成；15-撤销修改规则；16-发起修改规则审核；17-修改规则审核通过；18-修改规则审核不通过；19-撤销修改；20-修改规则装入失败；21-发起删除规则审核；22-删除规则审核不通过；23-撤销删除',
    records_data        STRING          COMMENT '操作日志详细信息（原 JSON 类型，解析请使用 get_json_object / 或建 DWD 时拆解为结构化字段）',
    create_time         DATETIME        COMMENT '新增时间'
)
COMMENT '业务管控规则操作日志表'
PARTITIONED BY (
    ds                  STRING          COMMENT '业务日期 yyyymmdd'
)
-- Xihe 原 DISTRIBUTE BY HASH(operate_id) → MaxCompute 分桶，按单分区 1~5GB 预估 64 桶
CLUSTERED BY (operate_id) SORTED BY (operate_id) INTO 64 BUCKETS
-- 日志类操作记录建议保留 18 个月，满足合规/审计需求
LIFECYCLE 540
;
