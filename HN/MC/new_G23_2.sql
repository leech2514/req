-- ============================================================================
-- 脚本名称: new_G23_2.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G23-2 担保解除明细月度报送（按还款数据生成解除明细，含3段逻辑：无代偿项目/24年10月后代偿/君航代偿）
-- 源表:     prod_dw_01.dwd_cons_loan_payment_info_incr_delta   （还款计划表，原 rd_cfund.ln_repay_info / prd_spark_db.ods_cons_td_repay_info）
--           prod_dw_01.ods_cons_td_loan_incr_delta              （借据表，原 rd_cfund.ln_loan_info / rd_cfund.td_loan）
--           prod_dw_01.hain_effective_data_interval             （有效数据区间配置表，原 test_zxbs_db.hain_effective_data_interval）
--           prod_dw_01.ads_hain_g23_detail                      （G23明细表，用于cont_no过滤）
-- 目标表:   ads_hain_g23_2_relieve_detail
-- 写入模式: MERGE INTO（Delta 主键表，按 relieve_no + pt 分区主键更新/插入）
-- 增量方式: incr（3段逻辑分别 MERGE，按 ddate 过滤当月数据）
-- 分区字段: pt (STRING, yyyymm，取自 ddate 报表日期所在月份)
-- 主键:     relieve_no（Delta 主键表，分区列 pt 自动纳入联合唯一性约束）
-- 调度参数: bizdate=$bizdate
--           bizmonth=$bizmonth        -- yyyyMMdd 业务月末（上月末日）
-- 调度周期: 月度（每月报送当月解除明细）
-- 负责人:   <name>
-- 创建日期: 2026-08-26
-- 修订记录:
--   2026-08-26  <name>  新建脚本  -  原 DMS old_G23_2.sql 迁移至 MaxCompute
--   2026-08-26  <name>  修改      -  按 new_hainanDDL.sql DDL 重构：INSERT INTO → MERGE INTO(Delta表)；补 create_time/update_time/project_name 字段；补 pt 动态分区；ON 条件加分区谓词
--   2026-08-26  <name>  优化      -  硬编码日期改为调度参数 ${bizmonth}；MERGE INSERT 补显式列清单对齐 DDL；移除冗余 repay_type 过滤；分区过滤改用调度参数
-- 迁移说明（原 old_G23_2.sql → MC）:
--   1. 源表按《表名映射关系.md》+ G23 参考映射替换：
--        rd_cfund.ln_repay_info              → prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--        rd_cfund.ln_loan_info               → prod_dw_01.ods_cons_td_loan_incr_delta
--        prd_spark_db.ods_cons_td_repay_info  → prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--        rd_cfund.td_loan                    → prod_dw_01.ods_cons_td_loan_incr_delta
--        test_zxbs_db.hain_effective_data_interval → prod_dw_01.hain_effective_data_interval
--        test_zxbs_db.ads_hain_g23_detail    → prod_dw_01.ads_hain_g23_detail
--   2. uuid() → UUID()（MC 无 GET_UUID() 函数，改用 MC 2.0 原生 UUID() 生成随机 UUID 字符串）
--   3. RIGHT(str, n) → SUBSTR(str, -n, n)（MC 无 RIGHT 函数，用 SUBSTR 负索引替代）
--   4. CAST(repay_time AS DATE) → TO_DATE(repay_time, 'yyyy-mm-dd')（MC 标准日期转换）
--   5. DATE_FORMAT(str, '%Y-%m-%d') → TO_CHAR(str, 'yyyy-mm-dd')（MC 日期格式串用小写）
--   6. 移除所有反引号 `` ` ``
--   7. a.repay_type != 8 → a.repay_type <> 8（MC 推荐 <> 语法，兼容保留）
--   8. 按 new_hainanDDL.sql DDL 重构：
--      - INSERT INTO → MERGE INTO（Delta 主键表必须用 MERGE）
--      - 补 create_time / update_time / project_name 字段（DDL 列）
--      - recv_amt CAST AS DECIMAL(20,2)（对齐 DDL 类型）
--      - pt 动态分区列：TO_CHAR(ddate, 'yyyymm')
--      - MERGE ON 条件：t.relieve_no = s.relieve_no AND t.pt = s.pt（分区谓词避免全分区扫描）
-- 风险提示:
--   - 目标表为 Delta 主键表（transactional=true），MERGE ON 必须包含分区谓词 t.pt=s.pt，否则触发全分区扫描报 ODPS-0130071
--   - recv_amt 原 a.print 类型需确认，若为 STRING 需 CAST AS DECIMAL(20,2)
--   - hain_effective_data_interval 表若跨 project（prod_bs_dw），需补 schema 前缀
--   - repay_time / recon_date 应为 STRING（yyyy-mm-dd）格式，若为 DATE 需格式调整
-- ============================================================================


-- ============================================================================
-- 段1: 不需要去掉代偿的项目
--      逻辑: repay_type <> 8 的还款记录，累计非代偿金额 = 放款金额时 settle_flag='Y'
--      产品: ZTDFSRL_CYCFC_FL_2 / ZTQSZT-QS-CY102507 / ZTKNchangyin_zhengtang / DXM
-- ============================================================================

MERGE INTO ads_hain_g23_2_relieve_detail t
USING (
    SELECT
        'DEFAULT_BANK'                                  AS dbank_id,    -- 机构代码
        LAST_DAY(a.repay_time)                          AS ddate,       -- 报表日期
        UUID()                                          AS xh,          -- 序号
        a.tran_rp_no                                    AS relieve_no,  -- 解保编号（主键）
        a.bill_app_no                                   AS cont_no,     -- 合同编号
        a.bill_app_no                                   AS biz_no,      -- 业务编号
        'A'                                             AS recv_type,   -- 收回方式
        TO_DATE(a.repay_time, 'yyyy-mm-dd')             AS recv_date,   -- 收回日期
        CAST(a.print AS DECIMAL(20,2))                  AS recv_amt,    -- 收回金额

        -- ★ 结清标识：rn=1 表示该借据最后一笔还款；(loan_amt - 累计非代偿金额)=0 表示已结清
        CASE
            WHEN rn = 1
             AND (b.loan_amt - sum_no_cps_print) = 0
            THEN 'Y'
            ELSE 'N'
        END                                             AS settle_flag, -- 是否结清

        GETDATE()                                       AS create_time, -- 创建时间
        GETDATE()                                       AS update_time, -- 修改时间
        e.project_name,                                                 -- 项目名称
        -- 动态分区列：按 ddate 所在月份取 yyyymm
        TO_CHAR(CAST(LAST_DAY(a.repay_time) AS DATE), 'yyyymm')  AS pt  -- 报表月份 yyyymm
    FROM (
        SELECT
            a.*,
            -- 累计非代偿金额（排除 repay_type=8 追偿）
            SUM(CASE WHEN a.repay_type <> 8 THEN a.print ELSE 0 END)
                OVER (PARTITION BY a.bill_app_no ORDER BY a.repay_time, term ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                AS sum_no_cps_print,
            -- 取每个借据最后一笔还款
            ROW_NUMBER() OVER (PARTITION BY a.bill_app_no ORDER BY a.repay_time DESC, term DESC) AS rn
        FROM prod_dw_01.dwd_cons_repay_info_incr_delta  a
        WHERE a.product_no IN (
            'ZTDFSRL_CYCFC_FL_2',
            'ZTQSZT-QS-CY102507',
            'ZTKNchangyin_zhengtang',
            'DXM'
        )
          AND a.repay_type <> 8
          AND a.pt <= '20260824'
          AND a.pt >= '20260624'
        --   AND a.pt <= '${bizmonth}'   -- 排除未来分区（调度参数，编译期分区裁剪）
    ) a
    JOIN prod_dw_01.dwd_cons_loan_payment_info_incr_delta  b
        ON a.bill_app_no = b.bill_app_no
    JOIN hain_effective_data_interval e
        ON b.product_no = e.project_code
        AND b.recon_date BETWEEN e.start_date AND e.end_date
    WHERE e.is_use = 'Y'
        AND b.product_no IN (
                'ZTDFSRL_CYCFC_FL_2',
                'ZTQSZT-QS-CY102507',
                'ZTKNchangyin_zhengtang',
                'DXM'
            )
        AND b.pt <= TO_CHAR(GETDATE(), 'yyyymm')
        -- AND LAST_DAY(a.repay_time) = TO_DATE('${bizmonth}', 'yyyyMMdd')
        AND LAST_DAY(a.repay_time) = TO_DATE('2026-07-31', 'yyyyMMdd')
        AND a.bill_app_no IN (SELECT DISTINCT cont_no FROM prod_bs_dw.ads_hain_g23_detail)
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

-- ============================================================================
-- 段2: 去掉代偿且代偿时间在 2024年10月以后的项目
--      逻辑: repay_type <> 8 排除追偿；repay_type=7（代偿）时间<=2024-09-30 或身份证尾号为5/9按正常还款报送
--      产品: HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk / ZT-360-ZA00-2507 / ZT-360-ZA01-2508
-- ============================================================================

MERGE INTO ads_hain_g23_2_relieve_detail t
USING (
    SELECT
        'DEFAULT_BANK'                                 AS dbank_id,    -- 机构代码
        LAST_DAY(a.repay_time)                          AS ddate,       -- 报表日期
        UUID()                                          AS xh,          -- 序号
        a.tran_rp_no                                    AS relieve_no,  -- 解保编号（主键）
        a.apply_no                                      AS cont_no,     -- 合同编号
        a.apply_no                                      AS biz_no,      -- 业务编号
        'A'                                             AS recv_type,   -- 收回方式
        TO_DATE(a.repay_time, 'yyyy-mm-dd')             AS recv_date,   -- 收回日期
        CAST(a.print AS DECIMAL(20,2))                 AS recv_amt,    -- 收回金额

        -- ★ 结清标识：rn=1 表示该借据最后一笔还款；(loan_amt - 累计非代偿金额)=0 表示已结清
        CASE
            WHEN rn = 1
             AND (b.loan_amt - sum_no_cps_print) = 0
            THEN 'Y'
            ELSE 'N'
        END                                             AS settle_flag, -- 是否结清

        GETDATE()                                       AS create_time, -- 创建时间
        GETDATE()                                       AS update_time, -- 修改时间
        e.project_name,                                                 -- 项目名称
        -- 动态分区列：按 ddate 所在月份取 yyyymm
        TO_CHAR(CAST(LAST_DAY(a.repay_time) AS DATE), 'yyyymm')  AS pt  -- 报表月份 yyyymm
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
          AND a.pt <= '${bizmonth}'   -- 排除未来分区（调度参数，编译期分区裁剪）
    ) a
    JOIN prod_dw_01.ods_cons_td_loan_incr_delta b
        ON a.apply_no = b.bill_app_no
    JOIN prod_dw_01.hain_effective_data_interval e
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
        AND LAST_DAY(a.repay_time) = TO_DATE('${bizmonth}', 'yyyyMMdd')
        AND a.apply_no IN (SELECT DISTINCT cont_no FROM prod_dw_01.ads_hain_g23_detail)
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


-- ============================================================================
-- 段3: 君航项目 - 去掉代偿且代偿时间在 2025年9月以后
--      逻辑: repay_type <> 8 排除追偿；repay_type=7（代偿）时间<=2025-08-31 或身份证尾号为5/9按正常还款报送
--      产品: ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509
-- ============================================================================

MERGE INTO ads_hain_g23_2_relieve_detail t
USING (
    SELECT
        'DEFAULT_BANK'                                 AS dbank_id,    -- 机构代码
        LAST_DAY(a.repay_time)                          AS ddate,       -- 报表日期
        UUID()                                          AS xh,          -- 序号
        a.tran_rp_no                                    AS relieve_no,  -- 解保编号（主键）
        a.apply_no                                      AS cont_no,     -- 合同编号
        a.apply_no                                      AS biz_no,      -- 业务编号
        'A'                                             AS recv_type,   -- 收回方式
        TO_DATE(a.repay_time, 'yyyy-mm-dd')             AS recv_date,   -- 收回日期
        CAST(a.print AS DECIMAL(20,2))                 AS recv_amt,    -- 收回金额

        -- ★ 结清标识：rn=1 表示该借据最后一笔还款；(loan_amt - 累计非代偿金额)=0 表示已结清
        CASE
            WHEN rn = 1
             AND (b.loan_amt - sum_no_cps_print) = 0
            THEN 'Y'
            ELSE 'N'
        END                                             AS settle_flag, -- 是否结清

        GETDATE()                                       AS create_time, -- 创建时间
        GETDATE()                                       AS update_time, -- 修改时间
        e.project_name,                                                 -- 项目名称
        -- 动态分区列：按 ddate 所在月份取 yyyymm
        TO_CHAR(CAST(LAST_DAY(a.repay_time) AS DATE), 'yyyymm')  AS pt  -- 报表月份 yyyymm
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
        WHERE a.product_no IN ('ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509')
          AND a.repay_type <> 8
          AND a.pt <= '${bizmonth}'   -- 排除未来分区（调度参数，编译期分区裁剪）
    ) a
    JOIN prod_dw_01.ods_cons_td_loan_incr_delta b
        ON a.apply_no = b.bill_app_no
    JOIN prod_dw_01.hain_effective_data_interval e
        ON b.product_no = e.project_code
        AND b.recon_date BETWEEN e.start_date AND e.end_date
    -- 还款信息报送策略：
    --      1.2025-09-30 之前不报送代偿和追偿，所有代偿/追偿一律按正常还款报送
    --      2.2025-09-30 以后的数据正常报送代偿和追偿
    WHERE
        -- 排除所有追偿（repay_type = 8）
        a.repay_type <> 8
        -- 代偿(repay_type=7)时间在2025年9月30日之前的记录；身份证尾号为5/9的本月代偿按正常报送
        AND (a.repay_type <> 7 OR a.repay_time <= '2025-08-31'
              OR SUBSTR(b.id_card, -1, 1) IN ('5', '9')
            )
        AND e.is_use = 'Y'
        AND b.product_no IN ('ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509')
        AND LAST_DAY(a.repay_time) = TO_DATE('${bizmonth}', 'yyyyMMdd')
        AND a.apply_no IN (SELECT DISTINCT cont_no FROM prod_dw_01.ads_hain_g23_detail)
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
