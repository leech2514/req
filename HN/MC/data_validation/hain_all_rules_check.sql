-- ============================================================
-- 海南监管报表数据校验脚本（MaxCompute 适配版）
-- 包含 RULE_01 ~ RULE_06 共 6 类校验规则
--   RULE_01：客户编号无对应客户信息
--   RULE_02：机构自身风险承担比例异常（<0 或 >1）
--   RULE_03：已结清但累计解保+代偿 > 担保金额
--   RULE_04：已结清但累计解保+代偿 < 担保金额
--   RULE_05：未结清但累计解保+代偿 = 担保金额（历史遗留，无结清标识）
--   RULE_06：未结清但累计解保+代偿 > 担保金额
--   RULE_05（子表）：G23_1/G23_2/G27/G28 合同号在 G23 不存在
-- 适配说明：
--   1. 所有表加分区过滤 pt <= TO_CHAR(GETDATE(), 'yyyymm')，启用分区裁剪
--   2. 去掉反引号
--   3. COALESCE MaxCompute 原生支持，保留不改
--   4. 注释统一用 --，规避 DataWorks 对 /* */ 块注释的解析坑
-- ============================================================


-- =====================================================
-- RULE_01：客户编号无对应客户信息
-- =====================================================
SELECT
    'RULE_01'              AS rule_code,
    '客户编号无对应客户信息' AS rule_desc,
    g23.cont_no,
    g23.biz_no,
    g23.cust_id,
    g23.ddate
FROM ads_hain_g23_detail g23
LEFT JOIN ads_hain_g11_cust_info g11
    ON g23.cust_id = g11.cust_id
WHERE g23.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND g11.cust_id IS NULL;


-- =====================================================
-- RULE_02：机构自身风险承担比例异常
-- =====================================================
SELECT
    'RULE_02'                  AS rule_code,
    '机构自身风险承担比例异常'   AS rule_desc,
    cont_no,
    biz_no,
    org_ratio,
    ddate
FROM ads_hain_g23_1_risk_share
WHERE pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND (org_ratio < 0 OR org_ratio > 1);


-- =====================================================
-- 公共 CTE：解保汇总 / 代偿汇总（供 RULE_03~06 复用）
-- 说明：MaxCompute 每条语句独立，CTE 不跨语句复用，
--       为减少重复代码，RULE_03~06 用 UNION ALL 合集输出，单条语句完成。
-- =====================================================
WITH relieve_sum AS (
    SELECT
        cont_no,
        biz_no,
        SUM(COALESCE(recv_amt, 0)) AS total_relieve_amt,
        MAX(settle_flag)           AS settle_flag
    FROM ads_hain_g23_2_relieve_detail
    WHERE pt <= TO_CHAR(GETDATE(), 'yyyymm')
    GROUP BY cont_no, biz_no
),
comp_sum AS (
    SELECT
        cont_no,
        biz_no,
        SUM(COALESCE(comp_amt, 0)) AS total_comp_amt
    FROM ads_hain_g27_comp_detail
    GROUP BY cont_no, biz_no
)

-- RULE_03：已结清但累计解保+代偿 > 担保金额
SELECT
    'RULE_03'                          AS rule_code,
    '已结清但累计解保+代偿大于担保金额'   AS rule_desc,
    g23.cont_no,
    g23.biz_no,
    g23.guar_amt,
    COALESCE(r.total_relieve_amt, 0) AS total_relieve_amt,
    COALESCE(c.total_comp_amt, 0)    AS total_comp_amt,
    rd.settle_flag
FROM ads_hain_g23_detail g23
JOIN ads_hain_g23_2_relieve_detail rd
    ON g23.cont_no = rd.cont_no
LEFT JOIN relieve_sum r
    ON g23.cont_no = r.cont_no
   AND g23.biz_no = r.biz_no
LEFT JOIN comp_sum c
    ON g23.cont_no = c.cont_no
   AND g23.biz_no = c.biz_no
WHERE g23.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND rd.settle_flag = 'Y'
  AND (COALESCE(r.total_relieve_amt,0) + COALESCE(c.total_comp_amt,0)) > g23.guar_amt

UNION ALL

-- RULE_04：已结清但累计解保+代偿 < 担保金额
SELECT
    'RULE_04'                          AS rule_code,
    '已结清但累计解保+代偿小于担保金额'   AS rule_desc,
    g23.cont_no,
    g23.biz_no,
    g23.guar_amt,
    COALESCE(r.total_relieve_amt, 0) AS total_relieve_amt,
    COALESCE(c.total_comp_amt, 0)    AS total_comp_amt,
    rd.settle_flag
FROM ads_hain_g23_detail g23
JOIN ads_hain_g23_2_relieve_detail rd
    ON g23.cont_no = rd.cont_no
