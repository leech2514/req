-- ============================================================
-- 报表：资方省份月报
-- 目标表：dm_req_supervision_finan_province_m（Delta 主键表，按 stat_month 分区）
-- 数据源：
--   1. dim_req_supervision_payment_info_full_t   简版借据：维度属性（担保方/资金方/平台/省份）、loan_day、loan_amt
--   2. dwd_req_supervision_detail_info_full_t    详版借据-消金：月末在贷余额快照
--   3. dwd_req_car_loan_detail_info_full_t       详版借据-车贷：月末在贷余额快照
-- 调度参数：${obsdt} 报表月末日期（yyyy-MM-dd）
-- 口径说明：
--   1. 详版借据 obs_date 为已平移后的报表观察点，直接按观察日取快照，无需再关联 bizctrl_loan_date_adjusted
--   2. 在贷余额统一取详版借据 loan_balance（资金在贷/在保余额）
--   3. 本月减少笔数：loan_balance = 0 且 LAST_DAY(release_time) = ${obsdt}（消金/车贷同口径）
--      前提：月末快照中保留余额=0 的已解保借据记录
--   4. term_down_amt 沿用平衡公式：期初 + 本月新增 - 期末，小于0时取0
--   5. 简版借据主键含 business_control_rule_id，同一借据存在多规则记录时会按规则展开
--      （与原脚本基于 dim_req_supervision_payment_info_d 的关联粒度保持一致）
-- ============================================================
MERGE INTO dm_req_supervision_finan_province_m t
USING (
    SELECT
        t1.`project_no`,
        t1.`financer_no`,
        t1.`financer_name`,
        t1.`platform_no`,
        t1.`platform_name`,
        t1.`guarantor_no`,
        t1.`guarantor_name`,
        t1.`province_id`,
        CAST(t1.`term_end_month_cnt` AS BIGINT) AS `term_end_month_cnt`,
        CAST(COALESCE(t4.`term_rise_cnt`, 0) AS BIGINT) AS `term_rise_cnt`,
        CAST(t1.`term_down_cnt` AS BIGINT) AS `term_down_cnt`,
        CAST(COALESCE(t2.`term_start_month_cnt`, 0) AS BIGINT) AS `term_start_month_cnt`,
        CAST(COALESCE(t2.`term_start_month_amt`, 0.00) AS DECIMAL(17,2)) AS `term_start_month_amt`,
        CAST(COALESCE(t4.`term_rise_amt`, 0.00) AS DECIMAL(17,2)) AS `term_rise_amt`,
        GREATEST(
            CAST(
                COALESCE(t2.`term_start_month_amt`, 0.00)
                + COALESCE(t4.`term_rise_amt`, 0.00)
                - COALESCE(t1.`term_end_month_amt`, 0.00)
            AS DECIMAL(17,2)),
            0) AS `term_down_amt`,
        CAST(t1.`term_end_month_amt` AS DECIMAL(17,2)) AS `term_end_month_amt`,
        TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm') AS `stat_month`
    FROM (
        /* ================================= t1：期末（${obsdt}）在贷 + 本月减少笔数 ================================= */
        /* ------------------------------------------------ 消金 ------------------------------------------------ */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`guarantor_name`,
            a.`province_id`,
            a.`financer_no`,
            a.`financer_name`,
            a.`platform_no`,
            a.`platform_name`,
            COUNT(IF(b.`loan_balance` > 0.00, a.`bill_app_no`, NULL)) AS `term_end_month_cnt`,
            COUNT(IF(b.`loan_balance` = 0.00
                     AND LAST_DAY(b.`release_time`) = CAST('${obsdt}' AS DATE),
                     a.`bill_app_no`, NULL)) AS `term_down_cnt`,
            SUM(IF(b.`loan_balance` > 0.00, b.`loan_balance`, 0.00)) AS `term_end_month_amt`
        FROM dim_req_supervision_payment_info_full_t a
        JOIN dwd_req_supervision_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`product_no`  = b.`product_no`
            AND a.`project_no`  = b.`project_no`
        WHERE a.`loan_day` <= CAST('${obsdt}' AS DATE)
          AND b.`obs_date` = '${obsdt}'
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`guarantor_name`,
            a.`province_id`, a.`financer_no`, a.`financer_name`,
            a.`platform_no`, a.`platform_name`

        UNION ALL

        /* ------------------------------------------------ 车贷 ------------------------------------------------ */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`guarantor_name`,
            a.`province_id`,
            a.`financer_no`,
            a.`financer_name`,
            a.`platform_no`,
            a.`platform_name`,
            COUNT(IF(b.`loan_balance` > 0.00, a.`bill_app_no`, NULL)) AS `term_end_month_cnt`,
            COUNT(IF(b.`loan_balance` = 0.00
                     AND LAST_DAY(b.`release_time`) = CAST('${obsdt}' AS DATE),
                     a.`bill_app_no`, NULL)) AS `term_down_cnt`,
            SUM(IF(b.`loan_balance` > 0.00, b.`loan_balance`, 0.00)) AS `term_end_month_amt`
        FROM dim_req_supervision_payment_info_full_t a
        JOIN dwd_req_car_loan_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`product_no`  = b.`product_no`
            AND a.`project_no`  = b.`project_no`
        WHERE a.`loan_day` <= CAST('${obsdt}' AS DATE)
          AND b.`obs_date` = '${obsdt}'
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`guarantor_name`,
            a.`province_id`, a.`financer_no`, a.`financer_name`,
            a.`platform_no`, a.`platform_name`
    ) t1
    LEFT JOIN (
        /* ========================= t2：期初（上月末）在贷笔数/金额 ========================= */
        /* ------------------------------------------------ 消金 ------------------------------------------------ */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`province_id`,
            a.`financer_no`,
            a.`platform_no`,
            COUNT(IF(b.`loan_balance` > 0.00, a.`bill_app_no`, NULL)) AS `term_start_month_cnt`,
            SUM(IF(b.`loan_balance` > 0.00, b.`loan_balance`, 0.00)) AS `term_start_month_amt`
        FROM dim_req_supervision_payment_info_full_t a
        JOIN dwd_req_supervision_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`product_no`  = b.`product_no`
            AND a.`project_no`  = b.`project_no`
        WHERE a.`loan_day` < TRUNC(CAST('${obsdt}' AS DATE), 'MM')
          AND b.`obs_date` = TO_CHAR(LAST_DAY(ADD_MONTHS(CAST('${obsdt}' AS DATE), -1)), 'yyyy-mm-dd')
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`province_id`,
            a.`financer_no`, a.`platform_no`

        UNION ALL

        /* ------------------------------------------------ 车贷 ------------------------------------------------ */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`province_id`,
            a.`financer_no`,
            a.`platform_no`,
            COUNT(IF(b.`loan_balance` > 0.00, a.`bill_app_no`, NULL)) AS `term_start_month_cnt`,
            SUM(IF(b.`loan_balance` > 0.00, b.`loan_balance`, 0.00)) AS `term_start_month_amt`
        FROM dim_req_supervision_payment_info_full_t a
        JOIN dwd_req_car_loan_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`product_no`  = b.`product_no`
            AND a.`project_no`  = b.`project_no`
        WHERE a.`loan_day` < TRUNC(CAST('${obsdt}' AS DATE), 'MM')
          AND b.`obs_date` = TO_CHAR(LAST_DAY(ADD_MONTHS(CAST('${obsdt}' AS DATE), -1)), 'yyyy-mm-dd')
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`province_id`,
            a.`financer_no`, a.`platform_no`
    ) t2
        ON  t1.`project_no`  = t2.`project_no`
        AND t1.`guarantor_no` = t2.`guarantor_no`
        AND t1.`province_id`  = t2.`province_id`
        AND t1.`financer_no`  = t2.`financer_no`
        AND t1.`platform_no`  = t2.`platform_no`
    LEFT JOIN (
        /* ========================= t4：本月新增放款（仅简版借据） ========================= */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`province_id`,
            a.`financer_no`,
            a.`platform_no`,
            COUNT(DISTINCT a.`bill_app_no`) AS `term_rise_cnt`,
            SUM(a.`loan_amt`) AS `term_rise_amt`
        FROM dim_req_supervision_payment_info_full_t a
        WHERE a.`loan_day` BETWEEN TRUNC(CAST('${obsdt}' AS DATE), 'MM')
                               AND CAST('${obsdt}' AS DATE)
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`province_id`,
            a.`financer_no`, a.`platform_no`
    ) t4
        ON  t1.`project_no`  = t4.`project_no`
        AND t1.`guarantor_no` = t4.`guarantor_no`
        AND t1.`province_id`  = t4.`province_id`
        AND t1.`financer_no`  = t4.`financer_no`
        AND t1.`platform_no`  = t4.`platform_no`
) s
ON  t.`financer_no`  = s.`financer_no`
AND t.`platform_no`  = s.`platform_no`
AND t.`guarantor_no` = s.`guarantor_no`
AND t.`project_no`   = s.`project_no`
AND t.`stat_month`   = s.`stat_month`
AND t.`province_id`  = s.`province_id`
WHEN MATCHED THEN UPDATE SET
    t.`guarantor_name`       = s.`guarantor_name`,
    t.`financer_name`        = s.`financer_name`,
    t.`platform_name`        = s.`platform_name`,
    t.`term_end_month_cnt`   = s.`term_end_month_cnt`,
    t.`term_rise_cnt`        = s.`term_rise_cnt`,
    t.`term_down_cnt`        = s.`term_down_cnt`,
    t.`term_start_month_cnt` = s.`term_start_month_cnt`,
    t.`term_end_month_amt`   = s.`term_end_month_amt`,
    t.`term_rise_amt`        = s.`term_rise_amt`,
    t.`term_down_amt`        = s.`term_down_amt`,
    t.`term_start_month_amt` = s.`term_start_month_amt`
WHEN NOT MATCHED THEN INSERT (
    `project_no`,
    `financer_no`,
    `financer_name`,
    `platform_no`,
    `platform_name`,
    `guarantor_no`,
    `guarantor_name`,
    `province_id`,
    `term_end_month_cnt`,
    `term_rise_cnt`,
    `term_down_cnt`,
    `term_start_month_cnt`,
    `term_end_month_amt`,
    `term_rise_amt`,
    `term_down_amt`,
    `term_start_month_amt`,
    `stat_month`
) VALUES (
    s.`project_no`,
    s.`financer_no`,
    s.`financer_name`,
    s.`platform_no`,
    s.`platform_name`,
    s.`guarantor_no`,
    s.`guarantor_name`,
    s.`province_id`,
    s.`term_end_month_cnt`,
    s.`term_rise_cnt`,
    s.`term_down_cnt`,
    s.`term_start_month_cnt`,
    s.`term_end_month_amt`,
    s.`term_rise_amt`,
    s.`term_down_amt`,
    s.`term_start_month_amt`,
    s.`stat_month`
);
