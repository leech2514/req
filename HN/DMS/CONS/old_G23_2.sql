-- -- 度小满异常借据更新（处理还款总额大于放款金额的情况）
-- UPDATE  rd_cfund.ln_repay_info
--   SET `print` = 4989.92
--   WHERE `apply_no` = 'DXM2023-04-16_00091162'
--     AND `term` = 12
-- ;
-- 
-- 
-- -- 1.不需要去掉代偿的项目
-- INSERT  INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
--   `dbank_id`,
--   `ddate`,
--   `xh`,
--   `relieve_no`,
--   `cont_no`,
--   `biz_no`,
--   `project_name`,
--   `recv_type`,
--   `recv_date`,
--   `recv_amt`,
--   `settle_flag`
-- )
-- 
-- SELECT
--     'DEFAULT_BANK' AS dbank_id,
--     LAST_DAY(a.repay_time) AS ddate,
--     uuid() AS xh,
--     a.tran_rp_no AS relieve_no,
--     a.apply_no AS cont_no,
--     a.apply_no AS biz_no,
--     e.project_name,
--     'A' AS recv_type,
--     CAST(a.repay_time AS DATE) AS recv_date,
--     a.print AS recv_amt,
-- 
--     -- ★ 关键逻辑：满足两个条件才为 Y
--     CASE
--         WHEN rn = 1   
--          AND (b.loan_amt - sum_no_cps_print) = 0
--         THEN 'Y'
--         ELSE 'N'
--     END AS settle_flag
-- 
-- FROM (
--     SELECT 
--         a.*,
--         SUM(CASE WHEN a.repay_type NOT IN (8) THEN a.print ELSE 0 END) 
--             OVER (PARTITION BY a.apply_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--             AS sum_no_cps_print,         -- 累计非代偿金额
-- 
--         ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC, term DESC) AS rn   -- 最后一笔还款
--     FROM rd_cfund.ln_repay_info a
--     WHERE `repay_type` <> 8
-- ) a
-- 
-- JOIN rd_cfund.ln_loan_info b
--     ON a.apply_no = b.apply_no
-- JOIN test_zxbs_db.hain_effective_data_interval e
--     ON b.product_no = e.project_code
--     AND b.recon_date BETWEEN e.start_date AND e.end_date
-- 
-- WHERE a.repay_type NOT IN (8)
--   AND e.is_use = 'Y'
--   AND a.product_no IN (
--         'ZTDFSRL_CYCFC_FL_2',
--         'ZTQSZT-QS-CY102507',
--         'ZTKNchangyin_zhengtang',
--         'DXM'
--       )
--   AND b.product_no IN (
--         'ZTDFSRL_CYCFC_FL_2',
--         'ZTQSZT-QS-CY102507',
--         'ZTKNchangyin_zhengtang',
--         'DXM'
--       );
-- 
-- 
-- -- 2 去掉代偿且代偿时间在24年10月以后的
-- INSERT INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
--   `dbank_id`,
--   `ddate`,
--   `xh`,
--   `relieve_no`,
--   `cont_no`,
--   `biz_no`,
--   `project_name`,
--   `recv_type`,
--   `recv_date`,
--   `recv_amt`,
--   `settle_flag`
-- )
-- SELECT
--     'DEFAULT_BANK' AS dbank_id,
--     LAST_DAY(a.repay_time) AS ddate,
--     uuid() AS xh,
--     a.tran_rp_no AS relieve_no,
--     a.apply_no AS cont_no,
--     a.apply_no AS biz_no,
--     e.project_name,
--     'A' AS recv_type,
--     CAST(a.repay_time AS DATE) AS recv_date,
--     a.print AS recv_amt,
--     
--     -- ★ 关键逻辑：满足两个条件才为 Y
--     CASE
--         WHEN rn = 1   
--          AND (b.loan_amt - sum_no_cps_print) = 0
--         THEN 'Y'
--         ELSE 'N'
--     END AS settle_flag
-- FROM (
--     SELECT 
--         a.*,
--         SUM(CASE WHEN a.repay_type NOT IN (8) THEN a.print ELSE 0 END) 
--             OVER (PARTITION BY a.apply_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--             AS sum_no_cps_print,         -- 累计非代偿金额
-- 
--         ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC,term DESC) AS rn   -- 最后一笔还款
--     FROM rd_cfund.ln_repay_info a
--     WHERE `repay_type` <> 8
-- ) a
-- JOIN rd_cfund.ln_loan_info b
--     ON a.apply_no = b.apply_no
-- JOIN test_zxbs_db.hain_effective_data_interval e
--     ON b.product_no = e.project_code
--     AND b.recon_date BETWEEN e.start_date AND e.end_date
-- WHERE a.repay_type != 8  -- 排除所有追偿（repay_type = 8）
-- AND (a.repay_type != 7 OR a.repay_time <= '2024-09-30')  -- 只取代偿（repay_type = 7）时间在2024年10月31日之前的记录
-- AND e.is_use = 'Y'
-- AND a.product_no IN (
--     'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
--     'ZT-360-ZA00-2507',
--     'JTTD-ZT-HC-ZYXJ',
--     'ZT-360-ZA01-2508'
-- )
-- AND b.product_no IN (
--     'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
--     'ZT-360-ZA00-2507',
--     'JTTD-ZT-HC-ZYXJ',
--     'ZT-360-ZA01-2508'
-- );
-- 
-- 
-- -- 3 君航：去掉代偿且代偿时间在25年9月以后的
-- INSERT INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
--   `dbank_id`,
--   `ddate`,
--   `xh`,
--   `relieve_no`,
--   `cont_no`,
--   `biz_no`,
--   `project_name`,
--   `recv_type`,
--   `recv_date`,
--   `recv_amt`,
--   `settle_flag`
-- )
-- SELECT
--     'DEFAULT_BANK' AS dbank_id,
--     LAST_DAY(a.repay_time) AS ddate,
--     uuid() AS xh,
--     a.tran_rp_no AS relieve_no,
--     a.apply_no AS cont_no,
--     a.apply_no AS biz_no,
--     e.project_name,
--     'A' AS recv_type,
--     CAST(a.repay_time AS DATE) AS recv_date,
--     a.print AS recv_amt,
--     
--     -- ★ 关键逻辑：满足两个条件才为 Y
--     CASE
--         WHEN rn = 1   
--          AND (b.loan_amt - sum_no_cps_print) = 0
--         THEN 'Y'
--         ELSE 'N'
--     END AS settle_flag
-- FROM (
--     SELECT 
--         a.*,
--         SUM(CASE WHEN a.repay_type NOT IN (8) THEN a.print ELSE 0 END) 
--             OVER (PARTITION BY a.apply_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--             AS sum_no_cps_print,         -- 累计非代偿金额
-- 
--         ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC,term DESC) AS rn   -- 最后一笔还款
--     FROM rd_cfund.ln_repay_info a
--     WHERE `repay_type` <> 8
-- ) a
-- JOIN rd_cfund.ln_loan_info b
--     ON a.apply_no = b.apply_no
-- JOIN test_zxbs_db.hain_effective_data_interval e
--     ON b.product_no = e.project_code
--     AND b.recon_date BETWEEN e.start_date AND e.end_date
-- WHERE a.repay_type != 8  -- 排除所有追偿（repay_type = 8）
-- AND (a.repay_type != 7 OR a.repay_time <= '2025-08-31')  -- 只取代偿（repay_type = 7）时间在2025年9月30日之前的记录
-- AND e.is_use = 'Y'
-- AND a.product_no IN (
--     'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
-- )
-- AND b.product_no IN (
--     'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
-- );
-- 
-- 
-- -- 4 消金简版
-- REPLACE INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
--   `dbank_id`,
--   `ddate`,
--   `xh`,
--   `relieve_no`,
--   `cont_no`,
--   `biz_no`,
--   `project_name`,
--   `recv_type`,
--   `recv_date`,
--   `recv_amt`,
--   `settle_flag`
-- )
-- SELECT
--     'DEFAULT_BANK' AS dbank_id,
--     last_day(a.repay_time) AS ddate,
--     uuid() AS xh,
--     a.tran_rp_no AS relieve_no,
--     a.loan_no AS cont_no,
--     a.loan_no AS biz_no,
--     e.project_name,
--     'A' AS recv_type,
--     DATE_FORMAT(a.repay_time, '%Y-%m-%d') AS recv_date,
--     a.print AS recv_amt,
--     
--     -- ★ 关键逻辑：满足两个条件才为 Y
--     CASE
--         WHEN rn = 1   
--          AND (b.loan_amt - sum_no_cps_print) = 0
--         THEN 'Y'
--         ELSE 'N'
--     END AS settle_flag
-- FROM (
--     SELECT 
--         a.*,
--         SUM(CASE WHEN a.repay_type NOT IN (5) THEN a.print ELSE 0 END) 
--             OVER (PARTITION BY a.loan_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--             AS sum_no_cps_print,         -- 累计非代偿金额
-- 
--         ROW_NUMBER() OVER (PARTITION BY a.loan_no ORDER BY a.repay_time DESC,term DESC) AS rn   -- 最后一笔还款
--     FROM `prd_spark_db`.ods_cons_td_repay_info a
-- ) a
-- JOIN `rd_cfund`.td_loan b
--     ON a.loan_no = b.loan_no
-- JOIN test_zxbs_db.hain_effective_data_interval e
--     ON b.product_no = e.project_code
--     AND b.recon_date BETWEEN e.start_date AND e.end_date
-- WHERE a.repay_type != 5  -- 排除所有追偿（repay_type = 8）
-- AND (a.repay_type NOT IN (3, 4) OR a.repay_time <= '2024-09-30')
-- AND b.product_no = 'JTTD-ZT-HC-ZYXJ';
-- 
-- 
-- -- 原数据逻辑异常，删掉这个是为了避免出现'担保-解除-代偿 < 0'的错误；
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'RA6710616891617988608'; -- 这个是25年11月的
-- 
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'ZTJH2429619';  -- 2025-07-31
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'ZTJH2429421';
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'ZTJH2414044';




-- ******************************************************************************************************************************************************


-- RENAME TABLE ads_hain_g23_2_relieve_detail TO ads_hain_g23_2_relieve_detail_20260306;
-- CREATE TABLE ads_hain_g23_2_relieve_detail LIKE ads_hain_g23_2_relieve_detail_20260306;
-- INSERT INTO ads_hain_g23_2_relieve_detail SELECT * FROM ads_hain_g23_2_relieve_detail_20260306;
-- SELECT COUNT(* )  FROM ads_hain_g23_2_relieve_detail;
-- SELECT COUNT(* )  FROM ads_hain_g23_2_relieve_detail_20260306;

-- -- 度小满异常借据更新（处理还款总额大于放款金额的情况）
-- UPDATE  rd_cfund.ln_repay_info
--   SET `print` = 4989.92
-- WHERE `apply_no` = 'DXM2023-04-16_00091162'
--     AND `term` = 12
-- ;



-- 1.不需要去掉代偿的项目
INSERT  INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
)
SELECT 
  -- DISTINCT(`project_name` ) 
    `dbank_id`,
    `ddate`,
    `xh`,
    `relieve_no`,
    `cont_no`,
    `biz_no`,
    `project_name`,
    `recv_type`,
    `recv_date`,
    `recv_amt`,
    `settle_flag`
