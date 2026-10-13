-- ============================================================
-- 数据校验：G23 已结清但担保金额仍有剩余的异常合同
-- 校验逻辑：担保金额 - 解保金额 - 代偿金额 > 0 且 settle_flag = 'Y'
--           （已标记结清但金额未核销完，疑似漏解保/代偿）
-- 来源表：
--   ads_hain_g23_detail           G23 担保明细（主表）
--   ads_hain_g23_2_relieve_detail  G23-2 解保明细
--   ads_hain_g27_comp_detail      G27 代偿明细
-- ============================================================
SELECT DISTINCT(cont_no) FROM (
SELECT
    a.cont_no,
    a.guar_amt,
    NVL(b.sum_1, 0) AS relieve_amt,
    NVL(c.sum_2, 0) AS comp_amt,
    (a.guar_amt - NVL(b.sum_1, 0) - NVL(c.sum_2, 0)) AS diff,
    d.settle_flag
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
-- 关联结清标志：按合同号取是否结清（存在 Y 则为 Y）
LEFT JOIN (
    SELECT cont_no,
           MAX(settle_flag) AS settle_flag
    FROM ads_hain_g23_2_relieve_detail
    WHERE pt <= TO_CHAR(GETDATE(), 'yyyymm')
    GROUP BY cont_no
) d ON a.cont_no = d.cont_no
WHERE
    (a.guar_amt - NVL(b.sum_1, 0) - NVL(c.sum_2, 0)) > 0   -- 差额大于 0
    AND d.settle_flag = 'Y'
    AND a.pt <= TO_CHAR(GETDATE(), 'yyyymm')
);
