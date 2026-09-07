-- ============================================================================
-- 表名: business_control_page_guide
-- 层级: ODS层（原始数据层）
-- 业务域: bc（业务管控域）
-- 源表: f_prd_spark_db.business_control_page_guide
-- 同步方式: 全量（full）
-- 分区类型: 日分区（d）
-- 表类型: 普通分区表（STORED AS aliorc，非事务）
-- 描述: 业务管控-页面使用说明
-- 调度参数: ${bdp.system.bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-14
-- ============================================================================

DROP TABLE IF EXISTS business_control_page_guide;

CREATE TABLE IF NOT EXISTS prod_f_dw.business_control_page_guide
(
    id           BIGINT COMMENT '主键'
    ,page_path   STRING COMMENT '页面路由(不含basePath, 如 /yewuguankong/control-rules)'
    ,page_name   STRING COMMENT '页面名称'
    ,title       STRING COMMENT '说明条目标题'
    ,content     STRING COMMENT '说明条目内容'
    ,sort_order  BIGINT COMMENT '排序(同页面内升序)'
    ,`status`    STRING COMMENT '状态(0正常 1删除)'
    ,create_by   STRING COMMENT '创建人'
    ,create_time TIMESTAMP COMMENT '创建时间'
    ,update_by   STRING COMMENT '更新人'
    ,update_time TIMESTAMP COMMENT '更新时间'
)
PARTITIONED BY 
(
    pt           STRING COMMENT '业务日期 yyyymmdd'
)
STORED AS aliorc
TBLPROPERTIES ('acid.data.retain.hours' = '24','cdc.data.retain.hours' = '24','columnar.nested.type' = 'true','comment' = '业务管控-页面使用说明','transactional' = 'true','acid.cdc.mode.enable' = 'false','write.bucket.num' = '1')
LIFECYCLE 365
;