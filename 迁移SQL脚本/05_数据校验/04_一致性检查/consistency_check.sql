-- ===================================================
-- 脚本名称: dwd_trade_order_chk.sql
-- 类型: 一致性检查
-- 功能: 检查 DWD 表的主键唯一性、外键完整性、空值率
-- 调度参数: ${bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-13
-- ===================================================

-- 1. 主键唯一性检查（order_id 应唯一）
SELECT
    '主键重复检查' AS check_item,
    COUNT(*) AS duplicate_cnt
FROM (
    SELECT order_id, COUNT(*) AS cnt
    FROM dwd_trade_order_di
    WHERE ds = '${bizdate}'
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t
;

-- 2. 空值率检查（关键字段不能为空）
SELECT
    '空值检查' AS check_item,
    COUNT(*) AS total_cnt,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_null,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS user_id_null,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS amount_null,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS status_null
FROM dwd_trade_order_di
WHERE ds = '${bizdate}'
;

-- 3. 外键完整性检查（user_id 应在 dim_user_info 中存在）
SELECT
    '外键完整性' AS check_item,
    COUNT(*) AS orphan_cnt
FROM dwd_trade_order_di o
LEFT ANTI JOIN dim_user_info_df u
    ON o.user_id = u.user_id
    AND u.ds = '${bizdate}'
WHERE o.ds = '${bizdate}'
;

-- 4. 业务规则检查（金额 >= 0）
SELECT
    '业务规则' AS check_item,
    COUNT(*) AS invalid_cnt
FROM dwd_trade_order_di
WHERE ds = '${bizdate}'
  AND (amount < 0 OR pay_amount < 0)
;

-- 5. 数据波动检查（与昨日对比，波动 > 20% 告警）
SELECT
    '数据波动' AS check_item,
    cur.cnt AS today_cnt,
    prev.cnt AS yesterday_cnt,
    ROUND((cur.cnt - prev.cnt) * 100.0 / NULLIF(prev.cnt, 0), 2) AS change_pct
FROM (
    SELECT COUNT(*) AS cnt FROM dwd_trade_order_di WHERE ds='${bizdate}'
) cur
CROSS JOIN (
    SELECT COUNT(*) AS cnt FROM dwd_trade_order_di
    WHERE ds = TO_CHAR(DATE_ADD(TO_DATE('${bizdate}','yyyymmdd'), -1), 'yyyymmdd')
) prev
;
