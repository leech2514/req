-- ============================================================
-- 报表：按项目统计月报
-- 目标表：dm_req_supervision_project_m（Delta 主键表，按 stat_month 分区）
-- 数据源：
--   1. dim_req_supervision_payment_info_full_t   简版借据：维度属性（担保方/资金方/平台/省份）、loan_day、loan_amt
--   2. dwd_req_supervision_detail_info_full_t    详版借据-消金：月末在贷余额快照
--   3. dwd_req_car_loan_detail_info_full_t       详版借据-车贷：月末在贷余额快照
--   4. business_control_project_detail            业务管控项目详情：过滤分保项目(guarantee_type!='3')与暂存状态
-- 调度参数：${obsdt} 报表月末日期（yyyy-MM-dd）
-- 口径说明：
--   1. 详版借据 obs_date 为已平移后的报表观察点，直接按观察日取快照，无需再关联 bizctrl_loan_date_adjusted
--   2. 在贷余额统一取详版借据 loan_balance（资金在贷/在保余额）
--   3. 本月减少笔数：loan_balance = 0 且 LAST_DAY(release_time) = ${obsdt}（消金/车贷同口径）
--      前提：月末快照中保留余额=0 的已解保借据记录
--   4. term_down_amt 沿用平衡公式：期初 + 本月新增 - 期末，小于0时取0
--   5. 通过 business_control_project_detail 过滤分保项目（guarantee_type != '3'）
--      和暂存状态（create_status 为空/NULL = 已创建，'draft' = 暂存）
-- ============================================================
MERGE INTO dm_req_supervision_project_m t
USING (
    SELECT
        month_end.`project_no`,
        month_end.`financer_no`,
        month_end.`financer_name`,
        month_end.`platform_no`,
        month_end.`platform_name`,
        month_end.`guarantor_no`,
        month_end.`guarantor_name`,
        month_end.`province_id`,
        CAST(month_end.`term_end_month_cnt` AS BIGINT) AS `term_end_month_cnt`,
        CAST(COALESCE(month_rise.`term_rise_cnt`, 0) AS BIGINT) AS `term_rise_cnt`,
        CAST(month_end.`term_down_cnt` AS BIGINT) AS `term_down_cnt`,
        CAST(COALESCE(month_start.`term_start_month_cnt`, 0) AS BIGINT) AS `term_start_month_cnt`,
        CAST(COALESCE(month_start.`term_start_month_amt`, 0.00) AS DECIMAL(17,2)) AS `term_start_month_amt`,
        CAST(COALESCE(month_rise.`term_rise_amt`, 0.00) AS DECIMAL(17,2)) AS `term_rise_amt`,
        GREATEST(
            CAST(
                COALESCE(month_start.`term_start_month_amt`, 0.00)
                + COALESCE(month_rise.`term_rise_amt`, 0.00)
                - COALESCE(month_end.`term_end_month_amt`, 0.00)
            AS DECIMAL(17,2)),
            0) AS `term_down_amt`,
        CAST(month_end.`term_end_month_amt` AS DECIMAL(17,2)) AS `term_end_month_amt`,
        TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm') AS `stat_month`
    FROM (
        /* ========================= month_end：期末（${obsdt}）在贷 + 本月减少笔数 ========================= */
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
        FROM prod_f_dw.dim_req_supervision_payment_info_full_t a
        JOIN prod_f_dw.dwd_req_supervision_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`project_no`  = b.`project_no`
        JOIN prod_f_dw.business_control_project_detail c
            ON  a.`project_no` = c.`project_id`
            AND c.`guarantee_type` != '3'
        WHERE a.`loan_day` <= CAST('${obsdt}' AS DATE)
          AND b.`obs_date` = '${obsdt}'
          AND (c.`create_status` IS NULL OR LOWER(c.`create_status`) = 'null')
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
        FROM prod_f_dw.dim_req_supervision_payment_info_full_t a
        JOIN prod_f_dw.dwd_req_car_loan_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`project_no`  = b.`project_no`
        JOIN prod_f_dw.business_control_project_detail c
            ON  a.`project_no` = c.`project_id`
            AND c.`guarantee_type` != '3'
        WHERE a.`loan_day` <= CAST('${obsdt}' AS DATE)
          AND b.`obs_date` = '${obsdt}'
          AND (c.`create_status` IS NULL OR LOWER(c.`create_status`) = 'null')
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`guarantor_name`,
            a.`province_id`, a.`financer_no`, a.`financer_name`,
            a.`platform_no`, a.`platform_name`
    ) month_end
    LEFT JOIN (
        /* ========================= month_start：期初（上月末）在贷笔数/金额 ========================= */
        /* ------------------------------------------------ 消金 ------------------------------------------------ */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`province_id`,
            a.`financer_no`,
            a.`platform_no`,
            COUNT(IF(b.`loan_balance` > 0.00, a.`bill_app_no`, NULL)) AS `term_start_month_cnt`,
            SUM(IF(b.`loan_balance` > 0.00, b.`loan_balance`, 0.00)) AS `term_start_month_amt`
        FROM prod_f_dw.dim_req_supervision_payment_info_full_t a
        JOIN prod_f_dw.dwd_req_supervision_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`project_no`  = b.`project_no`
        JOIN prod_f_dw.business_control_project_detail c
            ON  a.`project_no` = c.`project_id`
            AND c.`guarantee_type` != '3'
        WHERE a.`loan_day` < CAST(TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm-01') AS DATE)
          AND b.`obs_date` = LAST_DAY(DATEADD(CAST('${obsdt}' AS DATE), -1, 'mm'))
          AND (c.`create_status` IS NULL OR LOWER(c.`create_status`) = 'null')
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
        FROM prod_f_dw.dim_req_supervision_payment_info_full_t a
        JOIN prod_f_dw.dwd_req_car_loan_detail_info_full_t b
            ON  a.`bill_app_no` = b.`bill_app_no`
            AND a.`project_no`  = b.`project_no`
        JOIN prod_f_dw.business_control_project_detail c
            ON  a.`project_no` = c.`project_id`
            AND c.`guarantee_type` != '3'
        WHERE a.`loan_day` < CAST(TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm-01') AS DATE)
          AND b.`obs_date` = LAST_DAY(DATEADD(CAST('${obsdt}' AS DATE), -1, 'mm'))
          AND (c.`create_status` IS NULL OR LOWER(c.`create_status`) = 'null')
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`province_id`,
            a.`financer_no`, a.`platform_no`
    ) month_start
        ON  month_end.`project_no`  = month_start.`project_no`
        AND month_end.`guarantor_no` = month_start.`guarantor_no`
        AND month_end.`province_id`  = month_start.`province_id`
        AND month_end.`financer_no`  = month_start.`financer_no`
        AND month_end.`platform_no`  = month_start.`platform_no`
    LEFT JOIN (
        /* ========================= month_rise：本月新增放款（仅简版借据） ========================= */
        SELECT
            a.`project_no`,
            a.`guarantor_no`,
            a.`province_id`,
            a.`financer_no`,
            a.`platform_no`,
            COUNT(DISTINCT a.`bill_app_no`) AS `term_rise_cnt`,
            SUM(a.`loan_amt`) AS `term_rise_amt`
        FROM prod_f_dw.dim_req_supervision_payment_info_full_t a
        JOIN prod_f_dw.business_control_project_detail c
            ON  a.`project_no` = c.`project_id`
            AND c.`guarantee_type` != '3'
        WHERE a.`loan_day` BETWEEN CAST(TO_CHAR(CAST('${obsdt}' AS DATE), 'yyyy-mm-01') AS DATE)
                               AND CAST('${obsdt}' AS DATE)
          AND (c.`create_status` IS NULL OR LOWER(c.`create_status`) = 'null')
        GROUP BY
            a.`project_no`, a.`guarantor_no`, a.`province_id`,
            a.`financer_no`, a.`platform_no`
    ) month_rise
        ON  month_end.`project_no`  = month_rise.`project_no`
        AND month_end.`guarantor_no` = month_rise.`guarantor_no`
        AND month_end.`province_id`  = month_rise.`province_id`
        AND month_end.`financer_no`  = month_rise.`financer_no`
        AND month_end.`platform_no`  = month_rise.`platform_no`
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
