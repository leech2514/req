-- ============================================================
-- 目的：备份 ads_hain_g11_cust_info 表，并将符合 hainan_farmer.sql
--       条件的数据 farmer_flag 更新为 'N'
-- 产品：阿里云 AnalyticDB MySQL 版
-- 日期：2026-09-30
-- ============================================================

-- ------------------------------------------------------------
-- 1. 备份表（CTAS，保留全量数据与字段结构）
--    备份表名：ads_hain_g11_cust_info_20260930
-- ------------------------------------------------------------
CREATE TABLE ads_hain_g11_cust_info_20260930 AS
SELECT * FROM ads_hain_g11_cust_info;

-- 校验备份行数（应与原表一致）
-- SELECT COUNT(*) AS backup_cnt FROM ads_hain_g11_cust_info_20260930;
-- SELECT COUNT(*) AS origin_cnt FROM ads_hain_g11_cust_info;


-- ------------------------------------------------------------
-- 2. 更新：将符合条件数据的 farmer_flag 置为 'N'
--    条件：cust_id 不在 ads_hain_g23_detail（project_name 含'度小满'）中
--          且当前 farmer_flag = 'Y'
--    说明：用 NOT EXISTS 替代 NOT IN，规避 NULL 值陷阱并提升性能
-- ------------------------------------------------------------
UPDATE ads_hain_g11_cust_info g11
SET g11.farmer_flag = 'N'
WHERE g11.farmer_flag = 'Y'
  AND NOT EXISTS (
      SELECT 1
      FROM ads_hain_g23_detail g23
      WHERE g23.cust_id = g11.cust_id
        AND g23.project_name LIKE '%度小满%'
  );

-- 等价于原 NOT IN 写法（若偏好与原查询一致，可用此版本）：
-- UPDATE ads_hain_g11_cust_info
-- SET farmer_flag = 'N'
-- WHERE farmer_flag = 'Y'
--   AND cust_id NOT IN (
--       SELECT cust_id
--       FROM ads_hain_g23_detail
--       WHERE project_name LIKE '%度小满%'
--         AND cust_id IS NOT NULL
--   );


-- ------------------------------------------------------------
-- 3. 更新后核验（被更新的行应为 0 条 farmer_flag='Y' 的命中数据）
-- ------------------------------------------------------------
-- SELECT COUNT(*) AS updated_y_rows
-- FROM ads_hain_g11_cust_info g11
-- WHERE g11.farmer_flag = 'Y'
--   AND NOT EXISTS (
--       SELECT 1 FROM ads_hain_g23_detail g23
--       WHERE g23.cust_id = g11.cust_id
--         AND g23.project_name LIKE '%度小满%'
--   );
