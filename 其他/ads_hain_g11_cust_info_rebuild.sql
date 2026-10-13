-- ============================================================
-- 目的：将 prod_bs_dw.ads_hain_g11_cust_info 重建为事务表（Delta），
--       以支持 DELETE / UPDATE 操作
-- 原因：原表为非事务表，DELETE 报错
--       ODPS-0130071: trying to delete from a non-transactional table
-- 日期：2026-10-08
-- 说明：MaxCompute 不允许通过 ALTER 将非事务表转为事务表，
--       故采用“建新表 → 灌数据 → 校验 → 删旧表 → 改名”重建方式
-- ============================================================


-- ------------------------------------------------------------
-- 步骤 1：建新事务表（schema 与原表完全一致，仅追加事务属性）
--    transactional=true              启用 ACID，支持 DELETE/UPDATE
--    cdc.data.retain.hours=0         非历史回溯场景，节省存储
--    acid.data.retain.hours=0        非历史回溯场景，节省存储
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS prod_bs_dw.ads_hain_g11_cust_info_new(
    dbank_id        STRING COMMENT '机构代码',
    ddate           STRING COMMENT '报表日期',
    xh              BIGINT COMMENT '序号',
    cust_id         STRING COMMENT '客户编号',
    cust_name       STRING COMMENT '客户名称',
    biz_body        STRING COMMENT '经营主体',
    cust_type       STRING COMMENT '客户类型',
    hold_type       STRING COMMENT '控股类型',
    cert_type       STRING COMMENT '证件类型',
    cert_no         STRING COMMENT '证件号码',
    region          STRING COMMENT '所在地区',
    industry        STRING COMMENT '所属行业',
    ent_scale       STRING COMMENT '企业规模',
    emp_num         BIGINT COMMENT '从业人员',
    annual_inc      DECIMAL(20,2) COMMENT '年营业收入',
    asset_tot       DECIMAL(20,2) COMMENT '资产总额',
    credit_rate     STRING COMMENT '主体信用评级',
    agri_flag       STRING COMMENT '"三农"主体标志',
    farmer_flag     STRING COMMENT '农户标志',
    new_agri_flag   STRING COMMENT '新型农业主体标志',
    dual_innov_flag STRING COMMENT '双创双服主体标志',
    grp_uscc        STRING COMMENT '所属集团统一社会信用代码',
    create_time     STRING COMMENT '创建时间',
    update_time     STRING COMMENT '修改时间'
)
STORED AS aliorc
TBLPROPERTIES (
    'transactional'='true',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours'='0',
    'columnar.nested.type'='true',
    'comment'='融资担保公司客户信息表'
);


-- ------------------------------------------------------------
-- 步骤 2：从原表导入全量数据
-- ------------------------------------------------------------
INSERT OVERWRITE TABLE prod_bs_dw.ads_hain_g11_cust_info_new
SELECT
    dbank_id, ddate, xh, cust_id, cust_name, biz_body, cust_type,
    hold_type, cert_type, cert_no, region, industry, ent_scale,
    emp_num, annual_inc, asset_tot, credit_rate, agri_flag,
    farmer_flag, new_agri_flag, dual_innov_flag, grp_uscc,
    create_time, update_time
FROM prod_bs_dw.ads_hain_g11_cust_info;


-- ------------------------------------------------------------
-- 步骤 3：校验数据行数（新表行数必须与原表一致后再执行步骤 4）
-- ------------------------------------------------------------
SELECT COUNT(*) AS old_cnt FROM prod_bs_dw.ads_hain_g11_cust_info;
SELECT COUNT(*) AS new_cnt FROM prod_bs_dw.ads_hain_g11_cust_info_new;
-- 可选：抽样比对关键字段
-- SELECT * FROM prod_bs_dw.ads_hain_g11_cust_info_new
-- WHERE cust_id IN ('<抽样客户编号>') ORDER BY ddate;


-- ============================================================
-- ⚠️  以下为破坏性操作：确认步骤 3 两边行数一致后，
--     再取消注释执行！执行前建议对原表做一次数据备份。
-- ============================================================

-- ------------------------------------------------------------
-- 步骤 4：删除原表，将新表改名为原表名
-- ------------------------------------------------------------
-- DROP TABLE IF EXISTS prod_bs_dw.ads_hain_g11_cust_info;
-- ALTER TABLE prod_bs_dw.ads_hain_g11_cust_info_new RENAME TO ads_hain_g11_cust_info;


-- ------------------------------------------------------------
-- 步骤 5：执行原 DELETE 语句（事务表已支持 DELETE）
--    说明：ddate 为 STRING，LAST_DAY 返回 DATE，
--          MaxCompute 会做隐式转换；如需显式可包一层
--          TO_CHAR(LAST_DAY(...), 'yyyy-MM-dd')
-- ------------------------------------------------------------
-- DELETE FROM prod_bs_dw.ads_hain_g11_cust_info
-- WHERE ddate = LAST_DAY(DATEADD(CURRENT_DATE(), -1, 'MM'));


-- ============================================================
-- 附：若不想重建整表，仅临时清理某 ddate 数据的替代方案
-- （非事务表用 INSERT OVERWRITE 覆写全表，排除要删的分区）：
-- ============================================================
-- INSERT OVERWRITE TABLE prod_bs_dw.ads_hain_g11_cust_info
-- SELECT * FROM prod_bs_dw.ads_hain_g11_cust_info
-- WHERE ddate <> LAST_DAY(DATEADD(CURRENT_DATE(), -1, 'MM'));
