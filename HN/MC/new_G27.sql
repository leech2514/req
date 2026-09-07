-- ============================================================================
-- 脚本名称: new_G27.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G27 代偿明细月度报送（按还款数据生成代偿明细，排除身份证尾号为5/9的正常还款记录）
-- 源表:     prod_dw_01.dwd_cons_loan_payment_info_incr_delta   （还款计划表，原 rd_cfund.ln_repay_info）
--           prod_dw_01.ods_cons_td_loan_incr_delta              （借据表，原 rd_cfund.ln_loan_info）
--           prod_dw_01.hain_effective_data_interval             （有效数据区间配置表，原 test_zxbs_db.hain_effective_data_interval）
--           prod_dw_01.ads_hain_g23_detail                      （G23明细表，用于cont_no过滤）
-- 目标表:   ads_hain_g27_comp_detail
-- 写入模式: MERGE INTO（Delta 主键表，按 comp_seq + cont_no + pt 分区主键更新/插入）
-- 增量方式: incr（按月度过滤数据）
-- 分区字段: pt (STRING, yyyymm，取自 ddate 报表日期所在月份)
-- 主键:     comp_seq, cont_no（Delta 主键表，分区列 pt 自动纳入联合唯一性约束）
-- 调度参数: bizdate=$bizdate
--           bizmonth=$bizmonth        -- yyyyMMdd 业务月末（上月末日）
-- 调度周期: 月度（每月报送当月代偿明细）
-- 负责人:   <name>
-- 创建日期: 2026-08-26
-- 修订记录:
--   2026-08-26  <name>  新建脚本  -  原 DMS old_G27.sql 迁移至 MaxCompute
-- 迁移说明（原 old_G27.sql → MC）:
--   1. 源表按《表名映射关系.md》替换：
--        rd_cfund.ln_repay_info              → prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--        rd_cfund.ln_loan_info               → prod_dw_01.ods_cons_td_loan_incr_delta
--        test_zxbs_db.hain_effective_data_interval → prod_dw_01.hain_effective_data_interval
--        test_zxbs_db.ads_hain_g23_detail    → prod_dw_01.ads_hain_g23_detail
--   2. RIGHT(str, n) → SUBSTR(str, -n, n)（MC 无 RIGHT 函数）
--   3. CAST(... AS INTEGER) → CAST(... AS BIGINT)（对齐目标表 xh 字段类型）
--   4. 移除所有反引号 `` ` ``
--   5. 写入模式: INSERT INTO → MERGE INTO（Delta 主键表必须用 MERGE）
--   6. 补 create_time / update_time 字段（DDL 列），用 GETDATE() 赋值
--   7. 补 pt 动态分区列：TO_CHAR(ddate, 'yyyymm')
--   8. MERGE ON 条件：t.comp_seq = s.comp_seq AND t.cont_no = s.cont_no AND t.pt = s.pt（分区谓词避免全分区扫描）
--   9. 硬编码日期 '2026-06-30' → 调度参数 ${bizmonth}
-- 风险提示:
--   - 目标表为 Delta 主键表（transactional=true），MERGE ON 必须包含分区谓词 t.pt=s.pt，否则触发全分区扫描报 ODPS-0130071
--   - hain_effective_data_interval 表若跨 project（prod_bs_dw），需补 schema 前缀
--   - 源表字段 repay_time / recon_date 应为 STRING（yyyy-mm-dd）格式，若为 DATE 需格式调整
-- ============================================================================


-- ============================================================================
-- 段1: 代偿明细数据报送
--      逻辑: repay_type = 7（代偿），排除身份证尾号为5/9的记录（按正常还款报送）
--      产品: ZT-360-ZA00-2507 / ZT-360-ZA01-2508 / ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509 / HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk
-- ============================================================================

MERGE INTO ads_hain_g27_comp_detail t
USING (
    SELECT
        'DEFAULT_BANK'                          AS dbank_id,     -- 机构代码
        LAST_DAY(info.repay_time)                AS ddate,        -- 报表日期
        CAST(ROW_NUMBER() OVER () AS BIGINT)     AS xh,           -- 序号
        info.apply_no                           AS cont_no,      -- 合同编号
        info.apply_no                           AS biz_no,       -- 业务编号
        fb.project_name,
        'A'                                     AS comp_type,    -- 代偿机构类型
        info.tran_rp_no                          AS comp_seq,     -- 代偿序号（主键）
        TO_DATE(info.repay_time, 'yyyy-mm-dd')   AS comp_date,    -- 代偿日期
        CAST(info.print AS DECIMAL(20,2))       AS comp_amt,     -- 本次代偿金额
        CAST(info.int_amt AS DECIMAL(20,2))     AS comp_int,     -- 本次代偿利息
        GETDATE()                                AS create_time,  -- 创建时间
        GETDATE()                                AS update_time,  -- 修改时间
        -- 动态分区列：按 ddate 所在月份取 yyyymm
        TO_CHAR(LAST_DAY(info.repay_time), 'yyyymm') AS pt        -- 报表月份 yyyymm
    FROM prod_dw_01.dwd_cons_loan_payment_info_incr_delta info
    INNER JOIN (
        -- filter_bill 子查询：筛选有效数据区间内的借据
        SELECT
            l.product_no,
            l.apply_no,
            i.project_name,
            l.id_card
        FROM (
            SELECT product_no, apply_no, loan_time, id_card
            FROM prod_dw_01.ods_cons_td_loan_incr_delta
            WHERE product_no IN (
                'ZT-360-ZA00-2507',
                'ZT-360-ZA01-2508',
                'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509',
                'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
            )
        ) l
        JOIN prod_dw_01.hain_effective_data_interval i
            ON l.product_no = i.project_code
            AND l.loan_time BETWEEN i.start_date AND i.end_date
        WHERE i.is_use = 'Y'
    ) fb ON info.apply_no = fb.apply_no
    WHERE info.recon_date >= '2024-10-01'
        AND fb.product_no IN (
            'ZT-360-ZA00-2507',
            'ZT-360-ZA01-2508',
            'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
            -- 'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'  -- 注释：产品已调整
        )
        AND info.repay_type = 7
        -- 身份证尾号不为5或9的，代偿数据依旧按代偿来报
        AND SUBSTR(fb.id_card, -1, 1) NOT IN ('5', '9')
        AND LAST_DAY(info.repay_time) = TO_DATE('${bizmonth}', 'yyyyMMdd')
        AND info.pt <= '${bizmonth}'  -- 排除未来分区（调度参数，编译期分区裁剪）
    ORDER BY cont_no, comp_type
) s
-- ON 条件包含分区谓词 t.pt=s.pt，避免全分区扫描（ODPS-0130071）
ON t.comp_seq = s.comp_seq AND t.cont_no = s.cont_no AND t.pt = s.pt
WHEN MATCHED THEN UPDATE SET
    t.dbank_id      = s.dbank_id,
    t.ddate         = s.ddate,
    t.xh            = s.xh,
    t.comp_type     = s.comp_type,
    t.comp_date     = s.comp_date,
    t.comp_amt      = s.comp_amt,
    t.comp_int      = s.comp_int,
    t.update_time   = s.update_time,
    t.project_name  = s.project_name
WHEN NOT MATCHED THEN INSERT (
    dbank_id, ddate, xh, cont_no, biz_no,
    comp_type, comp_seq, comp_date, comp_amt, comp_int,
    create_time, update_time, project_name, pt
) VALUES (
    s.dbank_id, s.ddate, s.xh, s.cont_no, s.biz_no,
    s.comp_type, s.comp_seq, s.comp_date, s.comp_amt, s.comp_int,
    s.create_time, s.update_time, s.project_name, s.pt
)
;
