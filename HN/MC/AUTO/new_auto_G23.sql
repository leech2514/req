-- ============================================================================
-- 脚本名称: new_auto_G23.sql
-- 层级:     ADS
-- 业务域:   海南正堂/车贷担保报送
-- 功能描述: 车贷 G23 担保业务明细月度增量报送（按上月放款数据，row_hash 比对仅追加新增/变动记录）
-- 源表:     prod_dw_01.dwd_auto_oapi_loan_incr_delta（车贷放款信息表，映射 005，pt=yyyymm 月分区）
--           prod_dw_01.dim_base_indiv_info_incr_t（个人客户主档，映射 003）
--           hain_effective_data_interval（海南有效数据区间配置表，prod_bs_dw，映射 004）
-- 目标表:   ads_hain_g23_detail（Delta 事务主键分区表，主键 cont_no，分区 pt=yyyymm，映射 007）
-- 写入模式: INSERT INTO 动态分区（追加写入，仅新增/变动记录）+ 月末专项 UPDATE 调整担保费率
-- 调度周期: 月度（每月初跑上月数据，放款时间取上月 1 号至上月末）
-- 负责人:   <name>
-- 创建日期: 2026-09-14
-- ============================================================================

SET odps.sql.reshuffle.dynamicpt = true;

INSERT INTO TABLE ads_hain_g23_detail PARTITION(pt)
(
    dbank_id,        -- 机构代码
    ddate,           -- 报表日期
    cont_no,         -- 合同编号
    biz_no,          -- 业务编号
    project_name,    -- 项目名称
    cust_id,         -- 客户编号
    cust_name,       -- 客户名称
    guar_type,       -- 担保类型
    biz_mode,        -- 业务开展方式
    guar_amt,        -- 担保金额
    loan_rate,       -- 贷款/债券发行利率
    guar_rate,       -- 担保费率
    guar_start,      -- 担保起始日期
    guar_end,        -- 担保到期日期
    mgr_contact,     -- 项目经理及联系方式
    policy_flag,     -- 是否政策性担保业务
    strategic_flag,  -- 是否战略新兴产业
    first_loan_flag, -- 是否首贷户
    fin_inst_code,   -- 金融机构编码
    fin_inst_name,   -- 金融机构名称
    cust_mgr,        -- 经办客户经理
    cust_mgr_tel,    -- 客户经理联系方式
    orig_guar_inst,  -- 原担保机构
    orig_guar_amt,   -- 原担保金额
    orig_guar_rate,  -- 原担保费率
    od_flag,         -- 是否逾期
    uncomp_amt,      -- 尚未履行代偿责任金额
    loss_amt,        -- 损失金额
    five_class,      -- 五级分类
    counter_type,    -- 反担保方式
    counter_code,    -- 反担保人编码
    counter_name,    -- 反担保人名称
    counter_amt,     -- 反担保金额
    rely_net_flag,   -- 是否依托互联网开展融资担保业务
    pt               -- 报表月份 yyyymm（动态分区列，按 ddate 所在月份取值）
)
WITH first_loan AS (
    -- 取每个身份证最早放款日（首贷判断），保留全量历史，仅排除未来月分区
    SELECT id_card, MIN(loan_day) AS first_loan_day
    FROM prod_dw_01.dwd_auto_oapi_loan_incr_delta
    WHERE product_no IN ('ZT-LH-SS10-2512', 'ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
      AND pt <= TO_CHAR(GETDATE(), 'yyyymm')
    GROUP BY id_card
)
, source_data AS (
    -- 关联客户主档与有效数据区间，组装 G23 报送字段并计算 row_hash 行指纹
    SELECT
        l.bill_app_no AS cont_no,
        e.project_name,
        l.loan_day,
        CAST(i.indiv_cust_id AS STRING) AS cust_id,
        i.name AS cust_name,
        'A0101' AS guar_type,
        'A' AS biz_mode,                                       -- 业务开展方式
        l.loan_amt AS guar_amt,
        l.loan_day AS guar_start,
        -- 担保结束日期：有到期日取到期日，无到期日则放款日 +1 年
        CASE
            WHEN l.due_date IS NOT NULL THEN l.due_date
            ELSE CAST(DATEADD(TO_DATE(l.loan_day, 'yyyy-mm-dd'), 1, 'yyyy') AS STRING)
        END AS guar_end,
        CASE WHEN l.loan_day = f.first_loan_day THEN 'Y' ELSE 'N' END AS first_loan_flag,
        -- 逾期标识先全部按否报送，后续按最新状态更新
        'N' AS od_flag,
        l.total_term,
        e.cap_rate,

        -- MD5 行指纹
        MD5(CONCAT_WS('|',
            COALESCE(l.bill_app_no, ''),
            COALESCE(CAST(i.indiv_cust_id AS STRING), ''),
            COALESCE(i.name, ''),
            COALESCE(CAST(l.loan_amt AS STRING), '0.00'),
            COALESCE(CAST(l.loan_day AS STRING), ''),
            COALESCE(CAST(l.due_date AS STRING), ''),
            CASE WHEN l.loan_day = f.first_loan_day THEN '1' ELSE '0' END,
            CASE WHEN l.loan_status = 'OD' THEN 'Y' ELSE 'N' END
        )) AS row_hash
    FROM (
        -- 上月放款车贷借据
        SELECT
            bill_app_no, loan_day, loan_amt, date_due AS due_date,
            loan_status, id_card, product_no, total_term
        FROM prod_dw_01.dwd_auto_oapi_loan_incr_delta
        WHERE product_no IN ('ZT-LH-SS10-2512', 'ZT-ZR-GY-10-2512', 'ZT-LZ-ZY10-2608')
          AND loan_day BETWEEN
                CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
                AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
          AND pt = TO_CHAR(DATEADD(GETDATE(), -1, 'mm'), 'yyyymm')
    ) l
    JOIN prod_dw_01.dim_base_indiv_info_incr_t i
      ON l.id_card = i.id_card
    LEFT JOIN first_loan f
      ON l.id_card = f.id_card
    JOIN hain_effective_data_interval e
      ON l.product_no = e.project_code
     AND l.loan_day BETWEEN e.start_date AND e.end_date
    WHERE e.is_use = 'Y'
)
, target_data AS (
    -- 目标表按 cont_no 取最新一条记录重算 row_hash
    SELECT
        cont_no,
        MD5(CONCAT_WS('|',
            COALESCE(t.cont_no, ''),
            COALESCE(t.cust_id, ''),
            COALESCE(t.cust_name, ''),
            COALESCE(CAST(t.guar_amt AS STRING), '0.00'),
            COALESCE(CAST(t.guar_start AS STRING), ''),
            COALESCE(CAST(t.guar_end AS STRING), ''),
            first_loan_flag,
            od_flag
        )) AS row_hash
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cont_no ORDER BY update_time DESC) AS rn
        FROM ads_hain_g23_detail
    ) t
    WHERE rn = 1
)
SELECT
    CAST('DEFAULT_BANK' AS STRING)                                                       AS dbank_id,
    CAST(LAST_DAY(s.loan_day) AS DATE)                                                   AS ddate,
    CAST(s.cont_no AS STRING)                                                            AS cont_no,
    CAST(s.cont_no AS STRING)                                                            AS biz_no,
    CAST(s.project_name AS STRING)                                                       AS project_name,
    CAST(s.cust_id AS STRING)                                                            AS cust_id,
    CAST(s.cust_name AS STRING)                                                          AS cust_name,
    CAST(s.guar_type AS STRING)                                                          AS guar_type,
    CAST(s.biz_mode AS STRING)                                                           AS biz_mode,
    CAST(s.guar_amt AS DECIMAL(20,2))                                                    AS guar_amt,
    CAST(NULL AS DECIMAL(20,6))                                                          AS loan_rate,
    -- 担保费率：cap_rate 为空取默认 0.2，否则按 (24-cap_rate)/1.82/12*总期数 计算
    CAST(
        CASE WHEN s.cap_rate IS NULL THEN 0.2
             ELSE ((24 - s.cap_rate) / 1.82 / 12) * s.total_term
        END AS DECIMAL(20,6)
    )                                                                                    AS guar_rate,
    CAST(s.guar_start AS DATE)                                                           AS guar_start,
    CAST(s.guar_end AS DATE)                                                             AS guar_end,
    CAST('何书诺17689893638' AS STRING)                                                  AS mgr_contact,
    CAST('N' AS STRING)                                                                  AS policy_flag,
    CAST('N' AS STRING)                                                                  AS strategic_flag,
    CAST(s.first_loan_flag AS STRING)                                                    AS first_loan_flag,
    CAST(NULL AS STRING)                                                                 AS fin_inst_code,
    CAST(NULL AS STRING)                                                                 AS fin_inst_name,
    CAST(NULL AS STRING)                                                                 AS cust_mgr,
    CAST(NULL AS STRING)                                                                 AS cust_mgr_tel,
    CAST(NULL AS STRING)                                                                 AS orig_guar_inst,
    CAST(NULL AS DECIMAL(20,2))                                                          AS orig_guar_amt,
    CAST(NULL AS DECIMAL(20,6))                                                          AS orig_guar_rate,
    CAST(s.od_flag AS STRING)                                                            AS od_flag,
    CAST(NULL AS DECIMAL(20,2))                                                          AS uncomp_amt,
    CAST(NULL AS DECIMAL(20,2))                                                          AS loss_amt,
    CAST(NULL AS STRING)                                                                 AS five_class,
    CAST(NULL AS STRING)                                                                 AS counter_type,
    CAST(NULL AS STRING)                                                                 AS counter_code,
    CAST(NULL AS STRING)                                                                 AS counter_name,
    CAST(NULL AS DECIMAL(20,2))                                                          AS counter_amt,
    CAST('Y' AS STRING)                                                                  AS rely_net_flag,
    CAST(TO_CHAR(CAST(LAST_DAY(s.loan_day) AS DATE), 'yyyymm') AS STRING)                AS pt
FROM source_data s
LEFT JOIN target_data t
  ON s.cont_no = t.cont_no
 AND s.row_hash = t.row_hash    -- row_hash 一致说明记录未变
WHERE t.cont_no IS NULL         -- 仅插入新增或变动的行
;

-- 专项调整：龙环汇丰-苏商银行项目担保费率固定 0.003（限当月分区，避免全表扫描）
UPDATE ads_hain_g23_detail
SET guar_rate = CAST(0.003 AS DECIMAL(20,6))
WHERE project_name = '海南正堂-龙环汇丰-苏商银行'
  AND pt = TO_CHAR(DATEADD(GETDATE(), -1, 'mm'), 'yyyymm')
;