LEFT JOIN relieve_sum r
    ON g23.cont_no = r.cont_no
   AND g23.biz_no = r.biz_no
LEFT JOIN comp_sum c
    ON g23.cont_no = c.cont_no
   AND g23.biz_no = c.biz_no
WHERE g23.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND rd.settle_flag = 'Y'
  AND (COALESCE(r.total_relieve_amt,0) + COALESCE(c.total_comp_amt,0)) < g23.guar_amt

UNION ALL

-- RULE_05：未结清但累计解保+代偿 = 担保金额（历史遗留无结清标识）
SELECT
    'RULE_05'                                       AS rule_code,
    '未结清但累计解保+代偿等于担保金额（历史遗留无结清标识）' AS rule_desc,
    g23.cont_no,
    g23.biz_no,
    g23.guar_amt,
    COALESCE(r.total_relieve_amt, 0) AS total_relieve_amt,
    COALESCE(c.total_comp_amt, 0)    AS total_comp_amt,
    r.settle_flag
FROM ads_hain_g23_detail g23
JOIN ads_hain_g23_2_relieve_detail rd
    ON g23.cont_no = rd.cont_no
LEFT JOIN relieve_sum r
    ON g23.cont_no = r.cont_no
   AND g23.biz_no = r.biz_no
LEFT JOIN comp_sum c
    ON g23.cont_no = c.cont_no
   AND g23.biz_no = c.biz_no
WHERE g23.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND r.settle_flag = 'N'
  AND (COALESCE(r.total_relieve_amt,0) + COALESCE(c.total_comp_amt,0)) = g23.guar_amt
  AND (c.total_comp_amt = 0 OR c.total_comp_amt IS NULL)

UNION ALL

-- RULE_06：未结清但累计解保+代偿 > 担保金额
SELECT
    'RULE_06'                          AS rule_code,
    '未结清但累计解保+代偿大于担保金额'   AS rule_desc,
    g23.cont_no,
    g23.biz_no,
    g23.guar_amt,
    COALESCE(r.total_relieve_amt, 0) AS total_relieve_amt,
    COALESCE(c.total_comp_amt, 0)    AS total_comp_amt,
    rd.settle_flag
FROM ads_hain_g23_detail g23
JOIN ads_hain_g23_2_relieve_detail rd
    ON g23.cont_no = rd.cont_no
LEFT JOIN relieve_sum r
    ON g23.cont_no = r.cont_no
   AND g23.biz_no = r.biz_no
LEFT JOIN comp_sum c
    ON g23.cont_no = c.cont_no
   AND g23.biz_no = c.biz_no
WHERE g23.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND rd.settle_flag = 'N'
  AND (COALESCE(r.total_relieve_amt,0) + COALESCE(c.total_comp_amt,0)) > g23.guar_amt;


-- =====================================================
-- RULE_05：子表合同号必须在 G23 存在
-- =====================================================

-- G23_1 校验
SELECT
    'RULE05'                    AS rule_code,
    'G23_1合同号在G23不存在'      AS rule_desc,
    t.cont_no,
    'ads_hain_g23_1_risk_share' AS source_table
FROM ads_hain_g23_1_risk_share t
LEFT JOIN ads_hain_g23_detail g
    ON t.cont_no = g.cont_no
WHERE t.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND g.cont_no IS NULL

UNION ALL

-- G23_2 校验
SELECT
    'RULE05'                          AS rule_code,
    'G23_2合同号在G23不存在'            AS rule_desc,
    t.cont_no,
    'ads_hain_g23_2_relieve_detail'   AS source_table
FROM ads_hain_g23_2_relieve_detail t
LEFT JOIN ads_hain_g23_detail g
    ON t.cont_no = g.cont_no
WHERE t.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND g.cont_no IS NULL

UNION ALL

-- G27 校验
SELECT
    'RULE05'                      AS rule_code,
    'G27合同号在G23不存在'           AS rule_desc,
    t.cont_no,
    'ads_hain_g27_comp_detail'    AS source_table
FROM ads_hain_g27_comp_detail t
LEFT JOIN ads_hain_g23_detail g
    ON t.cont_no = g.cont_no
WHERE t.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND g.cont_no IS NULL

UNION ALL

-- G28 校验
SELECT
    'RULE05'                          AS rule_code,
    'G28合同号在G23不存在'              AS rule_desc,
    t.cont_no,
    'ads_hain_g28_recover_detail'     AS source_table
FROM ads_hain_g28_recover_detail t
LEFT JOIN ads_hain_g23_detail g
    ON t.cont_no = g.cont_no
WHERE t.pt <= TO_CHAR(GETDATE(), 'yyyymm')
  AND g.cont_no IS NULL;
