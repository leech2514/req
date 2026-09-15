INSERT INTO test_zxbs_db.`ads_hain_g27_comp_detail` (
     xh,dbank_id, ddate, cont_no, biz_no, project_name,
    comp_type, comp_seq, comp_date, comp_amt, comp_int
)
-- SELECT * FROM (
SELECT
    CAST(ROW_NUMBER() OVER () AS INTEGER) AS xh,
    t.dbank_id,
    t.ddate,
    t.cont_no,
    t.biz_no,
    t.project_name,
    t.comp_type,
    t.comp_seq,
    CAST(t.comp_date as date) AS comp_date,
    t.comp_amt,
    t.comp_int
FROM (
    -- 第一部分：ln_repay_info 表
    SELECT
        'DEFAULT_BANK' AS dbank_id,
        LAST_DAY(info.repay_time) AS ddate,
        info.apply_no AS cont_no,
        info.apply_no AS biz_no,
        fb.project_name,
        'A' AS comp_type,
        info.tran_rp_no AS comp_seq,
        info.repay_time AS comp_date,
        CAST(info.print  AS DECIMAL(20,2)) AS comp_amt,
        CAST(info.int_amt AS DECIMAL(20,2)) AS comp_int
    FROM `rd_cfund`.ln_repay_info info
    INNER JOIN (
        -- filter_bill 子查询
        SELECT
            l.product_no,
            l.apply_no,
            i.project_name,l.id_card
        FROM (
            SELECT product_no, apply_no, loan_time,`id_card` 
            FROM `rd_cfund`.ln_loan_info
            WHERE product_no IN (
          'ZT-360-ZA00-2507', 'ZT-360-ZA01-2508',
           'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
          , 'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
        )

            -- UNION ALL

            -- SELECT tl.product_no, tl.loan_no, tl.loan_date
            -- FROM td_loan tl
        ) AS l
      JOIN test_zxbs_db.hain_effective_data_interval i
          ON l.product_no = i.project_code
         AND l.loan_time BETWEEN i.start_date AND i.end_date
        WHERE i.is_use = 'Y'
    ) fb ON info.apply_no = fb.apply_no
    WHERE info.recon_date >= '2024-10-01'
        AND fb.product_no IN (
          'ZT-360-ZA00-2507', 'ZT-360-ZA01-2508',
          'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
         --  , 'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
        )
        AND info.repay_type = 7
        -- AND RIGHT(fb.`id_card` , 1) NOT IN (3,7)  -- 身份证尾号不为3或7的，代偿数据依旧按代偿来报
        -- AND RIGHT(fb.`id_card` , 1) NOT IN (4,8)  -- 身份证尾号不为4或8的，代偿数据依旧按代偿来报
        AND RIGHT(fb.`id_card` , 1) NOT IN (5,9)  -- 身份证尾号不为5或9的，代偿数据依旧按代偿来报
        AND  LAST_DAY(info.repay_time) = '2026-06-30'
    ORDER BY cont_no, comp_type
) t
  WHERE  `cont_no` IN (SELECT DISTINCT `cont_no` FROM `test_zxbs_db`.`ads_hain_g23_detail`)
    -- ) a WHERE ddate = '2026-06-30'
  ;