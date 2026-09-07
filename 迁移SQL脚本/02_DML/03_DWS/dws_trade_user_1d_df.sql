-- ===================================================
-- 脚本名称: dws_trade_user_1d_df.sql
-- 所属层级: DWS
-- 业务域: 交易域
-- 功能描述: 用户粒度1天汇总全量（订单数、金额、支付数）
-- 源表: dwd_trade_order_di
-- 目标表: dws_trade_user_1d_df
-- 调度参数: ${bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-13
-- ===================================================

INSERT OVERWRITE TABLE dws_trade_user_1d_df PARTITION (ds='${bizdate}')
SELECT
    user_id,
    COUNT(*)                   AS order_cnt,         -- 下单数
    COUNT(DISTINCT order_id)   AS distinct_order_cnt,-- 去重订单数
    SUM(amount)                AS order_amount,      -- 下单金额
    SUM(CASE WHEN status = 'PAID' THEN 1 ELSE 0 END) AS pay_cnt,
    SUM(CASE WHEN status = 'PAID' THEN pay_amount ELSE 0 END) AS pay_amount,
    MAX(create_time)           AS last_order_time,   -- 最近下单时间
    MIN(create_time)           AS first_order_time   -- 首次下单时间
FROM dwd_trade_order_di
WHERE ds = '${bizdate}'
  AND user_id IS NOT NULL
GROUP BY user_id
;
