DROP VIEW IF EXISTS prod_dw_01.v_dim_ins_guarantee_company_info_full_t;

-- ============================================================================
-- 视图名称: v_dim_ins_guarantee_company_info_full_t
-- 层级:     ODS（贴源层）
-- 业务域:   企业信息/RPA采集
-- 功能描述: RPA采集企业信息视图，在源表基础上派生加工字段
-- 源表:     prod_dw_01.dim_ins_guarantee_company_info_full_t（保函业务企业维表）
-- 目标:     v_dim_ins_guarantee_company_info_full_t（MaxCompute 视图）
-- 引擎:     MaxCompute
-- 负责人:   <待填写>
-- 创建日期: <待填写>
-- 备注:     从 AnalyticDB MySQL 物化视图迁移而来；
--           去除 AUTO_INCREMENT/主键/分布键/引擎/查询重写等 ADB 属性；
--           去除去重逻辑（原 ROW_NUMBER 窗口函数），保留全部源表记录
-- ============================================================================

CREATE VIEW IF NOT EXISTS v_dim_ins_guarantee_company_info_full_t AS
SELECT
    company_name,
    company_tag,
    social_credit_code,
    national_standard_industry,
    industry_code,
    scale,
    address,
    enterprise_type,
    dw_update_time,
    dw_create_time,

    -- 派生字段1：unitcode = 统一社会信用代码（字段重命名，语义更清晰）
    social_credit_code AS unitcode,

    -- 派生字段2：industry = 国民经济行业编码，取 industry_code 前三位
    -- 示例：industry_code='F51' → 'F51'
    SUBSTR(industry_code, 1, 3) AS industry,

    -- 派生字段3：unitprovince = 从统一社会信用代码第3-4位映射到省份代码
    -- 统一社会信用代码共18位：第1位=登记管理机关代码，第2位=机构类别代码
    -- 第3-4位=登记管理机关行政区划码（省级），补足 '0000' 形成6位行政区划
    -- 示例：'91440101...' → 第3-4位='44' → '440000'（广东省）
    CASE
        WHEN LENGTH(social_credit_code) = 18
        THEN CONCAT(SUBSTR(social_credit_code, 3, 2), '0000')
        ELSE NULL
    END AS unitprovince,

    -- 派生字段4：ent_scale = 企业规模等级映射
    -- 大型 → A；中型 → B；小型 → C；微型 → D；未匹配 → D（默认归入微型）
    CASE
        WHEN scale = '大型企业' THEN 'A'
        WHEN scale = '中型企业' THEN 'B'
        WHEN scale = '小型企业' THEN 'C'
        WHEN scale = '微型企业' THEN 'D'
        ELSE 'D'
    END AS ent_scale
FROM prod_dw_01.dim_ins_guarantee_company_info_full_t;
