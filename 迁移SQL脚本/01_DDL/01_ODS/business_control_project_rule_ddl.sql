-- ===================================================
-- 脚本名称: business_control_project_rule_df_original_ddl.sql
-- 所属层级: ODS
-- 业务域: 风控/管控域
-- 功能描述: 业务管控规则表日全量快照入仓（原始 DDL 版本，保留源语法原貌）
-- 源表: prod_f_dw.business_control_project_rule
-- 目标表: business_control_project_rule_df
-- 调度参数: ${bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-14
-- 说明: 本文件保留原始 DDL 语法（DOUBLE、PRIMARY KEY、TBLPROPERTIES），
--       作为模板库的迁移对照样例。
--       需要适配 MC 标准版的请参考同目录下同名非 original 版本。
-- ===================================================

DROP TABLE IF EXISTS prod_f_dw.business_control_project_rule;

CREATE TABLE IF NOT EXISTS prod_f_dw.business_control_project_rule
 (
     project_rule_id           BIGINT NOT NULL COMMENT '业务管控规则ID—主键'
     ,control_type             STRING COMMENT '业务管控类型：1-金融局；2-资方'
     ,project_id               INT COMMENT '业务管控项目ID'
     ,old_project_id           INT COMMENT '原项目ID'
     ,import_type              STRING COMMENT '导入方式：1-自动；2-手动'
     ,loaded_flag              STRING COMMENT '是否已装入：T-是；F-否'
     ,`status`                 STRING COMMENT '状态：1-计算在贷中；2-等待风险确认；3-等待装入确认；4-等待审核；5-审核通过；6-审核不通过；7-已装入；8-装入失败；9-规则生效中；10-暂停自动导入；11-恢复自动导入；12-修改待审核；13-修改审核通过；14-修改审核不通过；15-删除规则申请中；16-删除规则通过；17-删除规则驳回（中间 3~4/7~16 由业务流程推断，上线前请对照业务代码复核）'
     ,predict_loan_amount      DOUBLE COMMENT '预估导入在贷金额—单位：元'
     ,loan_amount              DOUBLE COMMENT '实际导入在贷金额—单位：元'
     ,margin_rate              DOUBLE COMMENT '保证金比例'
     ,over_predict_loan_amount DOUBLE COMMENT '超限后根据限制重新获取预估金额'
     ,max_loan_date            STRING COMMENT '超限后获取预估导入的最大放款时间'
     ,imported_data_type       STRING COMMENT '已导入数据处理方式：0-删除；1-保留'
     ,rule_description         STRING COMMENT '规则描述'
     ,task_status              STRING COMMENT '定时任务执行状态：0-未执行；1-执行完毕；99-执行中'
     ,business_control_rule_id BIGINT COMMENT '业务管控规则Id（新）'
     ,create_time              DATETIME COMMENT '首次配置时间'
     ,update_time              DATETIME COMMENT '最后修改时间'
     ,natural_days             INT COMMENT '记账与放款超N自然日不装入'
     ,import_success_time      DATETIME COMMENT '导入成功时间'
     ,PRIMARY KEY (project_rule_id)
 )
 STORED AS aliorc
 TBLPROPERTIES (
    'cdc.data.retain.hours'      = '24',
    'acid.cdc.mode.enable'       = 'false',
    'acid.data.retain.hours'     = '24',
    'columnar.nested.type'       = 'true',
    'comment'                    = '业务管控规则表',
    'transactional'              = 'true',
    'write.bucket.num'           = '16'
 )
 ;
