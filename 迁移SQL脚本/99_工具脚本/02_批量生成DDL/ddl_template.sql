-- ===================================================
-- 脚本名称: <layer>_<table_name>_ddl.sql
-- 所属层级: <ODS|DWD|DWS|ADS|DIM>
-- 业务域: <交易域|用户域|商品域|...>
-- 功能描述: <表用途说明>
-- 负责人: <name>
-- 创建日期: <YYYY-MM-DD>
-- 修改记录:
--   <YYYY-MM-DD> 初版
-- ===================================================

-- 删除已存在的表（谨慎，开发环境使用）
-- DROP TABLE IF EXISTS <table_name>;

CREATE TABLE IF NOT EXISTS <table_name> (
    id              BIGINT          COMMENT '主键ID',
    user_id         BIGINT          COMMENT '用户ID',
    amount          DECIMAL(18,2)   COMMENT '金额',
    status          STRING          COMMENT '状态',
    create_time     DATETIME        COMMENT '创建时间',
    update_time     DATETIME        COMMENT '更新时间'
)
COMMENT '<表说明>'
PARTITIONED BY (
    ds              STRING          COMMENT '业务日期 yyyymmdd'
)
-- 可选: 分桶（大表 JOIN 优化）
-- CLUSTERED BY (user_id) SORTED BY (id) INTO 32 BUCKETS
-- 可选: 生命周期（自动回收历史分区）
LIFECYCLE 365
;