FROM (
SELECT
    'DEFAULT_BANK' AS dbank_id,
    LAST_DAY(a.repay_time) AS ddate,
    uuid() AS xh,
    a.tran_rp_no AS relieve_no,
    a.apply_no AS cont_no,
    a.apply_no AS biz_no,
    e.project_name,
    'A' AS recv_type,
    CAST(a.repay_time AS DATE) AS recv_date,
    a.print AS recv_amt,

    -- ★ 关键逻辑：满足两个条件才为 Y
    CASE
        WHEN rn = 1   
         AND (b.loan_amt - sum_no_cps_print) = 0
        THEN 'Y'
        ELSE 'N'
    END AS settle_flag

FROM (
    SELECT 
        a.*,
        SUM(CASE WHEN a.repay_type NOT IN (8) THEN a.print ELSE 0 END) 
            OVER (PARTITION BY a.apply_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS sum_no_cps_print,         -- 累计非代偿金额

        ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC, term DESC) AS rn   -- 最后一笔还款
    FROM rd_cfund.ln_repay_info a
    WHERE a.product_no IN (
        'ZTDFSRL_CYCFC_FL_2',
        'ZTQSZT-QS-CY102507',
        'ZTKNchangyin_zhengtang',
        'DXM'
      ) AND a.`repay_type` <> 8
) a

JOIN rd_cfund.ln_loan_info b
    ON a.apply_no = b.apply_no
JOIN test_zxbs_db.hain_effective_data_interval e
    ON b.product_no = e.project_code
    AND b.recon_date BETWEEN e.start_date AND e.end_date

WHERE a.repay_type NOT IN (8)
  AND e.is_use = 'Y'
  AND a.product_no IN (
        'ZTDFSRL_CYCFC_FL_2',
        'ZTQSZT-QS-CY102507',
        'ZTKNchangyin_zhengtang',
        'DXM'
      )
  AND b.product_no IN (
        'ZTDFSRL_CYCFC_FL_2',
        'ZTQSZT-QS-CY102507',
        'ZTKNchangyin_zhengtang',
        'DXM'
      )
) WHERE `ddate` = '2026-06-30'
	AND `cont_no` IN (SELECT DISTINCT `cont_no` FROM `test_zxbs_db`.`ads_hain_g23_detail`)
  ;

