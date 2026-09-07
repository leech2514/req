-- ===================================================
-- 脚本名称: dwd_trade_order_di.sql
-- 所属层级: DWD
-- 业务域: 交易域
-- 功能描述: 订单明细日增量 ETL（清洗 + 维度退化）
-- 源表: ods_mysql_order_di, dim_user_info_df, dim_sku_info_df
-- 目标表: dwd_trade_order_di
-- 调度参数: ${bizdate}
-- 负责人: <name>
-- 创建日期: 2026-08-13
-- ===================================================

INSERT OVERWRITE TABLE dwd_trade_order_di PARTITION (ds='${bizdate}')
SELECT
    o.id                                  AS order_id,
    o.order_no                            AS order_no,
    o.user_id                             AS user_id,
    u.user_name                           AS user_name,
    o.sku_id                              AS sku_id,
    s.sku_name                            AS sku_name,
    s.category_id                         AS category_id,
    o.amount                              AS amount,
    o.pay_amount                          AS pay_amount,
    o.status                              AS status,
    o.channel                             AS channel,
    o.create_time                         AS create_time,
    o.pay_time                            AS pay_time,
    o.update_time                         AS update_time
FROM ods_mysql_order_di o
LEFT JOIN (
    SELECT user_id, user_name
    FROM dim_user_info_df
    WHERE ds = '${bizdate}'
) u ON o.user_id = u.user_id
LEFT JOIN (
    SELECT sku_id, sku_name, category_id
    FROM dim_sku_info_df
    WHERE ds = '${bizdate}'
) s ON o.sku_id = s.sku_id
WHERE o.ds = '${bizdate}'
  AND o.id IS NOT NULL
  AND o.status IS NOT NULL
;
