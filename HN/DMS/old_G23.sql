/* G23
1.业务开展方式：需要确认，（直接发放含义需要确认）
-- 2.担保金额：是否为放款金额（本+息？？？）
3.担保公司项目经理及联系方式: 具体的信息需要确认（何书诺）
4.金融机构名称：项目资方
*/

/*
  1.需要维护项目维表，来存放字段：
	1.1 业务开展方式: 担保业务中的放款方式（现在默认是直接发放，可能存在不是直接发放的情况）
	1.2 担保费率：需要跟具体的业务经理或风险经理确认如何取值
  -- 2.报表日期的加工逻辑待确认，目前是当前日期的对应的上一个月的月末

*/
/*
  g23_detail 增量插入脚本（使用 MD5 判断）
  逻辑：
    1.筛选固定项目的特定放款时间段内的数据 
    2.计算每条贷款记录对应的 MD5 行哈希
    3. 对比报表表中同一期（上月末）的 row_hash
    4. 仅插入新增或字段变动的记录
*/

-- 保费/担保金额/365*（担保到期日-担保起始日）
-- 仅插入新增或变动记录
INSERT INTO `ads_hain_g23_detail` (
    dbank_id, ddate, cont_no, biz_no,project_name,
    cust_id, cust_name, guar_type, biz_mode,
    guar_amt, loan_rate, guar_rate,
    guar_start, guar_end, mgr_contact,
    policy_flag, strategic_flag, first_loan_flag,
    fin_inst_code, fin_inst_name,
    cust_mgr, cust_mgr_tel,
    orig_guar_inst, orig_guar_amt, orig_guar_rate,
    od_flag, uncomp_amt, loss_amt,
    five_class, counter_type, counter_code, counter_name, counter_amt,rely_net_flag
)
WITH first_loan AS (
    SELECT indiv_cust_id, MIN(loan_day) AS first_loan_day
    FROM 
      (  
           /*---------------- 消金 ----------------------*/
            SELECT 
                indiv_cust_id,loan_day
            FROM `prd_spark_db`.dwd_cons_loan_payment_info_d
          	 WHERE product_no IN (
                  'ZTDFSRL_CYCFC_FL_2'
                  ,'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
                  ,'ZT-360-ZA00-2507'
                  ,'JTTD-ZT-HC-ZYXJ'
                  ,'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
                  ,'ZTQSZT-QS-CY102507'
                  ,'ZTKNchangyin_zhengtang'
                  ,'ZT-360-ZA01-2508'
                  ,'DXM'
                )

            UNION ALL

           /*---------------- 消金简版（通道消金） ----------------------*/
            SELECT 
                di.indiv_cust_id,tl.loan_day
            FROM `prd_spark_db`.ods_cons_td_loan tl 
              JOIN `prd_spark_db`.`dim_base_indiv_info` di ON tl.`id_card` = di.`id_card` 
          WHERE tl.product_no IN (
                  'ZTDFSRL_CYCFC_FL_2'
                  ,'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
                  ,'ZT-360-ZA00-2507'
                  ,'JTTD-ZT-HC-ZYXJ'
                  ,'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
                  ,'ZTQSZT-QS-CY102507'
                  ,'ZTKNchangyin_zhengtang'
                  ,'ZT-360-ZA01-2508'
                  ,'DXM'
                )
      )
    GROUP BY indiv_cust_id
)
-- 源数据计算 row_hash
,source_data AS (
    SELECT
        l.bill_app_no AS cont_no,
        e.project_name,
        l.loan_day,
        i.indiv_cust_id AS cust_id,
        i.name AS cust_name,
        'A0101' AS guar_type,
        'A' AS biz_mode,      -- 业务开展方式
        l.loan_amt AS guar_amt,
        l.loan_day AS guar_start,
        -- l.due_date AS guar_end,
        CASE 
    	    WHEN l.due_date IS NOT NULL THEN l.due_date 
        	ELSE DATE_ADD(l.loan_day, INTERVAL 1 YEAR) 
    	END AS guar_end,       -- 担保结束日期：无到期日则放款日+1年
        CASE WHEN l.loan_day = f.first_loan_day THEN 'Y' ELSE 'N' END AS first_loan_flag,
        -- 以后更新需要按最新状态，先全部按否进行报送 CASE WHEN l.loan_status = 'OD' THEN 'Y' ELSE 'N' END AS od_flag,
        'N' AS od_flag,
    	l.total_term,
    	e.cap_rate,
			
        -- MD5 行哈希
        MD5(CONCAT_WS('|',
            COALESCE(l.bill_app_no,''),
            COALESCE(i.indiv_cust_id,''),
            COALESCE(i.name,''),
            COALESCE(CAST(l.loan_amt AS CHAR),'0.00'),
            COALESCE(CAST(l.loan_day AS CHAR),''),
            COALESCE(CAST(l.due_date AS CHAR),''),
            CASE WHEN l.loan_day = f.first_loan_day THEN '1' ELSE '0' END,
            CASE WHEN l.loan_status = 'OD' THEN 'Y' ELSE 'N' END
        )) AS row_hash
    FROM 
      (  
           /*---------------- 消金 ----------------------*/
            SELECT 
               `bill_app_no` , `loan_day` , `loan_amt` , `due_date` , `loan_status` ,`indiv_cust_id` ,`product_no`,`total_term`
            FROM `prd_spark_db`.dwd_cons_loan_payment_info_d

            UNION ALL
          
           /*---------------- 消金简版（通道消金） ----------------------*/
            SELECT 
               `tl`.`bill_app_no` , tl.`loan_day` , tl.`loan_amt` , `tl`.`end_date` AS `due_date` , tl.`status` AS `loan_status` ,di.`indiv_cust_id` ,tl.`product_no`
              ,CASE WHEN tl.loan_term = 0 THEN 12 ELSE tl.loan_term END AS `total_term`  -- 通道消金总期数可能为0
            FROM `prd_spark_db`.ods_cons_td_loan tl 
              JOIN `prd_spark_db`.`dim_base_indiv_info` di ON tl.`id_card` = di.`id_card` 
      ) l
  
    JOIN prd_spark_db.dim_base_indiv_info i
      ON l.indiv_cust_id = i.indiv_cust_id
    LEFT JOIN first_loan f
      ON l.indiv_cust_id = f.indiv_cust_id
    JOIN `test_zxbs_db`.hain_effective_data_interval e
      ON l.product_no = e.project_code
     AND l.loan_day BETWEEN e.start_date AND e.end_date
    WHERE 
        -- i.indiv_cust_id = '100012905521' AND 
        e.is_use = 'Y'
),

