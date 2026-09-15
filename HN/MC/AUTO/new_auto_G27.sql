-- ============================================================================
-- 脚本名称: new_auto_G27.sql
-- 层级:     ADS
-- 业务域:   海南正堂/车贷担保报送
-- 功能描述: 车贷 G27 代偿明细月度报送（仅浙融 ZT-ZR、龙正 ZT-LZ；龙环汇丰不报代偿）
-- 源表:     rd_cfund.zf_rent_plan_info（还款计划信息，金额单位：分，repay_type=4 为代偿）
--           hain_effective_data_interval（海南有效数据区间配置表，prod_bs_dw，映射 004）
-- 目标表:   ads_hain_g27_comp_detail（Delta 事务主键分区表，主键 (comp_seq,cont_no)，分区 pt=yyyymm，映射 010）
-- 写入模式: INSERT INTO 动态分区（按月追加）
-- 调度周期: 月度（每月初跑上月数据，代偿日期 accept_date 取上月 1 号至上月末）
-- 负责人:   <name>
-- 创建日期: 2026-09-14
-- ============================================================================

SET odps.sql.reshuffle.dynamicpt = true;

INSERT INTO TABLE ads_hain_g27_comp_detail PARTITION(pt)
(
    dbank_id, ddate, xh, cont_no, biz_no, project_name,
    comp_type, comp_seq, comp_date, comp_amt, comp_int, pt
)
SELECT
    ROW_NUMBER() OVER (ORDER BY t.comp_date, t.comp_seq)  AS xh,          -- 序号
    t.dbank_id,
    t.ddate,
    t.cont_no,
    t.biz_no,
    t.project_name,
    t.comp_type,
    t.comp_seq,
    t.comp_date,
    t.comp_amt,
    t.comp_int,
    TO_CHAR(t.ddate, 'yyyymm')                            AS pt           -- 报表月份分区
FROM (
    SELECT
        'DEFAULT_BANK'                                        AS dbank_id,
        CAST(LAST_DAY(TO_DATE(r.accept_date, 'yyyy-mm-dd')) AS DATE) AS ddate,  -- 报表日期：代偿月月末
        r.rent_plan_code                                     AS cont_no,   -- 合同编号
        r.rent_plan_code                                     AS biz_no,    -- 业务编号
        fb.project_name                                      AS project_name,
        'A'                                                  AS comp_type, -- 代偿机构类型
        r.fund_code                                          AS comp_seq,  -- 代偿序号
        TO_DATE(r.accept_date, 'yyyy-mm-dd')                 AS comp_date, -- 代偿日期
        CAST(r.repaid_principal / 100 AS DECIMAL(20,2))      AS comp_amt,  -- 本次代偿金额（分→元）
        CAST(r.repaid_interest / 100 AS DECIMAL(20,2))       AS comp_int   -- 本次代偿利息（分→元）
    FROM rd_cfund.zf_rent_plan_info r
    INNER JOIN (
        -- 有效数据区间内的（产品, 借据, 项目）去重清单
        SELECT
            l.capital_product_code AS product_no,
            l.rent_plan_code,
            i.project_name
        FROM rd_cfund.zf_rent_plan_info l
        JOIN hain_effective_data_interval i
          ON l.capital_product_code = i.project_code
         AND TO_DATE(l.accept_date, 'yyyy-mm-dd') BETWEEN i.start_date AND i.end_date
        WHERE i.is_use = 'Y'
        GROUP BY
            l.capital_product_code,
            l.rent_plan_code,
            i.project_name
    ) fb
      ON r.rent_plan_code = fb.rent_plan_code
    WHERE
      -- 龙环汇丰 ZT-LH-SS10-2512 不报代偿数据
      fb.product_no IN ('ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
      AND r.repay_type = '4'
      -- 代偿时间：上月 1 号至上月末
      AND r.accept_date BETWEEN
            CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
            AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
) t
;
