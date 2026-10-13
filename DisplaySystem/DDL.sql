/******************************************/
/*   DatabaseName = prd_spark_db          */
/*   TableName = dm_req_supervision_project_full_t */
/* MaxCompute Delta 主键表，按 pt 分区 */
/******************************************/
DROP TABLE IF EXISTS `dm_req_supervision_project_full_t`;
CREATE TABLE IF NOT EXISTS `dm_req_supervision_project_full_t` (
  `project_no` BIGINT NOT NULL COMMENT '项目编号',
  `financer_no` STRING NOT NULL COMMENT '资金方编号',
  `financer_name` STRING COMMENT '资金方名称',
  `platform_no` STRING NOT NULL COMMENT '平台编号',
  `platform_name` STRING COMMENT '平台名称',
  `guarantor_no` STRING NOT NULL COMMENT '担保方编号',
  `guarantor_name` STRING COMMENT '担保方名称',
  `province_id` STRING NOT NULL COMMENT '省份ID',
  `stat_month` STRING NOT NULL COMMENT '统计月份（格式：yyyy-MM）',
  `term_start_month_cnt` BIGINT NOT NULL COMMENT '期初数：合作业务笔数',
  `term_rise_cnt` BIGINT NOT NULL COMMENT '本月度增加：合作业务笔数（发生额）',
  `term_down_cnt` BIGINT NOT NULL COMMENT '本月度减少：合作业务笔数（发生额）',
  `term_end_month_cnt` BIGINT NOT NULL COMMENT '期末数：合作业务笔数',
  `term_start_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期初数：融资在保余额',
  `term_rise_amt` DECIMAL(17, 2) NOT NULL COMMENT '本月度增加：融资在保余额（发生额）',
  `term_down_amt` DECIMAL(17, 2) NOT NULL COMMENT '本月度减少：融资在保余额（发生额）',
  `term_end_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期末数：融资在保余额',
  PRIMARY KEY (`financer_no`,`platform_no`,`guarantor_no`,`project_no`,`stat_month`,`province_id`)
)
-- LIFECYCLE 120
STORED AS ALIORC
TBLPROPERTIES (
  'transactional'='true',
  'columnar.nested.type'='true',
  'comment'='月报-按项目统计',
  'write.bucket.num'='16',
  'cdc.data.retain.hours'='0',
  'acid.data.retain.hours'='0'
);

/******************************************/
/*   DatabaseName = prd_spark_db          */
/*   TableName = dm_req_supervision_project_q_full_t */
/* MaxCompute Delta 主键表，按 pt 分区 */
/******************************************/
DROP TABLE IF EXISTS `dm_req_supervision_project_q_full_t`;
CREATE TABLE IF NOT EXISTS `dm_req_supervision_project_q_full_t` (
  `project_no` BIGINT NOT NULL COMMENT '项目编号',
  `financer_no` STRING NOT NULL COMMENT '资金方编号',
  `financer_name` STRING COMMENT '资金方名称',
  `platform_no` STRING NOT NULL COMMENT '平台编号',
  `platform_name` STRING COMMENT '平台名称',
  `guarantor_no` STRING NOT NULL COMMENT '担保方编号',
  `guarantor_name` STRING COMMENT '担保方名称',
  `province_id` STRING NOT NULL COMMENT '省份ID',
  `stat_quarter` STRING NOT NULL COMMENT '统计季度（格式：yyyy-Qn）',
  `term_start_month_cnt` BIGINT NOT NULL COMMENT '期初数：合作业务笔数',
  `term_rise_cnt` BIGINT NOT NULL COMMENT '本季度增加：合作业务笔数（发生额）',
  `term_down_cnt` BIGINT NOT NULL COMMENT '本季度减少：合作业务笔数（发生额）',
  `term_end_month_cnt` BIGINT NOT NULL COMMENT '期末数：合作业务笔数',
  `term_start_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期初数：融资在保余额',
  `term_rise_amt` DECIMAL(17, 2) NOT NULL COMMENT '本季度增加：融资在保余额（发生额）',
  `term_down_amt` DECIMAL(17, 2) NOT NULL COMMENT '本季度减少：融资在保余额（发生额）',
  `term_end_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期末数：融资在保余额',
  PRIMARY KEY (`financer_no`,`platform_no`,`guarantor_no`,`project_no`,`stat_quarter`,`province_id`)
)
-- LIFECYCLE 120
STORED AS ALIORC
TBLPROPERTIES (
  'transactional'='true',
  'columnar.nested.type'='true',
  'comment'='季报-按项目统计',
  'write.bucket.num'='16',
  'cdc.data.retain.hours'='0',
  'acid.data.retain.hours'='0'
);