-- 目标表当期报表数据 MD5
target_data AS (
    SELECT
        cont_no,
        MD5(CONCAT_WS('|',
            COALESCE(t.cont_no,''),
            COALESCE(t.cust_id,''),
            COALESCE(t.cust_name,''),
            -- 'A01', 
            -- COALESCE(NULLIF(biz_mode,''),''), 
            COALESCE(CAST(t.guar_amt AS CHAR),'0.00'),
            COALESCE(CAST(t.guar_start AS CHAR),''),
            COALESCE(CAST(t.guar_end AS CHAR),''),
            first_loan_flag,
            od_flag
        )) AS row_hash
        ,create_time
        ,update_time
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cont_no ORDER BY update_time DESC) AS rn
        FROM `ads_hain_g23_detail`
        -- WHERE `cust_id` = '100012905521'
    ) t
    WHERE rn = 1
)
SELECT
    'DEFAULT_BANK' AS dbank_id,
    last_day(s.loan_day) AS ddate,
    -- CAST(ROW_NUMBER() OVER (ORDER BY s.cont_no) AS INTEGER) AS xh,
    s.cont_no,
    s.cont_no AS biz_no,
    s.project_name,
    s.cust_id,
    s.cust_name,
    s.guar_type,
    s.biz_mode,
    s.guar_amt,
    NULL AS loan_rate,
    -- CAST('0.02' AS DECIMAL(20,6)) AS guar_rate,      -- 担保费率
    --  CAST(CASE WHEN s.cap_rate IS NULL THEN '0.002' 
    --      ELSE ((0.24 - s.cap_rate/100)/1.82/12)*s.`total_term` 
    --    END AS DECIMAL(20,6)) AS guar_rate,      -- 担保费率

    CAST(
       CASE WHEN s.cap_rate IS NULL THEN '0.2' 
       		ELSE ((24 - s.cap_rate)/1.82/12)*s.`total_term` 
       END AS DECIMAL(20,6)) AS guar_rate,      -- 担保费率

    s.guar_start,
    s.guar_end,
    '何书诺17689893638' AS mgr_contact,
    'N' AS policy_flag,
    'N' AS strategic_flag,
    s.first_loan_flag,
    NULL AS fin_inst_code,
    NULL AS fin_inst_name,
    NULL AS cust_mgr,
    NULL AS cust_mgr_tel,
    NULL AS orig_guar_inst,
    NULL AS orig_guar_amt,
    NULL AS orig_guar_rate,
    s.od_flag,
    NULL AS uncomp_amt,
    NULL AS loss_amt,
    NULL AS five_class,
    NULL AS counter_type,
    NULL AS counter_code,
    NULL AS counter_name,
    NULL AS counter_amt,
	'Y' AS rely_net_flag
FROM source_data s
LEFT JOIN target_data t
  ON s.cont_no = t.cont_no
     AND s.row_hash = t.row_hash   -- row_hash 一致说明记录未变
WHERE t.cont_no IS NULL          -- 仅插入新增或变动的行
	AND s.loan_day BETWEEN DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') AND LAST_DAY(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
;