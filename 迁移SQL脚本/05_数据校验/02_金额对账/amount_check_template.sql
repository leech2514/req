-- ===================================================
-- 脚本名称: <table_name>_amount_chk.sql
-- 类型: 金额对账
-- 功能: 对比新旧平台关键金额指标是否一致
-- 调度参数: ${bizdate}
-- 负责人: <name>
-- 创建日期: <YYYY-MM-DD>
-- ===================================================

-- 1. 总金额对账
SELECT
    'mc' AS src,
    COUNT(*)          AS order_cnt,
    SUM(amount)       AS total_amount,
    AVG(amount)       AS avg_amount,
    MAX(amount)       AS max_amount,
    MIN(amount)       AS min_amount
FROM <mc_table>
WHERE ds = '${bizdate}'
;

-- 2. Xihe 对照
-- SELECT
--     'xihe' AS src,
--     COUNT(*)          AS order_cnt,
--     SUM(amount)       AS total_amount,
--     AVG(amount)       AS avg_amount,
--     MAX(amount)       AS max_amount,
--     MIN(amount)       AS min_amount
-- FROM <xihe_table>
-- WHERE ds = '${bizdate}'
-- ;

-- 3. 按维度分组对账（更精细）
-- SELECT
--     'mc' AS src,
--     user_id,
--     COUNT(*) AS cnt,
--     SUM(amount) AS total
-- FROM <mc_table>
-- WHERE ds = '${bizdate}'
-- GROUP BY user_id
-- ;

-- 4. 差异容忍度检查
-- 金额类差异容忍度: 0（必须完全一致）
-- 计数类差异容忍度: 0.01%（1万条允许1条差异）
