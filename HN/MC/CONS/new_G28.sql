-- ============================================================================
-- 脚本名称: ads_hain_g28_recover_detail.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G28 代偿回收明细月度报送（基于 G27 代偿明细，按回收口径转换）
-- 源表:     ads_hain_g27_comp_detail（G27 已报送代偿明细，同 project 目标表）
-- 目标表:   ads_hain_g28_recover_detail
-- 写入模式: INSERT INTO TABLE PARTITION(pt)（动态分区追加写入）
-- 增量方式: 月度全量（按上月末 ddate 筛选 G27 数据，转换后写入 G28）
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-26
-- 修订记录:
--   2026-08-26  <name>  新建脚本  -  新建脚本，原 DMS old_G28.sql 迁移至 MaxCompute
-- 迁移说明（原 old_G28.sql → MC）:
--   1. 源表按《表名映射关系.md》替换：
--        test_zxbs_db.ads_hain_g27_comp_detail → ads_hain_g27_comp_detail（同 project 目标表）
--        test_zxbs_db.ads_hain_g28_recover_detail → ads_hain_g28_recover_detail（目标表，去库名前缀）
--   2. REPLACE INTO → INSERT INTO TABLE ... PARTITION(pt)
--      （MC Delta 主键表不支持 REPLACE INTO；如需 upsert 语义请改用 MERGE INTO，见风险提示）
--   3. DATE_ADD(comp_date, INTERVAL 1 DAY) → DATEADD(comp_date, 1, 'dd')（MC 日期加法）
--   4. DATE(...) 包装 → CAST(... AS DATE)（对齐 MC 类型转换语法）
--   5. cast((comp_amt+comp_int) as decimal(20,2)) → CAST((comp_amt + comp_int) AS DECIMAL(20,2))（小写→大写统一）
--   6. 去除反引号，补行内注释；INSERT 字段补中文注释（读自 new_hainanDDL.sql G28 段）
--   7. 改为 PARTITION(pt) 动态分区；pt=TO_CHAR(ddate,'yyyymm')，按 ddate 所在月份取值
--   8. 原硬编码 '2026-06-30' → LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))（取上月末，便于月度调度）
--   9. SELECT 列表按目标表 new_hainanDDL.sql G28 段声明类型逐一 CAST（STRING/DATE/BIGINT/DECIMAL(20,2)）
-- 业务说明:
--   - G28 回收数据由 G27 代偿明细转换而来：recv_seq ← comp_seq，recv_amt ← comp_amt + comp_int
--   - 回收日期 recv_date 规则：comp_date 为月末则取当天，否则取次日（口径与原脚本一致）
--   - 仅筛选 G27 中 ddate = 上月末 的数据
-- 风险提示:
--   - ⚠️ 原 INSERT 列顺序 (cont_no, biz_no) 与 SELECT 字段顺序 (biz_no, cont_no) 存在位置交换：
--     位置5: INSERT cont_no ← SELECT biz_no 值；位置6: INSERT biz_no ← SELECT cont_no 值
--     因 G27 源表 cont_no = biz_no = apply_no（同值），实际不影响数据；本脚本保持原位置映射不变
--     若需修正请在 SELECT 处调整字段顺序
--   - ⚠️ 原 REPLACE INTO 为 upsert 语义（同主键 recv_seq 重复时覆盖），改为 INSERT INTO 后同月重跑
--     会触发主键冲突；建议重跑前先清理当月分区：ALTER TABLE ads_hain_g28_recover_detail DROP IF EXISTS PARTITION(pt='yyyymm');
--     或改用 MERGE INTO 实现 upsert
--   - 原脚本未写 create_time/update_time，DDL 已移除默认值，这两个字段将为 NULL；如需赋值请在 SELECT 补 GETDATE()
--   - LAST_DAY/DATEADD/TO_CHAR 为 MC 2.0 扩展函数，若项目未开启 2.0 数据类型需补 SET odps.sql.type.system.odps2=true;
-- ============================================================================
-- DataWorks 调度参数配置：
--   bizdate=$bizdate        -- yyyymmdd 业务日期（T-1）
--   bizmonth=$bizmonth      -- yyyymm 业务月（上月）

INSERT INTO TABLE ads_hain_g28_recover_detail PARTITION(pt)
(
    dbank_id,        -- 1. 机构代码
    ddate,           -- 2. 报表日期
    xh,              -- 3. 序号
    project_name,    -- 4. 项目名称
    cont_no,         -- 5. 合同编号
    biz_no,          -- 6. 业务编号
    recv_seq,        -- 7. 回收序号
    recv_date,       -- 8. 回收日期
    recv_amt,        -- 9. 本次回收金额
    pt               -- 10. 报表月份 yyyymm（动态分区列，按 ddate 所在月份取值）
)
SELECT
    -- 以下每列按目标表 new_hainanDDL.sql G28 段声明类型逐一 CAST
    -- ⚠️ 保持原 G28 脚本 SELECT 顺序（biz_no 在 cont_no 前），与 INSERT 列顺序形成位置映射
    --    原 G27 源表中 cont_no = biz_no = apply_no（同值），故位置交换不影响数据
    CAST(dbank_id AS STRING)         AS dbank_id,        -- 1. 机构代码
    CAST(ddate AS DATE)              AS ddate,           -- 2. 报表日期
    CAST(xh AS BIGINT)               AS xh,              -- 3. 序号
    CAST(project_name AS STRING)     AS project_name,    -- 4. 项目名称
    CAST(biz_no AS STRING)           AS cont_no,         -- 5. 合同编号（源字段 biz_no，位置映射保持原脚本顺序）
    CAST(cont_no AS STRING)          AS biz_no,          -- 6. 业务编号（源字段 cont_no，位置映射保持原脚本顺序）
    CAST(comp_seq AS STRING)         AS recv_seq,        -- 7. 回收序号（源字段 comp_seq）
    -- 8. 回收日期：comp_date 为月末则取当天，否则取次日（口径与原脚本一致）
    CAST(
        CASE
            WHEN comp_date = LAST_DAY(comp_date) THEN comp_date
            ELSE DATEADD(comp_date, 1, 'dd')
        END AS DATE
    )                                                    AS recv_date,
    -- 9. 本次回收金额 = 本次代偿金额 + 本次代偿利息
    CAST((comp_amt + comp_int) AS DECIMAL(20,2))          AS recv_amt,
    -- ========= 动态分区列 pt 必须是 SELECT 列表最后一列 =========
    -- 按 ddate（上月末）的月份取 yyyymm，与 new_hainanDDL "按ddate的月份分区"一致
    CAST(TO_CHAR(CAST(ddate AS DATE), 'yyyymm') AS STRING) AS pt
FROM ads_hain_g27_comp_detail
WHERE ddate = LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))   -- 上月末（替代原硬编码 '2026-06-30'，便于月度调度）
;
