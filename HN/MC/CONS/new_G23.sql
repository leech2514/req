-- ============================================================================
-- 脚本名称: ads_hain_g23_detail.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G23 担保业务明细月度增量报送（按上月放款数据，row_hash 比对仅追加新增/变动记录）
-- 源表:     prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--           prod_dw_01.ods_cons_td_loan_incr_delta
--           prod_dw_01.dim_base_indiv_info_incr_t
--           hain_effective_data_interval
-- 目标表:   ads_hain_g23_detail
-- 写入模式: INSERT INTO TABLE（追加写入，保留历史数据，不覆盖）
-- 增量方式: incr（基于 row_hash 行指纹比对，仅挑新增/修改记录追加写入）
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- 修订记录:
--   2026-08-25  <name>  新建脚本  -  新建脚本，原 DMS G23.sql 迁移至 MaxCompute
--   2026-08-26  <name>  修改      -  INSERT INTO 字段补中文注释（读自 G23_DDL.sql）；改为 PARTITION(pt) 动态分区；pt=TO_CHAR(ddate,'yyyymm')
-- 迁移说明（原 G23.sql → MC）:
--   1. 源表按《表名映射关系.md》替换：
--        prd_spark_db.dwd_cons_loan_payment_info_d → prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--        prd_spark_db.ods_cons_td_loan             → prod_dw_01.ods_cons_td_loan_incr_delta
--        prd_spark_db.dim_base_indiv_info          → prod_dw_01.dim_base_indiv_info_incr_t
--        test_zxbs_db.hain_effective_data_interval → hain_effective_data_interval（跨 project 需补 schema 前缀）
--   2. CURDATE() → GETDATE()（MC 不支持 CURDATE）
--   3. DATE_SUB(CURDATE(), INTERVAL 1 MONTH) → DATEADD(GETDATE(), -1, 'mm')
--   4. DATE_ADD(l.loan_day, INTERVAL 1 YEAR) → DATEADD(l.loan_day, 1, 'yyyy')
--   5. DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01') → CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')（MC 日期格式串用小写）
--   6. CAST(... AS CHAR) → CAST(... AS STRING)（MC 无 CHAR，统一 STRING）
--   7. last_day(s.loan_day) → CAST(LAST_DAY(s.loan_day) AS STRING)（对齐目标 ddate STRING 类型）
--   8. 保留 INSERT INTO 增量写入语义（原脚本已用 row_hash 比对仅插入新增/变动行）
--   9. 保留 CTE + UNION ALL 结构，去除反引号，补行内注释
--  10. MD5/CONCAT_WS/COALESCE/NULLIF/ROW_NUMBER 均 MC 原生支持，保持不变
--  11. dwd/ods 增量 delta 表新增 pt <= TO_CHAR(GETDATE(),'yyyymmdd') 过滤，排除未来分区（last_day 字段保留全量历史用于首贷判断）
-- 风险提示:
--   - 目标表为非分区普通表，INSERT INTO 追加写入，历史保留不覆盖；同一 cont_no 修改会产生多条历史记录，由 target_data 的 ROW_NUMBER 取最新一条比对
--   - pt 比较的 GETDATE() 为运行时函数，MC 无法在编译期做分区裁剪，全表扫描，建议改用调度参数 ${bizdate}/${bizmonth}
--   - dim_base_indiv_info_incr_t 若为每日全量快照分区表，未加 pt 过滤会返回多日快照导致客户重复，建议补 pt = 最新快照条件（_incr_t 语义待确认）
--   - hain_effective_data_interval 跨 project（prod_bs_dw），若不在当前 project 需补 schema 前缀
--   - loan_day 应为 STRING（yyyy-MM-dd），若为 DATE 需 CAST 为 STRING 再比较；cap_rate/total_term 类型需与目标表 DDL 对齐
--   - LAST_DAY/DATEADD 为 MC 2.0 扩展函数，若项目未开启 2.0 数据类型需补 SET odps.sql.type.system.odps2=true;
-- ============================================================================
-- DataWorks 调度参数配置：
--   bizdate=$bizdate        -- yyyymmdd 业务日期（T-1）
--   bizmonth=$bizmonth      -- yyyymm 业务月（上月）

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
-- ==========================================
-- first_loan:    取每个客户最早放款日（判断是否首贷），需全量历史，不可限制 pt 到上月
-- source_data:   关联客户主档 + 有效数据区间，组装报送字段并计算 row_hash 行指纹
-- target_data:   取目标表每个 cont_no 最新一条记录，重算 row_hash 供比对
-- 最终 LEFT JOIN 挑出新增/变动记录，并限定上月放款数据
-- ==========================================
WITH first_loan AS (
    -- 取每个客户最早的放款日，用于判断 first_loan_flag（首贷标识）
    SELECT indiv_cust_id, MIN(loan_day) AS first_loan_day
    FROM (
        -- /*---------------- 消金 ----------------------*/
        SELECT indiv_cust_id, loan_day
        FROM prod_dw_01.dwd_cons_loan_payment_info_incr_delta
        WHERE product_no IN (
              'ZTDFSRL_CYCFC_FL_2'
            , 'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
            , 'ZT-360-ZA00-2507'
            , 'JTTD-ZT-HC-ZYXJ'
            , 'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
            , 'ZTQSZT-QS-CY102507'
            , 'ZTKNchangyin_zhengtang'
            , 'ZT-360-ZA01-2508'
            , 'DXM'
        )
          -- 仅排除未来分区，保留全部历史用于首贷判断
          AND pt <= TO_CHAR(GETDATE(), 'yyyymmdd')

        UNION ALL

        -- /*---------------- 消金简版（通道消金） ----------------------*/
        SELECT CAST(di.indiv_cust_id AS STRING) AS indiv_cust_id, tl.loan_date AS loan_day
        FROM prod_dw_01.ods_cons_td_loan_incr_delta tl
        JOIN prod_dw_01.dim_base_indiv_info_incr_t di ON tl.id_no = di.id_card
        WHERE tl.product_no IN (
              'ZTDFSRL_CYCFC_FL_2'
            , 'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk'
            , 'ZT-360-ZA00-2507'
            , 'JTTD-ZT-HC-ZYXJ'
            , 'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509'
            , 'ZTQSZT-QS-CY102507'
            , 'ZTKNchangyin_zhengtang'
            , 'ZT-360-ZA01-2508'
            , 'DXM'
        ) 

    )
    GROUP BY indiv_cust_id
)

