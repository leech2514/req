/******************************************/
/*   DatabaseName = test_zxbs_db   */
/*   TableName = ads_hain_g23_1_risk_share   */
/******************************************/
CREATE TABLE `ads_hain_g23_1_risk_share` (
  `dbank_id` varchar(100) NOT NULL COMMENT '机构代码',
  `ddate` date NOT NULL COMMENT '报表日期',
  `xh` int NOT NULL COMMENT '序号',
  `cont_no` varchar(100) NOT NULL COMMENT '合同编号',
  `biz_no` varchar(100) NOT NULL COMMENT '业务编号',
  `org_ratio` decimal(20, 6) COMMENT '机构自身风险承担比例',
  `natl_fund_ratio` decimal(20, 6) COMMENT '国家级担保基金机构风险承担比例',
  `prov_fund_ratio` decimal(20, 6) COMMENT '省级担保基金机构风险承担比例',
  `prov_gov_ratio` decimal(20, 6) COMMENT '省级人民政府风险承担比例',
  `prov_comp_ratio` decimal(20, 6) COMMENT '省级融资担保公司风险承担比例',
  `city_fund_ratio` decimal(20, 6) COMMENT '市级担保基金风险承担比例',
  `city_gov_ratio` decimal(20, 6) COMMENT '市级人民政府风险承担比例',
  `city_comp_ratio` decimal(20, 6) COMMENT '市级融资担保公司风险承担比例',
  `county_gov_ratio` decimal(20, 6) COMMENT '县级人民政府风险承担比例',
  `county_comp_ratio` decimal(20, 6) COMMENT '县级融资担保公司风险承担比例',
  `pbank_ratio` decimal(20, 6) COMMENT '国家开发银行及政策性银行风险承担比例',
  `big4_ratio` decimal(20, 6) COMMENT '四大国有商业银行风险承担比例',
  `joint_stock_ratio` decimal(20, 6) COMMENT '股份制商业银行风险承担比例',
  `city_bank_ratio` decimal(20, 6) COMMENT '城市商业银行风险承担比例',
  `rural_fin_ratio` decimal(20, 6) COMMENT '农村合作金融机构风险承担比例',
  `ins_ratio` decimal(20, 6) COMMENT '保险公司机构风险承担比例',
  `other_ratio` decimal(20, 6) COMMENT '其他各类机构风险承担比例',
  `total_ratio` decimal(20, 6) COMMENT '合计各类机构风险承担比例',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `project_name` varchar(64) COMMENT '项目名称',
  KEY `pk_sys_cont_no` (`cont_no`),
  KEY `pk_sys_ddate` (`ddate`),
  PRIMARY KEY (`cont_no`,`ddate`)
) DISTRIBUTE BY HASH(`cont_no`) STORAGE_POLICY='HOT' ENGINE='XUANWU_V2' TABLE_PROPERTIES='{"format":"columnstore"}' COMMENT='担保业务风险分担情况信息表'
;


/******************************************/
/*   DatabaseName = test_zxbs_db   */
/*   TableName = ads_hain_g23_2_relieve_detail   */
/******************************************/
CREATE TABLE `ads_hain_g23_2_relieve_detail` (
  `dbank_id` varchar(100) NOT NULL COMMENT '机构代码',
  `ddate` date NOT NULL COMMENT '报表日期',
  `xh` varchar(100) NOT NULL COMMENT '序号',
  `relieve_no` varchar(100) NOT NULL COMMENT '解保编号',
  `cont_no` varchar(100) NOT NULL COMMENT '合同编号',
  `biz_no` varchar(100) NOT NULL COMMENT '业务编号',
  `recv_type` varchar(100) COMMENT '收回方式',
  `recv_date` date COMMENT '收回日期',
  `recv_amt` decimal(20, 2) COMMENT '收回金额',
  `settle_flag` varchar(100) COMMENT '是否结清',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `project_name` varchar(64) COMMENT '项目名称',
  KEY `pk_sys_cont_no` (`cont_no`),
  KEY `pk_sys_ddate` (`ddate`),
  KEY `pk_sys_relieve_no` (`relieve_no`),
  PRIMARY KEY (`relieve_no`)
) DISTRIBUTE BY HASH(`relieve_no`) STORAGE_POLICY='HOT' ENGINE='XUANWU_V2' TABLE_PROPERTIES='{"format":"columnstore"}' COMMENT='担保业务解除明细信息表'
;

/******************************************/
/*   DatabaseName = test_zxbs_db   */
/*   TableName = ads_hain_g27_comp_detail   */
/******************************************/
CREATE TABLE `ads_hain_g27_comp_detail` (
  `dbank_id` varchar(100) NOT NULL COMMENT '机构代码',
  `ddate` date NOT NULL COMMENT '报表日期',
  `xh` int NOT NULL COMMENT '序号',
  `cont_no` varchar(100) NOT NULL COMMENT '合同编号',
  `biz_no` varchar(100) NOT NULL COMMENT '业务编号',
  `comp_type` varchar(100) COMMENT '代偿机构类型',
  `comp_seq` varchar(100) COMMENT '代偿序号',
  `comp_date` date COMMENT '代偿日期',
  `comp_amt` decimal(20, 2) COMMENT '本次代偿金额',
  `comp_int` decimal(20, 2) COMMENT '本次代偿利息',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `project_name` varchar(64) COMMENT '项目名称',
  KEY `pk_sys_comp_seq` (`comp_seq`),
  KEY `pk_sys_cont_no` (`cont_no`),
  KEY `pk_sys_xh` (`xh`),
  PRIMARY KEY (`comp_seq`,`cont_no`)
) DISTRIBUTE BY HASH(`cont_no`) STORAGE_POLICY='HOT' ENGINE='XUANWU_V2' TABLE_PROPERTIES='{"format":"columnstore"}' COMMENT='代偿明细信息表'
;


/******************************************/
/*   DatabaseName = test_zxbs_db   */
/*   TableName = ads_hain_g28_recover_detail   */
/******************************************/
CREATE TABLE `ads_hain_g28_recover_detail` (
  `dbank_id` varchar(100) NOT NULL COMMENT '机构代码',
  `ddate` date NOT NULL COMMENT '报表日期',
  `xh` int NOT NULL COMMENT '序号',
  `cont_no` varchar(100) NOT NULL COMMENT '合同编号',
  `biz_no` varchar(100) NOT NULL COMMENT '业务编号',
  `recv_seq` varchar(100) NOT NULL COMMENT '回收序号',
  `recv_date` date COMMENT '回收日期',
  `recv_amt` decimal(20, 2) COMMENT '本次回收金额',
  `create_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `project_name` varchar(64) COMMENT '项目名称',
  KEY `pk_sys_recv_seq` (`recv_seq`),
  PRIMARY KEY (`recv_seq`)
) DISTRIBUTE BY HASH(`recv_seq`) STORAGE_POLICY='HOT' ENGINE='XUANWU_V2' TABLE_PROPERTIES='{"format":"columnstore"}' COMMENT='代偿回收明细信息表'
;
