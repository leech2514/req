-- ===================================================
-- 脚本名称: skew_handle.sql
-- 类型: 数据倾斜处理
-- 功能: 检测与处理数据倾斜（热点 key 打散）
-- 负责人: <name>
-- 创建日期: 2026-08-13
-- ===================================================

-- 1. 检测倾斜 key（找出 TOP10 热点 user_id）
SELECT
    user_id,
    COUNT(*) AS cnt
FROM dwd_trade_order_di
WHERE ds = '${bizdate}'
GROUP BY user_id
ORDER BY cnt DESC
LIMIT 10
;

-- 2. 处理方式一: 倾斜 key 单独处理（如 user_id = 0 是异常值）
INSERT OVERWRITE TABLE dws_trade_user_1d_df PARTITION (ds='${bizdate}')
SELECT
    user_id,
    SUM(amount) AS total_amount
FROM dwd_trade_order_di
WHERE ds = '${bizdate}'
  AND user_id != 0          -- 排除异常值
GROUP BY user_id
UNION ALL
SELECT
    0 AS user_id,            -- 异常值单独处理
    SUM(amount) AS total_amount
FROM dwd_trade_order_di
WHERE ds = '${bizdate}'
  AND user_id = 0
;

-- 3. 处理方式二: 加随机前缀打散（适合两表 JOIN 倾斜）
-- 原始（倾斜）：
-- SELECT a.id, b.name FROM big_a a JOIN big_b b ON a.id = b.id;

-- 优化后：加随机前缀
SELECT
    SPLIT_PART(a.skew_id, '_', 2) AS id,
    b.name
FROM (
    SELECT
        CONCAT(CAST(RAND() * 10 AS STRING), '_', id) AS skew_id,
        id,
        amount
    FROM big_table_a
    WHERE ds = '${bizdate}'
) a
JOIN (
    SELECT
        CONCAT(CAST(seq AS STRING), '_', id) AS skew_id,
        id,
        name
    FROM big_table_b t
    LATERAL VIEW EXPLODE(SEQUENCE(0, 9)) t2 AS seq   -- 扩展 10 倍
) b ON a.skew_id = b.skew_id
;

-- 4. 处理方式三: 使用 MAPJOIN（小表广播）
SET odps.sql.mapper.join.memory.shared.cache = true;
SET odps.sql.join.mapjoin.memory.max = 2048;

SELECT /*+ MAPJOIN(b) */
    a.id,
    b.name,
    a.amount
FROM big_table_a a
JOIN small_table_b b ON a.id = b.id
WHERE a.ds = '${bizdate}'
;

-- 5. 处理方式四: 启用 SkewJoin 参数
SET odps.sql.join.skew = true;     -- 启用倾斜优化
SET odps.sql.skewjoin.skew.key = 100000;  -- 倾斜阈值