-- 源数据计算 row_hash
,source_data AS (
    SELECT
        l.bill_app_no AS cont_no,
        e.project_name,
        l.loan_day,
        i.indiv_cust_id AS cust_id,
        i.name AS cust_name,
        'A0101' AS guar_type,
        'A' AS biz_mode,                       -- 业务开展方式
        l.loan_amt AS guar_amt,
        l.loan_day AS guar_start,
        -- 担保结束日期：有到期日取到期日，无到期日则放款日 +1 年
        CASE
            WHEN l.due_date IS NOT NULL THEN l.due_date
            ELSE DATEADD(TO_DATE(l.loan_day, 'yyyy-mm-dd'), 1, 'yyyy')
        END AS guar_end,
        -- 首贷标识：放款日等于该客户最早放款日即为首贷
        CASE WHEN l.loan_day = f.first_loan_day THEN 'Y' ELSE 'N' END AS first_loan_flag,
        -- 以后更新需要按最新状态报送，先全部按否
        'N' AS od_flag,
        l.total_term,
        e.cap_rate,

        -- MD5 行哈希（行级指纹，用于和目标表历史数据比对差异）
        MD5(CONCAT_WS('|',
            COALESCE(l.bill_app_no, ''),
            COALESCE(i.indiv_cust_id, ''),
            COALESCE(i.name, ''),
            COALESCE(CAST(l.loan_amt AS STRING), '0.00'),
            COALESCE(CAST(l.loan_day AS STRING), ''),
            COALESCE(CAST(l.due_date AS STRING), ''),
            CASE WHEN l.loan_day = f.first_loan_day THEN '1' ELSE '0' END,
            CASE WHEN l.loan_status = 'OD' THEN 'Y' ELSE 'N' END
        )) AS row_hash
    FROM (
        -- /*---------------- 消金 ----------------------*/
        SELECT
            bill_app_no, loan_day, loan_amt, due_date, loan_status,
            indiv_cust_id, product_no, total_term
        FROM prod_dw_01.dwd_cons_loan_payment_info_incr_delta
        WHERE pt <= TO_CHAR(GETDATE(), 'yyyymmdd')   -- 排除未来分区

        UNION ALL

        -- /*---------------- 消金简版（通道消金） ----------------------*/
        SELECT
            tl.loan_no AS bill_app_no,
            tl.loan_date AS loan_day,
            tl.loan_amt,
            tl.end_date AS due_date,
            tl.status AS loan_status,
            CAST(di.indiv_cust_id AS STRING) AS indiv_cust_id,
            tl.product_no,
            -- 通道消金 total_term 可能为 0，统一兜底为 12
            CASE WHEN tl.loan_term = 0 THEN 12 ELSE tl.loan_term END AS total_term
        FROM prod_dw_01.ods_cons_td_loan_incr_delta tl
        JOIN prod_dw_01.dim_base_indiv_info_incr_t di ON tl.id_no = di.id_card

    ) l

    JOIN prod_dw_01.dim_base_indiv_info_incr_t i
      ON l.indiv_cust_id = i.indiv_cust_id
    LEFT JOIN first_loan f
      ON l.indiv_cust_id = f.indiv_cust_id
    JOIN hain_effective_data_interval e
      ON l.product_no = e.project_code
     AND l.loan_day BETWEEN e.start_date AND e.end_date
    WHERE
        e.is_use = 'Y'
),

