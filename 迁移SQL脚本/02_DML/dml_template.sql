-- ===================================================
-- 脚本名称: <layer>_<table_name>_di.sql (日增量) / _df.sql (日全量)
-- 所属层级: <DWD|DWS|ADS|DIM>
-- 业务域: <交易域|用户域|...>
-- 功能描述: <ETL 逻辑说明>
-- 源表: <source_table>
-- 目标表: <target_table>
-- 调度参数: ${bizdate} 业务日期(yyyymmdd)
-- 负责人: <name>
-- 创建日期: <YYYY-MM-DD>
-- 修改记录:
--   <YYYY-MM-DD> 初版
-- ===================================================

-- 日增量 ETL 示例
INSERT OVERWRITE TABLE <target_table> PARTITION (ds='${bizdate}')
SELECT
    s.id,
    s.user_id,
    s.amount,
    s.status,
    s.create_time,
    s.update_time
FROM <source_table> s
WHERE s.ds = '${bizdate}'
  AND s.status IS NOT NULL
;

-- 日全量 ETL 示例（拉链/全量快照）
-- INSERT OVERWRITE TABLE <target_table> PARTITION (ds='${bizdate}')
-- SELECT
--     s.id,
--     s.user_id,
--     s.amount,
--     s.status,
--     s.create_time,
--     s.update_time
-- FROM <source_table> s
-- WHERE s.ds = '${bizdate}'
-- ;
