/*---------------------------业务管控（仅删除指定projectId数据）-------------------------*/
-- 手动-项目规则借据
DELETE FROM `f_prd_spark_db`.`manual_bizctrl_project_bill_d` 
WHERE project_id IN (76);

-- 手动-公司规则借据（若有project_id字段，无则替换为关联字段如project_rule_id）
DELETE FROM `f_prd_spark_db`.`manual_bizctrl_company_bill_d` 
WHERE project_id IN (76);

-- 自动-项目规则借据
DELETE FROM `f_prd_spark_db`.`auto_bizctrl_project_bill_d` 
WHERE project_id IN (76);

-- 自动-公司规则借据（若有project_id字段，无则替换为关联字段）
DELETE FROM `f_prd_spark_db`.`auto_bizctrl_company_bill_d` 
WHERE project_id IN (76);


-- 数据调整日期
DELETE FROM `f_prd_spark_db`.bizctrl_loan_date_adjusted 
WHERE project_id IN (76);



/*---------------------------展示系统（仅删除指定projectId数据）-------------------------*/
-- 简版借据
DELETE FROM `prd_spark_db`.`dim_req_supervision_payment_info_d`
WHERE project_no IN (76);

-- 详版借据
DELETE FROM `prd_spark_db`.`dwd_req_supervision_detail_info_d`
WHERE project_no IN (76);

-- 日报
DELETE FROM `prd_spark_db`.`dws_req_supervision_statement_d`
WHERE project_no IN (76);

-- 在贷统计
DELETE FROM prd_spark_db.`dws_req_supervision_princ_info_m`
WHERE project_no IN (76);

-- 按资方省份
DELETE FROM prd_spark_db.dm_req_supervision_finan_province_m
WHERE project_no IN (76);


-- 按项目统计
DELETE FROM prd_spark_db.dm_req_supervision_project_m
WHERE project_no IN (76);
-- 四川
DELETE FROM `prd_spark_db`.`dm_req_supervision_sichuan_statement_m`
WHERE project_no IN (76);

-- -- 武汉相关
-- DELETE FROM prd_spark_db.dm_req_sup_wuhan_cpst_m
-- WHERE project_no IN (76);

-- DELETE FROM prd_spark_db.`dm_req_sup_wuhan_enterprise_m`
-- WHERE project_no IN (76);

-- DELETE FROM prd_spark_db.`dm_req_sup_wuhan_project_m`
-- WHERE project_no IN (76);

-- DELETE FROM `prd_spark_db`.`dm_req_supv_wuhan_cus_m`
-- WHERE project_no IN (76);

-- -- 海南相关
-- DELETE FROM prd_spark_db.`dm_req_supv_hainan_relese_m`
-- WHERE project_no IN (76);

-- DELETE FROM prd_spark_db.dm_req_supv_hainan_cpst_m
-- WHERE project_no IN (76);

-- DELETE FROM prd_spark_db.dm_req_supervision_hainan_statement_m
-- WHERE project_no IN (76);

-- 河北
DELETE FROM prd_spark_db.dm_req_supv_hebei_statement_m
WHERE project_no IN (76);
