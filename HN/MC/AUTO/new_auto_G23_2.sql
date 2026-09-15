-- ============================================================================
-- 脚本名称: new_auto_G23_2.sql
-- 层级:     ADS
-- 业务域:   海南正堂/车贷担保报送
-- 功能描述: 车贷 G23_2 担保业务解除（解保）明细月度报送
--           按产品分两段写入：①龙环汇丰 ZT-LH-SS10-2512；②浙融/龙正 ZT-ZR / ZT-LZ
-- 源表:     rd_cfund.zf_rent_plan_info（还款计划信息，金额单位：分）
--           rd_cfund.oapi_loan（借据信息，金额单位：分）
--           hain_effective_data_interval（海南有效数据区间配置表，prod_bs_dw，映射 004）
-- 目标表:   ads_hain_g23_2_relieve_detail（Delta 事务主键分区表，主键 relieve_no，分区 pt=yyyymm，映射 009）
-- 写入模式: INSERT INTO 动态分区（按月追加，共两段）
-- 调度周期: 月度（每月初跑上月数据，解保日期 accept_date 取上月 1 号至上月末）
-- 负责人:   <name>
-- 创建日期: 2026-09-14
-- ============================================================================

SET odps.sql.reshuffle.dynamicpt = true;

-- ============================================================================
-- 第①段：龙环汇丰 ZT-LH-SS10-2512（repay_type <> 5）
-- ============================================================================
INSERT INTO TABLE ads_hain_g23_2_relieve_detail PARTITION(pt)
(
    dbank_id, ddate, xh, relieve_no, cont_no, biz_no, project_name,
    recv_type, recv_date, recv_amt, settle_flag, pt
)
SELECT
    'DEFAULT_BANK'                                                            AS dbank_id,
    CAST(LAST_DAY(a.accept_date) AS DATE)                                     AS ddate,       -- 报表日期：解保月月末
    MD5(CONCAT_WS('|',
        a.fund_code, a.rent_plan_code,
        CAST(a.accept_date AS STRING), CAST(a.period AS STRING)))             AS xh,          -- 序号（替代 uuid()）
    a.fund_code                                                               AS relieve_no,  -- 解保编号
    a.rent_plan_code                                                          AS cont_no,     -- 合同编号
    a.rent_plan_code                                                          AS biz_no,      -- 业务编号
    e.project_name                                                            AS project_name,
    'A'                                                                       AS recv_type,   -- 收回方式
    CAST(a.accept_date AS DATE)                                               AS recv_date,   -- 收回日期
    CAST(a.repaid_principal / 100 AS DECIMAL(20,2))                           AS recv_amt,    -- 收回金额（分→元）
    -- 结清标识：最后一笔还款 且 合同金额-累计非代偿金额=0 才为 Y
    CASE
        WHEN a.rn = 1
         AND (b.loan_amount - a.sum_no_cps_print) = 0
        THEN 'Y'
        ELSE 'N'
    END                                                                       AS settle_flag,
    TO_CHAR(CAST(LAST_DAY(a.accept_date) AS DATE), 'yyyymm')                  AS pt
FROM (
    SELECT
        a.*,
        SUM(CASE WHEN a.repay_type NOT IN (5) THEN a.repaid_principal ELSE 0 END)
            OVER (PARTITION BY a.rent_plan_code
                  ORDER BY a.accept_date, a.period
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS sum_no_cps_print,                                              -- 累计非代偿金额
        ROW_NUMBER() OVER (PARTITION BY a.rent_plan_code
                           ORDER BY a.accept_date DESC, a.period DESC) AS rn  -- 最后一笔还款
    FROM rd_cfund.zf_rent_plan_info a
    WHERE a.capital_product_code IN ('ZT-LH-SS10-2512')
      AND a.repay_type <> 5
) a
JOIN rd_cfund.oapi_loan b
  ON a.rent_plan_code = b.rent_plan_code
JOIN hain_effective_data_interval e
  ON b.capital_product_code = e.project_code
 AND b.reconciliation_date BETWEEN e.start_date AND e.end_date
WHERE e.is_use = 'Y'
  AND a.capital_product_code IN ('ZT-LH-SS10-2512')
  -- 解保时间：上月 1 号至上月末
  AND a.accept_date BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;

-- ============================================================================
-- 第②段：浙融/龙正（内层 ZT-ZR、ZT-LZ，repay_type <> 5；外层 ZT-ZR 且 repay_type <> 4）
-- ============================================================================
INSERT INTO TABLE ads_hain_g23_2_relieve_detail PARTITION(pt)
(
    dbank_id, ddate, xh, relieve_no, cont_no, biz_no, project_name,
    recv_type, recv_date, recv_amt, settle_flag, pt
)
SELECT
    'DEFAULT_BANK'                                                            AS dbank_id,
    CAST(LAST_DAY(a.accept_date) AS DATE)                                     AS ddate,
    MD5(CONCAT_WS('|',
        a.fund_code, a.rent_plan_code,
        CAST(a.accept_date AS STRING), CAST(a.period AS STRING)))             AS xh,
    a.fund_code                                                               AS relieve_no,
    a.rent_plan_code                                                          AS cont_no,
    a.rent_plan_code                                                          AS biz_no,
    e.project_name                                                            AS project_name,
    'A'                                                                       AS recv_type,
    CAST(a.accept_date AS DATE)                                               AS recv_date,
    CAST(a.repaid_principal / 100 AS DECIMAL(20,2))                           AS recv_amt,
    CASE
        WHEN a.rn = 1
         AND (b.loan_amount - a.sum_no_cps_print) = 0
        THEN 'Y'
        ELSE 'N'
    END                                                                       AS settle_flag,
    TO_CHAR(CAST(LAST_DAY(a.accept_date) AS DATE), 'yyyymm')                  AS pt
FROM (
    SELECT
        a.*,
        SUM(CASE WHEN a.repay_type NOT IN (5) THEN a.repaid_principal ELSE 0 END)
            OVER (PARTITION BY a.rent_plan_code
                  ORDER BY a.accept_date, a.period
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            AS sum_no_cps_print,
        ROW_NUMBER() OVER (PARTITION BY a.rent_plan_code
                           ORDER BY a.accept_date DESC, a.period DESC) AS rn
    FROM rd_cfund.zf_rent_plan_info a
    WHERE a.capital_product_code IN ('ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
      AND a.repay_type <> 5
) a
JOIN rd_cfund.oapi_loan b
  ON a.rent_plan_code = b.rent_plan_code
JOIN hain_effective_data_interval e
  ON b.capital_product_code = e.project_code
 AND b.reconciliation_date BETWEEN e.start_date AND e.end_date
WHERE e.is_use = 'Y'
  AND a.capital_product_code IN ('ZT-ZR-GY-10-2512')
  AND a.repay_type <> 4
  -- 解保时间：上月 1 号至上月末
  AND a.accept_date BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;
