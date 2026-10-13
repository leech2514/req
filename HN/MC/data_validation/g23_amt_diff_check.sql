-- ============================================================
-- 数据校验：G23 担保金额与解保/代偿金额差额检查
-- 校验逻辑：担保金额 - 解保金额 - 代偿金额 < 0（异常数据）
-- 来源表：
--   ads_hain_g23_detail          G23 担保明细（主表）
--   ads_hain_g23_2_relieve_detail G23-2 解保明细
--   ads_hain_g27_comp_detail     G27 代偿明细
-- ============================================================
SELECT
    a.cont_no,
    (a.guar_amt - NVL(b.sum_1, 0) - NVL(c.sum_2, 0)) AS diff
FROM ads_hain_g23_detail a
-- 关联解保汇总：按合同号汇总解保金额
LEFT JOIN (
    SELECT cont_no, SUM(recv_amt) AS sum_1
    FROM ads_hain_g23_2_relieve_detail
    WHERE pt <= TO_CHAR(GETDATE(), 'yyyymm')
    GROUP BY cont_no
) b ON a.cont_no = b.cont_no
-- 关联代偿汇总：按合同号汇总代偿金额
LEFT JOIN (
    SELECT cont_no, SUM(comp_amt) AS sum_2
    FROM ads_hain_g27_comp_detail
    GROUP BY cont_no
) c ON a.cont_no = c.cont_no
-- 筛选差额为负的异常数据
WHERE (a.guar_amt - NVL(b.sum_1, 0) - NVL(c.sum_2, 0)) < 0
    AND a.pt <= TO_CHAR(GETDATE(), 'yyyymm');
