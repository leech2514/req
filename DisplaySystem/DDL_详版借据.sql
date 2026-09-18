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
