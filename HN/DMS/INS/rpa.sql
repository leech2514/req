-- ============================================================================
-- 物化视图名称: mv_ods_ins_rpa_capture_message
-- 层级:     ODS（贴源层）
-- 业务域:   企业信息/RPA采集
-- 功能描述: RPA采集企业信息物化视图，按企业名称去重，保留最新一条记录
-- 源表:     prd_spark_db.ods_ins_rpa_capture_message（RPA采集原始表）
-- 目标表:   mv_ods_ins_rpa_capture_message（物化视图）
-- 刷新模式: REFRESH COMPLETE ON DEMAND（全量刷新，手动触发）
-- 刷新周期: DataWorks每6小时调度一次（业务约定）
-- 去重逻辑: 按 company_name 分组，取 dw_update_time 最新、id 最大的一条
-- 存储引擎: XUANWU_V2（列存），主键 __adb_auto_id__ 自增
-- 负责人:   <待填写>
-- 创建日期: <待填写>
-- 备注:     该物化视图关闭查询重写（DISABLE QUERY REWRITE），仅作为数据快照使用
-- ============================================================================

CREATE MATERIALIZED VIEW `mv_ods_ins_rpa_capture_message` (
  -- 自增主键（AnalyticDB MySQL 物化视图特有，用于分布式存储路由）
  `__adb_auto_id__` bigint AUTO_INCREMENT,
  
  -- ========== 原表透传字段 ==========
  `id` bigint COMMENT '原表主键ID',
  `company_name` varchar COMMENT '企业名称（去重依据）',
  `company_tag` varchar COMMENT '企业标签',
  `social_credit_code` varchar COMMENT '统一社会信用代码',
  `national_standard_industry` varchar COMMENT '国民经济行业分类（含括号代码，如"批发业(F51)"）',
  `scale` varchar COMMENT '企业规模：大型/中型/小型/微型',
  `address` varchar COMMENT '企业地址',
  `enterprise_type` varchar COMMENT '企业类型',
  `create_time` datetime COMMENT '原表创建时间（业务时间）',
  `dw_update_time` timestamp COMMENT '数据仓库更新时间（用于排序取最新）',
  `dw_create_time` timestamp COMMENT '数据仓库创建时间',
  
  -- ========== 派生字段 ==========
  `unitcode` varchar COMMENT '单位代码（复用统一社会信用代码）',
  `industry` varchar COMMENT '行业代码（从 national_standard_industry 中提取括号内的代码）',
  `unitprovince` varchar COMMENT '单位所在省份代码（从统一社会信用代码第3-4位映射）',
  `ent_scale` varchar(1) COMMENT '企业规模等级：A-大型；B-中型；C-小型；D-微型（含未匹配）',
  
  -- ========== 索引定义 ==========
  KEY `pk_sys___adb_auto_id__` (`__adb_auto_id__`),
  PRIMARY KEY (`__adb_auto_id__`)
) 
DISTRIBUTED BY HASH(`__adb_auto_id__`)  -- 哈希分布，以自增主键为分片键
STORAGE_POLICY='HOT'                    -- 热数据存储策略
ENGINE='XUANWU_V2'                      -- 引擎：AnalyticDB MySQL 3.0 - XUANWU_V2
TABLE_PROPERTIES='{"format":"columnstore"}'  -- 列存格式
COMMENT='RPA采集企业信息物化视图，DataWorks每6小时调度全量刷新，按company_name去重，取dw_update_time最新一条'
REFRESH COMPLETE ON DEMAND               -- 刷新模式：COMPLETE=全量覆盖，ON DEMAND=手动触发
DISABLE QUERY REWRITE                    -- 关闭查询重写（禁止优化器自动改写查询使用此物化视图）
AS

-- ============================================================================
-- 核心加工逻辑
-- ============================================================================

WITH t_rpa AS (
    SELECT 
        -- 原表透传
        -- `id`,
        `company_name`,
        `company_tag`,
        `social_credit_code`,
        `national_standard_industry`,
        `industry_code`,
        `scale`,
        `address`,
        `enterprise_type`,
        -- `create_time`,
        `dw_update_time`,
        `dw_create_time`,
        
        -- 派生字段1：unitcode = 统一社会信用代码（字段重命名，语义更清晰）
        `social_credit_code` AS `unitcode`,
        
        -- 派生字段2：industry = 从 national_standard_industry 括号中提取代码
        -- 示例：'批发业(F51)' → regexp_substr 提取 '(F51)' → substring 取第2-4位 → 'F51'
        -- `substring`(
        --     `test_zxbs_db`.`regexp_substr`(`national_standard_industry`, '\\(([^)]+)\\)'), 
        --     2, 
        --     3
        -- ) AS `industry`,
        SUBSTRING(industry_code, 1, 3) AS industry,
        -- 派生字段3：unitprovince = 从统一社会信用代码第3-4位映射到省份代码
        -- 统一社会信用代码共18位：第1位=登记管理机关代码，第2位=机构类别代码
        -- 第3-4位=登记管理机关行政区划码（省级）
        -- 映射规则：取第3-4位 + '0000' 补足6位行政区划
        -- 示例：'91440101...' → 第3-4位='44' → '440000'（广东省）
        CASE 
            WHEN `length`(`social_credit_code`) = 18 
            THEN `concat`(prod_dw_01.`substring`(`social_credit_code`, 3, 2), '0000')
            ELSE NULL
        END AS `unitprovince`,
        
        -- 派生字段4：ent_scale = 企业规模等级映射
        -- 大型 → A；中型 → B；小型 → C；微型 → D；未匹配 → D（默认归入微型）
        CASE 
            WHEN `scale` = '大型企业' THEN 'A'
            WHEN `scale` = '中型企业' THEN 'B'
            WHEN `scale` = '小型企业' THEN 'C'
            WHEN `scale` = '微型企业' THEN 'D'
            ELSE 'D'                            -- 兜底：空值或未知值归入D
        END AS `ent_scale`
        
        -- -- 去重排序：按企业名称分组，取 dw_update_time 最新、id 最大的一条
        -- -- ⚠️ 注意：AnalyticDB MySQL 中 row_number() 需显式指定窗口，此处使用 OVER 子句
        -- `row_number`() OVER (
        --     PARTITION BY `company_name`          -- 按企业名称去重（业务唯一键）
        --     ORDER BY `dw_update_time` DESC      -- 优先取最新更新的记录
        --             --  `id` DESC                   -- 其次取ID最大的记录（防止同一时间多条）
        -- ) AS `rn`
        
    FROM prod_dw_01.dim_ins_guarantee_company_info_full_t
)

-- 最终输出：仅保留每个企业名称的最新一条记录（rn = 1）
SELECT 
    `id`,
    `company_name`,
    `company_tag`,
    `social_credit_code`,
    `national_standard_industry`,
    `scale`,
    `address`,
    `enterprise_type`,
    `create_time`,
    `dw_update_time`,
    `dw_create_time`,
    `unitcode`,
    `industry`,
    `unitprovince`,
    `ent_scale`
FROM `t_rpa`
WHERE `rn` = 1
;