-- 目标表当期报表数据 MD5
target_data AS (
    -- 取目标表每个 cont_no 最新一条记录（ROW_NUMBER 去重），重算 row_hash 供与源数据比对
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
        , create_time
        , update_time
    FROM (
        SELECT
            cont_no, cust_id, cust_name, guar_amt, guar_start, guar_end,
            first_loan_flag, od_flag, create_time, update_time,
            -- 按 cont_no 取最新 update_time 的一条
            ROW_NUMBER() OVER (PARTITION BY cont_no ORDER BY update_time DESC) AS rn
        FROM ads_hain_g23_detail
    ) t
    WHERE rn = 1
)
SELECT
    -- 以下每列按目标表 G23_DDL.sql 声明类型逐一 CAST
    CAST('DEFAULT_BANK' AS STRING)                                                       AS dbank_id,       -- 机构代码 varchar(100)
    CAST(LAST_DAY(s.loan_day) AS DATE)                                                   AS ddate,          -- 报表日期 date
    CAST(s.cont_no AS STRING)                                                            AS cont_no,        -- 合同编号 varchar(100)
    CAST(s.cont_no AS STRING)                                                            AS biz_no,         -- 业务编号 varchar(100)
    CAST(s.project_name AS STRING)                                                       AS project_name,   -- 项目名称 varchar(64)
    CAST(s.cust_id AS STRING)                                                            AS cust_id,        -- 客户编号 varchar(100)
    CAST(s.cust_name AS STRING)                                                          AS cust_name,      -- 客户名称 varchar(100)
    CAST(s.guar_type AS STRING)                                                          AS guar_type,      -- 担保类型 varchar(100)
    CAST(s.biz_mode AS STRING)                                                           AS biz_mode,       -- 业务开展方式 varchar(100)
    CAST(s.guar_amt AS DECIMAL(20,2))                                                    AS guar_amt,       -- 担保金额 decimal(20,2)
    CAST(NULL AS DECIMAL(20,6))                                                          AS loan_rate,      -- 贷款/债券发行利率 decimal(20,6)
    -- 担保费率：cap_rate 为空时取默认 0.2，否则按 (24 - cap_rate)/1.82/12*total_term 计算
    CAST(
        CASE WHEN s.cap_rate IS NULL THEN '0.2'
             ELSE ((24 - s.cap_rate) / 1.82 / 12) * s.total_term
        END AS DECIMAL(20,6)
    )                                                                                    AS guar_rate,      -- 担保费率 decimal(20,6)
    CAST(s.guar_start AS DATE)                                                           AS guar_start,     -- 担保起始日期 date
    CAST(s.guar_end AS DATE)                                                             AS guar_end,       -- 担保到期日期 date
    CAST('何书诺17689893638' AS STRING)                                                  AS mgr_contact,    -- 项目经理及联系方式 varchar(100)
    CAST('N' AS STRING)                                                                  AS policy_flag,    -- 是否政策性担保业务 varchar(10)
    CAST('N' AS STRING)                                                                  AS strategic_flag, -- 是否战略新兴产业 varchar(10)
    CAST(s.first_loan_flag AS STRING)                                                    AS first_loan_flag,-- 是否首贷户 varchar(10)
    CAST(NULL AS STRING)                                                                 AS fin_inst_code,  -- 金融机构编码 varchar(100)
    CAST(NULL AS STRING)                                                                 AS fin_inst_name,  -- 金融机构名称 varchar(100)
    CAST(NULL AS STRING)                                                                 AS cust_mgr,       -- 经办客户经理 varchar(100)
    CAST(NULL AS STRING)                                                                 AS cust_mgr_tel,   -- 客户经理联系方式 varchar(100)
    CAST(NULL AS STRING)                                                                 AS orig_guar_inst, -- 原担保机构 varchar(100)
    CAST(NULL AS DECIMAL(20,2))                                                          AS orig_guar_amt,  -- 原担保金额 decimal(20,2)
    CAST(NULL AS DECIMAL(20,6))                                                          AS orig_guar_rate, -- 原担保费率 decimal(20,6)
    CAST(s.od_flag AS STRING)                                                            AS od_flag,        -- 是否逾期 varchar(10)
    CAST(NULL AS DECIMAL(20,2))                                                          AS uncomp_amt,     -- 尚未履行代偿责任金额 decimal(20,2)
    CAST(NULL AS DECIMAL(20,2))                                                          AS loss_amt,       -- 损失金额 decimal(20,2)
    CAST(NULL AS STRING)                                                                 AS five_class,     -- 五级分类 varchar(100)
    CAST(NULL AS STRING)                                                                 AS counter_type,   -- 反担保方式 varchar(100)
    CAST(NULL AS STRING)                                                                 AS counter_code,   -- 反担保人编码 varchar(100)
    CAST(NULL AS STRING)                                                                 AS counter_name,   -- 反担保人名称 varchar(100)
    CAST(NULL AS DECIMAL(20,2))                                                          AS counter_amt,    -- 反担保金额 decimal(20,2)
    CAST('Y' AS STRING)                                                                  AS rely_net_flag,  -- 是否依托互联网开展融资担保业务 varchar(10)
    -- ========= 动态分区列 pt 必须是 SELECT 列表最后一列 =========
    -- 按 ddate（上月末）的月份取 yyyymm，与新G23_DDL "按ddate的月份分区"一致
    CAST(TO_CHAR(CAST(LAST_DAY(s.loan_day) AS DATE), 'yyyymm') AS STRING)                AS pt
FROM source_data s
LEFT JOIN target_data t
  ON s.cont_no = t.cont_no
  AND s.row_hash = t.row_hash    -- row_hash 一致说明记录未变
WHERE t.cont_no IS NULL          -- 仅插入新增或变动的行
  -- 限定上月 1 号到上月末的放款数据
  AND s.loan_day BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND
        LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;
