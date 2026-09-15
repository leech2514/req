-- ============================================================================
-- 脚本名称: new_auto_G28.sql
-- 层级:     ADS
-- 业务域:   海南正堂/车贷担保报送
-- 功能描述: 车贷 G28 代偿回收明细月度报送（取上月 G27 代偿明细，回收日=代偿日次日，
--           若代偿日恰为月末则当日回收；仅龙环汇丰/浙融两个项目）
-- 源表:     ads_hain_g27_comp_detail（G27 代偿明细表，prod_bs_dw，映射 010）
-- 目标表:   ads_hain_g28_recover_detail（Delta 事务主键分区表，主键 recv_seq，分区 pt=yyyymm，映射 011）
-- 写入模式: MERGE INTO（按 (recv_seq, pt) 幂等更新，同月可重跑）
-- 调度周期: 月度（每月初跑上月数据，取 G27 中 ddate=上月末 的记录）
-- 负责人:   <name>
-- 创建日期: 2026-09-14
-- ============================================================================

SET odps.sql.reshuffle.dynamicpt = true;

MERGE INTO ads_hain_g28_recover_detail t
USING (
    SELECT
        CAST('DEFAULT_BANK' AS STRING)                          AS dbank_id,
        ddate                                                   AS ddate,       -- 报表日期：上月末（来自 G27）
        xh                                                      AS xh,          -- 序号
        cont_no,                                                                                -- 合同编号
        biz_no,                                                                                 -- 业务编号
        project_name,                                                                           -- 项目名称
        comp_seq                                                AS recv_seq,    -- 回收序号=代偿序号
        -- 回收日期：代偿日为月末则当日回收，否则次日回收
        CASE
            WHEN comp_date = LAST_DAY(comp_date) THEN comp_date
            ELSE DATEADD(comp_date, 1, 'dd')
        END                                                     AS recv_date,
        CAST((comp_amt + comp_int) AS DECIMAL(20,2))            AS recv_amt,    -- 本次回收金额=代偿本金+利息
        TO_CHAR(ddate, 'yyyymm')                               AS pt           -- 报表月份分区
    FROM ads_hain_g27_comp_detail
    WHERE ddate = LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
      AND project_name IN ('海南正堂-浙江浙融-国银租赁', '海南正堂-龙环汇丰-苏商银行')
) s
ON t.recv_seq = s.recv_seq
AND t.pt = s.pt                          -- 分区谓词，避免全分区扫描
WHEN MATCHED THEN UPDATE SET
    t.dbank_id     = s.dbank_id,
    t.ddate        = s.ddate,
    t.xh           = s.xh,
    t.cont_no      = s.cont_no,
    t.biz_no       = s.biz_no,
    t.recv_date    = s.recv_date,
    t.recv_amt     = s.recv_amt,
    t.project_name = s.project_name
WHEN NOT MATCHED THEN INSERT
(
    dbank_id, ddate, xh, cont_no, biz_no, recv_seq,
    recv_date, recv_amt, project_name, pt
)
VALUES
(
    s.dbank_id, s.ddate, s.xh, s.cont_no, s.biz_no, s.recv_seq,
    s.recv_date, s.recv_amt, s.project_name, s.pt
)
;
