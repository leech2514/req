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

-- 原：business_control_project_detail
-- 源库：f_prd_spark_db
CREATE TABLE IF NOT EXISTS prod_f_dw.business_control_project_detail
(
    project_id                BIGINT COMMENT '项目详情—主键'
    ,project_name             STRING COMMENT '项目名称'
    ,control_type             STRING COMMENT '业务管控类型：1-金融局 2-资方'
    ,guarantee_company_id     BIGINT COMMENT '担保公司ID: sys_company表中类型为担保公司（855）的ID'
    ,asset_company_id         BIGINT COMMENT '资产端公司ID: sys_company表中类型为资产方（856）的ID'
    ,fund_company_id          BIGINT COMMENT '资金端公司ID: sys_company表中类型为资金方（857）的ID'
    ,guarantee_type           STRING COMMENT '担保类型：1-自有业务担保 2-拓展业务直保 3-拓展业务分保'
    ,max_loan_limit           DECIMAL(38,18) COMMENT '最大在贷限额-单位：元'
    ,earnest_money            DECIMAL(38,18) COMMENT '保证金—单位：元'
    ,margin_rate              DECIMAL(38,18) COMMENT '保证金比例'
    ,control_rules_type       STRING COMMENT '是否已添加管控规则：1-是 0-否'
    ,is_control_flag          STRING COMMENT '是否管控中：1-是 0-否'
    ,business_control_rule_id BIGINT COMMENT '业务管控规则Id（新）'
    ,create_time              TIMESTAMP COMMENT '首次配置时间'
    ,update_time              TIMESTAMP COMMENT '最后修改时间'
    ,earnest_rate             DECIMAL(38,18) COMMENT '保证金比例(百分数,5=5%); 应存出保证金=在贷×earnest_rate/100'
    ,guarantee_rate           DECIMAL(38,18) COMMENT '担保费率(百分数,5=5%)'
    ,create_status            STRING COMMENT '创建状态: 空/NULL=已创建(历史数据), draft=暂存'
    ,business_type            STRING COMMENT '业务类型(关联business_control_business_type.type_name)'
    ,display_page             STRING COMMENT '展示页面(字典 business_control_display_page)'
)
STORED AS aliorc
TBLPROPERTIES ('cdc.data.retain.hours' = '24','acid.cdc.mode.enable' = 'false','acid.data.retain.hours' = '24','columnar.nested.type' = 'true','comment' = '业务管控规则表','transactional' = 'true','write.bucket.num' = '1')
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
CREATE TABLE IF NOT EXISTS prod_dw_01.dwd_cons_repay_info_incr_delta(
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
    PRIMARY KEY (bill_app_no)
)
PARTITIONED BY (pt STRING COMMENT '分区=obs_date=loan_day，格式yyyy-MM-dd')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '003中间表-放款日快照（近3个月，所有规则产品）',
    'write.bucket.num' = '8'
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
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

