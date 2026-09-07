-- ===================================================
-- 脚本名称: <layer>_<table_name>_chk.sql
-- 类型: 行数对账
-- 功能: 对比新旧平台表行数是否一致
-- 调度参数: ${bizdate} 业务日期
-- 负责人: <name>
-- 创建日期: <YYYY-MM-DD>
-- ===================================================

-- 1. MaxCompute 表行数
SELECT 'mc_table' AS src, COUNT(*) AS cnt
FROM <mc_table>
WHERE ds = '${bizdate}'
;

-- 2. Xihe 表行数（迁移期间双跑对账时使用）
-- SELECT 'xihe_table' AS src, COUNT(*) AS cnt
-- FROM <xihe_table>
-- WHERE ds = '${bizdate}'
-- ;

-- 3. 一次性对比（需两个数据源可同时访问时使用）
-- SELECT
--     'mc' AS src, COUNT(*) AS cnt
-- FROM <mc_table> WHERE ds='${bizdate}'
-- UNION ALL
-- SELECT
--     'xihe' AS src, COUNT(*) AS cnt
-- FROM <xihe_table> WHERE ds='${bizdate}'
-- ;

-- 4. 差异分析（找出 MC 中多出/缺失的记录）
-- SELECT 'mc_only' AS src, COUNT(*) AS cnt
-- FROM <mc_table> mc
-- LEFT ANTI JOIN <xihe_table> xihe
--   ON mc.id = xihe.id
--   AND xihe.ds = '${bizdate}'
-- WHERE mc.ds = '${bizdate}'
-- ;
