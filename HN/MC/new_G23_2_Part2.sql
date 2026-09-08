-- ============================================================================
-- 段2: 去掉代偿且代偿时间在 2024年10月以后的项目
--      逻辑: repay_type <> 8 排除追偿；repay_type=7（代偿）时间<=2024-09-30 或身份证尾号为5/9按正常还款报送
--      产品: HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk / ZT-360-ZA00-2507 / ZT-360-ZA01-2508
-- ============================================================================
SET odps.sql.reshuffle.dynamicpt = true;

MERGE INTO ads_hain_g23_2_relieve_detail t
USING (
    SELECT
        'DEFAULT_BANK'                                 AS dbank_id,    -- 机构代码
        CAST(LAST_DAY(TO_DATE(a.repay_time, 'yyyy-mm-dd')) AS DATE)  AS ddate,       -- 报表日期
        UUID()                                          AS xh,          -- 序号
        a.tran_rp_no                                    AS relieve_no,  -- 解保编号（主键）
        a.apply_no                                      AS cont_no,     -- 合同编号
        a.apply_no                                      AS biz_no,      -- 业务编号
        'A'                                             AS recv_type,   -- 收回方式
        CAST(TO_DATE(a.repay_time, 'yyyy-mm-dd') AS DATE)             AS recv_date,   -- 收回日期
        CAST(a.print AS DECIMAL(20,2))                 AS recv_amt,    -- 收回金额

        -- ★ 结清标识：rn=1 表示该借据最后一笔还款；(loan_amt - 累计非代偿金额)=0 表示已结清
        CASE
            WHEN rn = 1
             AND (b.loan_amt - sum_no_cps_print) = 0
            THEN 'Y'
            ELSE 'N'
        END                                             AS settle_flag, -- 是否结清

        CURRENT_TIMESTAMP()                             AS create_time, -- 创建时间
        CURRENT_TIMESTAMP()                             AS update_time, -- 修改时间
        e.project_name,                                                 -- 项目名称
        -- 动态分区列：按 ddate 所在月份取 yyyymm
        TO_CHAR(CAST(LAST_DAY(TO_DATE(a.repay_time, 'yyyy-mm-dd')) AS DATE), 'yyyymm')  AS pt  -- 报表月份 yyyymm
    FROM (
        SELECT
            a.*,
            -- 累计非代偿金额（排除 repay_type=8 追偿）
            SUM(CASE WHEN a.repay_type <> 8 THEN a.print ELSE 0 END)
                OVER (PARTITION BY a.apply_no ORDER BY a.repay_time, term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                AS sum_no_cps_print,
            -- 取每个借据最后一笔还款
            ROW_NUMBER() OVER (PARTITION BY a.apply_no ORDER BY a.repay_time DESC, term DESC) AS rn
        FROM prod_dw_01.dwd_cons_loan_payment_info_incr_delta a
        WHERE a.product_no IN (
            'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
            'ZT-360-ZA00-2507',
            'ZT-360-ZA01-2508'
        )
          AND a.repay_type <> 8
          AND a.pt <= '20260831'
          AND a.pt >= '20220101'
        --   AND a.pt <= '${bizmonth}'   -- 排除未来分区（调度参数，编译期分区裁剪）
    ) a
    JOIN prod_dw_01.ods_cons_td_loan_incr_delta b
        ON a.apply_no = b.bill_app_no
    JOIN hain_effective_data_interval e
        ON b.product_no = e.project_code
        AND b.recon_date BETWEEN e.start_date AND e.end_date
    -- 还款信息报送策略：
    --      1.2024-09-30 之前不报送代偿和追偿，所有代偿/追偿一律按正常还款报送
    --      2.2024-09-30 以后的数据正常报送代偿和追偿
    WHERE
        -- 排除所有追偿（repay_type = 8）
        a.repay_type <> 8
        -- 代偿(repay_type=7)时间在2024年10月31日之前的记录；身份证尾号为5/9的本月代偿按正常报送
        AND (a.repay_type <> 7 OR a.repay_time <= '2024-09-30'
              OR SUBSTR(b.id_card, -1, 1) IN ('5', '9')
             )
        AND e.is_use = 'Y'
        AND b.product_no IN (
            'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
            'ZT-360-ZA00-2507',
            'ZT-360-ZA01-2508'
        )
        AND b.pt <= TO_CHAR(GETDATE(), 'yyyymm')
        AND LAST_DAY(CAST(a.repay_time AS DATE)) = LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
) s
-- ON 条件包含分区谓词 t.pt=s.pt，避免全分区扫描（ODPS-0130071）
ON t.relieve_no = s.relieve_no AND t.pt = s.pt
WHEN MATCHED THEN UPDATE SET
    t.dbank_id      = s.dbank_id,
    t.ddate         = s.ddate,
    t.xh            = s.xh,
    t.cont_no       = s.cont_no,
    t.biz_no        = s.biz_no,
    t.recv_type     = s.recv_type,
    t.recv_date     = s.recv_date,
    t.recv_amt      = s.recv_amt,
    t.settle_flag   = s.settle_flag,
    t.update_time   = s.update_time,
    t.project_name  = s.project_name
WHEN NOT MATCHED THEN INSERT (
    dbank_id, ddate, xh, relieve_no, cont_no, biz_no,
    recv_type, recv_date, recv_amt, settle_flag,
    create_time, update_time, project_name, pt
) VALUES (
    s.dbank_id, s.ddate, s.xh, s.relieve_no, s.cont_no, s.biz_no,
    s.recv_type, s.recv_date, s.recv_amt, s.settle_flag,
    s.create_time, s.update_time, s.project_name, s.pt
)
;