-- ============================================================
-- 原：req_black_dwd_cons_loan_payment_info_d（业务管控-放款信息黑名单）
-- 源库：f_prd_spark_db
-- 主键：(business_control_rule_id, bill_app_no)
-- 非分区事务表（PK Delta Table）
-- 数据量：约10万条，预估上限100万，4个桶
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_black_cons_loan_payment_info_full_t (
    business_control_rule_id   STRING  NOT NULL COMMENT '业务管控-公司规则ID',
    bill_app_no                STRING  NOT NULL COMMENT '借款申请编号',
    product_no                 STRING           COMMENT '产品编码',
    create_time                DATETIME         COMMENT '创建时间',
    update_time                DATETIME         COMMENT '修改时间',
    PRIMARY KEY (business_control_rule_id, bill_app_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-放款信息黑名单',
    'write.bucket.num' = '4'
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
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
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数',
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
-- 主键：bill_app_no, business_control_rule_id（联合主键）
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_req_supervision_payment_info_full_t (
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
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
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
    'comment' = '010中间表-fake库-消金还款',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
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
    'comment' = '011中间表-fake库-车贷还款',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
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
    'comment' = '012中间表-fake库樽昊还款',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
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
    financing_amount            DECIMAL(38,18) COMMENT '融资金额(元)',
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

-- ============================================================
-- 014：农户基础信息表
-- 原：f_prd_spark_db.dim_base_farmer_info
-- 新：dim_base_farmer_info
-- 非分区事务表，merge into 全量覆盖
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_base_farmer_info_full_t (
    id_card                     STRING NOT NULL COMMENT '身份证号（主键）',
    name                        STRING      COMMENT '姓名',
    age                         BIGINT      COMMENT '年龄（动态计算）',
    id_address                  STRING      COMMENT '身份证登记地址',
    address                     STRING      COMMENT '实际居住地址',
    work_address                STRING      COMMENT '工作地址',
    educational                 STRING      COMMENT '学历编码',
    PRIMARY KEY (id_card)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '农户基础信息维表',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- ============================================================
-- 015：业务管控-最新再贷统计表
-- 原：f_prd_spark_db.dwd_bizctrl_payment_performance_cur
-- dwd_req_bizctrl_payment_performance_cur_full_t
-- 非分区事务表，动态Bucket优化（table.format.version=2）
-- 数据量：约4000万条
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_bizctrl_payment_performance_cur_full_t (
    bill_app_no              STRING NOT NULL COMMENT '借据号（主键）',
    product_no               STRING      COMMENT '产品编号',
    obs_date                 STRING      COMMENT '观察日期',
    fund_princ_bal_info      DECIMAL(38,18) COMMENT '资金方本金余额',
    dw_create_time           DATETIME    COMMENT '创建时间',
    dw_update_time           DATETIME    COMMENT '更新时间',
    PRIMARY KEY (bill_app_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-最新再贷统计（消金+车贷+简版）',
   -- 'table.format.version' = '2'  -- 当不是PKdelet table的时候可以自动根据数据量增加分桶数，但是有主键的就不行
     'write.bucket.num' = '64'
);

-- ============================================================
-- 016/017：业务管控-借据表（4张）
-- 非分区事务表（PK Delta Table）
-- 主键 (project_id, bill_app_no, business_control_rule_id)，project_id前置以加速关联
-- 数据量：约2300万条，32个桶
-- ============================================================

-- 1. 手动-项目规则粒度借据
-- 原：f_prd_spark_db.manual_bizctrl_project_bill_d
CREATE TABLE IF NOT EXISTS dwd_req_manual_bizctrl_project_bill_full_t (
    business_control_rule_id   BIGINT  not null    COMMENT '公司规则ID',
    project_id                 BIGINT    COMMENT '项目编号（主键，关联加速）',
    project_rule_id            BIGINT      COMMENT '项目规则ID',
    product_no                 STRING      COMMENT '产品编码',
    bill_app_no                STRING NOT NULL COMMENT '借款申请编号（主键）',
    id_card                    STRING      COMMENT '证件号码',
    loan_day                   STRING      COMMENT '放款时间',
    loan_amt                   DECIMAL(21,2) COMMENT '放款金额',
    fund_princ_bal_info        DECIMAL(17,2)   COMMENT '资方在贷',
    tap                        STRING      COMMENT '项目是否执行的标识',
    create_time                DATETIME    COMMENT '创建时间',
    update_time                DATETIME    COMMENT '修改时间',
    PRIMARY KEY (bill_app_no, business_control_rule_id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '手动-项目规则粒度借据',
    'write.bucket.num' = '32'
);

-- 2. 手动-公司规则粒度借据
-- 原：f_prd_spark_db.manual_bizctrl_company_bill_d
CREATE TABLE IF NOT EXISTS dwd_req_manual_bizctrl_company_bill_full_t (
    business_control_rule_id   BIGINT  not null    COMMENT '公司规则ID',
    project_rule_id            BIGINT      COMMENT '项目规则',
    project_id                 BIGINT    COMMENT '项目编号（主键，关联加速）',
    product_no                 STRING      COMMENT '产品编码',
    bill_app_no                STRING NOT NULL COMMENT '借款申请编号（主键）',
    id_card                    STRING      COMMENT '证件号码',
    loan_day                   STRING      COMMENT '放款时间',
    loan_amt                   DECIMAL(21,2) COMMENT '放款金额',
    fund_princ_bal_info        DECIMAL(17,2)  COMMENT '资方在贷',
    fund_princ_bal             DECIMAL(17,2) COMMENT '在贷',
    create_time                DATETIME    COMMENT '创建时间',
    update_time                DATETIME    COMMENT '修改时间',
    PRIMARY KEY ( bill_app_no, business_control_rule_id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '手动-公司规则粒度借据',
    'write.bucket.num' = '32'
);

-- 3. 自动-项目规则粒度借据
-- 原：f_prd_spark_db.auto_bizctrl_project_bill_d
CREATE TABLE IF NOT EXISTS dwd_req_auto_bizctrl_project_bill_full_t (
    business_control_rule_id   BIGINT  not null    COMMENT '公司规则ID',
    project_id                 BIGINT    COMMENT '项目编号（主键，关联加速）',
    project_rule_id            BIGINT      COMMENT '项目规则',
    product_no                 STRING      COMMENT '产品编码',
    bill_app_no                STRING NOT NULL COMMENT '借款申请编号（主键）',
    id_card                    STRING      COMMENT '证件号码',
    loan_day                   STRING      COMMENT '放款时间',
    loan_amt                   BIGINT      COMMENT '放款金额',
    fund_princ_bal_info        DECIMAL(17,2) COMMENT '资方在贷',
    create_time                DATETIME    COMMENT '创建时间',
    update_time                DATETIME    COMMENT '修改时间',
    PRIMARY KEY ( bill_app_no, business_control_rule_id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '自动-项目规则粒度借据',
    'write.bucket.num' = '32'
);

-- 4. 自动-公司规则粒度借据
-- 原：f_prd_spark_db.auto_bizctrl_company_bill_d
CREATE TABLE IF NOT EXISTS dwd_req_auto_bizctrl_company_bill_full_t (
    business_control_rule_id   BIGINT  not null    COMMENT '公司规则ID',
    project_rule_id            BIGINT      COMMENT '项目规则',
    project_id                 BIGINT     COMMENT '项目编号（主键，关联加速）',
    product_no                 STRING      COMMENT '产品编码',
    bill_app_no                STRING NOT NULL COMMENT '借款申请编号（主键）',
    id_card                    STRING      COMMENT '证件号码',
    loan_day                   STRING      COMMENT '放款时间',
    loan_amt                   DECIMAL(21,2) COMMENT '放款金额',
    fund_princ_bal_info        DECIMAL(17,2)  COMMENT '资方在贷',
    fund_princ_bal             DECIMAL(17,2) COMMENT '在贷',
    create_time                DATETIME    COMMENT '创建时间',
    update_time                DATETIME    COMMENT '修改时间',
    PRIMARY KEY ( bill_app_no, business_control_rule_id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '自动-公司规则粒度借据',
    'write.bucket.num' = '32'
);




-- 源：ods_cons_td_loan
-- 源库：prd_spark_db
-- 消金简版通道放款表
CREATE TABLE IF NOT EXISTS ods_cons_td_loan_full_t(
	recon_date STRING NOT NULL COMMENT '对账日期',
	 product_no STRING COMMENT '产品编号',
	 bill_app_no STRING NOT NULL COMMENT '借据号',
	 loan_amt DECIMAL(17,2) COMMENT '借款金额',
	 name STRING COMMENT '借款人姓名',
	 id_card STRING COMMENT '身份证号',
	 mobile STRING COMMENT '联系电话',
	 sex STRING COMMENT '性别',
	 age INT COMMENT '年龄',
	 purpose STRING COMMENT '贷款用途',
	 year_rate DECIMAL(17,6) COMMENT '年利率',
	 loan_day STRING COMMENT '放款日',
	 end_date STRING COMMENT '到期日',
	 loan_term INT COMMENT '期数',
	 loan_bal DECIMAL(17,2) COMMENT '贷款余额',
	 ovd_days INT COMMENT '逾期天数',
	 `status` STRING COMMENT '借据状态',
	 repay_type STRING COMMENT '客户还款方式',
	 repay_prin_amt DECIMAL(17,2) COMMENT '数据日还款金额(本金)',
	 compensate_amt DECIMAL(17,2) COMMENT '截止数据日代偿金额(本金)',
	 bill_repay_type STRING COMMENT '借据还款方式',
	 create_time STRING COMMENT '创建时间',
	 update_time STRING COMMENT '更新时间',
	 company_size STRING COMMENT '企业规模',
	 enterprise_type STRING COMMENT '资本属性',
	 agriculture_related STRING COMMENT '是否涉农',
	 act_year_rate DECIMAL(17,6) COMMENT '资方利率',
	 compensate_type STRING COMMENT '代偿类型',
	 act_compensate_amt DECIMAL(17,2) COMMENT '代偿总额',
	 act_compensate_int_amt DECIMAL(17,2) COMMENT '代偿罚息',
	 act_compensate_define_amt DECIMAL(17,2) COMMENT '代偿违约金',
	 recovery_type STRING COMMENT '追偿类型',
	 id_card_type STRING COMMENT '证件类型',
	 id_address STRING COMMENT '身份证地址',
	 education STRING COMMENT '学历',
	 marray_status STRING COMMENT '婚姻状态',
	 mate_name STRING COMMENT '配偶姓名',
	 mate_id_type STRING COMMENT '配偶证件类型',
	 mate_id STRING COMMENT '配偶身份证号',
	 mate_telephone STRING COMMENT '配偶手机号',
	 mate_unit_name STRING COMMENT '配偶工作单位',
	 mate_unit_address STRING COMMENT '配偶工作地址',
	 degree STRING COMMENT '学位',
	 emp_status STRING COMMENT '就业状况',
	 unit_name STRING COMMENT '单位名称',
	 unit_type STRING COMMENT '单位性质',
	 industry STRING COMMENT '单位所属行业',
	 unit_address STRING COMMENT '单位地址',
	 unit_mail_code STRING COMMENT '单位邮编',
	 unit_address_code STRING COMMENT '单位地行政区划代码',
	 unit_telephone STRING COMMENT '单位电话',
	 occupation_duty STRING COMMENT '职业',
	 post STRING COMMENT '职务',
	 occupation_title STRING COMMENT '职称',
	 work_years STRING COMMENT '单位工作年限',
	 living_condition STRING COMMENT '居住状况',
	 living_address STRING COMMENT '居住地详细地址',
	 living_mail_code STRING COMMENT '居住地邮编',
	 living_address_code STRING COMMENT '居住地行政区划代码',
	 living_telephone STRING COMMENT '住宅电话',
	 com_address STRING COMMENT '通讯地址',
	 com_mail_code STRING COMMENT '通讯地邮编',
	 com_address_code STRING COMMENT '通讯地行政区划代码',
	 customer_id STRING COMMENT '客户唯一编码',
	 domicile_code STRING COMMENT '身份证地址行政区划代码',
	 property_address STRING COMMENT '抵押房产地址',
	 owner_name STRING COMMENT '抵押房产产权人',
	 int_amt DECIMAL(17,2) COMMENT '应还利息',
	 service_amt DECIMAL(17,2) COMMENT '应还服务费',
	 guarantee_amt DECIMAL(17,2) COMMENT '应还担保费',
	 margin_amt DECIMAL(17,2) COMMENT '应还保证金',
	 oint_amt DECIMAL(17,2) COMMENT '应还罚息',
	 define_amt DECIMAL(17,2) COMMENT '应还逾期违约金',
	 adv_define_amt DECIMAL(17,2) COMMENT '应还提前还款违约金',
	 total_act_int DECIMAL(17,2) COMMENT '累计还款利息',
	 total_act_service DECIMAL(17,2) COMMENT '累计还服务费',
	 total_act_guarantee DECIMAL(17,2) COMMENT '累计还担保费',
	 total_act_margin DECIMAL(17,2) COMMENT '累计还保证金',
	 total_act_compensate DECIMAL(17,2) COMMENT '累计还代偿金',
	 total_act_oint DECIMAL(17,2) COMMENT '累计还罚息',
	 total_act_define DECIMAL(17,2) COMMENT '累计还违约金',
	 total_act_adv_define DECIMAL(17,2) COMMENT '累计还提前还款违约金',
	 act_compensate_princ DECIMAL(17,2) COMMENT '实际代偿本金',
	 act_compensate_int DECIMAL(17,2) COMMENT '代偿利息',
	 guarantee_type STRING COMMENT '担保账户类型',
	 guarantee_category STRING COMMENT '担保业务大类',
	 guarantee_category_detail STRING COMMENT '担保业务种类细分',
	 counter_guarantee_type STRING COMMENT '反担保方式',
	 other_repayment STRING COMMENT '其他还款保证方式',
	 security_deposit DECIMAL(10,4) COMMENT '保证金比例',
	 contract_code STRING COMMENT '担保合同编号',
	 initial_creditor STRING COMMENT '初始债权人',
	 initial_creditor_code STRING COMMENT '初始债权人机构代码',
	 original_debt_type STRING COMMENT '原债务类型',
	 guarantee_status STRING COMMENT '担保账户状态',
	 owed_compensate_amt DECIMAL(17,2) COMMENT '应还代偿金',
	 property_nature STRING COMMENT '房产性质',
	 dw_create_time STRING COMMENT '数据创建时间',
	 dw_update_time STRING COMMENT '数据更新时间',
	PRIMARY KEY(recon_date,
	 bill_app_no)) STORED AS aliorc 
TBLPROPERTIES ('columnar.nested.type'='true',
	 'comment'='消金通道借据全量表(来源快照表)');


-- 原：ods_auto_oapi_loan
-- 源库：prd_spark_db
-- 车贷放款表
CREATE TABLE IF NOT EXISTS prod_dw_01.ods_auto_oapi_loan_incr_delta
(
    id                       STRING COMMENT '唯一编码'
    ,tenant_id               STRING COMMENT '租户ID'
    ,oapi_project_id         STRING COMMENT '立项id'
    ,channel_id              STRING COMMENT '资产方固定特殊唯一编码'
    ,reconciliation_date     STRING COMMENT '对账日期'
    ,capital_product_code    STRING COMMENT '产品编码'
    ,rent_plan_code          STRING NOT NULL COMMENT '借款申请编号'
    ,loan_req_no             STRING COMMENT '放款流水号'
    ,loan_status             STRING COMMENT '放款状态'
    ,loan_date               STRING COMMENT '放款时间'
    ,date_due                STRING COMMENT '到期日期'
    ,customer_name           STRING COMMENT '用户姓名'
    ,id_card_type            STRING COMMENT '用户证件类型'
    ,card_no                 STRING COMMENT '用户身份证号码'
    ,contract_amount         BIGINT COMMENT '合同金额'
    ,loan_amount             BIGINT COMMENT '放款金额'
    ,service_amt             BIGINT COMMENT '前期服务费金额'
    ,guarantee_fee           BIGINT COMMENT '前期担保费金额'
    ,security_amt            BIGINT COMMENT '前期保证金金额'
    ,commutation             BIGINT COMMENT '前期代偿金金额'
    ,repaid_service_amt      BIGINT COMMENT '实收前期服务费金额'
    ,repaid_guarantee_fee    BIGINT COMMENT '实收前期担保费金额'
    ,repaid_security_amt     BIGINT COMMENT '实收前期保证金金额'
    ,repaid_commutation      BIGINT COMMENT '实收前期代偿金金额'
    ,repaid_penalty_interest STRING COMMENT '还款日'
    ,pay_date                BIGINT COMMENT '分期期数'
    ,detail_status           STRING COMMENT '借据状态'
    ,remark                  STRING COMMENT '备注'
    ,created_by              STRING COMMENT '创建用户ID'
    ,created_date            STRING COMMENT '创建时间'
    ,last_modified_by        STRING COMMENT '修改用户ID'
    ,last_modified_date      STRING COMMENT '修改时间'
    ,dw_create_time          STRING COMMENT '数仓创建时间'
    ,dw_update_time          STRING COMMENT '数仓更新时间'
    ,PRIMARY KEY (rent_plan_code)
)
PARTITIONED BY 
(
    pt                       STRING COMMENT '分区字段：yyyymm，由loan_date生成'
)
STORED AS aliorc
TBLPROPERTIES ('acid.data.retain.hours' = '0','cdc.data.retain.hours' = '24','columnar.nested.type' = 'true','comment' = '车贷放款信息表','transactional' = 'true','acid.cdc.mode.enable' = 'false','write.bucket.num' = '16')
;



-- 源：ods_cons_ln_loan_info_d
-- 源库：prd_spark_db
-- 消金放款表
CREATE TABLE IF NOT EXISTS prod_dw_01.ods_cons_ln_loan_info_incr_delta
(
    id                  BIGINT COMMENT '物理主键'
    ,recon_date         STRING COMMENT '对账日期：格式YYYY-MM-DD'
    ,product_no         STRING COMMENT '产品编码'
    ,apply_no           STRING NOT NULL COMMENT '借款申请编号'
    ,loan_req_no        STRING COMMENT '放款流水号'
    ,loan_time          TIMESTAMP COMMENT '放款时间'
    ,due_date           STRING COMMENT '应还时间'
    ,name               STRING COMMENT '姓名/企业名称'
    ,id_card_type       STRING COMMENT '用户证件类型：01-身份证,02-港澳通行证,03-其他,04-统一社会信用代码'
    ,id_card            STRING COMMENT '身份证号/统一社会信用代码'
    ,contract_amt       DECIMAL(38,18) COMMENT '合同金额'
    ,loan_amt           DECIMAL(38,18) COMMENT '放款金额'
    ,service_amt        DECIMAL(38,18) COMMENT '前期服务费金额'
    ,guarantee_amt      DECIMAL(38,18) COMMENT '前期担保费金额'
    ,margin_amt         DECIMAL(38,18) COMMENT '前期保证金金额'
    ,compensate_amt     DECIMAL(38,18) COMMENT '前期代偿金金额'
    ,act_service_amt    DECIMAL(38,18) COMMENT '实收前期服务费金额'
    ,act_guarantee_amt  DECIMAL(38,18) COMMENT '实收前期担保费金额'
    ,act_margin_amt     DECIMAL(38,18) COMMENT '实收前期保证金金额'
    ,act_compensate_amt DECIMAL(38,18) COMMENT '实收前期代偿金金额'
    ,repay_day          BIGINT COMMENT '还款日：每月还款日，1-28'
    ,total_term         BIGINT COMMENT '分期期数，单位：月 如： 1、3、6、12'
    ,loan_status        STRING COMMENT '借据状态：NOR-正常,OD-逾期中,FP-结清'
    ,remark             STRING COMMENT '备注'
    ,loan_month         STRING COMMENT '放款月份'
    ,lend_status        STRING COMMENT '放款状态 默认S成功'
    ,create_time        TIMESTAMP COMMENT '创建时间'
    ,update_time        TIMESTAMP COMMENT '更新时间'
    ,dw_create_time     TIMESTAMP COMMENT '数仓创建时间'
    ,dw_update_time     TIMESTAMP COMMENT '数仓更新时间'
    ,PRIMARY KEY (apply_no)
)
PARTITIONED BY 
(
    pt                  STRING COMMENT '分区字段：yyyymm，由loan_time生成'
)
STORED AS aliorc
TBLPROPERTIES ('acid.data.retain.hours' = '0','cdc.data.retain.hours' = '24','columnar.nested.type' = 'true','comment' = '消金放款信息表','transactional' = 'true','acid.cdc.mode.enable' = 'false','write.bucket.num' = '16')
;



-- ============================================================
-- 申请基本信息表（全量）
-- 原：f_prd_spark_db.apply_base_info（申请基本信息）
-- 非分区事务表（PK Delta Table）
-- 主键：apply_no
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_fake_apply_base_info_full_t (
    id                                  BIGINT      COMMENT '物理主键',
    recon_date                          STRING      COMMENT '对账日期：格式YYYY-MM-DD',
    apply_no                            STRING NOT NULL COMMENT '借款申请编号（主键）',
    name                                STRING      COMMENT '姓名/企业名称',
    id_card                             STRING      COMMENT '身份证号/统一社会信用代码',
    id_card_type                        STRING      COMMENT '用户证件类型 01-身份证,02-港澳通行证，03-其他，04-统一社会信用代码',
    id_address                          STRING      COMMENT '身份证地址',
    id_expiry_date                      STRING      COMMENT '身份证失效日期',
    mobile                              STRING      COMMENT '手机号',
    gender                              STRING      COMMENT '01-男；02-女',
    educational                         STRING      COMMENT '10-研究生及以上，20-大学本科，30-大专，40-中专，50-技术学校，60-高中，70-初中，80-小学，90-文盲或半文盲，99-未知',
    address_time                        DOUBLE      COMMENT '居住时长1年单位',
    address                             STRING      COMMENT '居住地',
    detail_address                      STRING      COMMENT '详细地址',
    house_condition                     STRING      COMMENT '1. 自有住房，无贷款2.自有住房，有按揭贷款3.自有住房，已抵押4.租房 5.其它',
    car_condition                       STRING      COMMENT '1. 无车2.本人名下有车，无贷款3.本人名下有车，有按揭贷款4. 本人名下有车，已抵押 5.其它',
    annual_income                       STRING      COMMENT '年收入单位万',
    is_pay_security                     STRING      COMMENT '是否缴纳社保Y-有 N-无',
    debts                               STRING      COMMENT '负债情况Y-有 N-无',
    often_email                         STRING      COMMENT '常用邮箱有则传，没有则不传',
    marry_status                       STRING      COMMENT '10-未婚，20-已婚 ，30-丧偶，40-离异',
    has_children                        STRING      COMMENT '是否有子女Y-有 N-无',
    salary_date                         STRING      COMMENT '工资发放日期有则传，没有则不传',
    industry                            STRING      COMMENT '从事行业/职业类别,1-单位所属行业，2-或个人职业类别',
    unit_name                           STRING      COMMENT '单位名称',
    unit_address                        STRING      COMMENT '单位所在地',
    unit_detail_address                 STRING      COMMENT '单位详细地址',
    unit_telphone                       STRING      COMMENT '单位电话',
    contact_a_ref                       STRING      COMMENT '紧急联系人A关系:10-亲属，20子女，30-朋友，40-师生，50-同学，60父母，70-同事，80-战友，90-其他',
    contact_a_name                      STRING      COMMENT '紧急联系人A姓名',
    contact_a_mobile                    STRING      COMMENT '通讯录导入电话号码',
    contact_b_ref                       STRING      COMMENT '紧急联系人B关系:10-亲属，20子女，30-朋友，40-师生，50-同学，60父母，70-同事，80-战友，90-其他',
    contact_b_name                      STRING      COMMENT '紧急联系人B姓名',
    contact_b_mobile                    STRING      COMMENT '通讯录导入电话号码',
    work_years                          DOUBLE      COMMENT '现单位工作年限',
    apply_ref                           STRING      COMMENT '借款人与企业关系 10-法人、20-%5以上股东、30-董事、40-实控人、50-高管、90-其他',
    is_common_apply                     STRING      COMMENT '是否共借 Y-是 N-否',
    ent_name                            STRING      COMMENT '企业名称',
    ent_id                              STRING      COMMENT '统一社会信用代码',
    ent_create_date                     STRING      COMMENT '成立日期：格式YYYY-MM-DD',
    legal_name                          STRING      COMMENT '法定代表人',
    industry_code                       STRING      COMMENT '所属行业',
    industry_divide                     STRING      COMMENT '企业划型：01 大型 02 中型 03小型 04 微型',
    ent_type                            STRING      COMMENT '企业类型：01-企业法人 02-政府机关、事业单位、社会团体 03-新型农业经营主体 04-农户 05-个体工商户、小微企业主 06-个人',
    area_name                           STRING      COMMENT '所属地区',
    registration_authority              STRING      COMMENT '登记机关',
    person_number                       INT         COMMENT '参保人数',
    registered_address                  STRING      COMMENT '注册地址',
    business_scope                      STRING      COMMENT '经营范围',
    contact_c_name                      STRING      COMMENT '联系人',
    contact_c_ref                       STRING      COMMENT '联系人职位 10-股东，20-董事长、30-总经理、40-副总经理、50-财务总监、60-员工、90-其他',
    contact_c_mobile                    STRING      COMMENT '联系人电话',
    last_year_begin_total_assets        DECIMAL(17,2) COMMENT '上年期初总资产',
    last_year_begin_total_liabilities   DECIMAL(17,2) COMMENT '上年期初总负债',
    last_year_end_total_assets          DECIMAL(17,2) COMMENT '上年期末总资产',
    last_year_end_total_liabilities     DECIMAL(17,2) COMMENT '上年期末总负债',
    last_year_annual_income             DECIMAL(17,2) COMMENT '上年增值税纳税申报表年收入',
    is_tree_year_tax_penalty            STRING      COMMENT '前三年是否存在税收违法记录 Y-是 N-否',
    litigation_amt                      DECIMAL(17,2) COMMENT '涉诉金额',
    is_enforcement                      STRING      COMMENT '是否列为被执行人 Y-是 N-否',
    is_dishonesty                       STRING      COMMENT '是否有失信信息 Y-是 N-否',
    is_high_consumption                 STRING      COMMENT '是否限制高消费 Y-是 N-否',
    is_business_abnormal                STRING      COMMENT '是否经营异常 Y-是 N-否',
    is_stock_equity_freeze              STRING      COMMENT '是否有股东股权冻结 Y-是 N-否',
    is_administrative_penalty           STRING      COMMENT '是否有行政处罚记录 Y-是 N-否',
    account_name                        STRING      COMMENT '开户姓名',
    card_no                             STRING      COMMENT '银行卡号',
    pre_mobile                          STRING      COMMENT '手机号',
    partner_no                          STRING      COMMENT '合作机构编号',
    loan_use                            STRING      COMMENT '借款用途01-消费，02-装修，03-旅游，04-教育，05-医疗，06-经营周转，07-其他，08-小微企业经营',
    loan_amt                            DECIMAL(10,2) COMMENT '借款金额',
    loan_period                         SMALLINT    COMMENT '借款期限1,3,12',
    face_merchants                      STRING      COMMENT '人脸照片服务商face++等',
    facce_supply_param                   STRING      COMMENT '人脸照片补充参数:服务商补充参数，如用于比对的delta值等',
    face_card_compare                    DOUBLE      COMMENT '身份证照片人脸比对结果，置信度、相似度等 83 90分值，精确2位小数',
    product_no                          STRING      COMMENT '借款产品编号',
    product_name                        STRING      COMMENT '借款产品名称',
    apply_time                          DATETIME    COMMENT '进件时间',
    loan_title                          STRING      COMMENT '借款标题',
    apply_status                        STRING      COMMENT '01进件成功，02进件失败',
    guarantee_type                      STRING      COMMENT '01-一般担保/02-连带保证责任',
    buis_mode                           STRING      COMMENT '业务模式,01-保障/02-限额保证/03-保证',
    rev_guarantee_type                  STRING      COMMENT '反担保方式',
    guarantee_scope                     STRING      COMMENT '担保范围:对哪些科目进行担保，如本金、利息、罚息、逾期违约金等',
    cfund_channel_no                    STRING      COMMENT '资金方编号',
    cfund_channel_name                  STRING      COMMENT '资金方名称',
    pay_way                             STRING      COMMENT '缴费方式:01-趸交/02-期缴/03-双棒',
    repay_way                           STRING      COMMENT '还款方式:01-等额本息、02-等额本金、03-按日计息',
    year_rate                           DECIMAL(11,8) COMMENT '综合实际年化利率',
    service_rate                        DECIMAL(11,8) COMMENT '前期服务费费率',
    guarantee_rate                      DECIMAL(11,8) COMMENT '前期担保费费率',
    margin_rate                         DECIMAL(11,8) COMMENT '前期保证金费率',
    compensate_rate                     DECIMAL(11,8) COMMENT '每期代偿金费率',
    act_year_rate                       DECIMAL(11,8) COMMENT '利率（实际年化）',
    period_service_rate                 DECIMAL(11,8) COMMENT '每期服务费费率',
    period_guarantee_rate               DECIMAL(11,8) COMMENT '每期担保费费率',
    period_margin_rate                  DECIMAL(11,8) COMMENT '每期保证金费率',
    period_compensate_rate              DECIMAL(11,8) COMMENT '每期代偿金费率',
    oint_rate                           DECIMAL(11,8) COMMENT '罚息日利率',
    oguarantee_rate                     DECIMAL(11,8) COMMENT '担保费罚息日利率',
    define_rate                         DECIMAL(11,8) COMMENT '逾期违约金/滞纳金费率',
    adv_define_rate                     DECIMAL(11,8) COMMENT '提前还款违约金费率',
    compensate_days                     INT         COMMENT '代偿天数',
    grace_day                           INT         COMMENT '宽限期',
    interest_free_period                INT         COMMENT '免息期',
    create_time                         DATETIME    COMMENT '创建时间',
    update_time                         DATETIME    COMMENT '更新时间',
    credit_time                         DATETIME    COMMENT '授信时间',
    credit_no                           STRING      COMMENT '资方授信单号',
    credit_apply_no                     STRING      COMMENT '授信申请单号',
    risk_info                           STRING      COMMENT '风险字段信息',
    PRIMARY KEY (apply_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '申请基本信息表',
    'write.bucket.num' = '16'
);



-- ============================================================
-- 产品信息表（全量，维表）
-- 原：f_prd_spark_db.fake_dim_base_prod_info（产品信息表）
-- 非分区事务表（PK Delta Table）
-- 主键：product_no
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_fake_prod_info_full_t (
    id                              BIGINT      COMMENT '主键',
    product_no                      STRING NOT NULL COMMENT '产品编号（主键）',
    product_name                    STRING      COMMENT '产品名称',
    guarantor_no                    STRING      COMMENT '担保方编号',
    guarantor_name                  STRING      COMMENT '担保方',
    platform_no                     STRING      COMMENT '平台方编号',
    platform_name                   STRING      COMMENT '平台方',
    financer_no                     STRING      COMMENT '资金方编号',
    financer_name                   STRING      COMMENT '资金方',
    project_no                      STRING      COMMENT '项目编号',
    system_no                       BIGINT      COMMENT '系统(900:车贷、901:消金系统、902：数据导入)',
    oa_platform_no                  STRING      COMMENT '外部系统平台编码',
    oa_cust_no                      STRING      COMMENT '担保公司编码',
    oa_partner_no                   STRING      COMMENT '合作方编码',
    oa_fund_no                      STRING      COMMENT '资金方编码',
    oa_it_no                        STRING      COMMENT '科技方编码',
    is_project_finish               STRING      COMMENT '项目是否已结束,Y是N否',
    project_finish_date             STRING      COMMENT '项目结束日期',
    is_project_company              STRING      COMMENT '客户是否为企业,Y是C同时含有个人N否',
    is_project_td                   STRING      COMMENT '借据是否通道简版数据,Y是N否',
    is_project_plan                 STRING      COMMENT '借据是否有还款计划数据,Y有N否',
    is_project_plan_update          STRING      COMMENT '借据是否有还款计划实还更新数据,Y有C有但未上线N否',
    is_project_plan_reset           STRING      COMMENT '借据是否有还款计划缩期情况,Y有C有但未上线N否',
    is_project_repay1               STRING      COMMENT '借据是否有正常还款数据,Y有C有但未上线N否',
    is_project_repay4               STRING      COMMENT '借据是否有提前还款数据,Y有C有但未上线N否',
    is_project_repay5               STRING      COMMENT '借据是否有提前结清数据,Y有C有但未上线N否',
    is_project_repay7               STRING      COMMENT '借据是否有代偿还款数据,Y有C有但未上线N否',
    is_project_total_repay7         STRING      COMMENT '借据是否有累计代偿还款数据,Y有C有但未上线N否',
    is_project_total_repay          STRING      COMMENT '借据是否有用户累计还款数据,Y有C有但未上线N否',
    is_project_repay8               STRING      COMMENT '借据是否有追偿还款数据,Y有C有但未上线N否',
    is_project_repay7_finish        STRING      COMMENT '借据是否代偿时结清,Y是N否',
    is_project_repay8_normal        STRING      COMMENT '借据追偿还款是否按正常还款提供,Y是N否',
    is_result_fpd10                 STRING      COMMENT 'FPD10是否可用，Y是N否',
    is_result_vintage               STRING      COMMENT 'vintage是否可用，Y是N否',
    is_result_balance_distribution  STRING      COMMENT '余额分布是否可用，Y是N否',
    remark                          STRING      COMMENT '备注',
    status                          STRING      COMMENT '状态（0正常 1停用）',
    check_status                    STRING      COMMENT '审核状态 0新增审核状态，1修改项目审核中，2删除项目审核中，3（-）',
    description                     STRING      COMMENT '说明',
    create_time                     DATETIME    COMMENT '创建时间',
    update_time                     DATETIME    COMMENT '更新时间',
    create_by                       STRING      COMMENT '创建者',
    update_by                       STRING      COMMENT '更新人',
    biz_type                        STRING      COMMENT '业务类型 01-个人业务 02-对公业务',
    product_type                    STRING      COMMENT '产品类型',
    min_credit_limit                BIGINT      COMMENT '最低授信额度',
    max_credit_limit                BIGINT      COMMENT '最高授信额度',
    min_inte_rate                   DECIMAL(11,8) COMMENT '最低利率 年化小数',
    max_inte_rate                   DECIMAL(11,8) COMMENT '最高利率  年化小数',
    min_credit_spread               INT         COMMENT '最短授信期限',
    max_credit_spread               INT         COMMENT '最长授信期限',
    grt_method                      STRING      COMMENT '担保方式 01-信用 02-抵押 03-质押',
    repayment_method                STRING      COMMENT '还款方式',
    prepayment                      STRING      COMMENT '是否允许提前还款 0-可以提前还款 1-不可以提前还款',
    repayment_data                  TINYINT     COMMENT '还款数据优先级 1-优先还款信息 2-优先还款计划',
    act_year_rate                   DECIMAL(11,8) COMMENT '利率（实际年化）',
    service_rate                    DECIMAL(11,8) COMMENT '前期服务费费率',
    guarantee_rate                  DECIMAL(11,8) COMMENT '前期担保费费率',
    margin_rate                     DECIMAL(11,8) COMMENT '前期保证金费率',
    compensate_rate                 DECIMAL(11,8) COMMENT '前期代偿金费率',
    period_service_rate             DECIMAL(11,8) COMMENT '年化服务费费率',
    period_guarantee_rate           DECIMAL(11,8) COMMENT '年化担保费费率',
    period_margin_rate              DECIMAL(11,8) COMMENT '年化保证金费率',
    period_compensate_rate          DECIMAL(11,8) COMMENT '年化代偿金费率',
    oint_rate                       DECIMAL(11,8) COMMENT '罚息日利率',
    define_rate                     DECIMAL(11,8) COMMENT '逾期违约金/滞纳金费率',
    adv_define_rate                 DECIMAL(11,8) COMMENT '提前还款违约金费率',
    compensate_days                 SMALLINT    COMMENT '代偿天数',
    cpst_rule_no                    STRING      COMMENT '代偿规则编号',
    grace_day                       SMALLINT    COMMENT '宽限期',
    interest_free_period            SMALLINT    COMMENT '免息期',
    is_cpst                         STRING      COMMENT '是否提供代偿 0-是 1-否',
    is_recovery                     STRING      COMMENT '是否提供追偿 0-是 1-否',
    fee1_rate                       DECIMAL(11,8) COMMENT '费率1',
    fee2_rate                       DECIMAL(11,8) COMMENT '费率2',
    fee3_rate                       DECIMAL(11,8) COMMENT '费率3',
    fee4_rate                       DECIMAL(11,8) COMMENT '费率4',
    fee5_rate                       DECIMAL(11,8) COMMENT '费率5',
    fee6_rate                       DECIMAL(11,8) COMMENT '费率6',
    fee7_rate                       DECIMAL(11,8) COMMENT '费率7',
    fee8_rate                       DECIMAL(11,8) COMMENT '费率8',
    dw_create_time                  DATETIME    COMMENT '创建时间',
    dw_update_time                  DATETIME    COMMENT '修改时间',
    is_end                          STRING      COMMENT '是否结束 Y是  N否',
    project_name                    STRING      COMMENT '项目名称',
    yw_user                         STRING      COMMENT '业务负责人',
    cw_user                         STRING      COMMENT '财务负责人',
    db_identifier                   STRING      COMMENT '数据库标识',
    ext_remark                      STRING      COMMENT '业务管控-项目备注',
    PRIMARY KEY (product_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '产品信息表',
    'write.bucket.num' = '4'
);

-- ============================================================
-- 原：f_prd_spark_db.guarantee_company_detail（担保公司配置详情表）
-- 源库：f_prd_spark_db
-- 非分区事务表（PK Delta Table）
-- 主键：id
-- 数据量：小表（配置表），4个桶
-- ============================================================
CREATE TABLE IF NOT EXISTS guarantee_company_detail (
    id                          BIGINT NOT NULL COMMENT '担保公司配置信息—主键',
    company_id                  INT NOT NULL COMMENT '担保公司ID：sys_company表ID',
    control_type                STRING NOT NULL COMMENT '业务管控类型：1-金融局 2-资方',
    net_assets                  DOUBLE COMMENT '净资产-单位：元',
    guarantee_multiple          DOUBLE COMMENT '担保倍数',
    max_limit                   DOUBLE COMMENT '最大担保额度-单位：元',
    warning_balance_limit       DOUBLE COMMENT '担保余额比例预警下限',
    warning_switch_limit        STRING COMMENT '下限预警开关：T-打开预警 F-关闭预警',
    warning_balance_max         DOUBLE COMMENT '担保余额比例预警上限',
    warning_switch_max          STRING COMMENT '上限预警开关：T-打开预警 F-关闭预警',
    business_control_rule_id    BIGINT COMMENT '业务管控规则id',
    create_time                 DATETIME COMMENT '首次配置时间',
    update_time                 DATETIME COMMENT '最后修改时间',
    PRIMARY KEY (id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '担保公司配置详情表',
    'write.bucket.num' = '4'
);

-- ============================================================
-- 原：f_prd_spark_db.tmp_replace_farmer_bills_d（农户替换借据清单）
-- 非分区普通表（支持 INSERT OVERWRITE）
-- 数据量：约130万，4个桶
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_replace_farmer_bills_full_t_tmp (
    loandate_id    BIGINT COMMENT '放款时间段ID，对应business_control_loandate_detail.loandate_id',
    bill_app_no    STRING COMMENT '借据号（或申请号apply_no）',
    num            BIGINT COMMENT '排序序号，用于确定被选中的借据',
    agri_flag      INT COMMENT '是否农户标志：0为农户，1为非农户',
    replace_cnt    BIGINT COMMENT '该放款时间段需替换为农户的借据数量',
    create_time    DATETIME COMMENT '数据生成时间',
    update_time    DATETIME COMMENT '数据更新时间'
)
STORED AS ALIORC
TBLPROPERTIES (
    'comment' = '业务管控：待替换为农户的借据清单',
    'write.bucket.num' = '4'
);

-- ============================================================
-- 原：f_prd_spark_db.tmp_farmer_candidates_d（农户候选清单）
-- 非分区普通表（支持 INSERT OVERWRITE）
-- 数据量：2亿+，256个桶（高并发）
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_farmer_candidates_full_t_tmp (
    business_control_rule_id    STRING COMMENT '业务管控规则ID',
    loandate_id                 STRING COMMENT '放款时间段ID',
    id_card                     STRING COMMENT '农户身份证号',
    province_code               STRING COMMENT '身份证前两位，对应省份编码',
    create_time                 DATETIME COMMENT '记录生成时间'
)
STORED AS ALIORC
TBLPROPERTIES (
    'comment' = '业务管控：符合区域要求的农户清单（用于借据替换）',
    'write.bucket.num' = '256'
);

-- ============================================================
-- 原：f_prd_spark_db.dim_dict_data（地区编码字典表）
-- 非分区普通表
-- 数据量：小表，4个桶
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_dict_data (
    id          BIGINT COMMENT '主键',
    dict_type   STRING COMMENT '字典类型',
    dict_code   STRING COMMENT '字典编码',
    dict_value  STRING COMMENT '字典值'
)
STORED AS ALIORC
TBLPROPERTIES (
    'comment' = '地区编码字典表',
    'write.bucket.num' = '4'
);

-- ============================================================
-- 原：f_prd_spark_db.bizctrl_loan_date_adjusted（业务管控-放款时间调整结果表）
-- 非分区PK Delta Table（transactional=true）
-- 数据量：约2300万条，32个桶（高并发）
-- 主键：(bill_app_no, project_id) —— 唯一性保留
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_bizctrl_loan_date_adjusted_full_t (
    bill_app_no        STRING NOT NULL COMMENT '借款申请编号（主键）',
    product_no         STRING COMMENT '产品编号',
    project_id         BIGINT NOT NULL COMMENT '新项目ID（主键，关联加速）',
    old_project_id     BIGINT COMMENT '原项目ID',
    project_rule_id    BIGINT COMMENT '业务管控规则ID',
    old_loan_date      STRING COMMENT '原放款日期：yyyy-MM-dd',
    new_loan_date      STRING COMMENT '调整后放款日期：yyyy-MM-dd',
    loan_begin_date    STRING COMMENT '规则适用放款开始日期：yyyy-MM-dd',
    loan_end_date      STRING COMMENT '规则适用放款结束日期：yyyy-MM-dd',
    adjust_date        STRING COMMENT '调整目标日期：yyyy-MM-dd',
    shift_days         INT COMMENT '平移天数（adjust_date - loan_begin_date）',
    shift_months       INT COMMENT '平移月份数（按自然月计算）',
    is_adjusted        INT COMMENT '是否调整放款时间：0=未调整 1=已调整',
    adjust_reason      STRING COMMENT '调整原因（规则平移等）',
    create_time        DATETIME COMMENT '创建时间',
    update_time        DATETIME COMMENT '更新时间',
    PRIMARY KEY (bill_app_no, project_id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '业务管控-放款时间调整结果表',
    'write.bucket.num' = '32'
);

-- ============================================================
-- 原：f_prd_spark_db.auto_bizctrl_company_bill_d_bak（放款时间调整备份表）
-- 非分区普通表（支持 INSERT INTO 追加备份记录）
-- 数据量：每日增量备份，按需清理历史数据
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_auto_bizctrl_company_bill_bak (
    bill_app_no              STRING COMMENT '借款申请编号',
    project_id               BIGINT COMMENT '项目编号',
    business_control_rule_id BIGINT COMMENT '公司规则ID',
    product_no               STRING COMMENT '产品编码',
    id_card                  STRING COMMENT '证件号码',
    old_loan_day             STRING COMMENT '调整前放款日期：yyyy-MM-dd',
    backup_time              DATETIME COMMENT '备份时间'
)
STORED AS ALIORC
TBLPROPERTIES (
    'comment' = '自动-公司规则粒度借据放款时间调整备份表',
    'write.bucket.num' = '16'
);

-- ============================================================
-- 原：f_prd_spark_db.manual_bizctrl_company_bill_d_bak（放款时间调整备份表-手动）
-- 非分区普通表（支持 INSERT INTO 追加备份记录）
-- 数据量：每日增量备份，按需清理历史数据
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_manual_bizctrl_company_bill_bak (
    bill_app_no              STRING COMMENT '借款申请编号',
    project_id               BIGINT COMMENT '项目编号',
    business_control_rule_id BIGINT COMMENT '公司规则ID',
    product_no               STRING COMMENT '产品编码',
    id_card                  STRING COMMENT '证件号码',
    old_loan_day             STRING COMMENT '调整前放款日期：yyyy-MM-dd',
    backup_time              DATETIME COMMENT '备份时间'
)
STORED AS ALIORC
TBLPROPERTIES (
    'comment' = '手动-公司规则粒度借据放款时间调整备份表',
    'write.bucket.num' = '16'
);

-- ============================================================
-- 原：f_prd_spark_db.dim_sys_company_composite（虚拟公司表/组合公司表）
-- 非分区PK Delta Table（transactional=true）
-- 数据量：小表（虚拟公司数量有限），4个桶
-- 主键：id —— 唯一性保留
-- 用途：028中通过id关联补充资产方/资金方公司名称
-- ============================================================
CREATE TABLE IF NOT EXISTS dim_sys_company_composite (
    id                BIGINT NOT NULL COMMENT '主键ID',
    composite_name    STRING NOT NULL COMMENT '组合名称（拼接后的显示名称）',
    composite_type    STRING NOT NULL COMMENT '组合类型：1-资金方 2-资产端',
    is_virtual        STRING COMMENT '是否虚拟公司：1-是 0-否',
    create_by         STRING COMMENT '创建者',
    create_time       DATETIME COMMENT '创建时间',
    update_by         STRING COMMENT '更新者',
    update_time       DATETIME COMMENT '更新时间',
    PRIMARY KEY (id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '虚拟公司表（组合公司）',
    'write.bucket.num' = '4'
);



-- 原：prd_spark_db.dim_base_institute_info（机构信息表）
-- ============================================================
CREATE TABLE IF NOT EXISTS prod_dw_01.dim_base_institute_info_full_t
(
    com_no            BIGINT NOT NULL COMMENT '公司编号-主键'
    ,company_code     STRING COMMENT '公司编码'
    ,com_name         STRING COMMENT '公司名称'
    ,com_short_name   STRING COMMENT '公司简称'
    ,com_reg_addr     STRING COMMENT '公司注册地'
    ,contact_name     STRING COMMENT '联系人'
    ,contact_mobile   STRING COMMENT '联系人电话'
    ,email            STRING COMMENT '联系邮箱'
    ,postcode         STRING COMMENT '邮政编码'
    ,business_address STRING COMMENT '办公地址'
    ,website          STRING COMMENT '网站'
    ,company_no       STRING COMMENT '统一社会信用代码'
    ,is_inside        STRING COMMENT '是否为内部公司，1是 0否'
    ,`status`         STRING COMMENT '状态，0正常 1禁用'
    ,`source`         STRING COMMENT '数据来源(1公司信息 2项目立项)'
    ,check_status     STRING COMMENT '审核状态 0新增审核状态，1修改项目审核中，2删除项目审核中，3（-）'
    ,create_by        STRING COMMENT '创建者'
    ,create_time      STRING COMMENT '创建时间'
    ,update_by        STRING COMMENT '更新者'
    ,update_time      STRING COMMENT '更新时间'
    ,dw_create_time   TIMESTAMP COMMENT '数仓创建时间'
    ,dw_update_time   TIMESTAMP COMMENT '数仓更新时间'
    ,PRIMARY KEY (com_no)
)
STORED AS aliorc
TBLPROPERTIES ('columnar.nested.type' = 'true','comment' = '机构信息表')
;

-- 原：prd_spark_db.dim_base_project_info（项目信息表）
-- ============================================================
CREATE TABLE IF NOT EXISTS prod_dw_01.dim_base_project_info_full_t
(
    project_no              BIGINT NOT NULL COMMENT '项目编号'
    ,project_name           STRING COMMENT '项目名称'
    ,company_no             BIGINT COMMENT '公司编码'
    ,channel_type           STRING COMMENT '渠道方类型 1内部渠道方 2外部渠道方'
    ,channel_name           STRING COMMENT '渠道方'
    ,fund_credit_limit      STRING COMMENT '资方授信额度'
    ,project_type           STRING COMMENT '0通道业务1法催业务2分润业务3保函业务'
    ,is_enable              STRING COMMENT '是否启用Y启用N禁用'
    ,create_br              STRING COMMENT '创建人'
    ,create_time            STRING COMMENT '创建时间'
    ,update_br              STRING COMMENT '更新人'
    ,update_time            STRING COMMENT '更新时间'
    ,add_not_approve        STRING COMMENT '新增未审批标识。当新增未审批过的为9，新增审批过的为0'
    ,cw_relevance_status    STRING COMMENT '是否与财务项目管理关联，0-否，1-是'
    ,yw_user                STRING COMMENT '业务负责人'
    ,cw_user                STRING COMMENT '财务负责人'
    ,guarantor_no           STRING COMMENT '担保方编号'
    ,guarantor_name         STRING COMMENT '担保方'
    ,platform_no            STRING COMMENT '平台方编号'
    ,platform_name          STRING COMMENT '平台方'
    ,financer_no            STRING COMMENT '资金方编号'
    ,financer_name          STRING COMMENT '资金方'
    ,project_date           STRING COMMENT '立项时间'
    ,project_status         STRING COMMENT '项目状态(1对接中 2尽调中 3待上会 4合同签署 5已上线 6新增立项审核中 7认领项目审核中 8延期项目审核中 9终止项目审核中 10修改立项审核中 11修改项目审核中 12已终止)'
    ,product_type_no        BIGINT COMMENT '产品类型编号'
    ,product_type           STRING COMMENT '产品类型'
    ,parent_product_type_no BIGINT COMMENT '产品类型编号'
    ,parent_product_type    STRING COMMENT '产品类型'
    ,dw_create_time         TIMESTAMP COMMENT '数仓创建时间'
    ,dw_update_time         TIMESTAMP COMMENT '数仓更新时间'
    ,PRIMARY KEY (project_no)
)
STORED AS aliorc
TBLPROPERTIES ('columnar.nested.type' = 'true','comment' = '项目信息表')
;


-- 原：prd_spark_db.ods_cons_apply_base_info_d（借款申请基本信息增量表-incr_delta）
-- ============================================================
CREATE TABLE IF NOT EXISTS prod_dw_01.ods_cons_apply_base_info_incr_delta
(
    id                                 BIGINT COMMENT '自增主键'
    ,recon_date                        STRING COMMENT '对账日期：格式YYYY-MM-DD'
    ,apply_no                          STRING NOT NULL COMMENT '借款申请编号'
    ,name                              STRING COMMENT '姓名/企业名称'
    ,id_card                           STRING COMMENT '身份证号/统一社会信用代码'
    ,id_card_type                      STRING COMMENT '用户证件类型 01-身份证,02-港澳通行证，03-其他，04-统一社会信用代码'
    ,id_address                        STRING COMMENT '身份证地址'
    ,id_expiry_date                    STRING COMMENT '身份证失效日期'
    ,mobile                            STRING COMMENT '手机号'
    ,gender                            STRING COMMENT '01-男；02-女'
    ,educational                       STRING COMMENT '10-研究生及以上，20-大学本科，30-大专，40-中专，50-技术学校，60-高中，70-初中，80-小学，90-文盲或半文盲，99-未知'
    ,address_time                      STRING COMMENT '居住时长1年单位'
    ,address                           STRING COMMENT '居住地'
    ,detail_address                    STRING COMMENT '详细地址'
    ,house_condition                   STRING COMMENT '1. 自有住房，无贷款2.自有住房，有按揭贷款3.自有住房，已抵押4.租房 5.其它'
    ,car_condition                     STRING COMMENT '1. 无车2.本人名下有车，无贷款3.本人名下有车，有按揭贷款4. 本人名下有车，已抵押 5.其它'
    ,annual_income                     STRING COMMENT '年收入单位万'
    ,is_pay_security                   STRING COMMENT '是否缴纳社保Y-有 N-无'
    ,debts                             STRING COMMENT '负债情况Y-有 N-无'
    ,often_email                       STRING COMMENT '常用邮箱有则传，没有则不传'
    ,marry_status                      STRING COMMENT '10-未婚，20-已婚 ，30-丧偶，40-离异'
    ,has_children                      STRING COMMENT '是否有子女Y-有 N-无'
    ,salary_date                       STRING COMMENT '工资发放日期有则传，没有则不传'
    ,employent_status                  STRING COMMENT '就业状况 11 国家公务员 13 专业技术人员 17 职员 21 企业管理人员 24 工人 27 农民 31 学生 37 现役军人 51 自由职业者 54 个体经营者 70 无业人员 80 退（离）休人员 90 其他 91 在职 99 未知   20...'
    ,industry                          STRING COMMENT '从事行业/职业类别,1-单位所属行业，2-或个人职业类别   20251215新增：A—农、林、牧、渔业； B—采掘业； C—制造业； D—电力、燃气及水的生产和供应业； E—建筑业； F—交通运输、仓储和邮政业； G—信息传输、计算机服务和软件业；...'
    ,occupation                        STRING COMMENT '职业 0—国家机关、党群组织、企业、事业单位负责人； 1—专业技术人员； 3—办事人员和有关人员； 4—商业服务业人员； 5—农、林、牧、渔、水利业生产人员； 6—生产、运输设备操作人员及有关人员； X—军人； Y—不便分类的其他从业人员； Z—未知...'
    ,duty                              STRING COMMENT '职务  1-高级领导；2-中级领导；3-一般员工；4-其他；9-未知  20251215新增'
    ,title                             BIGINT COMMENT '职称 0-无；1-高级；2-中级；3-初级；9-未知 20251215新增'
    ,unit_name                         STRING COMMENT '单位名称'
    ,unit_address                      STRING COMMENT '单位所在地'
    ,unit_detail_address               STRING COMMENT '单位详情地址'
    ,unit_telphone                     STRING COMMENT '单位电话'
    ,contact_a_ref                     STRING COMMENT '紧急联系人A关系:10-亲属，20子女，30-朋友，40-师生，50-同学，60父母，70-同事，80-战友，90-其他'
    ,contact_a_name                    STRING COMMENT '紧急联系人A姓名'
    ,contact_a_mobile                  STRING COMMENT '通讯录导入电话号码'
    ,contact_b_ref                     STRING COMMENT '紧急联系人B关系:10-亲属，20子女，30-朋友，40-师生，50-同学，60父母，70-同事，80-战友，90-其他'
    ,contact_b_name                    STRING COMMENT '紧急联系人B姓名'
    ,contact_b_mobile                  STRING COMMENT '通讯录导入电话号码'
    ,work_years                        STRING COMMENT '现单位工作年限'
    ,apply_ref                         STRING COMMENT '借款人与企业关系 10-法人、20-%5以上股东、30-董事、40-实控人、50-高管、90-其他'
    ,is_common_apply                   STRING COMMENT '是否共借 Y-是 N-否'
    ,ent_name                          STRING COMMENT '企业名称'
    ,ent_id                            STRING COMMENT '统一社会信用代码'
    ,ent_create_date                   STRING COMMENT '成立日期：格式YYYY-MM-DD'
    ,legal_name                        STRING COMMENT '法定代表人'
    ,industry_code                     STRING COMMENT '所属行业'
    ,industry_divide                   STRING COMMENT '企业划型：01 大型 02 中型 03小型 04 微型'
    ,ent_type                          STRING COMMENT '企业类型：01-企业法人 02-政府机关、事业单位、社会团体 03-新型农业经营主体 04-农户 05-个体工商户、小微企业主 06-个人'
    ,area_name                         STRING COMMENT '所属地区'
    ,registration_authority            STRING COMMENT '登记机关'
    ,person_number                     BIGINT COMMENT '参保人数'
    ,registered_address                STRING COMMENT '注册地址'
    ,business_scope                    STRING COMMENT '经营范围'
    ,contact_c_name                    STRING COMMENT '联系人'
    ,contact_c_ref                     STRING COMMENT '联系人职位 10-股东，20-董事长、30-总经理、40-副总经理、50-财务总监、60-员工、90-其他'
    ,contact_c_mobile                  STRING COMMENT '联系人电话'
    ,last_year_begin_total_assets      STRING COMMENT '上年期初总资产'
    ,last_year_begin_total_liabilities STRING COMMENT '上年期初总负债'
    ,last_year_end_total_assets        STRING COMMENT '上年期末总资产'
    ,last_year_end_total_liabilities   STRING COMMENT '上年期末总负债'
    ,last_year_annual_income           STRING COMMENT '上年增值税纳税申报表年收入'
    ,is_tree_year_tax_penalty          STRING COMMENT '前三年是否存在税收违法记录 Y-是 N-否'
    ,litigation_amt                    STRING COMMENT '涉诉金额'
    ,is_enforcement                    STRING COMMENT '是否列为被执行人 Y-是 N-否'
    ,is_dishonesty                     STRING COMMENT '是否有失信信息 Y-是 N-否'
    ,is_high_consumption               STRING COMMENT '是否限制高消费 Y-是 N-否'
    ,is_business_abnormal              STRING COMMENT '是否经营异常 Y-是 N-否'
    ,is_stock_equity_freeze            STRING COMMENT '是否有股东股权冻结 Y-是 N-否'
    ,is_administrative_penalty         STRING COMMENT '是否有行政处罚记录 Y-是 N-否'
    ,account_name                      STRING COMMENT '开户姓名'
    ,card_no                           STRING COMMENT '银行卡号'
    ,pre_mobile                        STRING COMMENT '手机号'
    ,partner_no                        STRING COMMENT '合作机构编号'
    ,loan_use                          STRING COMMENT '借款用途01-消费，02-装修，03-旅游，04-教育，05-医疗，06-经营周转，07-其他，08-小微企业经营'
    ,loan_amt                          STRING COMMENT '借款金额'
    ,loan_period                       BIGINT COMMENT '借款期限1,3,12'
    ,face_merchants                    STRING COMMENT '人脸照片服务商face++等'
    ,face_supply_param                 STRING COMMENT '人脸照片补充参数:服务商补充参数，如用于比对的delta值等'
    ,face_card_compare                 STRING COMMENT '身份证照片人脸比对结果，置信度、相似度等 83 90分值，精确2位小数'
    ,product_no                        STRING COMMENT '借款产品编号'
    ,product_name                      STRING COMMENT '借款产品名称'
    ,apply_time                        TIMESTAMP COMMENT '进件时间'
    ,loan_title                        STRING COMMENT '借款标题'
    ,apply_status                      STRING COMMENT '01进件成功，02进件失败'
    ,guarantee_type                    STRING COMMENT '01-一般担保/02-连带保证责任'
    ,buis_mode                         STRING COMMENT '业务模式,01-保障/02-限额保证/03-保证'
    ,rev_guarantee_type                STRING COMMENT '反担保方式'
    ,guarantee_scope                   STRING COMMENT '担保范围:对哪些科目进行担保，如本金、利息、罚息、逾期违约金等'
    ,cfund_channel_no                  STRING COMMENT '资金方编号'
    ,cfund_channel_name                STRING COMMENT '资金方名称'
    ,pay_way                           STRING COMMENT '缴费方式:01-趸交/02-期缴/03-双棒'
    ,repay_way                         STRING COMMENT '还款方式:01-等额本息、02-等额本金、03-按日计息'
    ,year_rate                         STRING COMMENT '综合实际年化利率'
    ,service_rate                      STRING COMMENT '前期服务费费率'
    ,guarantee_rate                    STRING COMMENT '前期担保费费率'
    ,margin_rate                       STRING COMMENT '前期保证金费率'
    ,compensate_rate                   STRING COMMENT '每期代偿金费率'
    ,act_year_rate                     STRING COMMENT '利率（实际年化）'
    ,period_service_rate               DECIMAL(38,18) COMMENT '每期服务费费率'
    ,period_guarantee_rate             DECIMAL(38,18) COMMENT '每期担保费费率'
    ,period_margin_rate                DECIMAL(38,18) COMMENT '每期保证金费率'
    ,period_compensate_rate            DECIMAL(38,18) COMMENT '每期代偿金费率'
    ,oint_rate                         STRING COMMENT '罚息日利率'
    ,oguarantee_rate                   STRING COMMENT '担保费罚息日利率'
    ,define_rate                       STRING COMMENT '逾期违约金/滞纳金费率'
    ,adv_define_rate                   STRING COMMENT '提前还款违约金费率'
    ,compensate_days                   BIGINT COMMENT '代偿天数'
    ,grace_day                         BIGINT COMMENT '宽限期'
    ,interest_free_period              BIGINT COMMENT '免息期'
    ,create_time                       TIMESTAMP COMMENT '创建时间'
    ,update_time                       TIMESTAMP COMMENT '更新时间'
    ,credit_time                       TIMESTAMP COMMENT '授信时间'
    ,credit_no                         STRING COMMENT '资方授信单号'
    ,credit_apply_no                   STRING COMMENT '授信申请单号'
    ,risk_info                         STRING COMMENT '风险字段信息'
    ,dw_create_time                    TIMESTAMP COMMENT '数仓创建时间'
    ,dw_update_time                    TIMESTAMP COMMENT '数仓更新时间'
    ,PRIMARY KEY (apply_no)
)
PARTITIONED BY 
(
    pt                                 STRING COMMENT '分区字段：yyyymm，由apply_time生成'
)
STORED AS aliorc
TBLPROPERTIES ('cdc.data.retain.hours' = '24','acid.cdc.mode.enable' = 'false','acid.data.retain.hours' = '0','columnar.nested.type' = 'true','comment' = '消金申请基本信息','transactional' = 'true','write.bucket.num' = '16')
;


-- 撤保表
CREATE TABLE IF NOT EXISTS prod_dw_01.ods_cons_loan_cancel_full_t
(
    id              BIGINT COMMENT '主键'
    ,recon_date     STRING COMMENT '对账日期'
    ,product_no     STRING COMMENT '产品编码'
    ,apply_no       STRING NOT NULL COMMENT '借款申请编号'
    ,lend_status    STRING COMMENT '放款状态 S成功 F失败'
    ,cancel_time    TIMESTAMP COMMENT '撤单日期'
    ,loan_req_no    STRING COMMENT '放款流水号'
    ,name           STRING COMMENT '姓名/企业名称'
    ,id_card_type   STRING COMMENT '用户证件类型：01-身份证,02-港澳通行证,03-其他,04-统一社会信用代码'
    ,id_card        STRING COMMENT '身份证号/统一社会信用代码'
    ,loan_amt       DECIMAL(38,18) COMMENT '撤单金额'
    ,remark         STRING COMMENT '备注'
    ,create_time    TIMESTAMP COMMENT '创建时间'
    ,update_time    TIMESTAMP COMMENT '更新时间'
    ,dw_create_time TIMESTAMP COMMENT '数仓创建时间'
    ,dw_update_time TIMESTAMP COMMENT '数仓更新时间'
    ,PRIMARY KEY (apply_no)
)
STORED AS aliorc
TBLPROPERTIES ('columnar.nested.type' = 'true','comment' = '消金撤保信息表')
;


-- ============================================================
-- ALTER语句：为消金还款表现表新增追偿、逾期字段
-- 涉及表：
--   1. dwd_req_cons_payment_performance_incr_delta（目标表）
--   2. dwd_req_cons_payment_performance_incr_delta_003_tmp（003中间表）
--   3. dwd_req_cons_payment_performance_incr_delta_004_tmp（004中间表）
--   4. dwd_req_cons_payment_performance_incr_delta_005_tmp（005中间表）
-- ============================================================

-- 1. 目标表
ALTER TABLE dwd_req_cons_payment_performance_incr_delta ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);

-- 2. 003中间表
ALTER TABLE dwd_req_cons_payment_performance_incr_delta_003_tmp ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);

-- 3. 004中间表
ALTER TABLE dwd_req_cons_payment_performance_incr_delta_004_tmp ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);

-- 4. 005中间表
ALTER TABLE dwd_req_cons_payment_performance_incr_delta_005_tmp ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);


-- ============================================================
-- 车贷还款表现相关表 - 新增字段ALTER语句
-- 涉及表：
--   1. dwd_req_auto_balance_repay_info_incr_delta（目标表）
--   2. dwd_req_auto_balance_repay_info_incr_delta_007_tmp（007中间表）
--   3. dwd_req_auto_balance_repay_info_incr_delta_008_tmp（008中间表）
-- ============================================================

-- 1. 车贷目标表
ALTER TABLE dwd_req_auto_balance_repay_info_incr_delta ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);

-- 2. 007中间表
ALTER TABLE dwd_req_auto_balance_repay_info_incr_delta_007_tmp ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);

-- 3. 008中间表
ALTER TABLE dwd_req_auto_balance_repay_info_incr_delta_008_tmp ADD COLUMNS (
    recovery_principal          DECIMAL(38,18) COMMENT '追偿本金',
    recovery_total_amount       DECIMAL(38,18) COMMENT '追偿总额（本金+利息）',
    overdue_days                BIGINT COMMENT '逾期天数',
    overdue_amount              DECIMAL(38,18) COMMENT '逾期金额',
    max_overdue_days            BIGINT COMMENT '历史最大逾期天数'
);


-- ============================================================
-- 原：f_prd_spark_db.business_control_rule（管控规则表）
-- 非分区PK Delta Table（transactional=true）
-- 数据量：小表，1个桶
-- 主键：id —— 唯一性保留
-- 用途：030更新规则导入状态
-- ============================================================
CREATE TABLE IF NOT EXISTS prod_f_dw.business_control_rule
(
    id               BIGINT COMMENT '主键id'
    ,rule_name       STRING COMMENT '规则名称'
    ,show_dimensions STRING COMMENT '展示维度 1-金融局 2-资方'
    ,is_offline_data STRING COMMENT '是否为线下报送数据 1-是 0-否'
    ,remark          STRING COMMENT '备注'
    ,is_public       STRING COMMENT '是否公开 0-是 1-否'
    ,create_time     TIMESTAMP COMMENT '创建时间'
    ,update_time     TIMESTAMP COMMENT '更新时间'
    ,`status`        STRING COMMENT '数据状态 1-未导入 2-导入中 3-导入完成'
    ,url             STRING COMMENT '规则访问url'
)
STORED AS aliorc
TBLPROPERTIES ('cdc.data.retain.hours' = '24','acid.cdc.mode.enable' = 'false','acid.data.retain.hours' = '24','columnar.nested.type' = 'true','comment' = '管控规则','transactional' = 'true','write.bucket.num' = '1')
;


-- ============================================================
-- 原：prd_spark_db.dim_car（车辆信息表）
-- 源库：prd_spark_db
-- 非分区PK Delta Table（transactional=true）
-- 数据量：中等，16个桶
-- 主键：id —— 唯一性保留
-- 用途：034关联获取车牌省份、车架号、评估价格等车辆信息
-- ============================================================
CREATE TABLE IF NOT EXISTS prod_dw_01.ods_auto_oapi_car_full_t(
	id STRING COMMENT '唯一编码',
	 channel_id STRING COMMENT '资产方固定特殊唯一编码',
	 oapi_project_id STRING COMMENT '立项 id',
	 tenant_id STRING COMMENT '租户 ID',
	 vehicle_license_addr STRING COMMENT '行驶证住址',
	 rent_plan_code STRING NOT NULL COMMENT '借款申请编号',
	 is_in_stock BIGINT COMMENT '车本是否在库',
	 is_mortgage BIGINT COMMENT '是否已抵押',
	 car_type STRING COMMENT '车辆类型 01-乘用车   02-LCV',
	 brand_name STRING COMMENT '车辆品牌',
	 car_body_color STRING COMMENT '车身颜色',
	 car_register_date STRING COMMENT '首次登记日期',
	 is_non_local_license_plate STRING COMMENT '是否异地车牌',
	 maker_name STRING COMMENT '制造商名称',
	 register_reissue_date STRING COMMENT '登记证最近补领日期',
	 transfer_times STRING COMMENT '过户次数',
	 vehicle_license_addr_detail STRING COMMENT '行驶证住址详细',
	 license_plate_num STRING COMMENT '车牌号',
	 vin STRING COMMENT '车架号',
	 engine_num STRING COMMENT '发动机号',
	 model_year STRING COMMENT '款式',
	 displacement STRING COMMENT '排量',
	 car_mileage STRING COMMENT '公里数',
	 is_register_reissue STRING COMMENT '登记证是否存在补领记录',
	 mortgage_institution STRING COMMENT '抵押机构',
	 lately_mortgage_institution STRING COMMENT '最近一次抵押机构全称',
	 mortgage_times STRING COMMENT '抵押次数',
	 lately_release_mortgage_date STRING COMMENT '最近一次解抵押日期',
	 compulsory_traffic_insurance_company STRING COMMENT '交强险保险公司',
	 compulsory_traffic_insurance_date STRING COMMENT '交强险到期日',
	 commercial_insurance_company STRING COMMENT '商业险保险公司',
	 commercial_insurance_date STRING COMMENT '商业险到期日',
	 license_plate_assess STRING COMMENT '车牌评估值',
	 car_assess STRING COMMENT '车辆评估值',
	 assess_institution STRING COMMENT '评估机构',
	 created_by STRING COMMENT '创建用户 ID',
	 created_date STRING COMMENT '创建时间',
	 last_modified_by STRING COMMENT '修改用户 ID',
	 last_modified_date STRING COMMENT '修改时间',
	 dw_create_time STRING COMMENT '数仓创建时间',
	 dw_update_time STRING COMMENT '数仓更新时间',
	PRIMARY KEY(rent_plan_code)) STORED AS aliorc 
TBLPROPERTIES ('columnar.nested.type'='true',
	 'comment'='车辆信息表');


-- ============================================================
-- 原：prd_spark_db.dwd_req_car_loan_detail_info_d（车贷业务明细表/详版借据-车贷）
-- 源库：prd_spark_db
-- 非分区PK Delta Table（transactional=true）
-- 数据量：中等，16个桶
-- 主键：(project_no, bill_app_no, obs_date) —— 唯一性保留
-- 用途：034任务最终写入的目标表，用于监管报送展示
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_car_loan_detail_info_full_t (
    project_no                          BIGINT NOT NULL COMMENT '项目编号（主键）',
    project_name                        STRING      COMMENT '项目名称',
    bill_app_no                         STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                            STRING NOT NULL COMMENT '观察点：报表月末截至日期（主键），格式yyyy-MM-dd',
    customer_scale                      STRING      COMMENT '客户规模（中小微划型）',
    capital_attr                        STRING      COMMENT '资本属性',
    other_industry                      STRING      COMMENT '受保单位所属行业',
    plate_province                      STRING      COMMENT '车牌所在省份',
    vehicle_reg_cert_no                 STRING      COMMENT '机动车登记证书编号',
    vin                                 STRING      COMMENT '车架号',
    plate_no                            STRING      COMMENT '车牌号码',
    evaluate_price                      DECIMAL(18,2) COMMENT '评估价格',
    creditor_name                       STRING      COMMENT '债权人名称',
    creditor_type                       STRING      COMMENT '债权人类型',
    loan_balance                        DECIMAL(18,2) NOT NULL COMMENT '资金在保余额',
    repayment_method                    STRING      COMMENT '还款方式',
    loan_start_date                     DATE        COMMENT '借款起始日（放款日期），格式yyyy-MM-dd',
    loan_end_date                       DATE        COMMENT '借款终止日期，格式yyyy-MM-dd',
    loan_interest_rate                  STRING      COMMENT '借款利率',
    guarantee_fee_rate                  STRING      COMMENT '担保费率',
    guarantee_fee_opt_date              STRING      COMMENT '担保费收取/退还日期',
    guarantee_fee_opt_amt               STRING      COMMENT '担保费收取/退还金额',
    margin_opt_date                     STRING      COMMENT '保证金收取/退还日期',
    margin_opt_amt                      STRING      COMMENT '保证金收取/退还金额',
    other_fee_opt_date                  STRING      COMMENT '其他费用收取/退还日期',
    other_fee_opt_amt                   STRING      COMMENT '其他费用收取/退还金额',
    business_province                   STRING      COMMENT '业务开展省份',
    guarantee_margin_amt                DECIMAL(21,4) COMMENT '保证金数额（元）',
    release_time                        DATE        COMMENT '解保时间，格式yyyy-MM-dd',
    asset_side                          STRING      COMMENT '资产端',
    creditor                            STRING      COMMENT '债权人',
    product_no                          STRING      COMMENT '产品编码',
    product_name                        STRING      COMMENT '产品名称',
    business_guarantee_type             STRING      COMMENT '担保业务类型',
    loan_use                            STRING      COMMENT '贷款用途（业务类型）',
    cpst_principal                      DECIMAL(18,2) NOT NULL COMMENT '代偿本金',
    cpst_total_amount                   DECIMAL(18,2) NOT NULL COMMENT '代偿总金额',
    last_cpst_date                      DATE        COMMENT '截止当前最后一笔代偿日期，格式yyyy-MM-dd',
    cpst_grace_period                   STRING      COMMENT '代偿宽限期',
    cpst_grace_period_due_date          DATE        COMMENT '代偿宽限期到期日，格式yyyy-MM-dd',
    recovery_principal                  DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amount               DECIMAL(18,2) NOT NULL COMMENT '追偿还款总金额',
    unrecovered_amount                  DECIMAL(18,2) COMMENT '未追回金额',
    guarantee_fee_amount                DECIMAL(18,2) NOT NULL COMMENT '应收担保费',
    actual_guarantee_fee_amount         DECIMAL(18,2) NOT NULL COMMENT '已收担保费',
    end_of_month_guarantee_fee          DECIMAL(18,2) NOT NULL COMMENT '截止导出月末应收担保费',
    is_first_loan                       STRING      COMMENT '是否首贷',
    is_tech_innovation                  STRING      COMMENT '是否科创',
    is_culture_innovation               STRING      COMMENT '是否文创',
    is_policy                           STRING      COMMENT '是否政策性',
    is_strategic_emerging               STRING      COMMENT '是否战略性新兴',
    is_cancel                           STRING      COMMENT '是否撤保',
    bank_guarantee_ratio                DECIMAL(5,2) COMMENT '银行承担比例',
    other_responsibility_institution_name STRING    COMMENT '其他责任分担机构名称',
    other_responsibility_ratio          DECIMAL(5,2) COMMENT '其他机构分担责任比例',
    project_status                      STRING      COMMENT '项目状态',
    overdue_days                        BIGINT NOT NULL COMMENT '逾期天数',
    overdue_amount                      DECIMAL(18,2) NOT NULL COMMENT '逾期金额',
    max_ovd_days                        BIGINT NOT NULL COMMENT '历史最大逾期天数',
    princ_bal_status                    STRING      COMMENT '在贷判断字段，在贷异常/在贷正常',
    PRIMARY KEY (project_no, bill_app_no, obs_date)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '车贷业务明细表（详版借据-车贷）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);


-- ============================================================
-- 原：prd_spark_db.dwd_req_supervision_detail_info_d（消金业务明细表/详版借据-消金）
-- 源库：prd_spark_db
-- 非分区PK Delta Table（transactional=true）
-- 数据量：中等，16个桶
-- 主键：(project_no, bill_app_no, obs_date) —— 唯一性保留
-- 用途：035任务最终写入的目标表，用于监管报送展示（消金）
-- 新增字段：princ_bal_status（在贷判断字段，在贷异常/在贷正常）
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_supervision_detail_info_full_t (
    project_no                          BIGINT NOT NULL COMMENT '项目编号（主键）',
    project_name                        STRING      COMMENT '项目名称',
    bill_app_no                         STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                            STRING NOT NULL COMMENT '观察点：报表月末截至日期（主键），格式yyyy-MM-dd',
    other_industry                      STRING      COMMENT '受保单位所属行业',
    creditor_no                         STRING      COMMENT '债权人编号',
    creditor_name                       STRING      COMMENT '债权人名称',
    creditor_type                       STRING      COMMENT '债权人类型',
    release_amount                      DECIMAL(18,2) COMMENT '解保金额',
    loan_balance                        DECIMAL(18,2) NOT NULL COMMENT '资金在贷余额,负值赋值为0',
    loan_start_date                     DATE        COMMENT '借款起始日（放款日期），格式yyyy-MM-dd',
    loan_end_date                       DATE        COMMENT '借款终止日期，格式yyyy-MM-dd',
    composite_interest_rate             STRING      COMMENT '综合息费率',
    financing_interest_rate             STRING      COMMENT '融资利率（资金方）',
    guarantee_fee_rate                  STRING      COMMENT '担保费率',
    is_local_guarantee_business         STRING      COMMENT '是否本地担保业务',
    release_time                        DATE        COMMENT '解保时间，格式yyyy-MM-dd',
    guarantee_margin_amt                DECIMAL(18,2) COMMENT '保证金数额（元），负值赋为0',
    customer_type                       STRING      COMMENT '客户类型',
    rev_guarantee_type                  STRING      COMMENT '反担保方式',
    business_guarantee_type             STRING      COMMENT '担保业务类型',
    loan_use                            STRING      COMMENT '贷款用途（业务类型）',
    business_type                       STRING      COMMENT '业务类型',
    cpst_principal                      DECIMAL(18,2) NOT NULL COMMENT '累计代偿本金',
    cpst_interest                       DECIMAL(18,2) COMMENT '累计代偿利息',
    cpst_amount                         DECIMAL(18,2) NOT NULL COMMENT '累计代偿总金额',
    cpst_other_amount                   DECIMAL(18,2) COMMENT '累计代偿其他',
    recovery_principal                  DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amount               DECIMAL(18,2) NOT NULL COMMENT '追偿还款总金额',
    unrecovered_amount                  DECIMAL(18,2) COMMENT '未追回金额',
    cpst_grace_period                   STRING      COMMENT '代偿宽限期',
    cpst_grace_period_due_date          DATE        COMMENT '代偿宽限期到期日，格式yyyy-MM-dd',
    guarantee_fee_amount                DECIMAL(18,2) NOT NULL COMMENT '应收担保费',
    actual_guarantee_fee_amount         DECIMAL(18,2) NOT NULL COMMENT '已收担保费',
    end_of_month_guarantee_fee          DECIMAL(18,2) NOT NULL COMMENT '截止导出月末应收担保费',
    is_first_loan                       STRING      COMMENT '是否首贷',
    is_tech_innovation                  STRING      COMMENT '是否科创',
    is_culture_innovation               STRING      COMMENT '是否文创',
    is_strategic_innovation             STRING      COMMENT '是否战略性新兴',
    self_bearing_ratio                  DECIMAL(5,2) COMMENT '自身承担比例',
    self_guarantee_amount               DECIMAL(18,2) COMMENT '自身担保金额',
    bank_guarantee_ratio                DECIMAL(5,2) COMMENT '银行承担比例',
    bank_guarantee_amount               DECIMAL(18,2) COMMENT '银行承担金额',
    other_responsibility_institution_name STRING    COMMENT '其他责任分担机构名称',
    other_responsibility_ratio          DECIMAL(5,2) COMMENT '其他机构分担责任比例',
    unpaid_amount                       DECIMAL(18,2) COMMENT '未还金额',
    is_end_of_recovery                  STRING      COMMENT '是否结束追偿',
    overdue_days                        BIGINT NOT NULL COMMENT '逾期天数',
    overdue_amount                      DECIMAL(18,2) NOT NULL COMMENT '逾期金额',
    max_ovd_days                        BIGINT NOT NULL COMMENT '历史最大逾期天数',
    is_cancel                           STRING      COMMENT '是否撤保',
    princ_bal_status                    STRING      COMMENT '在贷判断字段，在贷异常/在贷正常',
    product_no                          STRING      COMMENT '产品编码',
    loan_amt                            DECIMAL(18,2) COMMENT '放款金额',
    princ_bal_info                      DECIMAL(18,2) COMMENT '客方在贷余额',
    act_repay_date                      STRING      COMMENT '实际还款日期/结清日期',
    month_cpst_amt                      DECIMAL(18,2) COMMENT '本月代偿额',
    month_cpst_princ_amt                DECIMAL(18,2) COMMENT '本月代偿本金金额',
    month_cpst_cnt                      BIGINT      COMMENT '本月代偿笔数',
    year_cpst_amt                       DECIMAL(18,2) COMMENT '当年代偿额',
    year_cpst_princ_amt                 DECIMAL(18,2) COMMENT '当年代偿本金金额',
    year_cpst_cnt                       BIGINT      COMMENT '当年代偿笔数',
    total_cpst_cnt                      BIGINT      COMMENT '累计代偿笔数',
    PRIMARY KEY (project_no, bill_app_no, obs_date)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '消金业务明细表（详版借据-消金）',
    'write.bucket.num' = '256',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

-- 2026-09-16 新增11列（原047/tmp2_cons_payment_common经业务讨论废弃，其场景字段改由
-- 详版借据直接输出；036写入，035通道/线下行为NULL不写。线上已建表执行以下加列，须在036上线前完成）
ALTER TABLE dwd_req_supervision_detail_info_full_t ADD COLUMNS (
    product_no                          STRING COMMENT '产品编码',
    loan_amt                            DECIMAL(18,2) COMMENT '放款金额',
    princ_bal_info                      DECIMAL(18,2) COMMENT '客方在贷余额',
    act_repay_date                      STRING COMMENT '实际还款日期/结清日期',
    month_cpst_amt                      DECIMAL(18,2) COMMENT '本月代偿额',
    month_cpst_princ_amt                DECIMAL(18,2) COMMENT '本月代偿本金金额',
    month_cpst_cnt                      BIGINT COMMENT '本月代偿笔数',
    year_cpst_amt                       DECIMAL(18,2) COMMENT '当年代偿额',
    year_cpst_princ_amt                 DECIMAL(18,2) COMMENT '当年代偿本金金额',
    year_cpst_cnt                       BIGINT COMMENT '当年代偿笔数',
    total_cpst_cnt                      BIGINT COMMENT '累计代偿笔数'
);



-- 原：ods_cons_pt_asset_product
-- 源库：rd_cfund
CREATE TABLE IF NOT EXISTS prod_bs_dw.ods_req_pt_asset_product_full_t
(
    id            BIGINT COMMENT '自增主键(源表MySQL自增)'
    ,product_no   STRING COMMENT '产品编码(业务唯一标识)'
    ,product_name STRING COMMENT '产品名称'
    ,asset_code   STRING COMMENT '对应资产方'
    ,fund_code    STRING COMMENT '对应资金方'
    ,`status`     TINYINT COMMENT '状态标识'
    ,is_pull      STRING COMMENT '是否拉取 0-是 1-否'
    ,create_time  DATETIME COMMENT '创建时间'
    ,update_time  DATETIME COMMENT '更新时间'
)
STORED AS aliorc
TBLPROPERTIES ('columnar.nested.type' = 'true','comment' = '资产方产品-每日全量覆盖表(主键:id; 业务唯一键:product_no)')
;


-- ============================================================
-- 保函业务明细表（原 dwd_req_guarantee_bill_detail_info_d）
-- 原ADB：分区obs_month(varchar6) + PRIMARY KEY(obs_month,obs_date,bill_app_no)
-- 适配：obs_month → pt(STRING yyyyMM)，事务表，write.bucket.num=16
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_guarantee_bill_detail_info_full_t (
    obs_date                       string      NOT NULL COMMENT '观察点：报表月末截至日期',
    guarantee_no                   STRING             COMMENT '保函编号',
    project_no                     bigint             COMMENT '项目编码',
    project_name                   STRING             COMMENT '项目名称',
    total_term                     INT                COMMENT '总期次',
    bill_app_no                    STRING    NOT NULL COMMENT '借款申请编号',
    guarantee_right_holder         STRING             COMMENT '保函权利人',
    grh_province                   STRING             COMMENT '保函权利人所在省份',
    grh_id_type                    STRING             COMMENT '保函权利人证件类型',
    grh_id_no                      STRING             COMMENT '保函权利人证件号码',
    capital_attr                   STRING             COMMENT '资本属性',
    project_region                STRING             COMMENT '项目所属区域（省市）',
    fin_guarantee_company          STRING             COMMENT '融担公司',
    channel                        STRING             COMMENT '渠道',
    bid_open_date                  datetime               COMMENT '开标时间 yyyy-mm-dd hh:mi:ss',
    written_date                   datetime               COMMENT '落款时间 yyyy-mm-dd hh:mi:ss',
    guarantee_amount               DECIMAL(18,2)      COMMENT '担保金额',
    balance_in_guarantee           DECIMAL(18,2)      COMMENT '在保余额',
    guarantee_open_date            datetime               COMMENT '保函开立日期 yyyy-mm-dd hh:mi:ss',
    guarantee_end_date             datetime               COMMENT '担保终止日期 yyyy-mm-dd hh:mi:ss',
    guarantee_fee_rate             STRING             COMMENT '担保费率',
    repayment_type                 STRING             COMMENT '还款方式',
    business_guarantee_type        STRING             COMMENT '担保业务类型',
    guarantee_fee_opt_date         STRING             COMMENT '担保费收取/退还日期',
    guarantee_fee_opt_amt          STRING             COMMENT '担保费收取/退还金额',
    margin_opt_date                STRING             COMMENT '保证金收取/退还日期',
    margin_opt_amt                 STRING             COMMENT '保证金收取/退还金额',
    other_fee_opt_date             STRING             COMMENT '其他费用收取/退还日期',
    other_fee_opt_amt              STRING             COMMENT '其他费用收取/退还金额',
    risk_share_org_name            STRING             COMMENT '风险分担机构名称',
    risk_share_ratio               DECIMAL(5,2)       COMMENT '风险分担责任比例（%）',
    is_agriculture                 STRING             COMMENT '是否三农',
    is_new_agriculture             STRING             COMMENT '是否新型农业',
    is_innovation_service          STRING             COMMENT '是否双创双服',
    is_first_loan                  STRING             COMMENT '是否首贷',
    is_tech_innovation             STRING             COMMENT '是否科创',
    is_culture_innovation          STRING             COMMENT '是否文创',
    is_policy                      STRING             COMMENT '是否政策性',
    is_strategic_emerging          STRING             COMMENT '是否战略性新兴',
    cpst_grace_period              STRING             COMMENT '代偿宽限期',
    cpst_grace_period_due_date     DATE               COMMENT '代偿宽限期到期日 yyyy-mm-dd',
    cpst_principal                 DECIMAL(18,2) NOT NULL COMMENT '代偿本金',
    cpst_other_amt                 DECIMAL(18,2) NOT NULL COMMENT '代偿其他',
    cpst_total_amount              DECIMAL(18,2) NOT NULL COMMENT '代偿金额',
    last_cpst_date                 DATE               COMMENT '截止当前最后一笔代偿日期 yyyy-mm-dd',
    recovery_principal             DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amt             DECIMAL(18,2) NOT NULL COMMENT '追偿金额',
    last_recovery_date             DATE               COMMENT '截止当前最后一笔追偿日期 yyyy-mm-dd',
    project_status                STRING             COMMENT '项目状态',
    PRIMARY KEY (obs_date, bill_app_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '保函业务明细表（原dwd_req_guarantee_bill_detail_info_d）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;


-- ============================================================
-- 房贷业务快照明细表（原 dwd_req_house_loan_detail_info_d）
-- 原ADB：分区obs_month(varchar6) + PRIMARY KEY(obs_month,obs_date,bill_app_no)
-- 适配：obs_month → pt(STRING yyyyMM)，release_time datetime → DATE，事务表
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_house_loan_detail_info_full_t (
    obs_date                       string      NOT NULL COMMENT '观察点：报表月末截至日期',
    product_code                   STRING             COMMENT '产品编码',
    product_name                   STRING             COMMENT '产品名称',
    bill_app_no                    STRING    NOT NULL COMMENT '借款申请编号',
    capital_attr                   STRING             COMMENT '资本属性',
    borrower_annual_income         DECIMAL(18,2)      COMMENT '借款人年收入',
    borrower_total_assets          DECIMAL(18,2)      COMMENT '借款人资产总额',
    creditor_name                  STRING             COMMENT '债权人名称',
    creditor_type                  STRING             COMMENT '债权人类型',
    industry                       STRING             COMMENT '受保单位所属行业',
    business_province              STRING             COMMENT '业务开展省份',
    estate_province                STRING             COMMENT '不动产所在省份',
    estate_cert_no                 STRING             COMMENT '不动产权证编号',
    borrower_image                 STRING             COMMENT '借款人借款的影像件',
    property_report_no             STRING             COMMENT '产调报告编号',
    release_amount                 DECIMAL(18,2) NOT NULL COMMENT '解保金额',
    loan_balance                   DECIMAL(18,2) NOT NULL COMMENT '资金在保余额',
    margin_total_amt               DECIMAL(18,2)      COMMENT '保证金数额（元）',
    loan_start_date                DATE               COMMENT '借款起始日（放款日期） yyyy-mm-dd',
    loan_end_date                  DATE               COMMENT '借款终止日期 yyyy-mm-dd',
    guarantee_fee_rate             STRING             COMMENT '担保费率',
    repayment_type                 STRING             COMMENT '还款方式',
    business_guarantee_type        STRING             COMMENT '担保业务类型',
    guarantee_fee_opt_date         STRING             COMMENT '担保费收取/退还日期',
    guarantee_fee_opt_amt          STRING             COMMENT '担保费收取/退还金额',
    margin_opt_date                STRING             COMMENT '保证金收取/退还日期',
    margin_opt_amt                 STRING             COMMENT '保证金收取/退还金额',
    other_fee_opt_date             STRING             COMMENT '其他费用收取/退还日期',
    other_fee_opt_amt              STRING             COMMENT '其他费用收取/退还金额',
    release_time                   DATE               COMMENT '解保时间（原datetime改为DATE） yyyy-mm-dd',
    rev_guarantee_name             STRING             COMMENT '反担保人名称',
    rev_guarantee_id_type          STRING             COMMENT '反担保人证件类型',
    rev_guarantee_id_no            STRING             COMMENT '反担保人证件编号',
    rev_guarantee_amt              DECIMAL(18,2)      COMMENT '反担保金额',
    bank_share_ratio               DECIMAL(5,2)       COMMENT '银行承担比例',
    other_risk_org_name            STRING             COMMENT '其他责任分担机构名称',
    other_share_ratio              DECIMAL(5,2)       COMMENT '其他机构分担责任比例',
    is_first_loan                  STRING             COMMENT '是否首贷',
    is_tech_innovation             STRING             COMMENT '是否科创',
    is_culture_innovation          STRING             COMMENT '是否文创',
    is_policy                      STRING             COMMENT '是否政策性',
    is_strategic_emerging          STRING             COMMENT '是否战略性新兴',
    cpst_grace_period              STRING             COMMENT '代偿宽限期',
    cpst_grace_period_due_date     DATE               COMMENT '代偿宽限期到期日 yyyy-mm-dd',
    cpst_principal                 DECIMAL(18,2) NOT NULL COMMENT '代偿本金',
    cpst_total_amount              DECIMAL(18,2) NOT NULL COMMENT '代偿总金额',
    last_cpst_date                 DATE               COMMENT '截止当前最后一笔代偿日期 yyyy-mm-dd',
    recovery_principal             DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amt             DECIMAL(18,2) NOT NULL COMMENT '追偿还款总金额',
    unrecovered_amount             DECIMAL(18,2)      COMMENT '未追回金额',
    receivable_guarantee_fee       DECIMAL(18,2) NOT NULL COMMENT '应收担保费',
    actual_guarantee_fee           DECIMAL(18,2) NOT NULL COMMENT '已收担保费',
    month_end_receivable_fee       DECIMAL(18,2) NOT NULL COMMENT '截止导出月末应收担保费',
    project_status                 STRING             COMMENT '项目状态',
    overdue_days                   BIGINT    NOT NULL COMMENT '逾期天数',
    overdue_amount                 DECIMAL(18,2) NOT NULL COMMENT '逾期金额',
    max_overdue_days               BIGINT    NOT NULL COMMENT '历史最大逾期天数',
    PRIMARY KEY (obs_date, bill_app_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '房贷业务快照明细表（原dwd_req_house_loan_detail_info_d）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;


-- ============================================================
-- 借据信息表报送-新项目（原 dwd_req_g_loan_info_m）
-- 报送域
-- 原ADB：非分区，PRIMARY KEY(loan_serial)，DISTRIBUTE BY HASH(loan_serial)
-- 适配：非分区事务表，PK=loan_serial，write.bucket.num=16，支持UPDATE/DELETE
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_g_loan_info_m (
    pt                              STRING    NOT NULL COMMENT '数据日期，格式yyyyMMdd，如20260701',
    platform_no                     STRING             COMMENT '外部系统编码',
    cust_no                         STRING             COMMENT '担保公司',
    project_id                      BIGINT             COMMENT '新项目ID',
    partner_no                      STRING             COMMENT '合作方',
    fund_no                         STRING             COMMENT '资金端',
    product_no                      STRING             COMMENT '产品编码',
    org_no                          STRING    NOT NULL COMMENT '融资担保业务经营许可证编号',
    info_id                         STRING    NOT NULL COMMENT '业务唯一识别编码',
    loan_serial                     STRING    NOT NULL COMMENT '借款编号',
    main_contract_code              STRING    NOT NULL COMMENT '合同编号',
    business_type                   STRING    NOT NULL COMMENT '业务类型',
    debtor_name                     STRING    NOT NULL COMMENT '债务人姓名',
    debtor_idcard                   STRING    NOT NULL COMMENT '债务人身份证号',
    debtor_idcard_type              STRING    NOT NULL COMMENT '债务人证件类型',
    debtor_phone                    STRING             COMMENT '债务人手机号',
    accept_property                 STRING    NOT NULL COMMENT '受保方性质',
    industry_divide                 STRING             COMMENT '工信部企业划型',
    industry_code                   STRING             COMMENT '四位行业代码',
    creditor_name                   STRING    NOT NULL COMMENT '债权人名称',
    creditor_type                   STRING    NOT NULL COMMENT '债权人类型',
    bond_credit_level               STRING             COMMENT '发行债券主体信用评级',
    assure_amount                   DECIMAL(20,2) NOT NULL COMMENT '担保合同金额（元）',
    loan_amount                     DECIMAL(20,2)      COMMENT '放款金额',
    refund_date                     DATE               COMMENT '放款日期',
    refund_method                   STRING             COMMENT '还款方式',
    loan_rate                       DECIMAL(20,3)      COMMENT '贷款利率（%/年）',
    start_date                      DATE               COMMENT '起始日期',
    end_date                        DATE               COMMENT '终止日期',
    date_limit                      STRING             COMMENT '期限（月）',
    anti_assure                     STRING    NOT NULL COMMENT '反担保',
    assure_fee                      DECIMAL(20,2) NOT NULL COMMENT '担保费（元）',
    review_fee                      DECIMAL(20,2) NOT NULL COMMENT '评审费（元）',
    deposit_amount                  DECIMAL(20,2) NOT NULL COMMENT '保证金金额（元）',
    is_first                        STRING             COMMENT '是否首贷（Y/N）',
    is_beijing                      STRING    NOT NULL COMMENT '是否在京业务（Y/N）',
    is_science                      STRING    NOT NULL COMMENT '是否科创（Y/N）',
    is_culture                      STRING    NOT NULL COMMENT '是否文创（Y/N）',
    is_new_strategy                 STRING    NOT NULL COMMENT '是否战略新兴（Y/N）',
    client_combination_pricing      DECIMAL(20,8)      COMMENT '客户综合定价',
    bank_rate                       DECIMAL(20,2) NOT NULL COMMENT '银行承担比例（%）',
    other_org_name                  STRING    NOT NULL COMMENT '其他责任分担机构名称',
    other_org_rate                  DECIMAL(17,4) NOT NULL COMMENT '其他机构分担责任比例（%）',
    apply_time                      DATE               COMMENT '进件时间',
    is_mapping                      STRING             COMMENT '是否映射成功',
    remark                          STRING             COMMENT '备注',
    create_by                       STRING             COMMENT '创建人',
    create_time                     DATETIME           COMMENT '创建时间',
    update_by                       STRING             COMMENT '修改人',
    update_time                     DATETIME           COMMENT '修改时间',
    PRIMARY KEY (loan_serial)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '湖北富宸-放款表报送-新项目',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;


-- ============================================================
-- 还款信息报送-新项目（原 dwd_req_g_repayment_info_m）
-- 原ADB：非分区，PRIMARY KEY(apply_no,tran_rp_no,term)，DISTRIBUTE BY HASH(tran_rp_no)
-- 适配：非分区事务表，PK=(apply_no,tran_rp_no,term)，write.bucket.num=16，支持UPDATE/DELETE
-- 小数精度保持decimal(15,2)与原表一致，不做修改
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_g_repayment_info_m (
    pt                  STRING    NOT NULL COMMENT '数据日期，格式yyyyMMdd，如20260601',
    platform_no         STRING    NOT NULL COMMENT '外部系统平台编码',
    cust_no             STRING             COMMENT '担保公司编码',
    project_id          BIGINT             COMMENT '新项目ID',
    partner_no          STRING             COMMENT '合作方编码',
    fund_no             STRING             COMMENT '资金方编码',
    product_no          STRING             COMMENT '产品编码',
    apply_no            STRING    NOT NULL COMMENT '借款申请编号',
    term                STRING    NOT NULL COMMENT '期次号',
    tran_rp_no          STRING    NOT NULL COMMENT '还款流水号',
    repay_time          DATE      NOT NULL COMMENT '还款时间',
    repay_total_amt     DECIMAL(15,2) NOT NULL COMMENT '还款总额',
    print               DECIMAL(15,2) NOT NULL COMMENT '还款本金',
    reduce_print        DECIMAL(15,2) NOT NULL COMMENT '减免本金',
    int_amt             DECIMAL(15,2) NOT NULL COMMENT '还款利息',
    reduce_int_amt      DECIMAL(15,2) NOT NULL COMMENT '减免利息',
    service_amt         DECIMAL(15,2) NOT NULL COMMENT '还款服务费',
    reduce_service_amt  DECIMAL(15,2) NOT NULL COMMENT '减免服务费',
    guarantee_amt       DECIMAL(15,2) NOT NULL COMMENT '还款担保费',
    reduce_guarantee_amt DECIMAL(15,2) NOT NULL COMMENT '减免担保费',
    margin_amt          DECIMAL(15,2) NOT NULL COMMENT '还款保证金',
    reduce_margin_amt   DECIMAL(15,2) NOT NULL COMMENT '减免保证金',
    compensate_amt      DECIMAL(15,2) NOT NULL COMMENT '还款代偿金',
    reduce_compensate_amt DECIMAL(15,2) NOT NULL COMMENT '减免代偿金',
    oint_amt            DECIMAL(15,2) NOT NULL COMMENT '还款罚息',
    reduce_oint_amt     DECIMAL(15,2) NOT NULL COMMENT '减免罚息',
    define_amt          DECIMAL(15,2) NOT NULL COMMENT '还款预期违约金',
    reduce_define_amt   DECIMAL(15,2) NOT NULL COMMENT '减免预期违约金',
    adv_define_amt      DECIMAL(15,2) NOT NULL COMMENT '提前还款违约金',
    reduce_adv_define_amt DECIMAL(15,2) NOT NULL COMMENT '减免提前还款违约金',
    repay_type          STRING    NOT NULL COMMENT '还款类型',
    is_mapping          STRING    NOT NULL COMMENT '是否映射成功',
    remark              STRING             COMMENT '备注',
    create_time         DATETIME  NOT NULL COMMENT '创建时间',
    update_time         DATETIME           COMMENT '更新时间',
    create_by           STRING             COMMENT '创建人',
    update_by           STRING             COMMENT '修改人',
    PRIMARY KEY (apply_no, tran_rp_no, term)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '还款信息报送-新项目',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;


-- ============================================================
-- 小微业务快照明细表（原 dwd_req_micro_loan_detail_info_d）
-- 原ADB：分区obs_month(varchar6) + PRIMARY KEY(obs_month,obs_date,bill_app_no)
-- 适配：obs_month → pt(STRING yyyyMM)，事务表
-- ============================================================
CREATE TABLE IF NOT EXISTS dwd_req_micro_loan_detail_info_full_t (
    obs_date                       string      NOT NULL COMMENT '观察点：报表月末截至日期',
    project_no                     bigint             COMMENT '项目编码',
    project_name                   STRING             COMMENT '项目名称',
    contract_no                    STRING             COMMENT '委保合同编号',
    total_term                     INT                COMMENT '总期次',
    bill_app_no                    STRING    NOT NULL COMMENT '借款申请编号',
    creditor_name                  STRING             COMMENT '债权人名称',
    creditor_id_type               STRING             COMMENT '债权人证件类型',
    creditor_id_no                 STRING             COMMENT '债权人证件号码',
    capital_attr                   STRING             COMMENT '企业资本属性',
    enterprise_region              STRING             COMMENT '企业所属区域（省市）',
    practitioners                  BIGINT             COMMENT '从业人员',
    annual_income                  DECIMAL(18,2)      COMMENT '年营业收入',
    total_assets                   DECIMAL(18,2)      COMMENT '资产总额',
    loan_purpose                   STRING             COMMENT '贷款用途',
    loan_balance                   DECIMAL(18,2)      COMMENT '资金在保余额',
    loan_start_date                DATE               COMMENT '借款开始日期 yyyy-mm-dd',
    loan_end_date                  DATE               COMMENT '借款终止日期 yyyy-mm-dd',
    guarantee_fee_rate             STRING             COMMENT '担保费率',
    repayment_type                 STRING             COMMENT '还款方式',
    business_guarantee_type        STRING             COMMENT '担保业务类型',
    guarantee_fee_opt_date         STRING             COMMENT '担保费收取/退还日期',
    guarantee_fee_opt_amt          STRING             COMMENT '担保费收取/退还金额',
    margin_opt_date                STRING             COMMENT '保证金收取/退还日期',
    margin_opt_amt                 STRING             COMMENT '保证金收取/退还金额',
    other_fee_opt_date             STRING             COMMENT '其他费用收取/退还日期',
    other_fee_opt_amt              STRING             COMMENT '其他费用收取/退还金额',
    rev_guarantee_name             STRING             COMMENT '反担保人名称',
    rev_guarantee_id_type          STRING             COMMENT '反担保人证件类型',
    rev_guarantee_id_no            STRING             COMMENT '反担保人证件编号',
    rev_guarantee_amt              DECIMAL(18,2)      COMMENT '反担保金额',
    rev_guarantee_remark           STRING             COMMENT '反担保备注',
    risk_share_org_name            STRING             COMMENT '风险分担机构名称',
    risk_share_ratio               DECIMAL(5,2)       COMMENT '风险分担责任比例（%）',
    is_agriculture                 STRING             COMMENT '是否三农',
    is_new_agriculture             STRING             COMMENT '是否新型农业',
    is_innovation_service          STRING             COMMENT '是否双创双服',
    is_first_loan                  STRING             COMMENT '是否首贷',
    is_policy                      STRING             COMMENT '是否政策性',
    is_strategic_emerging          STRING             COMMENT '是否战略性新兴',
    is_tech_innovation             STRING             COMMENT '是否科创',
    is_culture_innovation          STRING             COMMENT '是否文创',
    cpst_grace_period              STRING             COMMENT '代偿宽限期',
    cpst_grace_period_due_date     DATE               COMMENT '代偿宽限期到期日 yyyy-mm-dd',
    cpst_principal                 DECIMAL(18,2) NOT NULL COMMENT '代偿本金',
    cpst_total_amount              DECIMAL(18,2) NOT NULL COMMENT '代偿总金额',
    cpst_amount                    DECIMAL(18,2) NOT NULL COMMENT '代偿金额',
    last_cpst_date                 DATE               COMMENT '截止当前最后一笔代偿日期 yyyy-mm-dd',
    recovery_principal             DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amt             DECIMAL(18,2) NOT NULL COMMENT '追偿金额',
    last_recovery_date             DATE               COMMENT '截止当前最后一笔追偿日期 yyyy-mm-dd',
    project_status                 STRING             COMMENT '项目状态',
    PRIMARY KEY ( obs_date, bill_app_no)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '小微业务快照明细表（原dwd_req_micro_loan_detail_info_d）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;


-- ============================================================
-- 消金分保数据表（原 ods_xj_ln_share_d）
-- 原ADB：非分区，PRIMARY KEY(id)，AUTO_INCREMENT，DISTRIBUTE BY HASH(id)
-- 适配：非分区事务表，PK=(id)，write.bucket.num=16，支持UPDATE/DELETE
-- 注：MC不支持AUTO_INCREMENT，应用层生成id；不支持DEFAULT/ON UPDATE，应用层设置时间
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_req_xj_ln_share_d (
    id              BIGINT    NOT NULL COMMENT '物理主键（应用层生成）',
    share_cust_no   STRING             COMMENT '分保机构编码',
    apply_no        STRING    NOT NULL COMMENT '借款申请编号',
    create_time     DATETIME  NOT NULL COMMENT '创建时间',
    update_time     DATETIME  NOT NULL COMMENT '更新时间',
    PRIMARY KEY (id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '湖北富宸-消金分保数据表',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;


-- ============================================================
-- 车贷分保数据表（原 ods_cd_ln_share_d）
-- 原ADB：非分区，PRIMARY KEY(id)，AUTO_INCREMENT，DISTRIBUTE BY HASH(id)
-- 适配：非分区事务表，PK=(id)，write.bucket.num=16，支持UPDATE/DELETE
-- 注：MC不支持AUTO_INCREMENT，应用层生成id；不支持DEFAULT/ON UPDATE，应用层设置时间
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_req_cd_ln_share_d (
    id              BIGINT    NOT NULL COMMENT '物理主键（应用层生成）',
    share_cust_no   STRING             COMMENT '分保机构编码',
    apply_no        STRING    NOT NULL COMMENT '借款申请编号',
    create_time     DATETIME  NOT NULL COMMENT '创建时间',
    update_time     DATETIME  NOT NULL COMMENT '更新时间',
    PRIMARY KEY (id)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '湖北富宸-车贷分保数据表',
    'write.bucket.num' = '4',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
)
;



CREATE TABLE IF NOT EXISTS dim_req_supervision_payment_info_d (
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
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '简版借据原dms备份',
    'write.bucket.num' = '64',
    'cdc.data.retain.hours'='0',
    'acid.data.retain.hours' = '0'
);


CREATE TABLE IF NOT EXISTS dwd_req_car_loan_detail_info_d (
    project_no                          BIGINT NOT NULL COMMENT '项目编号（主键）',
    project_name                        STRING      COMMENT '项目名称',
    bill_app_no                         STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                            STRING NOT NULL COMMENT '观察点：报表月末截至日期（主键），格式yyyy-MM-dd',
    customer_scale                      STRING      COMMENT '客户规模（中小微划型）',
    capital_attr                        STRING      COMMENT '资本属性',
    other_industry                      STRING      COMMENT '受保单位所属行业',
    plate_province                      STRING      COMMENT '车牌所在省份',
    vehicle_reg_cert_no                 STRING      COMMENT '机动车登记证书编号',
    vin                                 STRING      COMMENT '车架号',
    plate_no                            STRING      COMMENT '车牌号码',
    evaluate_price                      DECIMAL(18,2) COMMENT '评估价格',
    creditor_name                       STRING      COMMENT '债权人名称',
    creditor_type                       STRING      COMMENT '债权人类型',
    loan_balance                        DECIMAL(18,2) NOT NULL COMMENT '资金在保余额',
    repayment_method                    STRING      COMMENT '还款方式',
    loan_start_date                     DATE        COMMENT '借款起始日（放款日期），格式yyyy-MM-dd',
    loan_end_date                       DATE        COMMENT '借款终止日期，格式yyyy-MM-dd',
    loan_interest_rate                  STRING      COMMENT '借款利率',
    guarantee_fee_rate                  STRING      COMMENT '担保费率',
    guarantee_fee_opt_date              STRING      COMMENT '担保费收取/退还日期',
    guarantee_fee_opt_amt               STRING      COMMENT '担保费收取/退还金额',
    margin_opt_date                     STRING      COMMENT '保证金收取/退还日期',
    margin_opt_amt                      STRING      COMMENT '保证金收取/退还金额',
    other_fee_opt_date                  STRING      COMMENT '其他费用收取/退还日期',
    other_fee_opt_amt                   STRING      COMMENT '其他费用收取/退还金额',
    business_province                   STRING      COMMENT '业务开展省份',
    guarantee_margin_amt                DECIMAL(21,4) COMMENT '保证金数额（元）',
    release_time                        DATE        COMMENT '解保时间，格式yyyy-MM-dd',
    asset_side                          STRING      COMMENT '资产端',
    creditor                            STRING      COMMENT '债权人',
    product_no                          STRING      COMMENT '产品编码',
    product_name                        STRING      COMMENT '产品名称',
    business_guarantee_type             STRING      COMMENT '担保业务类型',
    loan_use                            STRING      COMMENT '贷款用途（业务类型）',
    cpst_principal                      DECIMAL(18,2) NOT NULL COMMENT '代偿本金',
    cpst_total_amount                   DECIMAL(18,2) NOT NULL COMMENT '代偿总金额',
    last_cpst_date                      DATE        COMMENT '截止当前最后一笔代偿日期，格式yyyy-MM-dd',
    cpst_grace_period                   STRING      COMMENT '代偿宽限期',
    cpst_grace_period_due_date          DATE        COMMENT '代偿宽限期到期日，格式yyyy-MM-dd',
    recovery_principal                  DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amount               DECIMAL(18,2) NOT NULL COMMENT '追偿还款总金额',
    unrecovered_amount                  DECIMAL(18,2) COMMENT '未追回金额',
    guarantee_fee_amount                DECIMAL(18,2) NOT NULL COMMENT '应收担保费',
    actual_guarantee_fee_amount         DECIMAL(18,2) NOT NULL COMMENT '已收担保费',
    end_of_month_guarantee_fee          DECIMAL(18,2) NOT NULL COMMENT '截止导出月末应收担保费',
    is_first_loan                       STRING      COMMENT '是否首贷',
    is_tech_innovation                  STRING      COMMENT '是否科创',
    is_culture_innovation               STRING      COMMENT '是否文创',
    is_policy                           STRING      COMMENT '是否政策性',
    is_strategic_emerging               STRING      COMMENT '是否战略性新兴',
    is_cancel                           STRING      COMMENT '是否撤保',
    bank_guarantee_ratio                DECIMAL(5,2) COMMENT '银行承担比例',
    other_responsibility_institution_name STRING    COMMENT '其他责任分担机构名称',
    other_responsibility_ratio          DECIMAL(5,2) COMMENT '其他机构分担责任比例',
    project_status                      STRING      COMMENT '项目状态',
    overdue_days                        BIGINT NOT NULL COMMENT '逾期天数',
    overdue_amount                      DECIMAL(18,2) NOT NULL COMMENT '逾期金额',
    max_ovd_days                        BIGINT NOT NULL COMMENT '历史最大逾期天数',
    princ_bal_status                    STRING      COMMENT '在贷判断字段，在贷异常/在贷正常',
    PRIMARY KEY (project_no, bill_app_no, obs_date)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '详版借据原dms备份',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);

CREATE TABLE IF NOT EXISTS dwd_req_supervision_detail_info_d (
    project_no                          BIGINT NOT NULL COMMENT '项目编号（主键）',
    project_name                        STRING      COMMENT '项目名称',
    bill_app_no                         STRING NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                            STRING NOT NULL COMMENT '观察点：报表月末截至日期（主键），格式yyyy-MM-dd',
    other_industry                      STRING      COMMENT '受保单位所属行业',
    creditor_no                         STRING      COMMENT '债权人编号',
    creditor_name                       STRING      COMMENT '债权人名称',
    creditor_type                       STRING      COMMENT '债权人类型',
    release_amount                      DECIMAL(18,2) COMMENT '解保金额',
    loan_balance                        DECIMAL(18,2) NOT NULL COMMENT '资金在贷余额,负值赋值为0',
    loan_start_date                     DATE        COMMENT '借款起始日（放款日期），格式yyyy-MM-dd',
    loan_end_date                       DATE        COMMENT '借款终止日期，格式yyyy-MM-dd',
    composite_interest_rate             STRING      COMMENT '综合息费率',
    financing_interest_rate             STRING      COMMENT '融资利率（资金方）',
    guarantee_fee_rate                  STRING      COMMENT '担保费率',
    is_local_guarantee_business         STRING      COMMENT '是否本地担保业务',
    release_time                        DATE        COMMENT '解保时间，格式yyyy-MM-dd',
    guarantee_margin_amt                DECIMAL(18,2) COMMENT '保证金数额（元），负值赋为0',
    customer_type                       STRING      COMMENT '客户类型',
    rev_guarantee_type                  STRING      COMMENT '反担保方式',
    business_guarantee_type             STRING      COMMENT '担保业务类型',
    loan_use                            STRING      COMMENT '贷款用途（业务类型）',
    business_type                       STRING      COMMENT '业务类型',
    cpst_principal                      DECIMAL(18,2) NOT NULL COMMENT '代偿本金',
    cpst_interest                       DECIMAL(18,2) COMMENT '代偿利息',
    cpst_amount                         DECIMAL(18,2) NOT NULL COMMENT '代偿总金额',
    cpst_other_amount                   DECIMAL(18,2) COMMENT '代偿其他',
    recovery_principal                  DECIMAL(18,2) NOT NULL COMMENT '追偿本金',
    recovery_total_amount               DECIMAL(18,2) NOT NULL COMMENT '追偿还款总金额',
    unrecovered_amount                  DECIMAL(18,2) COMMENT '未追回金额',
    cpst_grace_period                   STRING      COMMENT '代偿宽限期',
    cpst_grace_period_due_date          DATE        COMMENT '代偿宽限期到期日，格式yyyy-MM-dd',
    guarantee_fee_amount                DECIMAL(18,2) NOT NULL COMMENT '应收担保费',
    actual_guarantee_fee_amount         DECIMAL(18,2) NOT NULL COMMENT '已收担保费',
    end_of_month_guarantee_fee          DECIMAL(18,2) NOT NULL COMMENT '截止导出月末应收担保费',
    is_first_loan                       STRING      COMMENT '是否首贷',
    is_tech_innovation                  STRING      COMMENT '是否科创',
    is_culture_innovation               STRING      COMMENT '是否文创',
    is_strategic_innovation             STRING      COMMENT '是否战略性新兴',
    self_bearing_ratio                  DECIMAL(5,2) COMMENT '自身承担比例',
    self_guarantee_amount               DECIMAL(18,2) COMMENT '自身担保金额',
    bank_guarantee_ratio                DECIMAL(5,2) COMMENT '银行承担比例',
    bank_guarantee_amount               DECIMAL(18,2) COMMENT '银行承担金额',
    other_responsibility_institution_name STRING    COMMENT '其他责任分担机构名称',
    other_responsibility_ratio          DECIMAL(5,2) COMMENT '其他机构分担责任比例',
    unpaid_amount                       DECIMAL(18,2) COMMENT '未还金额',
    is_end_of_recovery                  STRING      COMMENT '是否结束追偿',
    overdue_days                        BIGINT NOT NULL COMMENT '逾期天数',
    overdue_amount                      DECIMAL(18,2) NOT NULL COMMENT '逾期金额',
    max_ovd_days                        BIGINT NOT NULL COMMENT '历史最大逾期天数',
    is_cancel                           STRING      COMMENT '是否撤保',
    princ_bal_status                    STRING      COMMENT '在贷判断字段，在贷异常/在贷正常',
    PRIMARY KEY (project_no, bill_app_no, obs_date)
)
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '详版借据xj原dms备份',
    'write.bucket.num' = '256',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);


-- ============================================================
-- 手动生成的还款信息暂存表-目标表（原 ln_repay_info_manual）
-- 原ADB/MySQL：非分区，PRIMARY KEY(id)，UNIQUE KEY(tran_rp_no)，AUTO_INCREMENT，270万数据
-- 适配：按还款时间(repay_time)分区，pt=yyyyMM（STRING，月级分区），repay_time改为STRING类型
-- 主键=(tran_rp_no, pt)（分区表主键含分区字段），事务表支持MERGE INTO
-- 注：MC不支持AUTO_INCREMENT，id字段保留但不作为主键（应用层或源系统生成）
-- ============================================================
CREATE TABLE IF NOT EXISTS ods_cons_ln_repay_info_manual_incr_delta (
    id                       BIGINT      NOT NULL COMMENT '物理主键（源系统生成）',
    recon_date               STRING      NOT NULL COMMENT '对账日期：格式YYYY-MM-DD',
    product_no               STRING      NOT NULL COMMENT '产品编码',
    apply_no                 STRING      NOT NULL COMMENT '借款申请编号',
    term                     BIGINT      NOT NULL COMMENT '期次号',
    tran_rp_no               STRING      NOT NULL COMMENT '还款流水号（业务唯一键）',
    repay_time               STRING               COMMENT '还款时间（yyyy-MM-dd HH:mi:ss）',
    repay_total_amt          DECIMAL(17,2) NOT NULL COMMENT '还款总额',
    print                    DECIMAL(17,2) NOT NULL COMMENT '还款本金',
    int_amt                  DECIMAL(17,2) NOT NULL COMMENT '还款利息',
    service_amt              DECIMAL(17,2) NOT NULL COMMENT '还款服务费',
    guarantee_amt            DECIMAL(17,2) NOT NULL COMMENT '还款担保费',
    margin_amt               DECIMAL(17,2) NOT NULL COMMENT '还款保证金',
    compensate_amt           DECIMAL(17,2) NOT NULL COMMENT '还款代偿金',
    oint_amt                 DECIMAL(17,2) NOT NULL COMMENT '还款罚息',
    oguarantee_amt           DECIMAL(17,2) NOT NULL COMMENT '还款担保费罚息',
    define_amt               DECIMAL(17,2) NOT NULL COMMENT '还款逾期违约金',
    adv_define_amt           DECIMAL(17,2) NOT NULL COMMENT '提前还款违约金',
    reduce_print             DECIMAL(17,2) NOT NULL COMMENT '减免本金',
    reduce_int_amt           DECIMAL(17,2) NOT NULL COMMENT '实还免息券贴利息',
    reduce_service_amt      DECIMAL(17,2) NOT NULL COMMENT '实还免息券贴服务费',
    reduce_guarantee_amt    DECIMAL(17,2) NOT NULL COMMENT '实还免息券贴担保费',
    reduce_margin_amt       DECIMAL(17,2) NOT NULL COMMENT '减免保证金',
    reduce_compensate_amt   DECIMAL(17,2) NOT NULL COMMENT '减免代偿金',
    reduce_oint_amt         DECIMAL(17,2) NOT NULL COMMENT '减免罚息',
    reduce_oguarantee_amt   DECIMAL(17,2) NOT NULL COMMENT '减免担保费罚息',
    reduce_define_amt       DECIMAL(17,2) NOT NULL COMMENT '减免逾期违约金',
    reduce_adv_define_amt   DECIMAL(17,2) NOT NULL COMMENT '减免提前还款违约金',
    reduce_activity_amt     DECIMAL(17,2) NOT NULL COMMENT '活动减免金额',
    reduce_compliance_amt   DECIMAL(17,2) NOT NULL COMMENT '合规减免金额',
    reduce_total_amt        DECIMAL(17,2) NOT NULL COMMENT '减免总额',
    repay_type               STRING      NOT NULL COMMENT '还款类型：1-正常还款、4-提前还款、5-提前结清',
    compensate_type          STRING             COMMENT '代偿类型',
    repay_method             STRING             COMMENT '还款方式',
    remark                   STRING             COMMENT '备注',
    action_type              STRING      NOT NULL COMMENT '导入动作：INSERT-新增 UPDATE-更新已有记录本金',
    target_tran_rp_no       STRING             COMMENT 'action_type=UPDATE时被更新的tran_rp_no',
    origin_print             DECIMAL(17,2)      COMMENT 'action_type=UPDATE时被更新记录的原还款本金',
    gen_rule                 STRING      NOT NULL COMMENT '命中的生成分支：B1/B2/B2_FALLBACK/C',
    diff_amt                 DECIMAL(17,2) NOT NULL COMMENT '该借据的总缺口本金',
    batch_no                 STRING      NOT NULL COMMENT '生成批次号',
    import_status            STRING      NOT NULL COMMENT '导入状态：PENDING-待导入 IMPORTED-已导入 REJECTED-核对不通过',
    create_time              STRING      NOT NULL COMMENT '源表创建时间（yyyy-MM-dd HH:mi:ss）',
    update_time              STRING      NOT NULL COMMENT '源表更新时间（yyyy-MM-dd HH:mi:ss）',
    dw_create_time           STRING             COMMENT '数仓创建时间',
    dw_update_time           STRING             COMMENT '数仓更新时间',
    PRIMARY KEY (tran_rp_no)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM，从repay_time提取月份')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '手动生成的还款信息暂存表（原ln_repay_info_manual，按还款时间月级分区，Delta事务表+动态分区写入）',
    'write.bucket.num' = '16',
    'cdc.data.retain.hours' = '0',
    'acid.data.retain.hours' = '0'
);


-- ============================================================
-- 手动生成的还款信息暂存表-STG增量表（原 ln_repay_info_manual_stg）
-- 每日CDC增量临时表，仅存当天从源系统拉取的update数据
--   抽取条件：源表 create_time > '${updatetime}' OR update_time > '${updatetime}'
--   按业务日期分区 pt=yyyymmdd（${bdp.system.bizdate}），LIFECYCLE 30 天自动回收
-- 非事务表（transactional=false），配合目标表做 INSERT OVERWRITE 动态分区同步（ODS为月级分区yyyyMM）
-- 时间字段(repay_time/create_time/update_time/dw_*)用 TIMESTAMP，同步到目标表时 CAST 为 STRING
-- 字段与目标表一致（不含pt分区字段，同步时由 repay_time 动态计算 pt）
-- ============================================================
CREATE TABLE IF NOT EXISTS stg_cons_ln_repay_info_manual_incr_d (
    id                       BIGINT      NOT NULL COMMENT '物理主键（源系统生成）',
    recon_date               STRING      NOT NULL COMMENT '对账日期：格式YYYY-MM-DD',
    product_no               STRING      NOT NULL COMMENT '产品编码',
    apply_no                 STRING      NOT NULL COMMENT '借款申请编号',
    term                     BIGINT      NOT NULL COMMENT '期次号',
    tran_rp_no               STRING             COMMENT '还款流水号（业务唯一键，主键）',
    repay_time               TIMESTAMP          COMMENT '还款时间',
    repay_total_amt          DECIMAL(17,2) NOT NULL COMMENT '还款总额',
    print                    DECIMAL(17,2) NOT NULL COMMENT '还款本金',
    int_amt                  DECIMAL(17,2) NOT NULL COMMENT '还款利息',
    service_amt              DECIMAL(17,2) NOT NULL COMMENT '还款服务费',
    guarantee_amt            DECIMAL(17,2) NOT NULL COMMENT '还款担保费',
    margin_amt               DECIMAL(17,2) NOT NULL COMMENT '还款保证金',
    compensate_amt           DECIMAL(17,2) NOT NULL COMMENT '还款代偿金',
    oint_amt                 DECIMAL(17,2) NOT NULL COMMENT '还款罚息',
    oguarantee_amt           DECIMAL(17,2) NOT NULL COMMENT '还款担保费罚息',
    define_amt               DECIMAL(17,2) NOT NULL COMMENT '还款逾期违约金',
    adv_define_amt           DECIMAL(17,2) NOT NULL COMMENT '提前还款违约金',
    reduce_print             DECIMAL(17,2) NOT NULL COMMENT '减免本金',
    reduce_int_amt           DECIMAL(17,2) NOT NULL COMMENT '实还免息券贴利息',
    reduce_service_amt      DECIMAL(17,2) NOT NULL COMMENT '实还免息券贴服务费',
    reduce_guarantee_amt    DECIMAL(17,2) NOT NULL COMMENT '实还免息券贴担保费',
    reduce_margin_amt       DECIMAL(17,2) NOT NULL COMMENT '减免保证金',
    reduce_compensate_amt   DECIMAL(17,2) NOT NULL COMMENT '减免代偿金',
    reduce_oint_amt         DECIMAL(17,2) NOT NULL COMMENT '减免罚息',
    reduce_oguarantee_amt   DECIMAL(17,2) NOT NULL COMMENT '减免担保费罚息',
    reduce_define_amt       DECIMAL(17,2) NOT NULL COMMENT '减免逾期违约金',
    reduce_adv_define_amt   DECIMAL(17,2) NOT NULL COMMENT '减免提前还款违约金',
    reduce_activity_amt     DECIMAL(17,2) NOT NULL COMMENT '活动减免金额',
    reduce_compliance_amt   DECIMAL(17,2) NOT NULL COMMENT '合规减免金额',
    reduce_total_amt        DECIMAL(17,2) NOT NULL COMMENT '减免总额',
    repay_type               STRING      NOT NULL COMMENT '还款类型：1-正常还款、4-提前还款、5-提前结清',
    compensate_type          STRING             COMMENT '代偿类型',
    repay_method             STRING             COMMENT '还款方式',
    remark                   STRING             COMMENT '备注',
    action_type              STRING      NOT NULL COMMENT '导入动作：INSERT-新增 UPDATE-更新已有记录本金',
    target_tran_rp_no       STRING             COMMENT 'action_type=UPDATE时被更新的tran_rp_no',
    origin_print             DECIMAL(17,2)      COMMENT 'action_type=UPDATE时被更新记录的原还款本金',
    gen_rule                 STRING      NOT NULL COMMENT '命中的生成分支：B1/B2/B2_FALLBACK/C',
    diff_amt                 DECIMAL(17,2) NOT NULL COMMENT '该借据的总缺口本金',
    batch_no                 STRING      NOT NULL COMMENT '生成批次号',
    import_status            STRING      NOT NULL COMMENT '导入状态：PENDING-待导入 IMPORTED-已导入 REJECTED-核对不通过',
    create_time              TIMESTAMP          COMMENT '创建时间',
    update_time              TIMESTAMP          COMMENT '更新时间',
    dw_create_time           TIMESTAMP          COMMENT '数仓创建时间',
    dw_update_time           TIMESTAMP          COMMENT '数仓更新时间'
)
PARTITIONED BY (pt STRING COMMENT '分区:yyyymmdd（业务日期=${bdp.system.bizdate}）')
STORED AS ALIORC
TBLPROPERTIES (
    'columnar.nested.type' = 'true',
    'comment' = '手动还款信息暂存-STG当日增量（CDC临时表，每天update的数据）'
)
LIFECYCLE 30;


-- 原：prd_spark_db.dwd_auto_oapi_repay_info_d
-- 数仓车贷还款明细表
CREATE TABLE IF NOT EXISTS prod_dw_01.dwd_auto_repay_info_incr_delta(
	tran_rp_no STRING NOT NULL COMMENT '还款流水号（业务主键）',
	 repay_type STRING COMMENT '还款类型：1-正常还款、2-提前还款、3-提前结清、4-代偿还款、5-追偿还款',
	 compensate_type STRING COMMENT '代偿类型：1-单期，2-整笔，3-部分',
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
	 oint_amt DECIMAL(38,18) COMMENT '还款罚息（罚息+逾期违约金）',
	 oguarantee_amt DECIMAL(38,18) COMMENT '还款担保费罚息',
	 define_amt DECIMAL(38,18) COMMENT '还款逾期违约金',
	 adv_define_amt DECIMAL(38,18) COMMENT '提前还款违约金',
	 reduce_princ DECIMAL(38,18) COMMENT '减免本金',
	 reduce_int_amt DECIMAL(38,18) COMMENT '减免利息',
	 reduce_service_amt DECIMAL(38,18) COMMENT '减免服务费',
	 reduce_guarantee_amt DECIMAL(38,18) COMMENT '减免担保费',
	 reduce_margin_amt DECIMAL(38,18) COMMENT '减免保证金',
	 reduce_compensate_amt DECIMAL(38,18) COMMENT '减免代偿金',
	 reduce_oint_amt DECIMAL(38,18) COMMENT '减免罚息',
	 reduce_oguarantee_amt DECIMAL(38,18) COMMENT '减免担保费罚息',
	 reduce_define_amt DECIMAL(38,18) COMMENT '减免逾期违约金',
	 reduce_adv_define_amt DECIMAL(38,18) COMMENT '减免提前还款违约金',
	 reduce_activity_amt DECIMAL(38,18) COMMENT '活动减免金额',
	 reduce_compliance_amt DECIMAL(38,18) COMMENT '合规减免金额',
	 reduce_total_amt DECIMAL(38,18) COMMENT '减免总额',
	 repay_method STRING COMMENT '还款方式',
	 remark STRING COMMENT '备注',
	 create_time STRING COMMENT '创建时间',
	 update_time STRING COMMENT '更新时间',
	 dw_create_time STRING COMMENT '数仓创建时间',
	 dw_update_time STRING COMMENT '数仓更新时间',
	PRIMARY KEY(tran_rp_no)
) 
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM，由 accept_date 生成') STORED AS aliorc 
TBLPROPERTIES ('cdc.data.retain.hours'='24',
	 'acid.cdc.mode.enable'='false',
	 'acid.data.retain.hours'='0',
	 'columnar.nested.type'='true',
	 'comment'='DWD层-车贷还款信息明细表',
	 'transactional'='true',
	 'write.bucket.num'='16');


-- ============================================================
-- 海南-担保业务解除明细表（原 dm_req_supv_hainan_relese_m）
-- 原ADB：非分区，PRIMARY KEY(business_code, stat_month)，REPLACE INTO 全量覆盖，340万数据
-- 适配：按月分区（pt=YYYY-MM，由 stat_month 生成），循环任务每月重算对应分区
--   分区字段 pt 与业务字段 stat_month 值相同（YYYY-MM）
--   主键：(business_code, stat_month) — 保留原表主键
--   事务表，支持主键约束
-- 字段类型/小数精度对齐原表：guarantee_rec_amt DECIMAL(10,2)
-- ============================================================
CREATE TABLE IF NOT EXISTS dm_req_supv_hainan_relese_info_incr_delta (
    platform_no               STRING         COMMENT '平台编号',
    platform_name             STRING         COMMENT '平台名称',
    financer_no               STRING         COMMENT '资金方编号',
    financer_name             STRING         COMMENT '资金方名称',
    contract_code             STRING         COMMENT '合同编号',
    business_code             STRING     NOT NULL    COMMENT '业务编号',
    stat_month                STRING         COMMENT '月度（YYYY-MM）',
    guarantee_release_code    STRING         COMMENT '解保编号',
    guarantee_rec_method      STRING         COMMENT '收回方式',
    guarantee_rec_date        STRING         COMMENT '收回日期',
    guarantee_rec_amt         DECIMAL(10,2)  COMMENT '收回金额（元）',
    is_settled                STRING         COMMENT '是否结清 Y/N',
    project_no                BIGINT         COMMENT '项目编号',
    PRIMARY KEY (business_code)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM，由 stat_month 去掉横杠生成')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '海南-担保业务解除明细表（按月分区，循环任务每月重算）',
    'write.bucket.num' = '16'
);

-- ============================================================
-- 原：prd_spark_db.dm_req_supv_hainan_cpst_m（海南-代偿明细表）
-- 适配为 MC 分区事务表，按月分区 pt=yyyyMM，循环任务每月重算
-- 主键：(business_code, cpst_sequence)，同一借据可有多笔代偿
-- ============================================================
CREATE TABLE IF NOT EXISTS dm_req_supv_hainan_cpst_info_incr_delta (
    platform_no               STRING         COMMENT '平台编号',
    platform_name             STRING         COMMENT '平台名称',
    financer_no               STRING         COMMENT '资金方编号',
    financer_name             STRING         COMMENT '资金方名称',
    contract_code             STRING         COMMENT '合同编号',
    business_code             STRING     NOT NULL    COMMENT '业务编号',
    agency_type               STRING         COMMENT '代偿机构类型',
    stat_month                STRING         COMMENT '月度（YYYY-MM）',
    cpst_sequence             BIGINT    not null     COMMENT '代偿序号（按代偿日期排序，含历史所有代偿记录）',
    cpst_date                 STRING         COMMENT '代偿日期（yyyy-MM-dd）',
    cpst_princ                DECIMAL(18,2)  COMMENT '本次代偿金额（本金，元）',
    cpst_interest             DECIMAL(18,2)  COMMENT '本次代偿利息（元）',
    project_no                BIGINT         COMMENT '项目编号',
    PRIMARY KEY (business_code, cpst_sequence)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM，由 stat_month 去掉横杠生成')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '海南-代偿明细表（按月分区，循环任务每月重算）',
    'write.bucket.num' = '16'
);

-- ============================================================
-- 044 拆分表1：海南客户信息表（筛选基准表，非分区普通表）
-- 字段事实源：原044宽表 dm_req_supervision_hainan_statement_m + 简版借据
-- （宽表无的字段取自简版借据，注释中"新增"标注）
-- 承载044原筛选逻辑，供前端技术筛选使用（2/3表不JOIN本表，各自从源表取数）
-- 非分区普通表，INSERT OVERWRITE 全表覆盖
-- ============================================================
CREATE TABLE IF NOT EXISTS dm_req_supv_hainan_cust_info_incr_delta (
    bill_app_no                STRING     NOT NULL COMMENT '借款申请编号/业务编号（关联键）',
    stat_month                 STRING     NOT NULL COMMENT '月度=放款月份（yyyy-MM，关联键）',
    indiv_cust_id              STRING              COMMENT '客户编号',
    name                       STRING              COMMENT '客户名称',
    customer_type              STRING              COMMENT '客户类型（新增-源简版借据）',
    id_card_type               STRING              COMMENT '证件类型（新增-源简版借据）',
    id_card                    STRING              COMMENT '证件号码（新增-源简版借据）',
    address                    STRING              COMMENT '所在地区（新增-源简版借据）',
    farmer_flag                STRING              COMMENT '农户标志：0-非农户 1-农户（新增-源简版借据）',
    project_no                 BIGINT              COMMENT '项目编号',
    project_name               STRING              COMMENT '项目名称（新增-源简版借据）',
    guarantor_no               STRING              COMMENT '担保方编号（新增-源简版借据）',
    guarantor_name             STRING              COMMENT '担保方名称（新增-源简版借据）',
    platform_no                STRING              COMMENT '合作方编号',
    platform_name              STRING              COMMENT '合作方名称',
    financer_no                STRING              COMMENT '资金方编号',
    financer_name              STRING              COMMENT '资金方名称',
    guarantee_start_date       DATE                COMMENT '放款日期（044 ETL中=loan_day）',
    total_term                 BIGINT              COMMENT '期数（新增-源简版借据）',
    guarantee_amt              DECIMAL(17,2)       COMMENT '借款本金(元)（044 ETL中=loan_amt）',
    mobile                     STRING              COMMENT '联系电话（新增-源简版借据）'
)
STORED AS ALIORC
TBLPROPERTIES (
    'columnar.nested.type' = 'true',
    'comment' = '海南-客户信息表（筛选基准表，非分区普通表，INSERT OVERWRITE全表覆盖）',
    'write.bucket.num' = '8'
);

-- ============================================================
-- 044 拆分表2：海南担保业务明细表
-- 字段100%来自原044宽表，通过 business_code+stat_month 关联表1继承筛选
-- ============================================================
CREATE TABLE IF NOT EXISTS dm_req_supv_hainan_guar_biz_info_incr_delta (
    contract_code              STRING              COMMENT '合同编号',
    business_code              STRING     NOT NULL COMMENT '业务编号（关联表1 bill_app_no）',
    stat_month                 STRING     NOT NULL COMMENT '月度（关联表1键）',
    indiv_cust_id              STRING              COMMENT '客户编号',
    name                       STRING              COMMENT '客户名称',
    guarantee_type             STRING              COMMENT '担保类型',
    business_development_mode  STRING              COMMENT '业务开展方式',
    guarantee_amt              DECIMAL(17,2)       COMMENT '担保金额',
    loan_bond_issue_rate       DECIMAL(11,8)       COMMENT '贷款/债券发行利率',
    guarantee_rate             DECIMAL(10,2)       COMMENT '担保费率',
    guarantee_start_date       DATE                COMMENT '担保起始日期',
    guarantee_end_date         DATE                COMMENT '担保到期日期',
    is_first_loan              STRING              COMMENT '是否首贷户 Y/N',
    is_ovd                     STRING              COMMENT '是否逾期 Y/N',
    five_level_classification  STRING              COMMENT '五级分类 A-正常',
    PRIMARY KEY (business_code, stat_month)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '海南-担保业务明细表（按月分区）',
    'write.bucket.num' = '8'
);

-- ============================================================
-- 044 拆分表3：海南担保业务风险分担情况表
-- 字段100%来自原044宽表，通过 business_code+stat_month 关联表1继承筛选
-- ============================================================
CREATE TABLE IF NOT EXISTS dm_req_supv_hainan_risk_share_info_incr_delta (
    contract_code                                  STRING              COMMENT '合同编号',
    business_code                                  STRING     NOT NULL COMMENT '业务编号（关联表1 bill_app_no）',
    stat_month                                     STRING     NOT NULL COMMENT '月度（关联表1键）',
    institution_own_risk_ratio                     DECIMAL(5,2)        COMMENT '机构自身风险承担比例（%）',
    bank_risk_ratio                                DECIMAL(5,2)        COMMENT '银行风险承担比例（%）',
    financial_leasing_company_risk_ratio           DECIMAL(5,2)        COMMENT '金租公司风险承担比例（%）',
    other_institution_risk_ratio                   DECIMAL(5,2)        COMMENT '其他机构风险承担比例（%）',
    total_risk_ratio                               DECIMAL(5,2)        COMMENT '合计风险承担比例（%）',
    PRIMARY KEY (business_code, stat_month)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'columnar.nested.type' = 'true',
    'comment' = '海南-担保业务风险分担情况表（按月分区）',
    'write.bucket.num' = '8'
);

-- ============================================================
-- 原：f_prd_spark_db.tmp2_cons_payment_common（消费支付公共逻辑中间表-平移观察点后的在贷）
-- 045周期任务输出表，数据源由消金180天表现表改为详版借据
-- （dwd_req_supervision_detail_info_full_t，其obs_date即平移后观察点）
-- 原ADB：PARTITION BY VALUE(shifted_obs_date)，
--        PRIMARY KEY(shifted_obs_date, obs_date, bill_app_no, project_no)
-- 适配：按月分区pt=yyyyMM（平移后观察月份），单次调度产出单一平移月分区，
--   MERGE INTO按主键(shifted_obs_date,obs_date,bill_app_no,project_no)+分区pt upsert
--   （对应原ADB INSERT INTO主键覆盖语义：不清空分区、存量行按主键更新，重跑幂等）
-- ============================================================
CREATE TABLE IF NOT EXISTS tmp2_cons_payment_common (
    project_no              BIGINT        NOT NULL COMMENT '项目编号（主键）',
    product_no              STRING                 COMMENT '产品编码（源简版借据）',
    bill_app_no             STRING        NOT NULL COMMENT '借款申请编号（主键）',
    obs_date                STRING        NOT NULL COMMENT '观察日期（原始观察点=平移后观察月末-平移月数，yyyy-MM-dd）（主键）',
    princ_bal_info          DECIMAL(18,2)          COMMENT '客方在贷（放款金额-累计已还本金(非代偿)，含未回收，还款明细重算）',
    fund_princ_bal_info     DECIMAL(18,2)          COMMENT '资方在贷（放款金额-累计已还本金(非追偿)，还款明细重算）',
    loan_amt                DECIMAL(18,2)          COMMENT '放款金额（源简版借据）',
    shifted_obs_date        STRING        NOT NULL COMMENT '平移后的观察日期（=详版借据obs_date，yyyy-MM-dd）（主键）',
    shifted_act_repay_date  STRING                 COMMENT '平移后的实际还款日期（结清时=实际还款日期+平移月数，yyyy-MM-dd；中间表非最终展示表，用STRING）',
    month_cpst_amt          DECIMAL(18,2)          COMMENT '本月代偿额（原始观察点当月，repay_type=7，还款明细重算）',
    month_cpst_princ_amt    DECIMAL(18,2)          COMMENT '本月代偿本金金额（还款明细重算）',
    month_cpst_cnt          DECIMAL(18,2)          COMMENT '本月代偿笔数（还款明细重算）',
    year_cpst_amt           DECIMAL(18,2)          COMMENT '当年代偿额（原始观察点当年，还款明细重算）',
    year_cpst_princ_amt     DECIMAL(18,2)          COMMENT '当年代偿本金金额（还款明细重算）',
    year_cpst_cnt           DECIMAL(18,2)          COMMENT '当年代偿笔数（还款明细重算）',
    cum_cpst_amt            DECIMAL(18,2)          COMMENT '累计代偿额（还款明细重算，原180d口径）',
    cum_cpst_princ_amt      DECIMAL(18,2)          COMMENT '累计代偿本金金额（还款明细重算，原180d口径）',
    total_cpst_cnt          DECIMAL(18,2)          COMMENT '累计代偿笔数（还款明细重算）',
    PRIMARY KEY (shifted_obs_date, obs_date, bill_app_no, project_no)
)
PARTITIONED BY (pt STRING COMMENT '分区字段：yyyyMM，由平移后观察月份生成')
STORED AS ALIORC
TBLPROPERTIES (
    'transactional' = 'true',
    'acid.data.retain.hours' = '0',   -- ACID数据保留时长：0=后台合并后即清理历史数据版本（纯批处理表，无回溯需求）
    'cdc.data.retain.hours' = '0',    -- CDC数据保留时长：0=不保留变更记录（下游仅按分区读取，无CDC消费）
    'columnar.nested.type' = 'true',
    'comment' = '消费支付公共逻辑中间表（分区版）-平移观察点后的在贷',
    'write.bucket.num' = '16'
);


-- ============================================================
-- 045/046：业务管控规则操作日志表（数据删除任务的数据源）
-- 原：f_prd_spark_db.business_control_operate_log
-- 非分区PK Delta Table（transactional=true）
-- 主键：operate_id（原AUTO_INCREMENT，MC不支持自增，同步时保留源库自增值）
-- json类型 → STRING；去掉KEY idx_*；DISTRIBUTE BY HASH → write.bucket.num
-- 数据来源：需由数据集成同步任务从ADB灌入（全量+增量），SQL任务仅读取不写入
-- 045/046通过 GET_JSON_OBJECT(records_data,'$.projectRule.projectId') 提取管控项目ID
-- ============================================================
CREATE TABLE IF NOT EXISTS business_control_operate_log(
	operate_id BIGINT NOT NULL COMMENT '业务管控规则操作日志表—主键',
	 project_rule_id BIGINT NOT NULL COMMENT '业务管控规则ID',
	 operate_type STRING COMMENT '操作类型类型:\n1-新增管控规则\n2-计算在贷完成\n3-选择装入\n4-选择装入不超限部分\n5-发起新增规则审核\n6-新增规则审核通过\n7-新增规则审核不通过\n8-撤销新增\n9-新增规则装入失败\n10-暂停自动导入\n11-恢复自动导入\n12-自动导入完成\n13-修改管控规则\n14-修改计算在贷完成\n15-撤销修改规则\n16-发起修改规则审核\n17-修改规则审核通过\n18-修改规则审核不通过\n19-撤销修改\n20-修改规则装入失败\n21-发起删除规则审核\n22-删除规则审核不通过\n23-撤销删除',
	 records_data STRING COMMENT '操作日志详细信息',
	 create_time DATETIME COMMENT '新增时间',
	PRIMARY KEY(operate_id)) STORED AS aliorc 
TBLPROPERTIES ('cdc.data.retain.hours'='24',
	 'acid.cdc.mode.enable'='false',
	 'acid.data.retain.hours'='24',
	 'columnar.nested.type'='true',
	 'comment'='业务管控规则操作日志表',
	 'transactional'='true',
	 'write.bucket.num'='16');





