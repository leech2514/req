-- ============================================================================
-- 建表语句目录（供快速定位，行号为本文件内行号）
-- 统计：共 40 个 CREATE TABLE，38 个唯一表名（011_tmp/012_tmp 各重复定义 1 次）
-- 说明：[dup] 表示该表在文件中存在重复定义
-- ============================================================================
-- 业务管控配置
--   1. business_control_project_rule                    L62
--   2. business_control_compensate_rule                 L204
--   3. business_control_loandate_detail                 L221
--   4. tmp_req_comp_num                                 L241
-- 维度表
--   5. dim_base_prod_info_full_t                        L309
--   6. dim_base_indiv_info_incr_t                       L372
--   7. dim_req_supervision_payment_info_incr_delta      L1537
-- 消金-放款
--   8. dwd_cons_loan_payment_info_incr_delta            L426
--   9. ods_fake_cons_loan_info_incr_delta               L1332
-- 消金-还款
--  10. dwd_req_cons_repay_info_incr_delta               L93
--  11. dwd_cons_repay_info_incr_delta                   L472
--  12. dwd_req_black_cons_repay_info_full_t             L701
--  13. dwd_req_dummy_cons_repay_info_full_t             L762
--  14. ods_fake_cons_repay_plan_incr_delta              L1382
--  15. ods_fake_cons_repay_info_incr_delta              L1458
-- 消金-还款计划
--  16. dwd_cons_loan_repay_plan_incr_delta              L823
-- 消金-还款表现
--  17. dwd_req_cons_payment_performance_incr_delta      L532
--  18. dwd_req_cons_payment_performance_incr_delta_003_tmp L574
--  19. dwd_req_cons_payment_performance_incr_delta_004_tmp L616
--  20. dwd_req_cons_payment_performance_incr_delta_005_tmp L658
-- 车贷-放款
--  21. dwd_auto_oapi_loan_incr_delta                    L258
-- 车贷-还款
--  22. dwd_req_auto_oapi_repay_info_delta               L155
--  23. dwd_req_black_auto_oapi_repay_info_full_t        L1238
--  24. dwd_req_dummy_auto_oapi_repay_info_full_t        L1284
-- 车贷-在贷余额/还款
--  25. dwd_req_auto_balance_repay_info_incr_delta       L975
--  26. dwd_req_auto_balance_repay_info_incr_delta_007_tmp L1016
--  27. dwd_req_auto_balance_repay_info_incr_delta_008_tmp L1057
-- 车贷-还款计划
--  28. prod_dw_01.dwd_auto_loan_repay_plan_incr_delta   L1096
-- 模拟数据-消金/车贷 ODS
--  29. dwd_req_black_fake_loan_repay_info_full_t        L1513
--  30. ods_fake_auto_loan_info_incr_delta               L1798
--  31. ods_fake_auto_repay_plan_incr_delta              L1852
--  32. ods_fake_auto_repay_info_incr_delta              L1917
--  33. ods_fake_pacb_project_application_incr_delta     L1965
--  34. ods_fake_pacb_repay_plan_incr_delta              L2011
-- 模拟数据-线下还款表现
--  35. dwd_fake_offline_repay_performance_incr_delta    L1599
--  36. dwd_fake_offline_repay_performance_incr_delta_010_tmp L1648
--  37. dwd_fake_offline_repay_performance_incr_delta_011_tmp L1697  [dup: L2079]
--  38. dwd_fake_offline_repay_performance_incr_delta_012_tmp L1746  [dup: L2133]
--  39. dwd_fake_offline_repay_performance_incr_delta_011_tmp L2079  [dup of #37]
--  40. dwd_fake_offline_repay_performance_incr_delta_012_tmp L2133  [dup of #38]
-- ============================================================================

-- 原：business_control_project_rule
-- 源库：f_prd_spark_db
CREATE TABLE IF NOT EXISTS business_control_project_rule (
    project_rule_id          BIGINT  not null     COMMENT '业务管控规则ID—主键',
    control_type             STRING       COMMENT '业务管控类型：1-金融局 2-资方',
    project_id               INT          COMMENT '业务管控项目ID',
    old_project_id           INT          COMMENT '原项目ID',
    import_type              STRING       COMMENT '导入方式：1-自动 2-手动',
    loaded_flag              STRING       COMMENT '是否已装入：T-是 F-否',
    status                   STRING       COMMENT '状态: 1-计算在贷中 2-等待风险确认 ... 17-删除规则驳回',
    predict_loan_amount      DOUBLE       COMMENT '预估导入在贷金额—单位：元',
    loan_amount              DOUBLE       COMMENT '实际导入在贷金额—单位：元',
    margin_rate              DOUBLE       COMMENT '保证金比例',
    over_predict_loan_amount DOUBLE       COMMENT '超限后根据限制重新获取预估金额',
    max_loan_date            STRING       COMMENT '超限后获取预估导入的最大放款时间',
    imported_data_type       STRING       COMMENT '已导入数据处理方式：0-删除 1-保留',
    rule_description         STRING       COMMENT '规则描述',
    task_status              STRING       COMMENT '定时任务执行状态：0-未执行；1-执行完毕；99-执行中',
    business_control_rule_id BIGINT       COMMENT '业务管控规则Id（新）',
    create_time              DATETIME     COMMENT '首次配置时间',
    update_time              DATETIME     COMMENT '最后修改时间',
    natural_days             INT          COMMENT '记账与放款超N自然日不装入',
    import_success_time      DATETIME     COMMENT '导入成功时间',
    PRIMARY KEY (project_rule_id)
)
COMMENT '业务管控规则表'
TBLPROPERTIES ("transactional"="true")
;

-- 原：req_comp_dwd_cons_loan_repay_info_d
-- 源库：f_prd_spark_db
-- 说明：消金原始还款明细，包含客户信息、放款信息、还款信息等
-- 用于业务管控-消金-还款信息展示
CREATE TABLE IF NOT EXISTS dwd_req_cons_repay_info_incr_delta (
    bill_app_no         STRING  COMMENT '借款申请编号',
    recon_date          STRING  COMMENT '对账日期：格式YYYY-MM-DD',
    recon_month         STRING  COMMENT '对账月份：格式YYYY-MM',
    term                BIGINT  COMMENT '期次号',
    indiv_cust_id       STRING  COMMENT '客户号',
    product_no          STRING  COMMENT '产品编码',
    repay_series_no     STRING  NOT NULL COMMENT '还款流水号',
    repay_time          STRING  COMMENT '还款时间',
    repay_date          STRING  COMMENT '还款日期',
    repay_month         STRING  COMMENT '还款月份',
    repay_total_amt     DECIMAL(38,18) COMMENT '还款总额（元）',
    princ               DECIMAL(38,18) COMMENT '还款本金（元）',
    int_amt             DECIMAL(38,18) COMMENT '还款利息（元）',
    service_amt         DECIMAL(38,18) COMMENT '还款服务费（元）',
    guarantee_amt       DECIMAL(38,18) COMMENT '还款担保费（元）',
    margin_amt          DECIMAL(38,18) COMMENT '还款保证金（元）',
    compensate_amt      DECIMAL(38,18) COMMENT '还款代偿金（元）',
    oint_amt            DECIMAL(38,18) COMMENT '还款罚息（元）',
    define_amt          DECIMAL(38,18) COMMENT '还款逾期违约金（元）',
    adv_define_amt      DECIMAL(38,18) COMMENT '提前还款违约金（元）',
    oguarantee_amt      DECIMAL(38,18) COMMENT '还款担保费罚息（元）',
    reduce_total_amt    DECIMAL(38,18) COMMENT '减免总计（元）',
    reduce_princ        DECIMAL(38,18) COMMENT '减免本金（元）',
    reduce_int_amt      DECIMAL(38,18) COMMENT '实还免息券贴利息（元）',
    reduce_service_amt  DECIMAL(38,18) COMMENT '实还免息券贴服务费（元）',
    reduce_guarantee_amt DECIMAL(38,18) COMMENT '实还免息券贴担保费（元）',
    reduce_margin_amt   DECIMAL(38,18) COMMENT '减免保证金（元）',
    reduce_compensate_amt DECIMAL(38,18) COMMENT '减免代偿金（元）',
    reduce_oint_amt     DECIMAL(38,18) COMMENT '减免罚息（元）',
    reduce_define_amt   DECIMAL(38,18) COMMENT '减免逾期违约金（元）',
    reduce_adv_define_amt DECIMAL(38,18) COMMENT '减免提前还款违约金（元）',
    reduce_oguarantee_amt DECIMAL(38,18) COMMENT '减免担保费罚息（元）',
    reduce_activity_amt DECIMAL(38,18) COMMENT '活动减免金额（元）',
    reduce_compliance_amt DECIMAL(38,18) COMMENT '合规减免金额（元）',
    repay_type          STRING  COMMENT '还款类型：1-正常还款、2-非减免、3-减免、4-提前还款、5-提前结清、6-风险结清、7-代偿还款、8-追偿还款、9-对公还款',
    remark              STRING  COMMENT '备注',
    loan_month          STRING  COMMENT '放款月份：格式YYYY-MM',
    dw_create_time      STRING  COMMENT '数仓创建时间',
    dw_update_time      STRING  COMMENT '数仓修改时间',
    create_time         STRING  COMMENT '创建时间',
    update_time         STRING  COMMENT '更新时间',
    repay_method        STRING  COMMENT '还款方式：01-线上还款；02-线下还款；11-支付宝；12-微信支付；13-其他；21-对公还款；22-商户号',
    compensate_type     STRING  COMMENT '代偿类型：1-当期代偿 2-整笔代偿（当还款类型为7时必填）',
    PRIMARY KEY (repay_series_no)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMMdd，直接继承源表分区')
STORED AS aliorc
TBLPROPERTIES (
    'transactional' = 'true',
    'acid.data.retain.hours' = '0',
    'cdc.data.retain.hours' = '0',
    'columnar.nested.type' = 'true',
    'comment' = 'DWD层-消金还款信息表（业务管控使用）',
    'write.bucket.num' = '8'
);

-- 原：req_comp_dwd_auto_oapi_repay_info_d
-- 创建事务表，支持主键（tran_rp_no），并保留分区 pt
-- 源库：f_prd_spark_db
-- 说明：车贷原始还款明细，包含客户信息、放款信息、还款信息等
-- 用于业务管控-车贷-还款信息展示
CREATE TABLE IF NOT EXISTS dwd_req_auto_oapi_repay_info_delta (
    recon_date          STRING      COMMENT '账单日期（格式 yyyy-mm-dd）',
    product_no          STRING      COMMENT '产品编码',
    bill_app_no         STRING      COMMENT '借款申请编号',
    term                BIGINT      COMMENT '期次号',
    tran_rp_no          STRING      NOT NULL COMMENT '还款流水号（业务主键）',
    created_by          STRING      COMMENT '创建用户ID',
    last_modified_by    STRING      COMMENT '修改用户ID',
    tenant_id           STRING      COMMENT '租户ID',
    act_repay_date      STRING      COMMENT '实际还款日（格式 yyyy-mm-dd）',
    repay_type          STRING      COMMENT '还款类型:1-正常 2-提前 3-结清 4-代偿 5-追偿',
    print               DECIMAL(17,2) COMMENT '实还本金',
    int_amt             DECIMAL(17,2) COMMENT '实还利息',
    service_amt         DECIMAL(17,2) COMMENT '实还服务费',
    guarantee_fee       DECIMAL(17,2) COMMENT '实还担保费',
    margin_amt          DECIMAL(17,2) COMMENT '实还保证金',
    compensate_amt      DECIMAL(17,2) COMMENT '实还代偿金',
    oint_amt            DECIMAL(17,2) COMMENT '实还罚息',
    define_amt          DECIMAL(17,2) COMMENT '实还逾期违约金',
    adv_define_amt      DECIMAL(17,2) COMMENT '实还提前还款违约金',
    repay_total_amt     DECIMAL(17,2) COMMENT '实还总计',
    remark              STRING      COMMENT '备注',
    channel_id          STRING      COMMENT '渠道id',
    trd_id              STRING      COMMENT '批次号',
    create_time         STRING    COMMENT '创建时间',
    update_time         STRING    COMMENT '修改时间',
    dw_update_time      STRING    COMMENT '数仓更新时间',
    dw_create_time      STRING    COMMENT '数仓创建时间',
    PRIMARY KEY (tran_rp_no)        -- 主键定义
)
COMMENT 'DWD层-车贷还款信息表（业务管控使用））'
PARTITIONED BY (
    pt STRING COMMENT '业务日期分区，格式 YYYYMMDD'
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',       -- 开启事务，支持主键约束
    'acid.data.retain.hours' = '0',  -- ACID数据保留时长
    'cdc.data.retain.hours' = '0',   -- CDC数据保留时长
    'columnar.nested.type' = 'true',
    'write.bucket.num' = '4'        -- 写入分桶数，可根据数据量调整
);

-- ========================================
-- 以下为001任务需要新增迁移的表
-- ========================================

-- 原：business_control_compensate_rule（业务管控-代偿规则配置表）
-- 源库：f_prd_spark_db
CREATE TABLE IF NOT EXISTS business_control_compensate_rule (
    id              BIGINT   not null   COMMENT '主键',
    project_rule_id BIGINT      COMMENT '所属项目管控规则ID(business_control_project_rule.project_rule_id)',
    scope           STRING      COMMENT '配置范围: 0=项目总体 1=单项目',
    config_json     STRING      COMMENT '代偿配置JSON(col1/col2/col3, 每列 cancelCount/periodRules/unchecked/allSelected)',
    create_by       STRING      COMMENT '创建人',
    create_time     DATETIME    COMMENT '创建时间',
    update_by       STRING      COMMENT '更新人',
    update_time     DATETIME    COMMENT '更新时间',
    PRIMARY KEY (id)
)
COMMENT '业务管控-代偿规则配置表'
TBLPROPERTIES ("transactional"="true")
;

-- 原：business_control_loandate_detail（管控规则放款时间表）
-- 源库：f_prd_spark_db
CREATE TABLE IF NOT EXISTS business_control_loandate_detail (
    loandate_id          BIGINT not null  COMMENT '放款起止时间主键ID',
    project_rule_id      INT      COMMENT '业务管控规则ID',
    loan_begin_date      STRING   COMMENT '放款开始日期：yyyy-MM-dd',
    loan_end_date        STRING   COMMENT '放款结束日期：yyyy-MM-dd',
    update_historical_data INT     COMMENT '是否更新历史数据',
    adjust_data_date     INT      COMMENT '是否调整数据日期',
    adjust_date          STRING   COMMENT '调整日期',
    modify_to_farmer_data INT     COMMENT '是否修改为农户数据',
    farmer_regions       STRING   COMMENT '农户地区(JSON数组)',
    farmer_ratio         STRING   COMMENT '农户占比',
    PRIMARY KEY (loandate_id)
)
COMMENT '管控规则放款时间表'
TBLPROPERTIES ("transactional"="true")
;

-- 原：tmp_req_comp_num（数字辅助临时表）
-- 源库：f_prd_spark_db
-- 说明：用于JSON数组行转列拆解勾选规则，需初始化数据0-1400
CREATE TABLE IF NOT EXISTS tmp_req_comp_num (
    n   INT   COMMENT '数字序号，用于JSON行转列'
)
COMMENT '数字辅助临时表（用于JSON数组拆解，存储0-1400）'
;

-- 初始化数据（需手动执行，使用以下脚本生成0-1400的连续数字）：
/*INSERT INTO tmp_req_comp_num
SELECT num
FROM (
    SELECT SEQUENCE(0, 1400) AS num_array
) t
LATERAL VIEW EXPLODE(num_array) tmp AS num;
*/

-- 原：dwd_auto_oapi_loan_d
-- 源库：prd_spark_db
CREATE TABLE IF NOT EXISTS dwd_auto_oapi_loan_incr_delta(
	id STRING COMMENT '唯一编码',
	 oapi_project_id STRING COMMENT '立项id',
	 tenant_id STRING COMMENT '租户ID',
	 channel_id STRING COMMENT '资产方固定特殊唯一编码',
	 recon_date STRING COMMENT '对账日期',
	 product_no STRING COMMENT '产品编码',
	 bill_app_no STRING NOT NULL COMMENT '借款申请编号',
	 loan_req_no STRING COMMENT '放款流水号',
	 loan_status STRING COMMENT '放款状态',
	 loan_day STRING COMMENT '放款时间',
	 loan_month STRING COMMENT '放款月份',
	 date_due STRING COMMENT '到期日期',
	 name STRING COMMENT '用户姓名',
	 id_card_type STRING COMMENT '用户证件类型',
	 id_card STRING COMMENT '用户身份证号码',
	 contract_amt DECIMAL(17,2) COMMENT '合同金额(元)',
	 loan_amt DECIMAL(17,2) COMMENT '放款金额(元)',
	 service_amt DECIMAL(17,2) COMMENT '前期服务费金额(元)',
	 guarantee_amt DECIMAL(17,2) COMMENT '前期担保费金额(元)',
	 margin_amt DECIMAL(17,2) COMMENT '前期保证金金额(元)',
	 compensate_amt DECIMAL(17,2) COMMENT '前期代偿金金额(元)',
	 act_service_amt DECIMAL(17,2) COMMENT '实收前期服务费金额(元)',
	 act_guarantee_amt DECIMAL(17,2) COMMENT '实收前期担保费金额(元)',
	 act_margin_amt DECIMAL(17,2) COMMENT '实收前期保证金金额(元)',
	 act_compensate_amt DECIMAL(17,2) COMMENT '实收前期代偿金金额(元)',
	 repay_day STRING COMMENT '还款日',
	 total_term BIGINT COMMENT '总期数',
	 detail_status STRING COMMENT '借据状态',
	 remark STRING COMMENT '备注',
	 created_by STRING COMMENT '创建用户ID',
	 last_modified_by STRING COMMENT '修改用户ID',
	 create_time STRING COMMENT '创建时间',
	 update_time STRING COMMENT '修改时间',
	 dw_create_time STRING COMMENT '数仓创建时间',
	 dw_update_time STRING COMMENT '数仓更新时间',
	PRIMARY KEY(bill_app_no)
) 
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyymm 同ods一致') STORED AS aliorc 
TBLPROPERTIES ('acid.data.retain.hours'='0',
	 'cdc.data.retain.hours'='24',
	 'columnar.nested.type'='true',
	 'comment'='车贷放款信息表',
	 'transactional'='true',
	 'acid.cdc.mode.enable'='false',
	 'write.bucket.num'='16');


-- 原：dim_base_prod_info（产品信息表）
-- 源库：prd_spark_db
-- 说明：产品信息表，包含产品基本信息、联系信息、产品状态等
CREATE TABLE IF NOT EXISTS dim_base_prod_info_full_t(
	id BIGINT COMMENT 'd_project_parameter.id',
	 product_no STRING NOT NULL COMMENT '产品编号',
	 product_name STRING COMMENT '产品名称',
	 project_no STRING COMMENT '项目编号',
	 project_name STRING COMMENT '项目名称',
	 guarantor_no STRING COMMENT '担保方编号',
	 guarantor_name STRING COMMENT '担保方',
	 platform_no STRING COMMENT '平台方编号',
	 platform_name STRING COMMENT '平台方',
	 financer_no STRING COMMENT '资金方编号',
	 financer_name STRING COMMENT '资金方',
	 system_no BIGINT COMMENT '系统(900:车贷、901:消金系统、902：数据导入)',
	 system_name STRING COMMENT '来源系统',
	 oa_platform_no STRING COMMENT '外部系统平台编码',
	 oa_cust_no STRING COMMENT '担保公司编码',
	 oa_partner_no STRING COMMENT '合作方编码',
	 oa_fund_no STRING COMMENT '资金方编码',
	 oa_it_no STRING COMMENT '科技方编码',
	 is_project_finish STRING COMMENT '项目是否已结束,Y是N否',
	 project_finish_date STRING COMMENT '项目结束日期',
	 is_project_company STRING COMMENT '客户是否为企业,Y是C同时含有个人N否',
	 is_project_td STRING COMMENT '借据是否通道简版数据,Y是N否',
	 is_project_plan STRING COMMENT '借据是否有还款计划数据,Y有N否',
	 is_project_plan_update STRING COMMENT '借据是否有还款计划实还更新数据,Y有C有但未上线N否',
	 is_project_plan_reset STRING COMMENT '借据是否有还款计划缩期情况,Y有C有但未上线N否',
	 is_project_repay1 STRING COMMENT '借据是否有正常还款数据,Y有C有但未上线N否',
	 is_project_repay4 STRING COMMENT '借据是否有提前还款数据,Y有C有但未上线N否',
	 is_project_repay5 STRING COMMENT '借据是否有提前结清数据,Y有C有但未上线N否',
	 is_project_repay7 STRING COMMENT '借据是否有代偿还款数据,Y有C有但未上线N否',
	 is_project_total_repay7 STRING COMMENT '借据是否有累计代偿还款数据,Y有C有但未上线N否',
	 is_project_total_repay STRING COMMENT '借据是否有用户累计还款数据,Y有C有但未上线N否',
	 is_project_repay8 STRING COMMENT '借据是否有追偿还款数据,Y有C有但未上线N否',
	 is_project_repay7_finish STRING COMMENT '借据是否代偿时结清,Y是N否',
	 is_project_repay8_normal STRING COMMENT '借据追偿还款是否按正常还款提供,Y是N否',
	 is_result_fpd10 STRING COMMENT 'FPD10是否可用，Y是N否',
	 is_result_vintage STRING COMMENT 'vintage是否可用，Y是N否',
	 is_result_balance_distribution STRING COMMENT '余额分布是否可用，Y是N否',
	 remark STRING COMMENT '备注',
	 `status` STRING COMMENT '状态（0正常 1停用）',
	 check_status STRING COMMENT '审核状态 0新增审核状态，1修改项目审核中，2删除项目审核中，3（-）',
	 description STRING COMMENT '说明',
	 create_time STRING COMMENT '创建时间',
	 update_time STRING COMMENT '更新时间',
	 create_by STRING COMMENT '创建者',
	 update_by STRING COMMENT '更新人',
	 yw_user STRING COMMENT '业务负责人',
	 cw_user STRING COMMENT '财务负责人',
	 data_entry_time STRING COMMENT '产品数据最早进入时间',
	 channel_type STRING COMMENT '渠道方类型 1内部渠道方 2外部渠道方',
	 channel_name STRING COMMENT '渠道方',
	 product_type STRING COMMENT '产品类型',
	 product_type_no BIGINT COMMENT '产品类型编号',
	 dw_create_time TIMESTAMP COMMENT '数仓创建时间',
	 dw_update_time TIMESTAMP COMMENT '数仓更新时间',
	PRIMARY KEY(product_no)) STORED AS aliorc 
TBLPROPERTIES ('columnar.nested.type'='true',
	 'comment'='产品信息表');


-- 原：dim_base_indiv_info（个人客户维度）
-- 源库：prd_spark_db
-- 说明：个人客户维度表，包含客户基本信息、联系信息、客户状态等
CREATE TABLE IF NOT EXISTS dim_base_indiv_info_incr_t(
	id_card STRING NOT NULL COMMENT '身份证号（主键，跨来源唯一）',
	 indiv_cust_id BIGINT COMMENT '客户号（来自最优来源）',
	 id_card_type STRING COMMENT '证件类型',
	 id_address STRING COMMENT '身份证地址',
	 id_expiry_date STRING COMMENT '身份证失效日期',
	 id_province STRING COMMENT '身份证省份',
	 name STRING COMMENT '姓名',
	 gender STRING COMMENT '性别',
	 birth_date STRING COMMENT '出生日期',
	 mobile STRING COMMENT '手机号',
	 email STRING COMMENT '邮箱',
	 address STRING COMMENT '居住地',
	 detail_address STRING COMMENT '详细居住地址',
	 address_time STRING COMMENT '居住时长',
	 house_condition STRING COMMENT '住房情况',
	 annual_income STRING COMMENT '年收入',
	 is_pay_security STRING COMMENT '是否缴纳社保',
	 debts STRING COMMENT '是否有负债',
	 car_condition STRING COMMENT '车辆情况',
	 educational STRING COMMENT '学历',
	 industry STRING COMMENT '职业类别',
	 unit_name STRING COMMENT '工作单位',
	 unit_address STRING COMMENT '单位所在地',
	 unit_detail_address STRING COMMENT '单位详细地址',
	 unit_telphone STRING COMMENT '单位电话',
	 work_years STRING COMMENT '工作年限',
	 salary_date STRING COMMENT '工资发放日期',
	 marry_status STRING COMMENT '婚姻状况',
	 has_children STRING COMMENT '是否有子女',
	 agri_flag STRING COMMENT '是否农户',
	 contact_a_ref STRING COMMENT '联系人A关系',
	 contact_a_name STRING COMMENT '联系人A姓名',
	 contact_a_mobile STRING COMMENT '联系人A电话',
	 contact_b_ref STRING COMMENT '联系人B关系',
	 contact_b_name STRING COMMENT '联系人B姓名',
	 contact_b_mobile STRING COMMENT '联系人B电话',
	 data_source_list STRING COMMENT '该身份证在哪些来源存在（逗号拼接，如 01,02）',
	 dw_create_time STRING COMMENT '首次创建时间（取自明细表最早记录）',
	 dw_update_time STRING COMMENT '最近更新时间（取自明细表最新记录）',
	PRIMARY KEY(id_card)) STORED AS aliorc 
TBLPROPERTIES ('cdc.data.retain.hours'='24',
	 'acid.cdc.mode.enable'='false',
	 'acid.data.retain.hours'='24',
	 'columnar.nested.type'='true',
	 'comment'='客户维度汇总表（以身份证号为主键，跨来源合并）',
	 'transactional'='true',
	 'write.bucket.num'='16');


-- 原：dwd_cons_loan_payment_info_d  
-- 源库：prd_spark_db
-- 说明：消金原始放款信息，包含客户信息、放款信息等
-- 用于业务管控-消金-放款信息展示
CREATE TABLE IF NOT EXISTS dwd_cons_loan_payment_info_incr_delta(
	bill_app_no STRING NOT NULL COMMENT '借款申请编号',
	 loan_req_no STRING COMMENT '放款流水号',
	 indiv_cust_id STRING COMMENT '客户号',
	 product_no STRING COMMENT '产品编码',
	 recon_date STRING COMMENT '对账日期：格式YYYY-MM-DD',
	 recon_month STRING COMMENT '对账月份：格式YYYY-MM',
	 lend_status STRING COMMENT '放款状态 默认S成功',
	 loan_day STRING COMMENT '放款日期',
	 loan_month STRING COMMENT '放款月份：格式YYYY-MM',
	 due_date STRING COMMENT '到期日期：格式YYYY-MM-DD',
	 contract_amt DECIMAL(38,18) COMMENT '合同金额（元）',
	 loan_amt DECIMAL(38,18) COMMENT '放款金额（元）',
	 repay_day BIGINT COMMENT '还款日：每月还款日，1-28',
	 total_term BIGINT COMMENT '分期期数，单位：月 如： 1、3、6、12',
	 loan_status STRING COMMENT '借据状态：NOR-正常,OD-逾期中,FP-结清',
	 service_amt DECIMAL(38,18) COMMENT '前期服务费金额（元）',
	 guarantee_amt DECIMAL(38,18) COMMENT '前期担保费金额（元）',
	 margin_amt DECIMAL(38,18) COMMENT '前期保证金金额（元）',
	 compensate_amt DECIMAL(38,18) COMMENT '前期代偿金金额（元）',
	 act_service_amt DECIMAL(38,18) COMMENT '实收前期服务费金额（元）',
	 act_guarantee_amt DECIMAL(38,18) COMMENT '实收前期担保费金额（元）',
	 act_margin_amt DECIMAL(38,18) COMMENT '实收前期保证金金额（元）',
	 act_compensate_amt DECIMAL(38,18) COMMENT '实收前期代偿金金额（元）',
	 data_source STRING COMMENT '数据来源：0-生产数据；1-模拟数据',
	 remark STRING COMMENT '备注',
	 create_time STRING COMMENT '创建时间',
	 update_time STRING COMMENT '修改时间',
	 dw_create_time STRING COMMENT '数仓创建时间',
	 dw_update_time STRING COMMENT '数仓更新时间',
	PRIMARY KEY(bill_app_no)
) 
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyymm，和ods放款表一致') STORED AS aliorc 
TBLPROPERTIES ('acid.data.retain.hours'='0',
	 'cdc.data.retain.hours'='24',
	 'columnar.nested.type'='true',
	 'comment'='消金放款信息表',
	 'transactional'='true',
	 'acid.cdc.mode.enable'='false',
	 'write.bucket.num'='16');


-- 原：dwd_cons_loan_repay_info_d
-- 源库：prd_spark_db
-- 说明：消金原始还款信息，包含客户信息、还款信息等
-- 用于业务管控-消金-还款信息展示
CREATE TABLE IF NOT EXISTS dwd_cons_repay_info_incr_delta(
	tran_rp_no STRING NOT NULL COMMENT '还款流水号（业务主键）',
	 repay_type STRING COMMENT '还款类型：1-正常还款、2-非减免、3-减免、4-提前还款、5-提前结清、6-风险结清、7-代偿还款、8-追偿还款、9-对公还款、10-逾期还款、11-退货提前结清',
	 compensate_type STRING COMMENT '代偿类型：1-当期代偿，2-整笔代偿（当还款类型为7时必填）',
	 bill_app_no STRING COMMENT '借款申请编号',
	 recon_date STRING COMMENT '对账日期：格式YYYY-MM-DD',
	 recon_month STRING COMMENT '对账月份：格式YYYY-MM',
	 product_no STRING COMMENT '产品编码',
	 term BIGINT COMMENT '期次号',
	 repay_time STRING COMMENT '还款时间',
	 repay_date STRING COMMENT '还款日期（从repay_time提取）',
	 repay_month STRING COMMENT '还款月份：格式YYYY-MM',
	 repay_total_amt DECIMAL(38,18) COMMENT '还款总额',
	 print DECIMAL(38,18) COMMENT '还款本金',
	 int_amt DECIMAL(38,18) COMMENT '还款利息',
	 service_amt DECIMAL(38,18) COMMENT '还款服务费',
	 guarantee_amt DECIMAL(38,18) COMMENT '还款担保费',
	 margin_amt DECIMAL(38,18) COMMENT '还款保证金',
	 compensate_amt DECIMAL(38,18) COMMENT '还款代偿金',
	 oint_amt DECIMAL(38,18) COMMENT '还款罚息',
	 oguarantee_amt DECIMAL(38,18) COMMENT '还款担保费罚息',
	 define_amt DECIMAL(38,18) COMMENT '还款逾期违约金',
	 adv_define_amt DECIMAL(38,18) COMMENT '提前还款违约金',
	 reduce_print DECIMAL(38,18) COMMENT '减免本金',
	 reduce_int_amt DECIMAL(38,18) COMMENT '实还免息券贴利息',
	 reduce_service_amt DECIMAL(38,18) COMMENT '实还免息券贴服务费',
	 reduce_guarantee_amt DECIMAL(38,18) COMMENT '实还免息券贴担保费',
	 reduce_margin_amt DECIMAL(38,18) COMMENT '减免保证金',
	 reduce_compensate_amt DECIMAL(38,18) COMMENT '减免代偿金',
	 reduce_oint_amt DECIMAL(38,18) COMMENT '减免罚息',
	 reduce_oguarantee_amt DECIMAL(38,18) COMMENT '减免担保费罚息',
	 reduce_define_amt DECIMAL(38,18) COMMENT '减免逾期违约金',
	 reduce_adv_define_amt DECIMAL(38,18) COMMENT '减免提前还款违约金',
	 reduce_activity_amt DECIMAL(38,18) COMMENT '活动减免金额',
	 reduce_compliance_amt DECIMAL(38,18) COMMENT '合规减免金额',
	 reduce_total_amt DECIMAL(38,18) COMMENT '减免总额',
	 repay_method STRING COMMENT '还款方式：01-线上还款，02-线下还款，11-支付宝，12-微信支付，13-其他，21-对公还款，22-商户号',
	 remark STRING COMMENT '备注',
	 create_time STRING COMMENT '创建时间',
	 update_time STRING COMMENT '更新时间',
	 dw_create_time STRING COMMENT '数仓创建时间',
	 dw_update_time STRING COMMENT '数仓更新时间',
	PRIMARY KEY(tran_rp_no)
) 
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMMdd，直接继承ODS层分区') STORED AS aliorc 
TBLPROPERTIES ('cdc.data.retain.hours'='24',
	 'acid.cdc.mode.enable'='false',
	 'acid.data.retain.hours'='0',
	 'columnar.nested.type'='true',
	 'comment'='DWD层-消金还款信息明细表',
	 'transactional'='true',
	 'write.bucket.num'='16');


-- ============================================================
-- 原：dwd_cons_payment_performance_180d（消金放款180天表现表）
-- 目标表：分区表，pt=obs_date，格式yyyy-MM-dd
-- 主键：bill_app_no（分区表自动含pt）
-- 事务表，支持MERGE INTO
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_cons_payment_performance_incr_delta (                    
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    act_repay_date              STRING COMMENT '结清日期',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '还款表现-消金-业务管控',
    'write.bucket.num' = '32'
);


-- ============================================================
-- 原：003中间表 - 放款日快照（dwd_cons_payment_performance_incr_delta_003_tmp）
-- 数据范围：近3个月放款日，所有规则产品
-- 仅放款日初始快照，代偿/费率全为0，本金余额=放款金额
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_cons_payment_performance_incr_delta_003_tmp (
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    act_repay_date              STRING COMMENT '结清日期',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date=loan_day，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '003中间表-放款日快照（近3个月，所有规则产品）',
    'write.bucket.num' = '32'
);


-- ============================================================
-- 原：004中间表 - 新激活产品全量重算（dwd_cons_payment_performance_incr_delta_004_tmp）
-- 数据范围：2025-07-01~昨天，近2天新激活规则的产品
-- 完整计算代偿、担保费、本金余额等指标
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_cons_payment_performance_incr_delta_004_tmp (
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    act_repay_date              STRING COMMENT '结清日期',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '004中间表-新激活产品全量重算（2025-07至今，近2天激活产品）',
    'write.bucket.num' = '32'
);


-- ============================================================
-- 原：005中间表 - 近7天全量重算（dwd_cons_payment_performance_incr_delta_005_tmp）
-- 数据范围：近7天，所有规则产品
-- 完整计算代偿、担保费、本金余额等指标（同004逻辑，但范围不同）
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_cons_payment_performance_incr_delta_005_tmp (
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    act_repay_date              STRING COMMENT '结清日期',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '005中间表-近7天全量重算（所有规则产品）',
    'write.bucket.num' = '32'
);


-- ============================================================
-- 原：req_black_dwd_cons_loan_repay_info_d（业务管控-还款信息黑名单）
-- 源库：f_prd_spark_db
-- 主键：repay_series_no
-- 事务表，支持MERGE INTO
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_black_cons_repay_info_full_t (
    bill_app_no         STRING  COMMENT '借款申请编号',
    recon_date          STRING  COMMENT '对账日期：格式YYYY-MM-DD',
    recon_month         STRING  COMMENT '对账月份：格式YYYY-MM',
    term                BIGINT  COMMENT '期次号',
    indiv_cust_id       STRING  COMMENT '客户号',
    product_no          STRING  COMMENT '产品编码',
    repay_series_no     STRING  NOT NULL COMMENT '还款流水号',
    repay_time          STRING  COMMENT '还款时间',
    repay_date          STRING  COMMENT '还款日期',
    repay_month         STRING  COMMENT '还款月份',
    repay_total_amt     DECIMAL(38,18) COMMENT '还款总额（元）',
    princ               DECIMAL(38,18) COMMENT '还款本金（元）',
    int_amt             DECIMAL(38,18) COMMENT '还款利息（元）',
    service_amt         DECIMAL(38,18) COMMENT '还款服务费（元）',
    guarantee_amt       DECIMAL(38,18) COMMENT '还款担保费（元）',
    margin_amt          DECIMAL(38,18) COMMENT '还款保证金（元）',
    compensate_amt      DECIMAL(38,18) COMMENT '还款代偿金（元）',
    oint_amt            DECIMAL(38,18) COMMENT '还款罚息（元）',
    define_amt          DECIMAL(38,18) COMMENT '还款逾期违约金（元）',
    adv_define_amt      DECIMAL(38,18) COMMENT '提前还款违约金（元）',
    oguarantee_amt      DECIMAL(38,18) COMMENT '还款担保费罚息（元）',
    reduce_total_amt    DECIMAL(38,18) COMMENT '减免总计（元）',
    reduce_princ        DECIMAL(38,18) COMMENT '减免本金（元）',
    reduce_int_amt      DECIMAL(38,18) COMMENT '实还免息券贴利息（元）',
    reduce_service_amt  DECIMAL(38,18) COMMENT '实还免息券贴服务费（元）',
    reduce_guarantee_amt DECIMAL(38,18) COMMENT '实还免息券贴担保费（元）',
    reduce_margin_amt   DECIMAL(38,18) COMMENT '减免保证金（元）',
    reduce_compensate_amt DECIMAL(38,18) COMMENT '减免代偿金（元）',
    reduce_oint_amt     DECIMAL(38,18) COMMENT '减免罚息（元）',
    reduce_define_amt   DECIMAL(38,18) COMMENT '减免逾期违约金（元）',
    reduce_adv_define_amt DECIMAL(38,18) COMMENT '减免提前还款违约金（元）',
    reduce_oguarantee_amt DECIMAL(38,18) COMMENT '减免担保费罚息（元）',
    reduce_activity_amt DECIMAL(38,18) COMMENT '活动减免金额（元）',
    reduce_compliance_amt DECIMAL(38,18) COMMENT '合规减免金额（元）',
    repay_type          STRING  COMMENT '还款类型：1-正常还款、2-非减免、3-减免、4-提前还款、5-提前结清、6-风险结清、7-代偿还款、8-追偿还款、9-对公还款',
    remark              STRING  COMMENT '备注',
    loan_month          STRING  COMMENT '放款月份：格式YYYY-MM',
    dw_create_time      STRING  COMMENT '数仓创建时间',
    dw_update_time      STRING  COMMENT '数仓修改时间',
    create_time         STRING  COMMENT '创建时间',
    update_time         STRING  COMMENT '更新时间',
    repay_method        STRING  COMMENT '还款方式：01-线上还款；02-线下还款；11-支付宝；12-微信支付；13-其他；21-对公还款；22-商户号',
    compensate_type     STRING  COMMENT '代偿类型：1-当期代偿 2-整笔代偿（当还款类型为7时必填）',
    PRIMARY KEY (repay_series_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-消金还款信息黑名单',
    'write.bucket.num' = '16'
);


-- ============================================================
-- 原：req_dummy_dwd_cons_loan_repay_info_d（业务管控-人工解保还款信息）
-- 源库：f_prd_spark_db
-- 主键：repay_series_no
-- 事务表，支持MERGE INTO
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_dummy_cons_repay_info_full_t (
    bill_app_no         STRING  COMMENT '借款申请编号',
    recon_date          STRING  COMMENT '对账日期：格式YYYY-MM-DD',
    recon_month         STRING  COMMENT '对账月份：格式YYYY-MM',
    term                BIGINT  COMMENT '期次号',
    indiv_cust_id       STRING  COMMENT '客户号',
    product_no          STRING  COMMENT '产品编码',
    repay_series_no     STRING  NOT NULL COMMENT '还款流水号',
    repay_time          STRING  COMMENT '还款时间',
    repay_date          STRING  COMMENT '还款日期',
    repay_month         STRING  COMMENT '还款月份',
    repay_total_amt     DECIMAL(38,18) COMMENT '还款总额（元）',
    princ               DECIMAL(38,18) COMMENT '还款本金（元）',
    int_amt             DECIMAL(38,18) COMMENT '还款利息（元）',
    service_amt         DECIMAL(38,18) COMMENT '还款服务费（元）',
    guarantee_amt       DECIMAL(38,18) COMMENT '还款担保费（元）',
    margin_amt          DECIMAL(38,18) COMMENT '还款保证金（元）',
    compensate_amt      DECIMAL(38,18) COMMENT '还款代偿金（元）',
    oint_amt            DECIMAL(38,18) COMMENT '还款罚息（元）',
    define_amt          DECIMAL(38,18) COMMENT '还款逾期违约金（元）',
    adv_define_amt      DECIMAL(38,18) COMMENT '提前还款违约金（元）',
    oguarantee_amt      DECIMAL(38,18) COMMENT '还款担保费罚息（元）',
    reduce_total_amt    DECIMAL(38,18) COMMENT '减免总计（元）',
    reduce_princ        DECIMAL(38,18) COMMENT '减免本金（元）',
    reduce_int_amt      DECIMAL(38,18) COMMENT '实还免息券贴利息（元）',
    reduce_service_amt  DECIMAL(38,18) COMMENT '实还免息券贴服务费（元）',
    reduce_guarantee_amt DECIMAL(38,18) COMMENT '实还免息券贴担保费（元）',
    reduce_margin_amt   DECIMAL(38,18) COMMENT '减免保证金（元）',
    reduce_compensate_amt DECIMAL(38,18) COMMENT '减免代偿金（元）',
    reduce_oint_amt     DECIMAL(38,18) COMMENT '减免罚息（元）',
    reduce_define_amt   DECIMAL(38,18) COMMENT '减免逾期违约金（元）',
    reduce_adv_define_amt DECIMAL(38,18) COMMENT '减免提前还款违约金（元）',
    reduce_oguarantee_amt DECIMAL(38,18) COMMENT '减免担保费罚息（元）',
    reduce_activity_amt DECIMAL(38,18) COMMENT '活动减免金额（元）',
    reduce_compliance_amt DECIMAL(38,18) COMMENT '合规减免金额（元）',
    repay_type          STRING  COMMENT '还款类型：1-正常还款、2-非减免、3-减免、4-提前还款、5-提前结清、6-风险结清、7-代偿还款、8-追偿还款、9-对公还款',
    remark              STRING  COMMENT '备注',
    loan_month          STRING  COMMENT '放款月份：格式YYYY-MM',
    dw_create_time      STRING  COMMENT '数仓创建时间',
    dw_update_time      STRING  COMMENT '数仓修改时间',
    create_time         STRING  COMMENT '创建时间',
    update_time         STRING  COMMENT '更新时间',
    repay_method        STRING  COMMENT '还款方式：01-线上还款；02-线下还款；11-支付宝；12-微信支付；13-其他；21-对公还款；22-商户号',
    compensate_type     STRING  COMMENT '代偿类型：1-当期代偿 2-整笔代偿（当还款类型为7时必填）',
    PRIMARY KEY (repay_series_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-消金人工解保还款信息',
    'write.bucket.num' = '16'
);



-- 源：dwd_cons_loan_repay_plan_d
-- 主键：bill_app_no,term
-- 事务表，支持MERGE INTO
-- 原库：prd_spark_db
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_cons_loan_repay_plan_incr_delta
(
    bill_app_no                      STRING NOT NULL COMMENT '贷款申请编号'
    ,term                            BIGINT NOT NULL COMMENT '期数'
    ,recon_date                      STRING COMMENT '入账日期'
    ,product_no                      STRING COMMENT '产品编号'
    ,due_date                        STRING COMMENT '应还日期'
    ,act_repay_date                  STRING COMMENT '实际还款日期（流水优先，兼容字段）'
    ,plan_act_repay_date             STRING COMMENT '计划口径-实际还款日期'
    ,repay_act_repay_date            STRING COMMENT '还款口径-实际还款日期'
    ,plan_status                     STRING COMMENT '计划原始状态'
    ,current_status                  STRING COMMENT '综合派生状态'
    ,principal                       DECIMAL(38,18) COMMENT '应还本金'
    ,int_amt                         DECIMAL(38,18) COMMENT '应还利息'
    ,service_amt                     DECIMAL(38,18) COMMENT '应还服务费'
    ,guarantee_amt                   DECIMAL(38,18) COMMENT '应还担保费'
    ,margin_amt                      DECIMAL(38,18) COMMENT '应还保证金'
    ,compensate_amt                  DECIMAL(38,18) COMMENT '应还补偿金'
    ,oint_amt                        DECIMAL(38,18) COMMENT '应还逾期利息'
    ,define_amt                      DECIMAL(38,18) COMMENT '应还自定义金额'
    ,adv_define_amt                  DECIMAL(38,18) COMMENT '应还提前自定义金额'
    ,oguarantee_amt                  DECIMAL(38,18) COMMENT '应还原担保费'
    ,repay_total_amt                 DECIMAL(38,18) COMMENT '应还总金额'
    ,plan_act_print                  DECIMAL(38,18) COMMENT '计划实还本金'
    ,plan_act_int_amt                DECIMAL(38,18) COMMENT '计划实还利息'
    ,plan_act_service_amt            DECIMAL(38,18) COMMENT '计划实还服务费'
    ,plan_act_guarantee_amt          DECIMAL(38,18) COMMENT '计划实还担保费'
    ,plan_act_margin_amt             DECIMAL(38,18) COMMENT '计划实还保证金'
    ,plan_act_compensate_amt         DECIMAL(38,18) COMMENT '计划实还补偿金'
    ,plan_act_oint_amt               DECIMAL(38,18) COMMENT '计划实还逾期利息'
    ,plan_act_define_amt             DECIMAL(38,18) COMMENT '计划实还自定义金额'
    ,plan_act_adv_define_amt         DECIMAL(38,18) COMMENT '计划实还提前自定义金额'
    ,plan_act_oguarantee_amt         DECIMAL(38,18) COMMENT '计划实还原担保费'
    ,plan_act_repay_total_amt        DECIMAL(38,18) COMMENT '计划实还总金额'
    ,repay_act_print                 DECIMAL(38,18) COMMENT '流水实还本金'
    ,repay_act_int_amt               DECIMAL(38,18) COMMENT '流水实还利息'
    ,repay_act_service_amt           DECIMAL(38,18) COMMENT '流水实还服务费'
    ,repay_act_guarantee_amt         DECIMAL(38,18) COMMENT '流水实还担保费'
    ,repay_act_margin_amt            DECIMAL(38,18) COMMENT '流水实还保证金'
    ,repay_act_compensate_amt        DECIMAL(38,18) COMMENT '流水实还补偿金'
    ,repay_act_oint_amt              DECIMAL(38,18) COMMENT '流水实还逾期利息'
    ,repay_act_define_amt            DECIMAL(38,18) COMMENT '流水实还自定义金额'
    ,repay_act_adv_define_amt        DECIMAL(38,18) COMMENT '流水实还提前自定义金额'
    ,repay_act_oguarantee_amt        DECIMAL(38,18) COMMENT '流水实还原担保费'
    ,repay_act_repay_total_amt       DECIMAL(38,18) COMMENT '流水实还总金额'
    ,fix_act_repay_date              STRING COMMENT '修复口径-实际还款日期'
    ,fix_act_print                   DECIMAL(38,18) COMMENT '修复口径-实还本金'
    ,fix_act_int_amt                 DECIMAL(38,18) COMMENT '修复口径-实还利息'
    ,fix_act_service_amt             DECIMAL(38,18) COMMENT '修复口径-实还服务费'
    ,fix_act_guarantee_amt           DECIMAL(38,18) COMMENT '修复口径-实还担保费'
    ,fix_act_margin_amt              DECIMAL(38,18) COMMENT '修复口径-实还保证金'
    ,fix_act_compensate_amt          DECIMAL(38,18) COMMENT '修复口径-实还补偿金'
    ,fix_act_oint_amt                DECIMAL(38,18) COMMENT '修复口径-实还逾期利息'
    ,fix_act_define_amt              DECIMAL(38,18) COMMENT '修复口径-实还自定义金额'
    ,fix_act_adv_define_amt          DECIMAL(38,18) COMMENT '修复口径-实还提前自定义金额'
    ,fix_act_oguarantee_amt          DECIMAL(38,18) COMMENT '修复口径-实还原担保费'
    ,fix_act_repay_total_amt         DECIMAL(38,18) COMMENT '修复口径-实还总金额'
    ,plan_is_compensate              STRING COMMENT '计划是否代偿'
    ,plan_cpst_type                  STRING COMMENT '计划代偿类型'
    ,plan_cpst_date                  STRING COMMENT '计划代偿日期'
    ,plan_cpst_amt                   DECIMAL(38,18) COMMENT '计划代偿金额'
    ,plan_cpst_print                 DECIMAL(38,18) COMMENT '计划代偿本金'
    ,plan_cpst_int_amt               DECIMAL(38,18) COMMENT '计划代偿利息'
    ,plan_cpst_oint_amt              DECIMAL(38,18) COMMENT '计划代偿逾期利息'
    ,repay_has_cpst                  STRING COMMENT '流水是否代偿'
    ,repay_cpst_type                 STRING COMMENT '流水代偿类型'
    ,repay_cpst_date                 STRING COMMENT '流水代偿日期'
    ,repay_cpst_amt                  DECIMAL(38,18) COMMENT '流水代偿金额'
    ,repay_cpst_print                DECIMAL(38,18) COMMENT '流水代偿本金'
    ,repay_cpst_int_amt              DECIMAL(38,18) COMMENT '流水代偿利息'
    ,repay_cpst_service_amt          DECIMAL(38,18) COMMENT '流水代偿服务费'
    ,repay_cpst_guarantee_amt        DECIMAL(38,18) COMMENT '流水代偿担保费'
    ,repay_cpst_oint_amt             DECIMAL(38,18) COMMENT '流水代偿逾期利息'
    ,repay_cpst_define_amt           DECIMAL(38,18) COMMENT '流水代偿自定义金额'
    ,fix_is_compensate               STRING COMMENT '修复口径-是否代偿'
    ,fix_cpst_type                   STRING COMMENT '修复口径-代偿类型'
    ,fix_cpst_date                   STRING COMMENT '修复口径-代偿日期'
    ,fix_cpst_amt                    DECIMAL(38,18) COMMENT '修复口径-代偿金额'
    ,fix_cpst_print                  DECIMAL(38,18) COMMENT '修复口径-代偿本金'
    ,fix_cpst_int_amt                DECIMAL(38,18) COMMENT '修复口径-代偿利息'
    ,fix_cpst_oint_amt               DECIMAL(38,18) COMMENT '修复口径-代偿逾期利息'
    ,repay_has_recov                 STRING COMMENT '流水是否追偿'
    ,repay_recov_date                STRING COMMENT '流水追偿日期'
    ,repay_recov_amt                 DECIMAL(38,18) COMMENT '流水追偿金额'
    ,repay_recov_print               DECIMAL(38,18) COMMENT '流水追偿本金'
    ,repay_recov_int_amt             DECIMAL(38,18) COMMENT '流水追偿利息'
    ,repay_recov_service_amt         DECIMAL(38,18) COMMENT '流水追偿服务费'
    ,repay_recov_guarantee_amt       DECIMAL(38,18) COMMENT '流水追偿担保费'
    ,repay_recov_oint_amt            DECIMAL(38,18) COMMENT '流水追偿逾期利息'
    ,repay_recov_define_amt          DECIMAL(38,18) COMMENT '流水追偿自定义金额'
    ,plan_act_reduce_print           DECIMAL(38,18) COMMENT '计划减免本金'
    ,plan_act_reduce_int_amt         DECIMAL(38,18) COMMENT '计划减免利息'
    ,plan_act_reduce_service_amt     DECIMAL(38,18) COMMENT '计划减免服务费'
    ,plan_act_reduce_guarantee_amt   DECIMAL(38,18) COMMENT '计划减免担保费'
    ,plan_act_reduce_margin_amt      DECIMAL(38,18) COMMENT '计划减免保证金'
    ,plan_act_reduce_compensate_amt  DECIMAL(38,18) COMMENT '计划减免补偿金'
    ,plan_act_reduce_oint_amt        DECIMAL(38,18) COMMENT '计划减免逾期利息'
    ,plan_act_reduce_define_amt      DECIMAL(38,18) COMMENT '计划减免自定义金额'
    ,plan_act_reduce_adv_define_amt  DECIMAL(38,18) COMMENT '计划减免提前自定义金额'
    ,plan_act_reduce_oguarantee_amt  DECIMAL(38,18) COMMENT '计划减免原担保费'
    ,plan_act_reduce_total_amt       DECIMAL(38,18) COMMENT '计划减免总金额'
    ,repay_act_reduce_print          DECIMAL(38,18) COMMENT '流水减免本金'
    ,repay_act_reduce_int_amt        DECIMAL(38,18) COMMENT '流水减免利息'
    ,repay_act_reduce_service_amt    DECIMAL(38,18) COMMENT '流水减免服务费'
    ,repay_act_reduce_guarantee_amt  DECIMAL(38,18) COMMENT '流水减免担保费'
    ,repay_act_reduce_margin_amt     DECIMAL(38,18) COMMENT '流水减免保证金'
    ,repay_act_reduce_compensate_amt DECIMAL(38,18) COMMENT '流水减免补偿金'
    ,repay_act_reduce_oint_amt       DECIMAL(38,18) COMMENT '流水减免逾期利息'
    ,repay_act_reduce_define_amt     DECIMAL(38,18) COMMENT '流水减免自定义金额'
    ,repay_act_reduce_adv_define_amt DECIMAL(38,18) COMMENT '流水减免提前自定义金额'
    ,repay_act_reduce_oguarantee_amt DECIMAL(38,18) COMMENT '流水减免原担保费'
    ,repay_act_reduce_total_amt      DECIMAL(38,18) COMMENT '流水减免总金额'
    ,fix_act_reduce_print            DECIMAL(38,18) COMMENT '修复口径-减免本金'
    ,fix_act_reduce_int_amt          DECIMAL(38,18) COMMENT '修复口径-减免利息'
    ,fix_act_reduce_service_amt      DECIMAL(38,18) COMMENT '修复口径-减免服务费'
    ,fix_act_reduce_guarantee_amt    DECIMAL(38,18) COMMENT '修复口径-减免担保费'
    ,fix_act_reduce_margin_amt       DECIMAL(38,18) COMMENT '修复口径-减免保证金'
    ,fix_act_reduce_compensate_amt   DECIMAL(38,18) COMMENT '修复口径-减免补偿金'
    ,fix_act_reduce_oint_amt         DECIMAL(38,18) COMMENT '修复口径-减免逾期利息'
    ,fix_act_reduce_define_amt       DECIMAL(38,18) COMMENT '修复口径-减免自定义金额'
    ,fix_act_reduce_adv_define_amt   DECIMAL(38,18) COMMENT '修复口径-减免提前自定义金额'
    ,fix_act_reduce_oguarantee_amt   DECIMAL(38,18) COMMENT '修复口径-减免原担保费'
    ,fix_act_reduce_total_amt        DECIMAL(38,18) COMMENT '修复口径-减免总金额'
    ,remark                          STRING COMMENT '备注'
    ,create_time                     STRING COMMENT '创建时间'
    ,update_time                     STRING COMMENT '更新时间'
    ,dw_create_time                  TIMESTAMP COMMENT '数据仓库创建时间'
    ,dw_update_time                  TIMESTAMP COMMENT '数据仓库更新时间'
    ,dw_batch_date                   STRING COMMENT '数据来源批次日期'
    ,PRIMARY KEY (bill_app_no,term)
)
STORED AS aliorc
TBLPROPERTIES (
    'cdc.data.retain.hours' = '24'
    ,'acid.cdc.mode.enable' = 'false'
    ,'acid.data.retain.hours' = '24'
    ,'columnar.nested.type' = 'true'
    ,'comment' = 'DWD层-消金还款计划明细（非分区事务表）'
    ,'transactional' = 'true'
    ,'write.bucket.num' = '16'
)
;


-- ============================================================
-- 原：dwd_auto_balance_repay_info_d（车贷还款表现表）
-- 源库：f_prd_spark_db
-- 目标表：分区表，pt=obs_date，格式yyyy-MM-dd
-- 主键：bill_app_no（分区表自动含pt）
-- 事务表，支持MERGE INTO
-- 与消金180d表现表的区别：无loan_amt字段
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_auto_balance_repay_info_incr_delta (
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    act_repay_date              STRING COMMENT '结清日期',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '还款表现-车贷-业务管控',
    'write.bucket.num' = '4'
);


-- ============================================================
-- 007中间表 - 车贷新激活产品全量重算（dwd_req_auto_balance_repay_info_incr_delta_007_tmp）
-- 数据范围：2025-07-01~昨天，近2天新激活规则的产品
-- 完整计算代偿、担保费、本金余额等指标
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_auto_balance_repay_info_incr_delta_007_tmp (
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    act_repay_date              STRING COMMENT '结清日期',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '007中间表-车贷新激活产品全量重算（2025-07至今，近2天激活产品）',
    'write.bucket.num' = '4'
);


-- ============================================================
-- 008中间表 - 车贷近7天全量重算（dwd_req_auto_balance_repay_info_incr_delta_008_tmp）
-- 数据范围：近7天，所有规则产品
-- 完整计算代偿、担保费、本金余额等指标
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_auto_balance_repay_info_incr_delta_008_tmp (
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                    STRING COMMENT '观察日期',
    product_no                  STRING COMMENT '产品编码',
    princ_bal_info              DECIMAL(38,18) COMMENT '客方在贷',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷',
    dw_insert_time              STRING COMMENT '数据写入时间',
    obs_month                   STRING COMMENT '观察月份',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    act_repay_date              STRING COMMENT '结清日期',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '当前实还担保金额',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保费',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT COMMENT '累计代偿笔数',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING COMMENT '截止观察点前最后一次代偿时间',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '008中间表-车贷近7天全量重算（所有规则产品）',
    'write.bucket.num' = '4'
);



-- 原：dwd_auto_zf_rent_plan_d
-- 源库：prd_spark_db
CREATE TABLE IF NOT EXISTS prod_dw_01.dwd_auto_loan_repay_plan_incr_delta
(
    bill_app_no                      STRING NOT NULL COMMENT '贷款申请编号'
    ,term                            BIGINT NOT NULL COMMENT '期数'
    ,recon_date                      STRING COMMENT '入账日期'
    ,product_no                      STRING COMMENT '产品编号'
    ,due_date                        STRING COMMENT '应还日期'
    ,act_repay_date                  STRING COMMENT '实际还款日期（流水优先，兼容字段）'
    ,plan_act_repay_date             STRING COMMENT '计划口径-实际还款日期'
    ,repay_act_repay_date            STRING COMMENT '还款口径-实际还款日期'
    ,plan_status                     STRING COMMENT '计划原始状态'
    ,current_status                  STRING COMMENT '综合派生状态'
    ,principal                       DECIMAL(38,18) COMMENT '应还本金'
    ,int_amt                         DECIMAL(38,18) COMMENT '应还利息'
    ,service_amt                     DECIMAL(38,18) COMMENT '应还服务费'
    ,guarantee_amt                   DECIMAL(38,18) COMMENT '应还担保费'
    ,margin_amt                      DECIMAL(38,18) COMMENT '应还保证金'
    ,compensate_amt                  DECIMAL(38,18) COMMENT '应还补偿金'
    ,oint_amt                        DECIMAL(38,18) COMMENT '应还逾期利息'
    ,define_amt                      DECIMAL(38,18) COMMENT '应还自定义金额'
    ,adv_define_amt                  DECIMAL(38,18) COMMENT '应还提前自定义金额'
    ,oguarantee_amt                  DECIMAL(38,18) COMMENT '应还原担保费'
    ,repay_total_amt                 DECIMAL(38,18) COMMENT '应还总金额'
    ,plan_act_print                  DECIMAL(38,18) COMMENT '计划实还本金'
    ,plan_act_int_amt                DECIMAL(38,18) COMMENT '计划实还利息'
    ,plan_act_service_amt            DECIMAL(38,18) COMMENT '计划实还服务费'
    ,plan_act_guarantee_amt          DECIMAL(38,18) COMMENT '计划实还担保费'
    ,plan_act_margin_amt             DECIMAL(38,18) COMMENT '计划实还保证金'
    ,plan_act_compensate_amt         DECIMAL(38,18) COMMENT '计划实还补偿金'
    ,plan_act_oint_amt               DECIMAL(38,18) COMMENT '计划实还逾期利息'
    ,plan_act_define_amt             DECIMAL(38,18) COMMENT '计划实还自定义金额'
    ,plan_act_adv_define_amt         DECIMAL(38,18) COMMENT '计划实还提前自定义金额'
    ,plan_act_oguarantee_amt         DECIMAL(38,18) COMMENT '计划实还原担保费'
    ,plan_act_repay_total_amt        DECIMAL(38,18) COMMENT '计划实还总金额'
    ,repay_act_print                 DECIMAL(38,18) COMMENT '流水实还本金'
    ,repay_act_int_amt               DECIMAL(38,18) COMMENT '流水实还利息'
    ,repay_act_service_amt           DECIMAL(38,18) COMMENT '流水实还服务费'
    ,repay_act_guarantee_amt         DECIMAL(38,18) COMMENT '流水实还担保费'
    ,repay_act_margin_amt            DECIMAL(38,18) COMMENT '流水实还保证金'
    ,repay_act_compensate_amt        DECIMAL(38,18) COMMENT '流水实还补偿金'
    ,repay_act_oint_amt              DECIMAL(38,18) COMMENT '流水实还逾期利息'
    ,repay_act_define_amt            DECIMAL(38,18) COMMENT '流水实还自定义金额'
    ,repay_act_adv_define_amt        DECIMAL(38,18) COMMENT '流水实还提前自定义金额'
    ,repay_act_oguarantee_amt        DECIMAL(38,18) COMMENT '流水实还原担保费'
    ,repay_act_repay_total_amt       DECIMAL(38,18) COMMENT '流水实还总金额'
    ,fix_act_repay_date              STRING COMMENT '修复口径-实际还款日期'
    ,fix_act_print                   DECIMAL(38,18) COMMENT '修复口径-实还本金'
    ,fix_act_int_amt                 DECIMAL(38,18) COMMENT '修复口径-实还利息'
    ,fix_act_service_amt             DECIMAL(38,18) COMMENT '修复口径-实还服务费'
    ,fix_act_guarantee_amt           DECIMAL(38,18) COMMENT '修复口径-实还担保费'
    ,fix_act_margin_amt              DECIMAL(38,18) COMMENT '修复口径-实还保证金'
    ,fix_act_compensate_amt          DECIMAL(38,18) COMMENT '修复口径-实还补偿金'
    ,fix_act_oint_amt                DECIMAL(38,18) COMMENT '修复口径-实还逾期利息'
    ,fix_act_define_amt              DECIMAL(38,18) COMMENT '修复口径-实还自定义金额'
    ,fix_act_adv_define_amt          DECIMAL(38,18) COMMENT '修复口径-实还提前自定义金额'
    ,fix_act_oguarantee_amt          DECIMAL(38,18) COMMENT '修复口径-实还原担保费'
    ,fix_act_repay_total_amt         DECIMAL(38,18) COMMENT '修复口径-实还总金额'
    ,plan_is_compensate              STRING COMMENT '计划是否代偿'
    ,plan_cpst_type                  STRING COMMENT '计划代偿类型'
    ,plan_cpst_date                  STRING COMMENT '计划代偿日期'
    ,plan_cpst_amt                   DECIMAL(38,18) COMMENT '计划代偿金额'
    ,plan_cpst_print                 DECIMAL(38,18) COMMENT '计划代偿本金'
    ,plan_cpst_int_amt               DECIMAL(38,18) COMMENT '计划代偿利息'
    ,plan_cpst_oint_amt              DECIMAL(38,18) COMMENT '计划代偿逾期利息'
    ,repay_has_cpst                  STRING COMMENT '流水是否代偿'
    ,repay_cpst_type                 STRING COMMENT '流水代偿类型'
    ,repay_cpst_date                 STRING COMMENT '流水代偿日期'
    ,repay_cpst_amt                  DECIMAL(38,18) COMMENT '流水代偿金额'
    ,repay_cpst_print                DECIMAL(38,18) COMMENT '流水代偿本金'
    ,repay_cpst_int_amt              DECIMAL(38,18) COMMENT '流水代偿利息'
    ,repay_cpst_service_amt          DECIMAL(38,18) COMMENT '流水代偿服务费'
    ,repay_cpst_guarantee_amt        DECIMAL(38,18) COMMENT '流水代偿担保费'
    ,repay_cpst_oint_amt             DECIMAL(38,18) COMMENT '流水代偿逾期利息'
    ,repay_cpst_define_amt           DECIMAL(38,18) COMMENT '流水代偿自定义金额'
    ,fix_is_compensate               STRING COMMENT '修复口径-是否代偿'
    ,fix_cpst_type                   STRING COMMENT '修复口径-代偿类型'
    ,fix_cpst_date                   STRING COMMENT '修复口径-代偿日期'
    ,fix_cpst_amt                    DECIMAL(38,18) COMMENT '修复口径-代偿金额'
    ,fix_cpst_print                  DECIMAL(38,18) COMMENT '修复口径-代偿本金'
    ,fix_cpst_int_amt                DECIMAL(38,18) COMMENT '修复口径-代偿利息'
    ,fix_cpst_oint_amt               DECIMAL(38,18) COMMENT '修复口径-代偿逾期利息'
    ,repay_has_recov                 STRING COMMENT '流水是否追偿'
    ,repay_recov_date                STRING COMMENT '流水追偿日期'
    ,repay_recov_amt                 DECIMAL(38,18) COMMENT '流水追偿金额'
    ,repay_recov_print               DECIMAL(38,18) COMMENT '流水追偿本金'
    ,repay_recov_int_amt             DECIMAL(38,18) COMMENT '流水追偿利息'
    ,repay_recov_service_amt         DECIMAL(38,18) COMMENT '流水追偿服务费'
    ,repay_recov_guarantee_amt       DECIMAL(38,18) COMMENT '流水追偿担保费'
    ,repay_recov_oint_amt            DECIMAL(38,18) COMMENT '流水追偿逾期利息'
    ,repay_recov_define_amt          DECIMAL(38,18) COMMENT '流水追偿自定义金额'
    ,plan_act_reduce_print           DECIMAL(38,18) COMMENT '计划减免本金'
    ,plan_act_reduce_int_amt         DECIMAL(38,18) COMMENT '计划减免利息'
    ,plan_act_reduce_service_amt     DECIMAL(38,18) COMMENT '计划减免服务费'
    ,plan_act_reduce_guarantee_amt   DECIMAL(38,18) COMMENT '计划减免担保费'
    ,plan_act_reduce_margin_amt      DECIMAL(38,18) COMMENT '计划减免保证金'
    ,plan_act_reduce_compensate_amt  DECIMAL(38,18) COMMENT '计划减免补偿金'
    ,plan_act_reduce_oint_amt        DECIMAL(38,18) COMMENT '计划减免逾期利息'
    ,plan_act_reduce_define_amt      DECIMAL(38,18) COMMENT '计划减免自定义金额'
    ,plan_act_reduce_adv_define_amt  DECIMAL(38,18) COMMENT '计划减免提前自定义金额'
    ,plan_act_reduce_oguarantee_amt  DECIMAL(38,18) COMMENT '计划减免原担保费'
    ,plan_act_reduce_total_amt       DECIMAL(38,18) COMMENT '计划减免总金额'
    ,repay_act_reduce_print          DECIMAL(38,18) COMMENT '流水减免本金'
    ,repay_act_reduce_int_amt        DECIMAL(38,18) COMMENT '流水减免利息'
    ,repay_act_reduce_service_amt    DECIMAL(38,18) COMMENT '流水减免服务费'
    ,repay_act_reduce_guarantee_amt  DECIMAL(38,18) COMMENT '流水减免担保费'
    ,repay_act_reduce_margin_amt     DECIMAL(38,18) COMMENT '流水减免保证金'
    ,repay_act_reduce_compensate_amt DECIMAL(38,18) COMMENT '流水减免补偿金'
    ,repay_act_reduce_oint_amt       DECIMAL(38,18) COMMENT '流水减免逾期利息'
    ,repay_act_reduce_define_amt     DECIMAL(38,18) COMMENT '流水减免自定义金额'
    ,repay_act_reduce_adv_define_amt DECIMAL(38,18) COMMENT '流水减免提前自定义金额'
    ,repay_act_reduce_oguarantee_amt DECIMAL(38,18) COMMENT '流水减免原担保费'
    ,repay_act_reduce_total_amt      DECIMAL(38,18) COMMENT '流水减免总金额'
    ,fix_act_reduce_print            DECIMAL(38,18) COMMENT '修复口径-减免本金'
    ,fix_act_reduce_int_amt          DECIMAL(38,18) COMMENT '修复口径-减免利息'
    ,fix_act_reduce_service_amt      DECIMAL(38,18) COMMENT '修复口径-减免服务费'
    ,fix_act_reduce_guarantee_amt    DECIMAL(38,18) COMMENT '修复口径-减免担保费'
    ,fix_act_reduce_margin_amt       DECIMAL(38,18) COMMENT '修复口径-减免保证金'
    ,fix_act_reduce_compensate_amt   DECIMAL(38,18) COMMENT '修复口径-减免补偿金'
    ,fix_act_reduce_oint_amt         DECIMAL(38,18) COMMENT '修复口径-减免逾期利息'
    ,fix_act_reduce_define_amt       DECIMAL(38,18) COMMENT '修复口径-减免自定义金额'
    ,fix_act_reduce_adv_define_amt   DECIMAL(38,18) COMMENT '修复口径-减免提前自定义金额'
    ,fix_act_reduce_oguarantee_amt   DECIMAL(38,18) COMMENT '修复口径-减免原担保费'
    ,fix_act_reduce_total_amt        DECIMAL(38,18) COMMENT '修复口径-减免总金额'
    ,remark                          STRING COMMENT '备注'
    ,create_time                     STRING COMMENT '创建时间'
    ,update_time                     STRING COMMENT '更新时间'
    ,dw_create_time                  TIMESTAMP COMMENT '数据仓库创建时间'
    ,dw_update_time                  TIMESTAMP COMMENT '数据仓库更新时间'
    ,dw_batch_date                   STRING COMMENT '数据来源批次日期'
    ,PRIMARY KEY (bill_app_no,term)
)
STORED AS aliorc
TBLPROPERTIES ('cdc.data.retain.hours' = '24','acid.cdc.mode.enable' = 'false','acid.data.retain.hours' = '0','columnar.nested.type' = 'true','comment' = 'DWD层-车贷还款计划明细（非分区事务表）','transactional' = 'true','write.bucket.num' = '16')
;


-- ============================================================
-- 原：req_black_dwd_auto_oapi_repay_info_d（车贷还款信息黑名单）
-- 源库：f_prd_spark_db
-- 主键：tran_rp_no
-- 事务表，无分区
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_black_auto_oapi_repay_info_full_t (
    id                          STRING      COMMENT '主键',
    recon_date                  STRING      COMMENT '账单日期',
    product_no                  STRING      COMMENT '产品编码',
    bill_app_no                 STRING      COMMENT '借款申请编号',
    term                        BIGINT      COMMENT '期次号',
    tran_rp_no                  STRING NOT NULL COMMENT '还款流水号（主键）',
    created_by                  STRING      COMMENT '创建用户ID',
    last_modified_by            STRING      COMMENT '修改用户ID',
    tenant_id                   STRING      COMMENT '租户ID',
    act_repay_date              STRING      COMMENT '实际还款日',
    repay_type                  STRING      COMMENT '还款类型:1-正常还款 2-提前还款 3-提前结清 4-代偿还款 5-追偿还款',
    print                       DECIMAL(38,18) COMMENT '实还本金',
    int_amt                     DECIMAL(38,18) COMMENT '实还利息',
    service_amt                 DECIMAL(38,18) COMMENT '实还服务费',
    guarantee_fee               DECIMAL(38,18) COMMENT '实还担保费',
    margin_amt                  DECIMAL(38,18) COMMENT '实还保证金',
    compensate_amt              DECIMAL(38,18) COMMENT '实还代偿金',
    oint_amt                    DECIMAL(38,18) COMMENT '实还罚息',
    define_amt                  DECIMAL(38,18) COMMENT '实还逾期违约金',
    adv_define_amt              DECIMAL(38,18) COMMENT '实还提前还款违约金',
    repay_total_amt             DECIMAL(38,18) COMMENT '实还总计',
    remark                      STRING      COMMENT '备注',
    channel_id                  STRING      COMMENT '渠道id',
    trd_id                      STRING      COMMENT '批次号',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '修改时间',
    dw_update_time              STRING      COMMENT '数仓更新时间',
    dw_create_time              STRING      COMMENT '数仓创建时间',
    PRIMARY KEY (tran_rp_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-车贷还款信息黑名单',
    'write.bucket.num' = '16'
);


-- ============================================================
-- 原：req_dummy_dwd_auto_oapi_repay_info_d（车贷人工解保还款信息）
-- 源库：f_prd_spark_db
-- 主键：tran_rp_no
-- 事务表，无分区
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_dummy_auto_oapi_repay_info_full_t (
    id                          STRING      COMMENT '主键',
    recon_date                  STRING      COMMENT '账单日期',
    product_no                  STRING      COMMENT '产品编码',
    bill_app_no                 STRING      COMMENT '借款申请编号',
    term                        BIGINT      COMMENT '期次号',
    tran_rp_no                  STRING NOT NULL COMMENT '还款流水号（主键）',
    created_by                  STRING      COMMENT '创建用户ID',
    last_modified_by            STRING      COMMENT '修改用户ID',
    tenant_id                   STRING      COMMENT '租户ID',
    act_repay_date              STRING      COMMENT '实际还款日',
    repay_type                  STRING      COMMENT '还款类型:1-正常还款 2-提前还款 3-提前结清 4-代偿还款 5-追偿还款',
    print                       DECIMAL(38,18) COMMENT '实还本金',
    int_amt                     DECIMAL(38,18) COMMENT '实还利息',
    service_amt                 DECIMAL(38,18) COMMENT '实还服务费',
    guarantee_fee               DECIMAL(38,18) COMMENT '实还担保费',
    margin_amt                  DECIMAL(38,18) COMMENT '实还保证金',
    compensate_amt              DECIMAL(38,18) COMMENT '实还代偿金',
    oint_amt                    DECIMAL(38,18) COMMENT '实还罚息',
    define_amt                  DECIMAL(38,18) COMMENT '实还逾期违约金',
    adv_define_amt              DECIMAL(38,18) COMMENT '实还提前还款违约金',
    repay_total_amt             DECIMAL(38,18) COMMENT '实还总计',
    remark                      STRING      COMMENT '备注',
    channel_id                  STRING      COMMENT '渠道id',
    trd_id                      STRING      COMMENT '批次号',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '修改时间',
    dw_update_time              STRING      COMMENT '数仓更新时间',
    dw_create_time              STRING      COMMENT '数仓创建时间',
    PRIMARY KEY (tran_rp_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-车贷人工解保还款信息',
    'write.bucket.num' = '16'
);




-- ============================================================
-- 原：f_prd_spark_db.ln_loan_info（fake库-消金放款信息表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=recon_date，格式yyyy-MM-dd
-- 主键：apply_no（分区表自动含pt）
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_cons_loan_info_incr_delta (
    id                          BIGINT      COMMENT '物理主键',
    recon_date                  STRING      COMMENT '对账日期，格式yyyy-MM-dd',
    product_no                  STRING      COMMENT '产品编码',
    apply_no                    STRING NOT NULL COMMENT '借款申请编号',
    loan_req_no                 STRING      COMMENT '放款流水号',
    loan_time                   STRING      COMMENT '放款时间，格式yyyy-MM-dd HH:mm:ss',
    due_date                    STRING      COMMENT '到期日',
    name                        STRING      COMMENT '姓名/企业名称',
    id_card_type                STRING      COMMENT '用户证件类型',
    id_card                     STRING      COMMENT '身份证号',
    contract_amt                DECIMAL(38,18) COMMENT '合同金额',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    service_amt                 DECIMAL(38,18) COMMENT '前期服务费金额',
    guarantee_amt               DECIMAL(38,18) COMMENT '前期担保费金额',
    margin_amt                  DECIMAL(38,18) COMMENT '前期保证金金额',
    compensate_amt              DECIMAL(38,18) COMMENT '前期代偿金金额',
    act_service_amt             DECIMAL(38,18) COMMENT '实收前期服务费金额',
    act_guarantee_amt           DECIMAL(38,18) COMMENT '实收前期担保费金额',
    act_margin_amt              DECIMAL(38,18) COMMENT '实收前期保证金金额',
    act_compensate_amt          DECIMAL(38,18) COMMENT '实收前期代偿金金额',
    repay_day                   INT      COMMENT '还款日',
    total_term                  INT      COMMENT '分期期数',
    loan_status                 STRING      COMMENT '借据状态',
    remark                      STRING      COMMENT '备注',
    loan_month                  STRING      COMMENT '放款月份，格式yyyyMM',
    lend_status                 STRING      COMMENT '放款状态',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=loan_time，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-消金放款信息（事务分区表）',
    'write.bucket.num' = '16',   
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours' = '0'
);

-- 数据量：53051729
-- ============================================================
-- 原：f_prd_spark_db.ln_plan_info（fake库-消金还款计划信息表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=repay_date，格式yyyy-MM-dd
-- 主键：id（物理主键）
-- 注意：repay_date → MaxCompute保留字，字段名映射为due_date
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_cons_repay_plan_incr_delta (
    id                          BIGINT     COMMENT '物理主键',
    recon_date                  STRING      COMMENT '对账日期，格式yyyy-MM-dd',
    product_no                  STRING      COMMENT '产品编码',
    apply_no                    STRING   not null   COMMENT '借款申请编号',
    term                        INT   not null  COMMENT '期次号',
    repay_date                  STRING      COMMENT '计划还款日',
    act_repay_date              STRING      COMMENT '实际还款日',
    compensate_date             STRING      COMMENT '代偿日期',
    compensate_type             INT      COMMENT '代偿类型',
    status                      STRING      COMMENT '每期状态',
    ovd_days                    INT      COMMENT '逾期天数',
    is_compensate               STRING      COMMENT '是否代偿',
    print                       DECIMAL(38,18) COMMENT '应还本金',
    int_amt                     DECIMAL(38,18) COMMENT '应还利息',
    service_amt                 DECIMAL(38,18) COMMENT '应还服务费',
    guarantee_amt               DECIMAL(38,18) COMMENT '应还担保费',
    margin_amt                  DECIMAL(38,18) COMMENT '应还保证金',
    compensate_amt              DECIMAL(38,18) COMMENT '应还代偿金',
    oint_amt                    DECIMAL(38,18) COMMENT '应还罚息',
    oguarantee_amt              DECIMAL(38,18) COMMENT '应还担保费罚息',
    define_amt                  DECIMAL(38,18) COMMENT '应还逾期违约金',
    adv_define_amt              DECIMAL(38,18) COMMENT '应还提前还款违约金',
    repay_total_amt             DECIMAL(38,18) COMMENT '应还总计',
    act_print                   DECIMAL(38,18) COMMENT '实还本金',
    act_int_amt                 DECIMAL(38,18) COMMENT '实还利息',
    act_service_amt             DECIMAL(38,18) COMMENT '实还服务费',
    act_guarantee_amt           DECIMAL(38,18) COMMENT '实还担保费',
    act_margin_amt              DECIMAL(38,18) COMMENT '实还保证金',
    act_compensate_amt          DECIMAL(38,18) COMMENT '实还代偿金',
    act_oint_amt                DECIMAL(38,18) COMMENT '实还罚息',
    act_oguarantee_amt          DECIMAL(38,18) COMMENT '实还担保费罚息',
    act_define_amt              DECIMAL(38,18) COMMENT '实还逾期违约金',
    act_adv_define_amt          DECIMAL(38,18) COMMENT '实还提前还款违约金',
    act_repay_total_amt         DECIMAL(38,18) COMMENT '实还总计',
    compensate_print            DECIMAL(38,18) COMMENT '代偿本金',
    compensate_int_amt          DECIMAL(38,18) COMMENT '代偿利息',
    compensate_oint_amt         DECIMAL(38,18) COMMENT '代偿罚息',
    is_reduce                   STRING      COMMENT '是否减免',
    reduce_amt                  DECIMAL(38,18) COMMENT '减免金额',
    coupon_amt                  DECIMAL(38,18) COMMENT '优惠券金额',
    remark                      STRING      COMMENT '备注',
    loan_month                  STRING      COMMENT '放款月份',
    act_reduce_print            DECIMAL(38,18) COMMENT '减免本金',
    act_reduce_int_amt          DECIMAL(38,18) COMMENT '实还免息券贴利息',
    act_reduce_service_amt      DECIMAL(38,18) COMMENT '实还免息券贴服务费',
    act_reduce_guarantee_amt    DECIMAL(38,18) COMMENT '实还免息券贴担保费',
    act_reduce_margin_amt       DECIMAL(38,18) COMMENT '减免保证金',
    act_reduce_compensate_amt   DECIMAL(38,18) COMMENT '减免代偿金',
    act_reduce_oint_amt         DECIMAL(38,18) COMMENT '减免罚息',
    act_reduce_oguarantee_amt   DECIMAL(38,18) COMMENT '减免担保费罚息',
    act_reduce_define_amt       DECIMAL(38,18) COMMENT '减免逾期违约金',
    act_reduce_adv_define_amt   DECIMAL(38,18) COMMENT '减免提前还款违约金',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    PRIMARY KEY (apply_no,term)
)
PARTITIONED BY (pt STRING COMMENT '分区=repay_date，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-消金还款计划信息（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours' = '0'
);

-- 47971127
-- ============================================================
-- 原：f_prd_spark_db.ln_repay_info（fake库-消金还款信息表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=recon_date，格式yyyy-MM-dd
-- 主键：tran_rp_no
-- 注意：repay_time → MaxCompute保留字，字段名映射为repay_time_str
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_cons_repay_info_incr_delta (
    id                          BIGINT      COMMENT '物理主键',
    recon_date                  STRING      COMMENT '对账日期，格式yyyy-MM-dd',
    product_no                  STRING      COMMENT '产品编码',
    apply_no                    STRING      COMMENT '借款申请编号',
    term                        INT      COMMENT '期次号',
    tran_rp_no                  STRING NOT NULL COMMENT '还款流水号',
    repay_time                  STRING      COMMENT '还款时间，格式yyyy-MM-dd HH:mm:ss',
    repay_total_amt             DECIMAL(38,18) COMMENT '还款总额',
    print                       DECIMAL(38,18) COMMENT '还款本金',
    int_amt                     DECIMAL(38,18) COMMENT '还款利息',
    service_amt                 DECIMAL(38,18) COMMENT '还款服务费',
    guarantee_amt               DECIMAL(38,18) COMMENT '还款担保费',
    margin_amt                  DECIMAL(38,18) COMMENT '还款保证金',
    compensate_amt              DECIMAL(38,18) COMMENT '还款代偿金',
    oint_amt                    DECIMAL(38,18) COMMENT '还款罚息',
    oguarantee_amt              DECIMAL(38,18) COMMENT '还款担保费罚息',
    define_amt                  DECIMAL(38,18) COMMENT '还款逾期违约金',
    adv_define_amt              DECIMAL(38,18) COMMENT '提前还款违约金',
    reduce_print                DECIMAL(38,18) COMMENT '减免本金',
    reduce_int_amt              DECIMAL(38,18) COMMENT '实还免息券贴利息',
    reduce_service_amt          DECIMAL(38,18) COMMENT '实还免息券贴服务费',
    reduce_guarantee_amt        DECIMAL(38,18) COMMENT '实还免息券贴担保费',
    reduce_margin_amt           DECIMAL(38,18) COMMENT '减免保证金',
    reduce_compensate_amt       DECIMAL(38,18) COMMENT '减免代偿金',
    reduce_oint_amt             DECIMAL(38,18) COMMENT '减免罚息',
    reduce_oguarantee_amt       DECIMAL(38,18) COMMENT '减免担保费罚息',
    reduce_define_amt           DECIMAL(38,18) COMMENT '减免逾期违约金',
    reduce_adv_define_amt       DECIMAL(38,18) COMMENT '减免提前还款违约金',
    reduce_activity_amt         DECIMAL(38,18) COMMENT '活动减免金额',
    reduce_compliance_amt       DECIMAL(38,18) COMMENT '合规减免金额',
    repay_type                  STRING      COMMENT '还款类型',
    remark                      STRING      COMMENT '备注',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    PRIMARY KEY (tran_rp_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=repay_time，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-消金还款信息（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours' = '0'
);


-- ============================================================
-- 原：f_prd_spark_db.req_black_dwd_fake_loan_repay_info_d（fake库-还款信息黑名单）
-- 源库：f_prd_spark_db
-- 事务表，无分区
-- 主键：repay_series_no
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_black_fake_loan_repay_info_full_t (
    bill_app_no                 STRING      COMMENT '借款申请编号',
    product_no                  STRING      COMMENT '产品编码',
    repay_series_no             STRING NOT NULL COMMENT '还款流水号（主键）',
    remark                      STRING      COMMENT '备注',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    PRIMARY KEY (repay_series_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-fake库还款信息黑名单',
    'write.bucket.num' = '8'
);


-- ============================================================
-- 原：prd_spark_db.dim_req_supervision_payment_info_d（监管支付信息维表）
-- 源库：prd_spark_db → 迁移至当前库
-- 事务表，无分区（维表，数据量较小）
-- 主键：bill_app_no, business_control_rule_id（联合主键）
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_req_supervision_payment_info_incr_delta (
    business_control_rule_id    BIGINT  not null    COMMENT '业务管控规则Id',
    project_no                  BIGINT      COMMENT '项目编号',
    project_name                STRING      COMMENT '项目名称',
    bill_app_no                 STRING NOT NULL COMMENT '借款申请编号',
    product_no                  STRING      COMMENT '产品编码',
    product_name                STRING      COMMENT '产品名称',
    financer_no                 STRING      COMMENT '资金编号',
    financer_name               STRING      COMMENT '资金方名称',
    platform_no                 STRING      COMMENT '平台编号',
    platform_name               STRING      COMMENT '平台名称',
    guarantor_no                STRING      COMMENT '担保方编号',
    guarantor_name              STRING      COMMENT '担保方名称',
    name                        STRING      COMMENT '客户姓名',
    loan_day                    date      COMMENT '贷款日期，格式yyyy-MM-dd',
    loan_year                   BIGINT      COMMENT '贷款年份',
    total_term                  BIGINT      COMMENT '总期次',
    loan_amt                    DECIMAL(38,18) COMMENT '贷款金额',
    id_card                     STRING      COMMENT '身份证号',
    mobile                      STRING      COMMENT '手机号',
    province_id                 STRING      COMMENT '省份编号',
    gender                      STRING      COMMENT '性别',
    age                         BIGINT      COMMENT '年龄',
    loan_period                 BIGINT      COMMENT '贷款期限',
    city_id                     STRING      COMMENT '用户所在市',
    farmer_flag                 STRING      COMMENT '农户标识：0-非农户 1-农户 -99 ：身份证具体地址缺失',
    loan_req_no                 STRING      COMMENT '放款流水号',
    enterp_sc                   STRING      COMMENT '中小微划型',
    indiv_cust_id               STRING      COMMENT '客户号',
    id_card_type                STRING      COMMENT '证件类型',
    address                     STRING      COMMENT '所在地区',
    is_cancel                   STRING      COMMENT '是否撤保',
    rev_guarantee_type          STRING      COMMENT '反担保方式',
    act_year_rate               DECIMAL(38,18) COMMENT '实际年化利率',
    loan_use                    STRING      COMMENT '借款用途',
    grace_day                   BIGINT      COMMENT '宽限期',
    is_local_guarantee_business STRING      COMMENT '是否本地担保',
    customer_type               STRING      COMMENT '客户类型',
    repayment_method            STRING      COMMENT '还款方式',
    loan_balance                DECIMAL(38,18) COMMENT '资金在贷余额',
    PRIMARY KEY (bill_app_no, business_control_rule_id)
)
PARTITIONED BY (pt STRING COMMENT '分区=loan_day，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '展示系统放款借据信息（简版借据）',
    'write.bucket.num' = '64',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours' = '0'
);


-- ============================================================
-- 原：f_prd_spark_db.dwd_offline_repay_performance_d（fake数据还款表现表）
-- 源库：f_prd_spark_db
-- 目标表：分区表，pt=obs_date，格式yyyy-MM-dd
-- 主键：apply_no（分区表自动含pt）
-- 事务表，支持MERGE INTO
-- 010/011/012 三个脚本最终都写入此表
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_fake_offline_repay_performance_incr_delta (
    apply_no                    STRING NOT NULL COMMENT '借据号/合同号（主键）',
    product_no                  STRING      COMMENT '产品编号',
    obs_date                    STRING      COMMENT '观察日，格式yyyy-MM-dd',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    user_repaid_principal       DECIMAL(38,18) COMMENT '用户已还本金',
    cpst_repaid_principal       DECIMAL(38,18) COMMENT '代偿本金',
    princ_bal_info              DECIMAL(38,18) COMMENT '用户在贷余额',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷余额',
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT      COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT      COMMENT '历史最大逾期天数',
    is_cancel                   STRING      COMMENT '是否撤保',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保金额',
    act_repay_date              STRING      COMMENT '结清时间',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT      COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT      COMMENT '累计代偿笔数',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING      COMMENT '截止观察点前的最后一次代偿时间',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake数据还款表现表',
    'write.bucket.num' = '16'
);


-- ============================================================
-- 010中间表 - fake库全量重算（dwd_offline_repay_performance_incr_delta_010_tmp）
-- 数据范围：2025-07-01~昨天，近2天新激活规则的产品
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_fake_offline_repay_performance_incr_delta_010_tmp (
    apply_no                    STRING NOT NULL COMMENT '借据号/合同号（主键）',
    product_no                  STRING      COMMENT '产品编号',
    obs_date                    STRING      COMMENT '观察日',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    user_repaid_principal       DECIMAL(38,18) COMMENT '用户已还本金',
    cpst_repaid_principal       DECIMAL(38,18) COMMENT '代偿本金',
    princ_bal_info              DECIMAL(38,18) COMMENT '用户在贷余额',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷余额',
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额',
    overdue_days                BIGINT      COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT      COMMENT '历史最大逾期天数',
    is_cancel                   STRING      COMMENT '是否撤保',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保金额',
    act_repay_date              STRING      COMMENT '结清时间',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT      COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT      COMMENT '累计代偿笔数',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt         DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING      COMMENT '截止观察点前的最后一次代偿时间',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '010中间表-fake库全量重算（2025-07至今，近2天激活产品）',
    'write.bucket.num' = '16'
);


-- ============================================================
-- 011中间表 - fake库近7天全量重算（dwd_offline_repay_performance_incr_delta_011_tmp）
-- 数据范围：近7天，所有规则产品
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_fake_offline_repay_performance_incr_delta_011_tmp (
    apply_no                    STRING NOT NULL COMMENT '借据号/合同号（主键）',
    product_no                  STRING      COMMENT '产品编号',
    obs_date                    STRING      COMMENT '观察日',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    user_repaid_principal       DECIMAL(38,18) COMMENT '用户已还本金',
    cpst_repaid_principal       DECIMAL(38,18) COMMENT '代偿本金',
    princ_bal_info              DECIMAL(38,18) COMMENT '用户在贷余额',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷余额',
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额',
    overdue_days                BIGINT      COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT      COMMENT '历史最大逾期天数',
    is_cancel                   STRING      COMMENT '是否撤保',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保金额',
    act_repay_date              STRING      COMMENT '结清时间',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT      COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT      COMMENT '累计代偿笔数',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt         DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING      COMMENT '截止观察点前的最后一次代偿时间',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '011中间表-fake库近7天全量重算（所有规则产品）',
    'write.bucket.num' = '16'
);


-- ============================================================
-- 012中间表 - fake库全量重算（dwd_offline_repay_performance_incr_delta_012_tmp）
-- 数据范围：近7天，所有规则产品
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_fake_offline_repay_performance_incr_delta_012_tmp (
    apply_no                    STRING NOT NULL COMMENT '借据号/合同号（主键）',
    product_no                  STRING      COMMENT '产品编号',
    obs_date                    STRING      COMMENT '观察日',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    user_repaid_principal       DECIMAL(38,18) COMMENT '用户已还本金',
    cpst_repaid_principal       DECIMAL(38,18) COMMENT '代偿本金',
    princ_bal_info              DECIMAL(38,18) COMMENT '用户在贷余额',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资方在贷余额',
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额',
    overdue_days                BIGINT      COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT      COMMENT '历史最大逾期天数',
    is_cancel                   STRING      COMMENT '是否撤保',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '应还担保金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '实还担保金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '截至当前应还担保金额',
    act_repay_date              STRING      COMMENT '结清时间',
    month_cpst_amt              DECIMAL(38,18) COMMENT '本月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '本月代偿本金金额',
    month_cpst_cnt              BIGINT      COMMENT '本月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金金额',
    year_cpst_cnt               BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT      COMMENT '累计代偿笔数',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿金额',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金金额',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt         DECIMAL(38,18) COMMENT '累计代偿其他',
    last_cpst_date              STRING      COMMENT '截止观察点前的最后一次代偿时间',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '012中间表-fake库全量重算',
    'write.bucket.num' = '16'
);

-- 46677
-- ============================================================
-- 原：f_prd_spark_db.oapi_loan（fake库-车贷放款信息表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=loan_date，格式yyyy-MM
-- 主键：rent_plan_code
-- 注意：字段loan_amount为bigint（分），需/100转换为元
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_auto_loan_info_incr_delta (
    id                          STRING      COMMENT '物理主键',
    channel_id                  STRING      COMMENT '渠道id',
    reconciliation_date         STRING      COMMENT '对账日期，格式yyyy-MM-dd',
    capital_product_code        STRING      COMMENT '产品编码',
    rent_plan_code              STRING NOT NULL COMMENT '借款申请编号',
    loan_req_no                 STRING      COMMENT '放款流水号',
    loan_status                 STRING      COMMENT '借据状态',
    loan_date                   STRING      COMMENT '放款日期，格式yyyy-MM-dd',
    date_due                    STRING      COMMENT '到期日期',
    customer_name               STRING      COMMENT '客户姓名',
    id_card_type                STRING      COMMENT '证件类型',
    card_no                     STRING      COMMENT '证件号',
    contract_amount             BIGINT      COMMENT '合同金额（分）',
    loan_amount                 BIGINT      COMMENT '放款金额（分）',
    service_amt                 BIGINT      COMMENT '前期服务费（分）',
    guarantee_fee               BIGINT      COMMENT '前期担保费（分）',
    security_amt                BIGINT      COMMENT '前期保证金（分）',
    commutation                 BIGINT      COMMENT '前期代偿金（分）',
    repaid_service_amt          BIGINT      COMMENT '已还前期服务费（分）',
    repaid_guarantee_fee        BIGINT      COMMENT '已还前期担保费（分）',
    repaid_security_amt         BIGINT      COMMENT '已还前期保证金（分）',
    repaid_commutation          BIGINT      COMMENT '已还前期代偿金（分）',
    repaid_penalty_interest     STRING      COMMENT '已还罚息',
    pay_date                    BIGINT      COMMENT '还款日',
    detail_status               STRING      COMMENT '状态',
    remark                      STRING      COMMENT '备注',
    oapi_project_id             STRING      COMMENT '项目ID',
    created_by                  STRING      COMMENT '创建人',
    created_date                STRING      COMMENT '创建时间',
    last_modified_by            STRING      COMMENT '修改人',
    last_modified_date          STRING      COMMENT '修改时间',
    tenant_id                   STRING      COMMENT '租户ID',
    PRIMARY KEY (rent_plan_code)
)
PARTITIONED BY (pt STRING COMMENT '分区=loan_date，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-车贷放款信息（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- 949858
-- ============================================================
-- 原：f_prd_spark_db.zf_rent_plan（fake库-车贷还款计划表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=pay_date，格式yyyy-MM
-- 主键：(rent_plan_code, period)
-- 注意：金额字段为bigint（分），需/100转换为元
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_auto_repay_plan_incr_delta (
    id                          STRING      COMMENT '物理主键',
    reconciliation_date         STRING      COMMENT '对账日期',
    rent_plan_code              STRING NOT NULL COMMENT '借款申请编号',
    period                      INT NOT NULL COMMENT '期次号',
    pay_date                    STRING      COMMENT '计划还款日，格式yyyy-MM-dd',
    created_by                  STRING      COMMENT '创建人',
    created_date                STRING      COMMENT '创建时间',
    last_modified_by            STRING      COMMENT '修改人',
    last_modified_date          STRING      COMMENT '修改时间',
    tenant_id                   STRING      COMMENT '租户ID',
    accept_date                 STRING      COMMENT '实际还款日',
    detail_status               STRING      COMMENT '每期状态',
    over_due_days               INT      COMMENT '逾期天数',
    compensatory                STRING      COMMENT '是否代偿',
    compensate_type             STRING      COMMENT '代偿类型',
    compensate_date             STRING      COMMENT '代偿日期',
    principal                   BIGINT      COMMENT '应还本金（分）',
    interest                    BIGINT      COMMENT '应还利息（分）',
    service_amt                 BIGINT      COMMENT '应还服务费（分）',
    guarantee_fee               BIGINT      COMMENT '应还担保费（分）',
    security_amt                BIGINT      COMMENT '应还保证金（分）',
    commutation                 BIGINT      COMMENT '应还代偿金（分）',
    penalty_interest            BIGINT      COMMENT '应还罚息（分）',
    over_due_penalty            BIGINT      COMMENT '应还逾期违约金（分）',
    advance_settle_penalty      BIGINT      COMMENT '应还提前还款违约金（分）',
    summary                     BIGINT      COMMENT '应还总计（分）',
    repaid_principal            BIGINT      COMMENT '实还本金（分）',
    repaid_interest             BIGINT      COMMENT '实还利息（分）',
    repaid_service_amt          BIGINT      COMMENT '实还服务费（分）',
    repaid_guarantee_fee        BIGINT      COMMENT '实还担保费（分）',
    repaid_security_amt         BIGINT      COMMENT '实还保证金（分）',
    repaid_commutation          BIGINT      COMMENT '实还代偿金（分）',
    repaid_penalty_interest     BIGINT      COMMENT '实还罚息（分）',
    repaid_over_due_penalty     BIGINT      COMMENT '实还逾期违约金（分）',
    repaid_advance_settle_penalty BIGINT    COMMENT '实还提前还款违约金（分）',
    repaid_summary              BIGINT      COMMENT '实还总计（分）',
    is_reduction                STRING      COMMENT '是否减免',
    reduction_amt               BIGINT      COMMENT '减免金额（分）',
    coupon_amt                  BIGINT      COMMENT '优惠券金额（分）',
    remark                      STRING      COMMENT '备注',
    channel_id                  STRING      COMMENT '渠道id',
    capital_product_code        STRING      COMMENT '产品编号',
    trd_id                      STRING      COMMENT '批次号',
    PRIMARY KEY (rent_plan_code, period)
)
PARTITIONED BY (pt STRING COMMENT '分区=pay_date，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-车贷还款计划（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- 451938
-- ============================================================
-- 原：f_prd_spark_db.zf_rent_plan_info（fake库-车贷还款信息表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=accept_date，格式yyyy-MM
-- 主键：fund_code
-- 注意：金额字段为bigint（分），需/100转换为元
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_auto_repay_info_incr_delta (
    id                          STRING      COMMENT '物理主键',
    reconciliation_date         STRING      COMMENT '对账日期',
    capital_product_code        STRING      COMMENT '产品编码',
    rent_plan_code              STRING      COMMENT '借款申请编号',
    period                      INT      COMMENT '期次号',
    fund_code                   STRING NOT NULL COMMENT '还款流水号',
    created_by                  STRING      COMMENT '创建人',
    created_date                STRING      COMMENT '创建时间',
    last_modified_by            STRING      COMMENT '修改人',
    last_modified_date          STRING      COMMENT '修改时间',
    tenant_id                   STRING      COMMENT '租户ID',
    accept_date                 STRING      COMMENT '实际还款日，格式yyyy-MM-dd',
    repay_type                  STRING      COMMENT '还款类型：4-代偿、5-追偿',
    repaid_principal            BIGINT      COMMENT '实还本金（分）',
    repaid_interest             BIGINT      COMMENT '实还利息（分）',
    repaid_service_amt          BIGINT      COMMENT '实还服务费（分）',
    repaid_guarantee_fee        BIGINT      COMMENT '实还担保费（分）',
    repaid_security_amt         BIGINT      COMMENT '实还保证金（分）',
    repaid_commutation          BIGINT      COMMENT '实还代偿金（分）',
    repaid_penalty_interest     BIGINT      COMMENT '实还罚息（分）',
    repaid_over_due_penalty     BIGINT      COMMENT '实还逾期违约金（分）',
    repaid_advance_settle_penalty BIGINT    COMMENT '实还提前还款违约金（分）',
    repaid_summary              BIGINT      COMMENT '实还总计（分）',
    remark                      STRING      COMMENT '备注',
    channel_id                  STRING      COMMENT '渠道id',
    trd_id                      STRING      COMMENT '批次号',
    PRIMARY KEY (fund_code)
)
PARTITIONED BY (pt STRING COMMENT '分区=accept_date，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-车贷还款信息（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- 2072
-- ============================================================
-- 原：f_prd_spark_db.pacb_project_application（fake库-樽昊项目申请表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=loan_disbursement_time，格式yyyy-MM
-- 主键：id
-- 注意：financing_amount为decimal(10,2)（元），不用/100
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_pacb_project_application_incr_delta (
    id                          BIGINT NOT NULL COMMENT '主键id',
    project_application_time    STRING      COMMENT '项目申请时间',
    contract_number             STRING      COMMENT '合同编号',
    name                        STRING      COMMENT '姓名',
    user_id_type                STRING      COMMENT '证件类型',
    id_number                   STRING      COMMENT '证件号',
    id_address                  STRING      COMMENT '身份证地址',
    gender                      STRING      COMMENT '性别',
    bank_card_number            STRING      COMMENT '银行卡号',
    phone_number                STRING      COMMENT '手机号',
    financing_term              BIGINT      COMMENT '融资期限（月）',
    financing_amount            DECIMAL(38,18) COMMENT '融资金额',
    contract_interest_rate      DECIMAL(38,18) COMMENT '合同利率',
    product_name                STRING      COMMENT '产品名称',
    loan_disbursement_time      STRING      COMMENT '放款时间，格式yyyy-MM-dd',
    maturity_date               STRING      COMMENT '到期日期',
    repayment_date              STRING      COMMENT '还款日',
    vehicle_frame_number        STRING      COMMENT '车架号',
    create_by                   STRING      COMMENT '创建人',
    create_time                 STRING      COMMENT '创建时间',
    update_by                   STRING      COMMENT '修改人',
    update_time                 STRING      COMMENT '修改时间',
    product_no                  STRING      COMMENT '产品编号',
    product_name_union          STRING      COMMENT '产品名称',
    PRIMARY KEY (id)
)
PARTITIONED BY (pt STRING COMMENT '分区=loan_disbursement_time，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-樽昊项目申请（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- 102756
-- ============================================================
-- 原：f_prd_spark_db.pacb_zf_rent_plan（fake库-樽昊还款计划表）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=pay_date，格式yyyy-MM
-- 主键：id
-- 注意：金额字段为bigint（分），需/100转换为元
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_fake_pacb_repay_plan_incr_delta (
    id                          STRING NOT NULL COMMENT '物理主键',
    reconciliation_date         STRING      COMMENT '对账日期',
    rent_plan_code              STRING      COMMENT '借款申请编号',
    period                      BIGINT      COMMENT '期次号',
    pay_date                    STRING      COMMENT '计划还款日，格式yyyy-MM-dd',
    created_by                  STRING      COMMENT '创建人',
    created_date                STRING      COMMENT '创建时间',
    last_modified_by            STRING      COMMENT '修改人',
    last_modified_date          STRING      COMMENT '修改时间',
    tenant_id                   STRING      COMMENT '租户ID',
    accept_date                 STRING      COMMENT '实际还款日',
    detail_status               STRING      COMMENT '每期状态',
    over_due_days               BIGINT      COMMENT '逾期天数',
    compensatory                STRING      COMMENT '是否代偿',
    compensate_date             STRING      COMMENT '代偿日期',
    compensate_type             STRING      COMMENT '代偿类型',
    principal                   BIGINT      COMMENT '应还本金（分）',
    interest                    BIGINT      COMMENT '应还利息（分）',
    service_amt                 BIGINT      COMMENT '应还服务费（分）',
    guarantee_fee               BIGINT      COMMENT '应还担保费（分）',
    security_amt                BIGINT      COMMENT '应还保证金（分）',
    commutation                 BIGINT      COMMENT '应还代偿金（分）',
    penalty_interest            BIGINT      COMMENT '应还罚息（分）',
    over_due_penalty            BIGINT      COMMENT '应还逾期违约金（分）',
    advance_settle_penalty      BIGINT      COMMENT '应还提前还款违约金（分）',
    summary                     BIGINT      COMMENT '应还总计（分）',
    repaid_principal            BIGINT      COMMENT '实还本金（分）',
    repaid_interest             BIGINT      COMMENT '实还利息（分）',
    repaid_service_amt          BIGINT      COMMENT '实还服务费（分）',
    repaid_guarantee_fee        BIGINT      COMMENT '实还担保费（分）',
    repaid_security_amt         BIGINT      COMMENT '实还保证金（分）',
    repaid_commutation          BIGINT      COMMENT '实还代偿金（分）',
    repaid_penalty_interest     BIGINT      COMMENT '实还罚息（分）',
    repaid_over_due_penalty     BIGINT      COMMENT '实还逾期违约金（分）',
    repaid_advance_settle_penalty BIGINT    COMMENT '实还提前还款违约金（分）',
    repaid_summary              BIGINT      COMMENT '实还总计（分）',
    is_reduction                STRING      COMMENT '是否减免',
    reduction_amt               BIGINT      COMMENT '减免金额（分）',
    coupon_amt                  BIGINT      COMMENT '优惠券金额（分）',
    remark                      STRING      COMMENT '备注',
    channel_id                  STRING      COMMENT '渠道id',
    capital_product_code        STRING      COMMENT '产品编号',
    trd_id                      STRING      COMMENT '批次号',
    product_no                  STRING      COMMENT '产品编号',
    product_name                STRING      COMMENT '产品名称',
    PRIMARY KEY (id)
)
PARTITIONED BY (pt STRING COMMENT '分区=pay_date，格式yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = 'fake库-樽昊还款计划（事务分区表）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- 未集成

-- ============================================================
-- 原：f_prd_spark_db.dwd_offline_repay_performance_d（011中间表-车贷）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=obs_date，格式yyyy-MM-dd
-- 主键：apply_no
-- 注意：用于存储车贷offline还款表现数据
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_fake_offline_repay_performance_incr_delta_011_tmp (
    apply_no                    STRING NOT NULL COMMENT '申请号',
    product_no                  STRING      COMMENT '产品编号',
    obs_date                    STRING      COMMENT '观察日期，格式yyyy-MM-dd',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    user_repaid_principal       DECIMAL(38,18) COMMENT '用户累计实还本金',
    cpst_repaid_principal       DECIMAL(38,18) COMMENT '代偿累计本金',
    princ_bal_info              DECIMAL(38,18) COMMENT '本金余额',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资金方本金余额',
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总金额',
    overdue_days                BIGINT      COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT      COMMENT '最大逾期天数',
    is_cancel                   STRING      COMMENT '撤保标识',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '到期担保费累计金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '实际担保费累计金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '月末担保费',
    act_repay_date              STRING      COMMENT '实际还款日期',
    month_cpst_amt              DECIMAL(38,18) COMMENT '当月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '当月代偿本金',
    month_cpst_cnt              BIGINT      COMMENT '当月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金',
    year_cpst_cnt               BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT      COMMENT '累计代偿笔数',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿额',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他金额',
    last_cpst_date              STRING      COMMENT '最近代偿日期',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '011中间表-fake车贷offline还款表现',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);


-- ============================================================
-- 原：f_prd_spark_db.dwd_offline_repay_performance_d（012中间表-樽昊）
-- 源库：f_prd_spark_db
-- 事务表，分区pt=obs_date，格式yyyy-MM-dd
-- 主键：apply_no
-- 注意：用于存储樽昊offline还款表现数据
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_fake_offline_repay_performance_incr_delta_012_tmp (
    apply_no                    STRING NOT NULL COMMENT '申请号',
    product_no                  STRING      COMMENT '产品编号',
    obs_date                    STRING      COMMENT '观察日期，格式yyyy-MM-dd',
    loan_amt                    DECIMAL(38,18) COMMENT '放款金额',
    user_repaid_principal       DECIMAL(38,18) COMMENT '用户累计实还本金',
    cpst_repaid_principal       DECIMAL(38,18) COMMENT '代偿累计本金',
    princ_bal_info              DECIMAL(38,18) COMMENT '本金余额',
    fund_princ_bal_info         DECIMAL(38,18) COMMENT '资金方本金余额',
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总金额',
    overdue_days                BIGINT      COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT      COMMENT '最大逾期天数',
    is_cancel                   STRING      COMMENT '撤保标识',
    create_time                 STRING      COMMENT '创建时间',
    update_time                 STRING      COMMENT '更新时间',
    due_guarantee_cum_amt       DECIMAL(38,18) COMMENT '到期担保费累计金额',
    act_guarantee_cum_amt       DECIMAL(38,18) COMMENT '实际担保费累计金额',
    end_of_month_guarantee_fee  DECIMAL(38,18) COMMENT '月末担保费',
    act_repay_date              STRING      COMMENT '实际还款日期',
    month_cpst_amt              DECIMAL(38,18) COMMENT '当月代偿额',
    month_cpst_princ_amt        DECIMAL(38,18) COMMENT '当月代偿本金',
    month_cpst_cnt              BIGINT      COMMENT '当月代偿笔数',
    year_cpst_amt               DECIMAL(38,18) COMMENT '当年代偿额',
    year_cpst_princ_amt         DECIMAL(38,18) COMMENT '当年代偿本金',
    year_cpst_cnt               BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt              BIGINT      COMMENT '累计代偿笔数',
    cum_cpst_amt                DECIMAL(38,18) COMMENT '累计代偿额',
    cum_cpst_princ_amt          DECIMAL(38,18) COMMENT '累计代偿本金',
    cum_cpst_int_amt            DECIMAL(38,18) COMMENT '累计代偿利息',
    cum_cpst_other_amt          DECIMAL(38,18) COMMENT '累计代偿其他金额',
    last_cpst_date              STRING      COMMENT '最近代偿日期',
    PRIMARY KEY (apply_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '012中间表-fake樽昊offline还款表现',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);
