-- ============================================================================
-- 脚本名称: ins_G23.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G23 担保业务明细信息月度增量报送
-- 源表:     prod_dw_01.dwd_ins_guarantee_apply_wide_full_t（保函申请宽表）
-- 目标表:   ads_hain_g23_detail
-- 表类型:   Delta 事务主键分区表（transactional=true，支持 ACID）
-- 主键:     cont_no
-- 分区字段: pt (STRING, yyyymm，取自 ddate 报表日期所在月份)
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 写入模式: INSERT INTO（增量插入，动态分区，追加写入不覆盖历史）
-- 负责人:   <name>
-- 创建日期: <待填写>
-- ----------------------------------------------------------------------------
-- 字段映射（按 DDL 字段顺序）:
--   dbank_id        = 'DEFAULT_BANK'（默认银行标识）
--   ddate           = LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))（上月末，DATE 类型）
--   project_name    = project_name（OA项目名称）
--   loan_date       = NULL（DDL 保留字段，待业务接入）
--   cont_no/biz_no  = bill_app_no（保函编号同时作合同编号与业务编号）
--   cust_id         = MD5(applicant_credit_code)（统一社会信用代码的 MD5 哈希，32 位 STRING）
--   cust_name       = applicant_company_name
--   guar_type       = 'B01'（担保类型）
--   biz_mode        = 'Z'（业务开展方式）
--   guar_amt        = CAST(guarantee_amount AS DECIMAL(20,2))（源 DECIMAL(38,18) → 目标 DECIMAL(20,2)）
--   loan_rate       = NULL（贷款/债券发行利率，待业务接入）
--   guar_rate       = CAST(premium/guarantee_amount AS DECIMAL(20,6))（担保费率 = 保费/保函金额）
--   guar_start      = CAST(effective_date AS DATE)（源 STRING → 目标 DATE）
--   guar_end        = CAST(expiry_date AS DATE)（源 STRING → 目标 DATE）
--   mgr_contact     = '何书诺17689893638'（固定项目经理联系方式）
--   policy_flag/strategic_flag/first_loan_flag/od_flag/rely_net_flag = 'N'（默认值）
--   fin_inst_*/cust_mgr*/orig_guar_*/uncomp_amt/loss_amt/five_class/counter_* = NULL（待业务接入）
--   create_time/update_time = CURRENT_TIMESTAMP()（由 DML 显式写入，替代原 DEFAULT/ON UPDATE CURRENT_TIMESTAMP）
--   pt              = TO_CHAR(CAST(LAST_DAY(DATEADD(GETDATE(), -1, 'mm')) AS DATE), 'yyyymm')（动态分区列，SELECT 末尾提供）
-- ----------------------------------------------------------------------------
-- 风险提示:
--   ⚠ Delta 主键分区表 (cont_no, pt) 联合唯一，同月重复执行 INSERT INTO 会违反主键唯一性，
--     需保证每月仅执行一次，或改用 MERGE INTO 幂等重跑（ON 条件需含 t.pt = s.pt 分区谓词）
--   ⚠ 动态分区写入按 DDL 字段顺序位置匹配，SELECT 列顺序必须与 DDL 一致（含 loan_date 占位 NULL）
-- ============================================================================

SET odps.sql.reshuffle.dynamicpt = true;

-- 筛选海南正堂上月增量保函借据，动态分区写入（SELECT 按 DDL 字段顺序，末尾追加 pt 分区列）
INSERT INTO ads_hain_g23_detail PARTITION (pt)
SELECT
    'DEFAULT_BANK'                                          AS dbank_id,
    LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))                  AS ddate,
    project_name,                                                -- 项目名称（OA项目名称）
    NULL,                                                        -- loan_date 放款日期（DDL 保留字段，占位 NULL）
    bill_app_no                                             AS cont_no,
    bill_app_no                                             AS biz_no,
    MD5(applicant_credit_code)                              AS cust_id,            -- 客户编号：统一社会信用代码的 MD5 哈希
    applicant_company_name                                  AS cust_name,          -- 客户名称
    'B01'                                                   AS guar_type,          -- 担保类型
    'Z'                                                     AS biz_mode,           -- 业务开展方式
    CAST(guarantee_amount AS DECIMAL(20,2))                 AS guar_amt,           -- 担保金额：源 DECIMAL(38,18) → 目标 DECIMAL(20,2)
    NULL                                                    AS loan_rate,          -- 贷款/债券发行利率
    CAST(premium / guarantee_amount AS DECIMAL(20,6))      AS guar_rate,          -- 担保费率 = 保费/保函金额
    CAST(effective_date AS DATE)                           AS guar_start,         -- 担保起始日期：源 STRING → 目标 DATE
    CAST(expiry_date AS DATE)                               AS guar_end,           -- 担保到期日期：源 STRING → 目标 DATE
    '何书诺17689893638'                                      AS mgr_contact,        -- 项目经理及联系方式
    'N'                                                     AS policy_flag,        -- 是否政策性担保业务
    'N'                                                     AS strategic_flag,     -- 是否战略新兴产业
    'N'                                                     AS first_loan_flag,    -- 是否首贷户
    NULL AS fin_inst_code,                                        -- 金融机构编码
    NULL AS fin_inst_name,                                        -- 金融机构名称
    NULL AS cust_mgr,                                             -- 经办客户经理
    NULL AS cust_mgr_tel,                                         -- 客户经理联系方式
    NULL AS orig_guar_inst,                                       -- 原担保机构
    NULL AS orig_guar_amt,                                        -- 原担保金额
    NULL AS orig_guar_rate,                                       -- 原担保费率
    'N'  AS od_flag,                                             -- 是否逾期
    NULL AS uncomp_amt,                                          -- 尚未履行代偿责任金额
    NULL AS loss_amt,                                            -- 损失金额
    NULL AS five_class,                                          -- 五级分类
    NULL AS counter_type,                                        -- 反担保方式
    NULL AS counter_code,                                        -- 反担保人编码
    NULL AS counter_name,                                        -- 反担保人名称
    NULL AS counter_amt,                                         -- 反担保金额
    'N'  AS rely_net_flag,                                       -- 是否依托互联网开展融资担保业务
    CURRENT_TIMESTAMP()                                     AS create_time,        -- 创建时间
    CURRENT_TIMESTAMP()                                     AS update_time,        -- 修改时间
    TO_CHAR(CAST(LAST_DAY(DATEADD(GETDATE(), -1, 'mm')) AS DATE), 'yyyymm') AS pt  -- 报表月份分区（动态分区列）
FROM prod_dw_01.dwd_ins_guarantee_apply_wide_full_t
WHERE
    guarantor_no = 5                                              -- 担保公司为海南正堂
    AND effective_date BETWEEN
        TO_CHAR(DATEADD(GETDATE(), -1, 'mm'), 'yyyy-mm-01')       -- 上月1号
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))                -- 上月末
;
