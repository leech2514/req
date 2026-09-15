-- ============================================================================
-- 脚本名称: ins_G11.sql
-- 目标表:   test_zxbs_db.ads_hain_g11_cust_info
-- 业务域:   保险-保函（G11 客户信息表）
-- 功能描述: 海南正堂每月增量保函客户信息报送
-- 源表:     prod_dw_01.dwd_ins_guarantee_apply_wide_full_t（保函申请宽表）
--           mv_ods_ins_new_rpa_capture_message_full_t（RPA采集企业信息视图）
-- 触发条件: 担保公司=5（海南正堂），effective_date 在上月1号至上月末
-- 调度周期: 月度（每月初执行，取上月增量数据）
-- 负责人:   <待填写>
-- 创建日期: <待填写>
-- ----------------------------------------------------------------------------
-- 字段映射说明:
--   dbank_id      = 'DEFAULT_BANK'（默认银行标识）
--   ddate         = 上月最后一天（报送日期）
--   cust_id       = MD5(applicant_credit_code)（统一社会信用代码的 MD5 哈希）
--                   原方案 HASH 返回 BIGINT 可能产生负值；MD5 返回 32 位 STRING，
--                   无负值风险且分布均匀
--   cust_name     = applicant_company_name
--   cert_type     = 'B01'（统一社会信用代码）
--   cert_no/region/industry/ent_scale = 来自 RPA 视图，按 social_credit_code 关联
--   emp_num/annual_inc/asset_tot       = 暂未接入业务数据，填 0 兜底
--   agri_flag/farmer_flag/new_agri_flag/dual_innov_flag = 默认 'N'（待业务确认）
-- ----------------------------------------------------------------------------
-- 去重逻辑: 按 applicant_credit_code 分组，取 create_time 最早的一条
--           （ROW_NUMBER ORDER BY create_time ASC + WHERE row_num = 1）
-- 风险提示:
--   - 目标表为非分区普通表，INSERT INTO 追加写入，历史数据保留不覆盖
--   - 同一 cust_id 跨月重复报送会产生多条历史记录
--   - mv 视图字段来源于 RPA 采集，若 social_credit_code 缺失则关联字段为 NULL
-- TODO: 接入从业人员数、年营业收入、资产总额等业务字段
-- ============================================================================
INSERT INTO test_zxbs_db.ads_hain_g11_cust_info
(
  dbank_id, ddate, cust_id, cust_name, biz_body, cust_type,
  hold_type, cert_type, cert_no, region, industry, ent_scale,
  emp_num, annual_inc, asset_tot, credit_rate, agri_flag, farmer_flag,
  new_agri_flag, dual_innov_flag, grp_uscc
)
WITH deduplicated_data AS (
  SELECT
    applicant_company_name,
    applicant_credit_code,
    ROW_NUMBER() OVER (
        PARTITION BY applicant_credit_code
        ORDER BY create_time
    ) AS row_num
  FROM prod_dw_01.dwd_ins_guarantee_apply_wide_full_t
  WHERE
    guarantor_no = 5                                  -- 担保公司为海南正堂
    AND effective_date
        BETWEEN TO_CHAR(DATEADD(GETDATE(), -1, 'mm'), 'yyyy-mm-01')
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
)
SELECT
  'DEFAULT_BANK'           AS dbank_id,                -- 默认银行标识
  LAST_DAY(DATEADD(GETDATE(), -1, 'mm')) AS ddate,    -- 报送日期：上月末
  MD5(dd.applicant_credit_code) AS cust_id,            -- 客户编号：统一社会信用代码的MD5哈希
  dd.applicant_company_name AS cust_name,             -- 客户名称
  NULL                     AS biz_body,               -- 经营主体
  'Z'                      AS cust_type,              -- 客户类型
  NULL                     AS hold_type,              -- 控股类型
  'B01'                    AS cert_type,              -- 证件类型：B01统一社会信用代码
  mv.social_credit_code    AS cert_no,                -- 证件号码
  mv.unitprovince          AS region,                 -- 所属地区
  mv.industry              AS industry,               -- 所属行业
  mv.ent_scale             AS ent_scale,              -- 企业规模
  0                        AS emp_num,                -- 从业人员（TODO 待接入）
  0.00                     AS annual_inc,             -- 年营业收入（TODO 待接入）
  0.00                     AS asset_tot,              -- 资产总额（TODO 待接入）
  NULL                     AS credit_rate,            -- 主体信用评级
  'N'                      AS agri_flag,              -- 三农主体标识
  'N'                      AS farmer_flag,            -- 农户标志
  'N'                      AS new_agri_flag,          -- 新型农业主体标志
  'N'                      AS dual_innov_flag,        -- 双创双服主体标志
  NULL                     AS grp_uscc                 -- 所属集团统一社会信用代码
FROM deduplicated_data dd
LEFT JOIN mv_ods_ins_new_rpa_capture_message_full_t mv
    ON dd.applicant_credit_code = mv.social_credit_code
WHERE row_num = 1
;