-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `project_name` IN ('正堂-君航-中原青岛产品','正堂-360-众安D产品', '正堂-360-众安产品') AND `ddate` = '2026-03-31';
-- SELECT * FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `project_name` IN ('正堂-君航-中原青岛产品','正堂-360-众安D产品', '正堂-360-众安产品') AND `ddate` = '2026-03-31';


-- 2 去掉代偿且代偿时间在24年10月以后的
INSERT INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
)
SELECT 
  -- COUNT(*) 
  -- DISTINCT(`project_name` ) 
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
  
FROM (
    SELECT
        'DEFAULT_BANK' AS dbank_id,
        LAST_DAY(a.repay_time) AS ddate,
        uuid() AS xh,
        a.tran_rp_no AS relieve_no,
        a.apply_no AS cont_no,
        a.apply_no AS biz_no,
        e.project_name,
        'A' AS recv_type,
        CAST(a.repay_time AS DATE) AS recv_date,
        a.print AS recv_amt,
        
        -- ★ 关键逻辑：满足两个条件才为 Y
        CASE
            WHEN rn = 1   
             AND (b.loan_amt - sum_no_cps_print) = 0
            THEN 'Y'
            ELSE 'N'
        END AS settle_flag
    FROM (
        SELECT 
            a.*,
            SUM(CASE WHEN a.repay_type NOT IN (8) THEN a.print ELSE 0 END) 
                OVER (PARTITION BY a.apply_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                AS sum_no_cps_print,         -- 累计非代偿金额
    
            ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC,term DESC) AS rn   -- 最后一笔还款
        FROM rd_cfund.ln_repay_info a
        WHERE product_no IN (
            'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
            'ZT-360-ZA00-2507',
            'ZT-360-ZA01-2508'
        ) AND a.`repay_type` <> 8
    ) a
    JOIN rd_cfund.ln_loan_info b
        ON a.apply_no = b.apply_no
    JOIN test_zxbs_db.hain_effective_data_interval e
        ON b.product_no = e.project_code
        AND b.recon_date BETWEEN e.start_date AND e.end_date
    -- 还款信息报送策略：
    --      1.2024-09-30之前不报送代偿和追偿，所有的代偿和追偿一律按正常还款报送
    --      2.2024-09-30以后的数据正常报送代偿和追偿数据
    WHERE a.repay_type != 8  -- 排除所有追偿（repay_type = 8）
        AND (a.repay_type != 7 OR a.repay_time <= '2024-09-30' 
              OR RIGHT(b.`id_card` , 1)  IN (5,9)  
             )  -- 只取代偿（repay_type = 7）时间在2024年10月31日之前的记录 ,同时身份证号尾号为4和8的，本月的代偿还款按正常还款来报送
  
        AND e.is_use = 'Y'
        AND a.product_no IN (
           --  'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk', -- 海南正堂-桔子-中原消金/中关村银行（联合贷）：项目已结束
            'ZT-360-ZA00-2507',
            'ZT-360-ZA01-2508'
        )
        AND b.product_no IN (
            'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
            'ZT-360-ZA00-2507',
            'ZT-360-ZA01-2508'
        )
 ) 