/******************************************/
/*   DatabaseName = prd_spark_db          */
/*   TableName = dm_req_supervision_finan_province_full_t */
/* MaxCompute Delta 主键表，按 pt 分区 */
/******************************************/
DROP TABLE IF EXISTS `dm_req_supervision_finan_province_full_t`;
CREATE TABLE IF NOT EXISTS `dm_req_supervision_finan_province_full_t` (
  `project_no` BIGINT NOT NULL COMMENT '项目编号',
  `financer_no` STRING NOT NULL COMMENT '资金方编号',
  `financer_name` STRING COMMENT '资金方名称',
  `platform_no` STRING NOT NULL COMMENT '平台编号',
  `platform_name` STRING COMMENT '平台名称',
  `guarantor_no` STRING NOT NULL COMMENT '担保方编号',
  `guarantor_name` STRING COMMENT '担保方名称',
  `province_id` STRING NOT NULL COMMENT '省份ID',
  `stat_month` STRING NOT NULL COMMENT '统计月份（格式：yyyy-MM）',
  `term_start_month_cnt` BIGINT NOT NULL COMMENT '期初数：合作业务笔数',
  `term_rise_cnt` BIGINT NOT NULL COMMENT '本月度增加：合作业务笔数（发生额）',
  `term_down_cnt` BIGINT NOT NULL COMMENT '本月度减少：合作业务笔数（发生额）',
  `term_end_month_cnt` BIGINT NOT NULL COMMENT '期末数：合作业务笔数',
  `term_start_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期初数：融资在保余额',
  `term_rise_amt` DECIMAL(17, 2) NOT NULL COMMENT '本月度增加：融资在保余额（发生额）',
  `term_down_amt` DECIMAL(17, 2) NOT NULL COMMENT '本月度减少：融资在保余额（发生额）',
  `term_end_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期末数：融资在保余额',
  PRIMARY KEY (`financer_no`,`platform_no`,`guarantor_no`,`project_no`,`stat_month`,`province_id`)
)
-- LIFECYCLE 120
STORED AS ALIORC
TBLPROPERTIES (
  'transactional'='true',
  'columnar.nested.type'='true',
  'comment'='月报-资方&省份',
  'write.bucket.num'='16',
  'cdc.data.retain.hours'='0',
  'acid.data.retain.hours'='0'
);



/******************************************/
/*   DatabaseName = prd_spark_db          */
/*   TableName = dm_req_supervision_finan_province_q_full_t */
/* MaxCompute Delta 主键表，按 pt 分区 */
/******************************************/
DROP TABLE IF EXISTS `dm_req_supervision_finan_province_q_full_t`;
CREATE TABLE IF NOT EXISTS `dm_req_supervision_finan_province_q_full_t` (
  `project_no` BIGINT NOT NULL COMMENT '项目编号',
  `financer_no` STRING NOT NULL COMMENT '资金方编号',
  `financer_name` STRING COMMENT '资金方名称',
  `platform_no` STRING NOT NULL COMMENT '平台编号',
  `platform_name` STRING COMMENT '平台名称',
  `guarantor_no` STRING NOT NULL COMMENT '担保方编号',
  `guarantor_name` STRING COMMENT '担保方名称',
  `province_id` STRING NOT NULL COMMENT '省份ID',
  `stat_quarter` STRING NOT NULL COMMENT '统计季度（格式：yyyy-Qn）',
  `term_start_month_cnt` BIGINT NOT NULL COMMENT '期初数：合作业务笔数',
  `term_rise_cnt` BIGINT NOT NULL COMMENT '本季度增加：合作业务笔数（发生额）',
  `term_down_cnt` BIGINT NOT NULL COMMENT '本季度减少：合作业务笔数（发生额）',
  `term_end_month_cnt` BIGINT NOT NULL COMMENT '期末数：合作业务笔数',
  `term_start_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期初数：融资在保余额',
  `term_rise_amt` DECIMAL(17, 2) NOT NULL COMMENT '本季度增加：融资在保余额（发生额）',
  `term_down_amt` DECIMAL(17, 2) NOT NULL COMMENT '本季度减少：融资在保余额（发生额）',
  `term_end_month_amt` DECIMAL(17, 2) NOT NULL COMMENT '期末数：融资在保余额',
  PRIMARY KEY (`financer_no`,`platform_no`,`guarantor_no`,`project_no`,`stat_quarter`,`province_id`)
)
-- LIFECYCLE 120
STORED AS ALIORC
TBLPROPERTIES (
  'transactional'='true',
  'columnar.nested.type'='true',
  'comment'='季报-资方&省份',
  'write.bucket.num'='16',
  'cdc.data.retain.hours'='0',
  'acid.data.retain.hours'='0'
);
