-- ============================================================
-- 报表：按资方省份季报
-- 目标表：dm_req_supervision_finan_province_q（Delta 主键表，按 stat_quarter 分区）
-- 数据源：dm_req_supervision_finan_province_m（月报，已按 stat_month 分区）
-- 调度参数：${obsdt} 报表月末日期（yyyy-MM-dd）
-- 口径说明：
--   1. 从月报聚合为季报，每月调度更新当前季度数据
--   2. 期初数（term_start_month_cnt/amt）：取季度内第一个月（rn_asc=1）的期初值
--   3. 期末数（term_end_month_cnt/amt）：取季度内最后一个月（rn_desc=1）的期末值
--   4. 新增/减少数（term_rise/term_down）：季度内各月求和
--   5. stat_quarter 格式：yyyy-Qn（如 2026-Q1），由 stat_month 派生
--   6. 通过 stat_month 范围过滤实现分区裁剪，仅扫描当前季度的三个月分区
-- ============================================================
MERGE INTO dm_req_supervision_finan_province_q t
USING (
    /* ========================= 第三层：按季度聚合 ========================= */
    SELECT
        q.`project_no`,
        q.`financer_no`,
        q.`financer_name`,
        q.`platform_no`,
        q.`platform_name`,
        q.`guarantor_no`,
        q.`guarantor_name`,
        q.`province_id`,
        q.`stat_quarter`,
        MAX(CASE WHEN q.`rn_asc` = 1 THEN q.`term_start_month_cnt` ELSE 0 END) AS `term_start_month_cnt`,
        SUM(q.`term_rise_cnt`) AS `term_rise_cnt`,
        SUM(q.`term_down_cnt`) AS `term_down_cnt`,
        MAX(CASE WHEN q.`rn_desc` = 1 THEN q.`term_end_month_cnt` ELSE 0 END) AS `term_end_month_cnt`,
        MAX(CASE WHEN q.`rn_asc` = 1 THEN q.`term_start_month_amt` ELSE 0.00 END) AS `term_start_month_amt`,
        SUM(q.`term_rise_amt`) AS `term_rise_amt`,
        SUM(q.`term_down_amt`) AS `term_down_amt`,
        MAX(CASE WHEN q.`rn_desc` = 1 THEN q.`term_end_month_amt` ELSE 0.00 END) AS `term_end_month_amt`
    FROM (
        /* ========================= 第二层：计算季度内月份排序 ========================= */
        SELECT
            base.*,
            ROW_NUMBER() OVER (
                PARTITION BY
                    base.`project_no`, base.`financer_no`, base.`platform_no`, base.`guarantor_no`,
                    base.`stat_quarter`, base.`province_id`
                ORDER BY base.`stat_month` ASC
            ) AS `rn_asc`,
            ROW_NUMBER() OVER (
                PARTITION BY
                    base.`project_no`, base.`financer_no`, base.`platform_no`, base.`guarantor_no`,
                    base.`stat_quarter`, base.`province_id`
                ORDER BY base.`stat_month` DESC
            ) AS `rn_desc`
        FROM (
            /* ========================= 第一层：取月报数据 + 计算 stat_quarter + 分区裁剪 ========================= */
            /* 季度起始月 = obsdt 往前推 (月份-1)%3 个月；季度结束月 = obsdt 往后推 2-(月份-1)%3 个月 */
            SELECT
                m.`project_no`,
                m.`financer_no`,
                m.`financer_name`,
                m.`platform_no`,
                m.`platform_name`,
                m.`guarantor_no`,
                m.`guarantor_name`,
                m.`province_id`,
                m.`stat_month`,
                CONCAT(
                    SUBSTR(m.`stat_month`, 1, 4),
                    '-Q',
                    CAST(CEIL(CAST(SUBSTR(m.`stat_month`, 6, 2) AS DOUBLE) / 3) AS STRING)
                ) AS `stat_quarter`,
                m.`term_start_month_cnt`,
                m.`term_rise_cnt`,
                m.`term_down_cnt`,
                m.`term_end_month_cnt`,
                m.`term_start_month_amt`,
                m.`term_rise_amt`,
                m.`term_down_amt`,
                m.`term_end_month_amt`
            FROM prod_f_dw.dm_req_supervision_finan_province_m m
            WHERE m.`stat_month` >=
                TO_CHAR(
                    DATEADD(
                        CAST('${obsdt}' AS DATE),
                        -((CAST(SUBSTR(TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm'), 6, 2) AS INT) - 1) % 3),
                        'mm'
                    ),
                    'yyyy-mm'
                )
              AND m.`stat_month` <=
                TO_CHAR(
                    DATEADD(
                        CAST('${obsdt}' AS DATE),
                        2 - (CAST(SUBSTR(TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm'), 6, 2) AS INT) - 1) % 3,
                        'mm'
                    ),
                    'yyyy-mm'
                )
        ) base
    ) q
    GROUP BY
        q.`project_no`, 
        q.`financer_no`, q.`financer_name`,
        q.`platform_no`, q.`platform_name`,
        q.`guarantor_no`, q.`guarantor_name`,
        q.`province_id`, 
        q.`stat_quarter`
) s
ON  t.`financer_no`  = s.`financer_no`
AND t.`platform_no`  = s.`platform_no`
AND t.`guarantor_no` = s.`guarantor_no`
AND t.`project_no`   = s.`project_no`
AND t.`stat_quarter` = s.`stat_quarter`
AND t.`province_id`  = s.`province_id`
WHEN MATCHED THEN UPDATE SET
    t.`guarantor_name`       = s.`guarantor_name`,
    t.`financer_name`        = s.`financer_name`,
    t.`platform_name`        = s.`platform_name`,
    t.`term_start_month_cnt` = s.`term_start_month_cnt`,
    t.`term_rise_cnt`        = s.`term_rise_cnt`,
    t.`term_down_cnt`        = s.`term_down_cnt`,
    t.`term_end_month_cnt`   = s.`term_end_month_cnt`,
    t.`term_start_month_amt` = s.`term_start_month_amt`,
    t.`term_rise_amt`        = s.`term_rise_amt`,
    t.`term_down_amt`        = s.`term_down_amt`,
    t.`term_end_month_amt`   = s.`term_end_month_amt`
WHEN NOT MATCHED THEN INSERT (
    `project_no`,
    `financer_no`,
    `financer_name`,
    `platform_no`,
    `platform_name`,
    `guarantor_no`,
    `guarantor_name`,
    `province_id`,
    `term_start_month_cnt`,
    `term_rise_cnt`,
    `term_down_cnt`,
    `term_end_month_cnt`,
    `term_start_month_amt`,
    `term_rise_amt`,
    `term_down_amt`,
    `term_end_month_amt`,
    `stat_quarter`
) VALUES (
    s.`project_no`,
    s.`financer_no`,
    s.`financer_name`,
    s.`platform_no`,
    s.`platform_name`,
    s.`guarantor_no`,
    s.`guarantor_name`,
    s.`province_id`,
    s.`term_start_month_cnt`,
    s.`term_rise_cnt`,
    s.`term_down_cnt`,
    s.`term_end_month_cnt`,
    s.`term_start_month_amt`,
    s.`term_rise_amt`,
    s.`term_down_amt`,
    s.`term_end_month_amt`,
    s.`stat_quarter`
);