WHERE `ddate` = '2026-06-30' 
	AND `cont_no` IN (SELECT DISTINCT `cont_no` FROM `test_zxbs_db`.`ads_hain_g23_detail`)
;


-- 3 君航：去掉代偿且代偿时间在25年9月以后的
INSERT INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
)
SELECT 
    -- COUNT(*) 
  -- DISTINCT(`project_name` ) 
  `dbank_id`,
  `ddate`,
  `xh`,
  `relieve_no`,
  `cont_no`,
  `biz_no`,
  `project_name`,
  `recv_type`,
  `recv_date`,
  `recv_amt`,
  `settle_flag`
FROM (
SELECT
    'DEFAULT_BANK' AS dbank_id,
    LAST_DAY(a.repay_time) AS ddate,
    uuid() AS xh,
    a.tran_rp_no AS relieve_no,
    a.apply_no AS cont_no,
    a.apply_no AS biz_no,
    e.project_name,
    'A' AS recv_type,
    CAST(a.repay_time AS DATE) AS recv_date,
    a.print AS recv_amt,
    
    -- ★ 关键逻辑：满足两个条件才为 Y
    CASE
        WHEN rn = 1   
         AND (b.loan_amt - sum_no_cps_print) = 0
        THEN 'Y'
        ELSE 'N'
    END AS settle_flag
FROM (
    SELECT 
        a.*,
        SUM(CASE WHEN a.repay_type NOT IN (8) THEN a.print ELSE 0 END) 
            OVER (PARTITION BY a.apply_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS sum_no_cps_print,         -- 累计非代偿金额

        ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC,term DESC) AS rn   -- 最后一笔还款
    FROM rd_cfund.ln_repay_info a
   WHERE product_no IN (
        'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
    ) AND a.`repay_type` <> 8
) a
JOIN rd_cfund.ln_loan_info b
    ON a.apply_no = b.apply_no
JOIN test_zxbs_db.hain_effective_data_interval e
    ON b.product_no = e.project_code
    AND b.recon_date BETWEEN e.start_date AND e.end_date
    -- 还款信息报送策略：
    --      1.2025-09-30之前不报送代偿和追偿，所有的代偿和追偿一律按正常还款报送
    --      2.2025-09-30以后的数据正常报送代偿和追偿数据
    WHERE a.repay_type != 8  -- 排除所有追偿（repay_type = 8）
    AND (a.repay_type != 7 OR a.repay_time <= '2025-08-31'
          OR RIGHT(b.`id_card` , 1)  IN (5,9)  
        )  -- 只取代偿（repay_type = 7）时间在2025年9月30日之前的记录
    AND e.is_use = 'Y'
    AND a.product_no IN (
        'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
    )
    AND b.product_no IN (
        'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
    )
)  WHERE `ddate` = '2026-06-30' 
	AND `cont_no` IN (SELECT DISTINCT `cont_no` FROM `test_zxbs_db`.`ads_hain_g23_detail`)
  ;


