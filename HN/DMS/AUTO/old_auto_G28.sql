REPLACE INTO test_zxbs_db.`ads_hain_g28_recover_detail` (
    dbank_id,
    ddate,
    xh,
    project_name,
    cont_no,
    biz_no,
    recv_seq,
    recv_date,
    recv_amt
)
select dbank_id, ddate, xh, project_name, biz_no,cont_no, comp_seq, 
       DATE(
            CASE
                WHEN comp_date = LAST_DAY(comp_date)
                THEN comp_date
                ELSE DATE_ADD(comp_date, INTERVAL 1 DAY)
            END
        ) AS recv_date
       , CAST((comp_amt+comp_int) AS DECIMAL(20,2)) AS recv_amt
  from `test_zxbs_db`.ads_hain_g27_comp_detail
  -- WHERE `ddate` = '2026-05-31'
  WHERE `ddate` = DATE_SUB(DATE_FORMAT(CURRENT_DATE , '%Y-%m-01') , INTERVAL 1 DAY)
  AND `project_name` IN ('海南正堂-浙江浙融-国银租赁', '海南正堂-龙环汇丰-苏商银行')
;