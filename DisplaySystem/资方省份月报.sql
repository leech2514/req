 DELETE FROM prd_spark_db.dm_req_supervision_finan_province_m WHERE stat_month =  DATE_FORMAT('${obsdt}', '%Y-%m');
 
 REPLACE INTO prd_spark_db.dm_req_supervision_finan_province_m (
     `project_no`,
     `guarantor_no`,
     `guarantor_name`,
     `stat_month`,
     `province_id`,
     `financer_no`,
     `financer_name`,
     `platform_no`,
     `platform_name`,
     `term_end_month_cnt`,
     `term_rise_cnt`,
     `term_down_cnt`,
     `term_start_month_cnt`,
     `term_end_month_amt`,
     `term_rise_amt`,
     `term_down_amt`,
     `term_start_month_amt`
 )
 WITH t1 AS (
    
     /* ================================================ 消金 ============================================================== */
     SELECT 
         a.`project_no`, a.`guarantor_no`, a.`guarantor_name`, 
         DATE_FORMAT('${obsdt}', '%Y-%m') AS `stat_month`,
         a.`province_id`, a.`financer_no`, a.`platform_no`, 
         a.`financer_name`, a.`platform_name`,
         COUNT(IF(b.`fund_princ_bal_info` > 0.00 , a.`bill_app_no`, NULL)) AS `term_end_month_cnt`,
         COUNT(IF(b.obs_date >= CAST(DATE_FORMAT('${obsdt}','%Y-%m-01') AS DATE)
                 AND last_day(b.act_repay_date) = '${obsdt}'
                 AND (b.`fund_princ_bal_info` = 0.00), 
                 a.`bill_app_no`, NULL)) AS `term_down_cnt`,
         SUM(IF(b.`fund_princ_bal_info` > 0.00 , b.`fund_princ_bal_info`, 0.00)) AS `term_end_month_amt`
   
     FROM prd_spark_db.`dim_req_supervision_payment_info_d` a
     JOIN (
         /* ------------------------- 线上数据：保持写法不变 ------------------------- */
         -- 平移观察时间
            SELECT 
                `project_no`,`product_no`,`bill_app_no`
                , shifted_obs_date AS `obs_date`
                , shifted_act_repay_date AS `act_repay_date`
                ,`fund_princ_bal_info`
            FROM f_prd_spark_db.tmp2_cons_payment_common
            WHERE 
                 shifted_obs_date = '${obsdt}'
   
         /* ------------------------- 线下数据：按线上逻辑平移 ------------------------- */
         UNION ALL
         -- 平移观察时间(fake库数据没有平移)
         SELECT 
              a.`product_no` ,b.`project_id` AS project_no, a.apply_no AS `bill_app_no`,
             DATE_ADD(a.obs_date, INTERVAL COALESCE(b.shift_months, 0) MONTH) AS obs_date,
             DATE_ADD(a.act_repay_date, INTERVAL COALESCE(b.shift_months, 0) MONTH) AS act_repay_date,
             a.fund_princ_bal_info 
         FROM `f_prd_spark_db`.`dwd_offline_repay_performance_d` a
         JOIN `f_prd_spark_db`.`bizctrl_loan_date_adjusted` b
             ON a.`apply_no` = b.bill_app_no
         WHERE a.obs_date = '${obsdt}'
         
     ) b ON a.`bill_app_no` = b.`bill_app_no` AND a.`product_no` = b.`product_no` AND a.`project_no`  = b.`project_no` 
     WHERE a.`loan_day` <= '${obsdt}'
     GROUP BY 
         a.`project_no`, a.`guarantor_no`, a.`province_id`, a.`financer_no`, a.`platform_no`
     
     UNION ALL
     
    /* ================================================ 车贷 ============================================================== */
     SELECT 
         a.`project_no`, a.`guarantor_no`, a.`guarantor_name`, 
         DATE_FORMAT('${obsdt}', '%Y-%m') AS `stat_month`,
         a.`province_id`, a.`financer_no`, a.`platform_no`, 
         a.`financer_name`, a.`platform_name`,
         COUNT(IF(b.`fund_princ_bal_info` > 0.00, 
                  a.`bill_app_no`, NULL)) AS `term_end_month_cnt`,
         COUNT(IF(  b.obs_date >= DATE_FORMAT('${obsdt}','%Y-%m-01') 
                    AND b.`fund_princ_bal_info` = 0.00 
                    AND last_day(b.act_repay_date) = '${obsdt}',  -- cuf>0表示本月有还款/结清行为
                 a.`bill_app_no`, NULL)) AS `term_down_cnt`,
         SUM(IF(b.`fund_princ_bal_info` > 0.00, 
                b.`fund_princ_bal_info`, 0.00)) AS `term_end_month_amt`
     FROM prd_spark_db.`dim_req_supervision_payment_info_d` a
     JOIN (
   
         SELECT 
              `project_no`,bill_app_no, obs_date, fund_princ_bal_info, product_no,act_repay_date,
             ROW_NUMBER() OVER (PARTITION BY project_no,bill_app_no ORDER BY obs_date DESC) AS rn
         FROM (
             -- 平移观察时间
             SELECT 
                 b.`project_id` AS `project_no`,
                 b.`product_no` , 
                 a.bill_app_no,
                 DATE_ADD(a.obs_date, INTERVAL COALESCE(b.shift_months, 0) MONTH) AS obs_date,
                 DATE_ADD(a.act_repay_date, INTERVAL COALESCE(b.shift_months, 0) MONTH) AS act_repay_date,
                 a.fund_princ_bal_info
             FROM `f_prd_spark_db`.dwd_auto_balance_repay_info_d a
             JOIN `f_prd_spark_db`.`bizctrl_loan_date_adjusted` b
                 ON a.`bill_app_no` = b.bill_app_no
 		    WHERE 
                 a.`obs_date`= LAST_DAY(DATE_SUB('${obsdt}',INTERVAL COALESCE(b.shift_months, 0) MONTH))
   
         ) sub
   
     ) b ON a.`bill_app_no` = b.`bill_app_no` AND a.`product_no` = b.`product_no` AND a.`project_no`  = b.`project_no` 
     WHERE `loan_day` <= '${obsdt}' AND b.rn = 1 
          --    AND a.`project_no` = 13 AND a.`province_id` = '140000'
     GROUP BY 
         a.`project_no`, a.`guarantor_no`, a.`province_id`,  a.`financer_no`, a.`platform_no`
 ),
 t2 AS (
     SELECT 
         a.`project_no`, a.`guarantor_no`,
         DATE_FORMAT('${obsdt}', '%Y-%m') AS `stat_month`,
         a.`province_id`, a.`financer_no`, a.`platform_no`,
         COUNT(IF(t.`fund_princ_bal_info` > 0.00 , a.`bill_app_no`, NULL)) AS `term_start_month_cnt`,
   
         SUM(if(t.`fund_princ_bal_info` > 0.00, t.fund_princ_bal_info,0)) AS `term_start_month_amt`
     FROM prd_spark_db.`dim_req_supervision_payment_info_d` a
     JOIN (
         /* ------------------------------- 线上 dwd_cons_payment_performance_180d ----------------------------- */
         SELECT 
             `project_no`,`product_no`,`bill_app_no`
             , shifted_obs_date AS `obs_date`
             ,`fund_princ_bal_info`
         FROM f_prd_spark_db.tmp2_cons_payment_common
         WHERE 
             shifted_obs_date = DATE_SUB(DATE_FORMAT('${obsdt}','yyyy-MM-01'),1)
   
         UNION ALL        
         /* ------------------------------- 车贷生产dwd_auto_balance_repay_info_d ----------------------- */
         SELECT 
                t.`project_no`,t.`product_no` ,
                t.bill_app_no, t.shifted_obs_date AS obs_date, 
                t.fund_princ_bal_info
         FROM (
             SELECT 
                 b.`project_id` AS `project_no`,
                 b.`product_no` , 
                 a.bill_app_no,
                 DATE_ADD(a.obs_date, INTERVAL COALESCE(b.shift_months, 0) MONTH) AS shifted_obs_date,
                 a.fund_princ_bal_info,
                 ROW_NUMBER() OVER (PARTITION BY b.project_id,a.bill_app_no ORDER BY a.obs_date DESC) AS rn
             FROM `f_prd_spark_db`.`dwd_auto_balance_repay_info_d` a
             JOIN `f_prd_spark_db`.`bizctrl_loan_date_adjusted` b
                 ON a.bill_app_no = b.bill_app_no
 	        WHERE 
                   a.`obs_date` = LAST_DAY(DATE_SUB(ADD_MONTHS('${obsdt}', -1),INTERVAL COALESCE(b.shift_months, 0) MONTH ))
   
         ) t
         WHERE t.rn = 1
         
         UNION ALL      
         /* ----------------------------- 线下 dwd_offline_repay_performance_d ------------------------------ */
         SELECT t.project_no,  t.product_no,  t.bill_app_no, t.shifted_obs_date AS obs_date, 
                t.fund_princ_bal_info
         FROM (
             SELECT
                 a.apply_no AS bill_app_no,
                 DATE_ADD(a.obs_date, INTERVAL COALESCE(b.shift_months, 0) MONTH) AS shifted_obs_date,
                 a.fund_princ_bal_info,
                 a.princ_bal_info, a.product_no, b.project_id AS project_no
             FROM `f_prd_spark_db`.`dwd_offline_repay_performance_d` a
             JOIN `f_prd_spark_db`.`bizctrl_loan_date_adjusted` b
                 ON a.apply_no = b.bill_app_no
             WHERE a.obs_date = DATE_SUB(DATE_FORMAT('${obsdt}','yyyy-MM-01'),1)
         ) t
         WHERE t.shifted_obs_date = DATE_SUB(DATE_FORMAT('${obsdt}','yyyy-MM-01'),1)
   
     ) t ON a.bill_app_no = t.bill_app_no AND a.`product_no` = t.product_no AND a.`project_no` = t.`project_no` 
     WHERE a.loan_day < DATE_FORMAT('${obsdt}','%Y-%m-01')
          --    AND a.`project_no` = 13 AND a.`province_id` = '140000'
     GROUP BY 
         a.project_no, a.guarantor_no, a.province_id, a.financer_no, a.platform_no
 ),
 t4 AS (
     SELECT 
         a.`project_no`, a.`guarantor_no`, 
         DATE_FORMAT('${obsdt}', '%Y-%m') AS `stat_month`, 
         a.`province_id`, a.`financer_no`, a.`platform_no`,
         COUNT(DISTINCT a.`bill_app_no`) AS `term_rise_cnt`,
         SUM(a.`loan_amt`) AS `term_rise_amt`
     FROM prd_spark_db.`dim_req_supervision_payment_info_d` a
     WHERE a.`loan_day` BETWEEN DATE_FORMAT('${obsdt}','%Y-%m-01') AND '${obsdt}'
          --    AND a.`project_no` = 13 AND a.`province_id` = '140000'
     GROUP BY 
         a.`project_no`, a.`guarantor_no`, a.`province_id`, a.`financer_no`, a.`platform_no`
 )
 SELECT 
     t1.`project_no`,
     t1.`guarantor_no`,
     t1.`guarantor_name`,
     DATE_FORMAT('${obsdt}', '%Y-%m') AS `stat_month`,
     t1.`province_id`,
     t1.`financer_no`,
     t1.`financer_name`,
     t1.`platform_no`,
     t1.`platform_name`,
     CAST(t1.`term_end_month_cnt` AS INTEGER) AS `term_end_month_cnt`,
     CAST(COALESCE(t4.`term_rise_cnt`, 0) AS INTEGER) AS `term_rise_cnt`,
     CAST(t1.`term_down_cnt` AS INTEGER) AS `term_down_cnt`,
     CAST(COALESCE(t2.`term_start_month_cnt`, 0) AS INTEGER) AS `term_start_month_cnt`,
     CAST(t1.`term_end_month_amt` AS DECIMAL(17,2)) AS `term_end_month_amt`,
     CAST(COALESCE(t4.`term_rise_amt`, 0.00) AS DECIMAL(17,2)) AS `term_rise_amt`,
     GREATEST(CAST(COALESCE((
           COALESCE(t2.`term_start_month_amt`,0.00) 
           + COALESCE(t4.`term_rise_amt`, 0.00) 
           - COALESCE(t1.`term_end_month_amt`, 0.00))
           , 0.00) 
       AS DECIMAL(17,2)), 0) AS `term_down_amt`,
     CAST(COALESCE(t2.`term_start_month_amt`, 0.00) AS DECIMAL(17,2)) AS `term_start_month_amt`
 FROM t1
 LEFT JOIN t2 ON t1.project_no = t2.project_no 
     AND t1.guarantor_no = t2.guarantor_no 
     AND t1.province_id = t2.province_id 
     AND t1.financer_no = t2.financer_no 
     AND t1.platform_no = t2.platform_no
     AND t1.stat_month = t2.stat_month
 LEFT JOIN t4 ON t1.project_no = t4.project_no 
     AND t1.guarantor_no = t4.guarantor_no 
     AND t1.province_id = t4.province_id 
     AND t1.financer_no = t4.financer_no 
     AND t1.platform_no = t4.platform_no
     AND t1.stat_month = t4.stat_month
 ;