-- -- 4 消金简版(海南正堂-恒昌-中原消金:已结束，项目最晚还款时间20251104)
-- REPLACE INTO `test_zxbs_db`.`ads_hain_g23_2_relieve_detail`(
--   `dbank_id`,
--   `ddate`,
--   `xh`,
--   `relieve_no`,
--   `cont_no`,
--   `biz_no`,
--   `project_name`,
--   `recv_type`,
--   `recv_date`,
--   `recv_amt`,
--   `settle_flag`
-- )
-- SELECT 
--   `dbank_id`,
--   `ddate`,
--   `xh`,
--   `relieve_no`,
--   `cont_no`,
--   `biz_no`,
--   `project_name`,
--   `recv_type`,
--   `recv_date`,
--   `recv_amt`,
--   `settle_flag`
-- FROM (
-- SELECT
--     'DEFAULT_BANK' AS dbank_id,
--     last_day(a.repay_time) AS ddate,
--     uuid() AS xh,
--     a.tran_rp_no AS relieve_no,
--     a.loan_no AS cont_no,
--     a.loan_no AS biz_no,
--     e.project_name,
--     'A' AS recv_type,
--     DATE_FORMAT(a.repay_time, '%Y-%m-%d') AS recv_date,
--     a.print AS recv_amt,
--     
--     -- ★ 关键逻辑：满足两个条件才为 Y
--     CASE
--         WHEN rn = 1   
--          AND (b.loan_amt - sum_no_cps_print) = 0
--         THEN 'Y'
--         ELSE 'N'
--     END AS settle_flag
-- FROM (
--     SELECT 
--         a.*,
--         SUM(CASE WHEN a.repay_type NOT IN (5) THEN a.print ELSE 0 END) 
--             OVER (PARTITION BY a.loan_no ORDER BY a.repay_time,term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--             AS sum_no_cps_print,         -- 累计非代偿金额
-- 
--         ROW_NUMBER() OVER (PARTITION BY a.loan_no ORDER BY a.repay_time DESC,term DESC) AS rn   -- 最后一笔还款
--     FROM `prd_spark_db`.ods_cons_td_repay_info a
--     WHERE a.product_no = 'JTTD-ZT-HC-ZYXJ'
--         -- AND a.`repay_time` BETWEEN '2026-04-01' AND '2026-04-30'
-- ) a
-- JOIN `rd_cfund`.td_loan b
--     ON a.loan_no = b.loan_no
-- JOIN test_zxbs_db.hain_effective_data_interval e
--     ON b.product_no = e.project_code
--     AND b.recon_date BETWEEN e.start_date AND e.end_date
-- WHERE a.repay_type != 5  -- 排除所有追偿（repay_type = 8）
-- AND (a.repay_type NOT IN (3, 4) OR a.repay_time <= '2024-09-30') -- 还款类型为3，4代表代偿
-- AND b.product_no = 'JTTD-ZT-HC-ZYXJ'
-- ) WHERE `ddate` = '2026-04-30' 
-- 	AND `cont_no` IN (SELECT DISTINCT `cont_no` FROM `test_zxbs_db`.`ads_hain_g23_detail`)
--   ;


-- -- 原数据逻辑异常，删掉这个是为了避免出现'担保-解除-代偿 < 0'的错误；
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'RA6710616891617988608'; -- 这个是25年11月的

-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'ZTJH2429619';  -- 2025-07-31
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'ZTJH2429421';
-- DELETE FROM `test_zxbs_db`.`ads_hain_g23_2_relieve_detail` WHERE `relieve_no` = 'ZTJH2414044';

-- -- SELECT * FROM `test_zxbs_db`.`hain_effective_data_interval` ;
-- SELECT *  FROM `prd_spark_db`.`ods_cons_td_loan`  WHERE `product_no` = 'JTTD-ZT-HC-ZYXJ' ;
-- SELECT `bill_app_no`   FROM `prd_spark_db`.`ods_cons_td_loan`  WHERE `product_no` = 'JTTD-ZT-HC-ZYXJ' ;
-- -- SELECT MAX(`repay_time`)  FROM `prd_spark_db`.`ods_cons_td_repay_info` WHERE `product_no` = 'JTTD-ZT-HC-ZYXJ' ;
-- SELECT MAX(`repay_time`)  FROM `prd_spark_db`.`ods_cons_td_repay_info` WHERE `loan_no` in (
--   SELECT `bill_app_no`   FROM `prd_spark_db`.`ods_cons_td_loan`  WHERE `product_no` = 'JTTD-ZT-HC-ZYXJ' 
-- ) ;