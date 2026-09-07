-- ============================================================================
-- 脚本名称: 新G23_DDL.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G23 担保业务明细信息表（事务表，按报表日期月份分区）
-- 源表:     test_zxbs_db.ads_hain_g23_detail（原 XUANWU_V2 列存表）
-- 目标表:   ads_hain_g23_detail
-- 表类型:   Delta 事务主键表（transactional=true，支持 ACID + MERGE INTO）
-- 主键:     cont_no（合同编号，原 PRIMARY KEY 保留不变）
-- 分区字段: pt (STRING, yyyymm，取自 ddate 报表日期所在月份)
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- 修订记录:
--   2026-08-25  <name>  新建脚本  -  新建脚本，原 XUANWU_V2 列存表迁移为 MaxCompute Delta 事务主键表
-- 迁移说明（原 G23_DDL.sql → MC）:
--   1. 表名 ads_hain_g23_detail 保持不变；字段名保持不变；主键 cont_no 保持不变
--   2. varchar(N) → STRING（MC 无 varchar，统一 STRING；长度不影响存储）
--   3. date → DATE（MC 原生支持）
--   4. decimal(20,2)/decimal(20,6) → DECIMAL(20,2)/DECIMAL(20,6)（保持不变）
--   5. timestamp → TIMESTAMP（保留类型；移除 DEFAULT CURRENT_TIMESTAMP 与 ON UPDATE CURRENT_TIMESTAMP，MC 字段级不支持此类默认值，改由 DML 写入 GETDATE()）
--   6. 主键字段 cont_no 保留 NOT NULL（Delta 主键表强制要求主键字段显式声明 NOT NULL，且不使用 NOT ENFORCED 关键字）
--   7. 保留 dbank_id/ddate/cont_no/biz_no/cust_id 的 NOT NULL 约束（原表即有，MC 支持）
--   8. 移除 KEY pk_sys_cont_no 二级索引（MC 不支持二级索引，主键已覆盖 cont_no 查询）
--   9. 移除 DISTRIBUTE BY HASH / STORAGE_POLICY='HOT' / ENGINE='XUANWU_V2' / TABLE_PROPERTIES（MC 不支持，Delta 表内置分桶与存储策略）
--  10. 新增分区字段 pt (STRING, yyyymm)，取自 ddate 报表日期所在月份；分区列自动纳入主键唯一性约束，即 (cont_no, pt) 联合唯一
--  11. 新增 TBLPROPERTIES('transactional'='true') 开启 ACID；非历史回溯场景配 'cdc.data.retain.hours'='0'、'acid.data.retain.hours'='0' 降低存储
--  12. 原表 loan_date 字段在 G23 DML 中未写入，DDL 予以保留（字段名不变要求），由后续 DML 决定是否补数
-- 风险提示:
--   - Delta 分区表的主键唯一性为 (cont_no, pt) 联合：同一 cont_no 可跨月存在于不同 pt 分区，符合"按月报送"语义
--   - DML（新G23.sql）目前用 INSERT INTO 且未提供 pt 分区列与 create_time/update_time，需改为动态分区写入并补时间字段，否则 pt/create_time/update_time 将为 NULL
--   - Delta 表不支持 INSERT OVERWRITE，DML 必须用 INSERT INTO 或 MERGE INTO
--   - 如需时区/精度，create_time/update_time 也可改 STRING 类型对齐 G11 做法（当前保留 TIMESTAMP）
-- ============================================================================

CREATE TABLE IF NOT EXISTS ads_hain_g23_detail (
    dbank_id        STRING          NOT NULL    COMMENT '机构代码（原 varchar(100) → STRING）',
    ddate           DATE            NOT NULL    COMMENT '报表日期',
    project_name    STRING                      COMMENT '项目名称（原 varchar(64) → STRING）',
    loan_date       DATE                        COMMENT '放款日期',
    cont_no         STRING          NOT NULL    COMMENT '合同编号（主键，原 PRIMARY KEY 保留；Delta 主键字段强制 NOT NULL，不使用 NOT ENFORCED）',
    biz_no          STRING          NOT NULL    COMMENT '业务编号（原 varchar(100) → STRING）',
    cust_id         STRING          NOT NULL    COMMENT '客户编号（原 varchar(100) → STRING）',
    cust_name       STRING                      COMMENT '客户名称（原 varchar(100) → STRING）',
    guar_type       STRING                      COMMENT '担保类型（原 varchar(100) → STRING）',
    biz_mode        STRING                      COMMENT '业务开展方式（原 varchar(100) → STRING）',
    guar_amt        DECIMAL(20,2)               COMMENT '担保金额',
    loan_rate       DECIMAL(20,6)               COMMENT '贷款/债券发行利率',
    guar_rate       DECIMAL(20,6)               COMMENT '担保费率',
    guar_start      DATE                        COMMENT '担保起始日期',
    guar_end        DATE                        COMMENT '担保到期日期',
    mgr_contact     STRING                      COMMENT '项目经理及联系方式（原 varchar(100) → STRING）',
    policy_flag     STRING                      COMMENT '是否政策性担保业务（原 varchar(10) → STRING）',
    strategic_flag  STRING                      COMMENT '是否战略新兴产业（原 varchar(10) → STRING）',
    first_loan_flag STRING                      COMMENT '是否首贷户（原 varchar(10) → STRING）',
    fin_inst_code   STRING                      COMMENT '金融机构编码（原 varchar(100) → STRING）',
    fin_inst_name   STRING                      COMMENT '金融机构名称（原 varchar(100) → STRING）',
    cust_mgr        STRING                      COMMENT '经办客户经理（原 varchar(100) → STRING）',
    cust_mgr_tel    STRING                      COMMENT '客户经理联系方式（原 varchar(100) → STRING）',
    orig_guar_inst  STRING                      COMMENT '原担保机构（原 varchar(100) → STRING）',
    orig_guar_amt   DECIMAL(20,2)               COMMENT '原担保金额',
    orig_guar_rate  DECIMAL(20,6)               COMMENT '原担保费率',
    od_flag         STRING                      COMMENT '是否逾期（原 varchar(10) → STRING）',
    uncomp_amt      DECIMAL(20,2)               COMMENT '尚未履行代偿责任金额',
    loss_amt        DECIMAL(20,2)               COMMENT '损失金额',
    five_class      STRING                      COMMENT '五级分类（原 varchar(100) → STRING）',
    counter_type    STRING                      COMMENT '反担保方式（原 varchar(100) → STRING）',
    counter_code    STRING                      COMMENT '反担保人编码（原 varchar(100) → STRING）',
    counter_name    STRING                      COMMENT '反担保人名称（原 varchar(100) → STRING）',
    counter_amt     DECIMAL(20,2)               COMMENT '反担保金额',
    rely_net_flag   STRING                      COMMENT '是否依托互联网开展融资担保业务（原 varchar(10) → STRING）',
    create_time     TIMESTAMP                   COMMENT '创建时间（原 timestamp DEFAULT CURRENT_TIMESTAMP → TIMESTAMP，移除默认值，由 DML 写入 GETDATE()）',
    update_time     TIMESTAMP                   COMMENT '修改时间（原 timestamp ON UPDATE CURRENT_TIMESTAMP → TIMESTAMP，移除 ON UPDATE，由 DML 写入 GETDATE()）',
    PRIMARY KEY (cont_no)
)
PARTITIONED BY (
    pt STRING COMMENT '报表月份 yyyymm（取自 ddate 报表日期所在月份）'
)
TBLPROPERTIES (
    'transactional'='true',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours'='0',
    'comment'='担保业务明细信息表'
)
;
