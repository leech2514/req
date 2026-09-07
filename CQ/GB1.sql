-- ============================================================================
-- 脚本名称: GB1.sql (重庆淘然-中恒信合车金融1.0 金融局报送)
-- 所属层级: ADS
-- 业务域: 重庆淘然/担保报送
-- 功能描述: 生成重庆金融局担保业务日报数据，写入 ads_cq_financial_report_business_d
-- 源表:
--   prd_spark_db.dwd_auto_zf_rent_plan_d   还款计划明细（本金/利息/实还）
--   prd_spark_db.dwd_auto_oapi_loan_d      放款明细（放款金额/放款日/到期日）
--   prd_spark_db.dim_base_indiv_info       个人信息维度（客户号/姓名）
--   prd_spark_db.ods_auto_oapi_project_d   项目信息（年利率/担保费率）
-- 目标表: test_zxbs_db.ads_cq_financial_report_business_d
-- 调度参数: datadt=$bizdate   (DataWorks 节点 > 调度配置 > 参数；格式 yyyymmdd)
-- 负责人: <name>
-- 创建日期: 2026-08-17
-- 迁移说明 (Xihe/Spark → MaxCompute):
--   1. DATE '${datadt}'  →  to_date('${datadt}','yyyymmdd')   (datadt 统一为 yyyymmdd)
--   2. DATE_ADD(d, INTERVAL n MONTH)  →  ADD_MONTHS(d, n)      (MC 的 DATE_ADD 仅支持天)
--   3. 库名 prd_spark_db / test_zxbs_db 迁移后按实际 MC 项目名调整
--   4. 建议将目标表改为按 obs_date 分区，并用 INSERT OVERWRITE PARTITION 覆盖写入，
--      避免重跑产生重复数据（当前保留原 INSERT INTO 语义）
--   5. 若源表日期字段迁移后改为 STRING，需在比较处补 to_date 转换
-- ============================================================================

INSERT INTO `test_zxbs_db`.`ads_cq_financial_report_business_d` (
    `org_code`,                       -- 机构编码
    `project_code`,                   -- 项目编码
    `cust_type`,                      -- 客户类型（1企业客户 2个人客户）
    `cust_id`,                        -- 客户编码
    `cust_name`,                      -- 客户名称
    `cert_type`,                      -- 证件类型（1军官证 2护照 3身份证 4其他）
    `cert_number`,                    -- 证件编码(企业填法人代表对应的证件编码)
    `industry_code`,                  -- 所属行业编码
    `industry_name`,                  -- 所属行业名称
    `user_zone_code`,                 -- 所属区域编码
    `user_zone_name`,                 -- 所属区域名称
    `user_scale`,                     -- 客户规模编码（1大型企业 2中型企业 3小型企业 4微型企业）
    `is_relate_agriculture`,          -- 是否涉农（1是 2否）
    `business_type`,                  -- 业务类型（10 融资性担保业务 1001流动资金贷款担保..）
    `contract_amount`,                -- 合同金额
    `loan_amount`,                    -- 已放款金额
    `loan_rate`,                      -- 贷款年利率，传入2则利率就是 2%
    `guarantee_sum_rate`,             -- 担保综合费率，传入2则利率就是 2%
    `loan_date`,                      -- 放款日期 yyyy-MM-dd
    `contract_end_date`,              -- 合同截止日期 yyyy-MM-dd
    `repayment_type`,                 -- 还款方式(1按月等额本金 2按月等额本息...)
    `counter_guarantee_measures`,     -- 反担保措施(1抵押 2质押 3保证 4信用 5其他)
    `counter_guarantee_measures_memo`,-- 反担保备注
    `bank_credit_tag`,                -- 银行授信记录标识
    `project_status`,                 -- 项目状态(60保后监管 70项目逾期...)
    `surety_man`,                     -- 担保人，债权人
    `counter_guarantee_amount`,       -- 反担保物总价值
    `is_deposit_pledge`,              -- 是否存单质押（1是 2否）
    `processing_time`,                -- 受理时间：发生日期或者信息变更日期
    `contract_number`,                -- 合同编码
    `cust_deposit_received`,          -- 客户存入保证金
    `cust_deposits_paid`,             -- 客户存出保证金
    `capital_property`,               -- 资本属性(1国有控股 2民营控股 3外资控股)
    `project_end_date`,               -- 项目结束时间 yyyy-MM-dd
    `data_date`,                      -- 数据日期 yyyy-MM-dd
    `push_status`,                    -- 推送状态(0未推送 1推送中 2成功 3失败)
    `revoke_flag`,                    -- 撤销标识（1撤销）
    `project_name`,                   -- 项目名称
    `obs_date`,                       -- 推送日期
    -- `batch_no`,                    -- 推送批次号
    `create_by`,                      -- 创建者
    `update_by`                       -- 更新者
)
WITH loan_balance AS (
    SELECT
        bill_app_no,
        SUM(principal) AS total_principal,
        SUM(CASE
                WHEN act_repay_date IS NOT NULL
                     AND act_repay_date <= to_date('${datadt}','yyyymmdd')
                THEN act_print
                ELSE 0
            END) AS repaid_principal_upto_obs,
        SUM(principal) - SUM(CASE
                                WHEN act_repay_date IS NOT NULL
                                     AND act_repay_date <= to_date('${datadt}','yyyymmdd')
                                THEN act_print
                                ELSE 0
                              END) AS os_principal,
        MAX(CASE
                WHEN act_repay_date IS NOT NULL
                     AND act_repay_date <= to_date('${datadt}','yyyymmdd')
                THEN act_repay_date
            END) AS last_repay_date,  -- 最近一次实还日期（截止观察点）
        SUM(`principal` + `int_amt`) AS `contract_amount`
    FROM `prd_spark_db`.dwd_auto_zf_rent_plan_d
    WHERE `product_no` = 'trzhxh1.0'
  -- AND bill_app_no = 'J_TR_ZHXH_ZHXH_000LI35309022388026425957'
    GROUP BY bill_app_no
),
nearest_term AS (
    SELECT
        t.bill_app_no,
        t.term,
        t.due_date,
        t.act_repay_date,
        t.cpst_date,
        t.is_compensate,
        t.ovd_days,
        ROW_NUMBER() OVER (
            PARTITION BY t.bill_app_no
            ORDER BY t.term DESC
        ) AS rn
    FROM `prd_spark_db`.dwd_auto_zf_rent_plan_d t
    WHERE (t.due_date <= to_date('${datadt}','yyyymmdd') OR t.`act_repay_date` <= to_date('${datadt}','yyyymmdd'))
      AND `product_no` = 'trzhxh1.0'
  -- AND bill_app_no = 'J_TR_ZHXH_ZHXH_000LI35309022388026425957'
)
, status_change AS (
    SELECT
        b.bill_app_no,
        b.contract_amount,
        CASE
            WHEN b.os_principal = 0 THEN '90'  -- 解保（包括提前结清）
            ELSE '60'                          -- 保后监管
        END AS loan_status,

        CASE
            WHEN b.os_principal = 0 THEN b.last_repay_date   -- 解保：最后实还日
            ELSE  daol.loan_day                              -- 保后监管：最近实还日
        END AS raw_event_date,

        ROW_NUMBER() OVER (
            PARTITION BY b.bill_app_no
            ORDER BY n.term DESC
        ) AS rn,

        LAG(
            CASE
                WHEN b.os_principal = 0 THEN '90'
                ELSE '60'
            END
        ) OVER (PARTITION BY b.bill_app_no ORDER BY n.term) AS prev_status,

        LAG(
            CASE
                WHEN b.os_principal = 0 THEN b.last_repay_date
                ELSE daol.loan_day
            END
        ) OVER (PARTITION BY b.bill_app_no ORDER BY n.term) AS prev_event_date

    FROM loan_balance b
    LEFT JOIN nearest_term n ON b.bill_app_no = n.bill_app_no
    JOIN prd_spark_db.`dwd_auto_oapi_loan_d` daol ON b.bill_app_no = daol.`bill_app_no`
)
, t1 AS (
    SELECT
        bill_app_no,
        contract_amount,
        loan_status,
        CASE
            WHEN loan_status != prev_status  OR prev_status IS NULL
                 THEN raw_event_date
            ELSE prev_event_date
        END AS event_date
    FROM status_change
    WHERE rn = 1
  )
, t2 AS (
    SELECT
        daol.id_card AS org_code,
        'TR-ZHXH' AS project_code,
        CASE daol.id_card_type
            WHEN '01' THEN '2'   -- 身份证 → 个人客户
            WHEN '02' THEN '2'   -- 港澳通行证 → 个人客户
            WHEN '03' THEN '2'   -- 其他 → 默认个人客户
            WHEN '04' THEN '1'   -- 统一社会信用代码 → 企业客户
            ELSE NULL
         END AS cust_type,
        dbii.indiv_cust_id AS cust_id,
        dbii.name AS cust_name,
        CASE daol.id_card_type
           WHEN '01' THEN '3'   -- 身份证
           WHEN '02' THEN '5'   -- 港澳通行证归到“其他”
           WHEN '03' THEN '5'   -- 其他
           WHEN '04' THEN '4'   -- 统一社会信用代码
           ELSE NULL            -- 异常值
          END AS cert_type,
        daol.id_card AS cert_number,
        'Y' AS industry_code,
        '个人' AS industry_name,
        '500000' AS user_zone_code,
        '重庆市' AS user_zone_name,
        '6' AS user_scale,
        -- CASE dbii.agri_flag
        --    WHEN '0' THEN '1'
        --    WHEN '1' THEN '2'
        --    ELSE NULL
        --   END AS is_relate_agriculture,
        '2' AS is_relate_agriculture,
        '1008' AS business_type,                                                                    -- 业务类型
        CAST(t1.contract_amount AS DECIMAL(20,2)) AS contract_amount,
        daol.loan_amt AS loan_amount,
        CAST(oaop.year_rate AS DECIMAL(7,5)) AS loan_rate,                                          -- 贷款年利率
        CAST(COALESCE(oaop.per_guarantee_fee_rate, 0.00) AS DECIMAL(7,5)) AS guarantee_sum_rate,    -- 担保综合费率
        daol.loan_day AS loan_date,
        daol.date_due AS contract_end_date,
        '2' AS repayment_type,                                                                      -- 还款方式：按月等额本息
        '5' AS counter_guarantee_measures,                                                          -- 反担保措施-其他
        NULL AS counter_guarantee_measures_memo,                                                    -- 反担保备注-非必填
        '无授信' AS bank_credit_tag,                                                                -- 银行授信记录标识
        t1.loan_status  AS project_status,                                                          -- 项目状态
        NULL AS surety_man,                                                                         -- 担保权人-非必填
        NULL AS counter_guarantee_amount,                                                           -- 反担保物价值-非必填
        NULL  AS is_deposit_pledge,                                                                 -- 存单质押-非必填
        daol.loan_day AS processing_time,                                                           -- 受理时间
        daol.bill_app_no AS contract_number,
        0.00 AS cust_deposit_received,                                                              -- 客户存入保证金
        0.00 AS cust_deposits_paid,                                                                 -- 客户存出保证金
        '4' AS capital_property,                                                                    -- 资本属性
        -- '2031-11-30' AS project_end_date,                                                        -- 项目结束时间（在贷为0）
        CAST(ADD_MONTHS(daol.`loan_day`, daol.total_term) AS DATE) AS project_end_date,             -- 项目结束时间（在贷为0）
        t1.event_date AS data_date,                                                                 -- 数据发生日期
        '0' AS push_status,
        '0' AS revoke_flag,
        '重庆淘然-中恒信合车金融1.0' AS project_name,
        to_date('${datadt}','yyyymmdd') AS obs_date,
        '数仓' AS create_by,
        '数仓' AS update_by
    FROM prd_spark_db.`dwd_auto_oapi_loan_d` daol
      JOIN  prd_spark_db.dim_base_indiv_info dbii ON daol.id_card = dbii.id_card
    LEFT JOIN prd_spark_db.ods_auto_oapi_project_d oaop ON daol.bill_app_no = oaop.bill_app_no
    LEFT JOIN t1 ON daol.bill_app_no = t1.bill_app_no
    WHERE daol.`product_no` = 'trzhxh1.0'
    -- AND `dbii`.`data_source` = '02'
)
SELECT
    `org_code`,                       -- 机构编码
    `project_code`,                   -- 项目编码
    `cust_type`,                      -- 客户类型（1企业客户 2个人客户）
    `cust_id`,                        -- 客户编码
    `cust_name`,                      -- 客户名称
    `cert_type`,                      -- 证件类型（1军官证 2护照 3身份证 4其他）
    `cert_number`,                    -- 证件编码(企业填法人代表对应的证件编码)
    `industry_code`,                  -- 所属行业编码
    `industry_name`,                  -- 所属行业名称
    `user_zone_code`,                 -- 所属区域编码
    `user_zone_name`,                 -- 所属区域名称
    `user_scale`,                     -- 客户规模编码（1大型企业 2中型企业 3小型企业 4微型企业）
    `is_relate_agriculture`,          -- 是否涉农（1是 2否）
    `business_type`,                  -- 业务类型（10 融资性担保业务 1001流动资金贷款担保..）
    `contract_amount`,                -- 合同金额
    `loan_amount`,                    -- 已放款金额
    `loan_rate`,                      -- 贷款年利率，传入2则利率就是 2%
    `guarantee_sum_rate`,             -- 担保综合费率，传入2则利率就是 2%
    `loan_date`,                      -- 放款日期 yyyy-MM-dd
    `contract_end_date`,              -- 合同截止日期 yyyy-MM-dd
    `repayment_type`,                 -- 还款方式(1按月等额本金 2按月等额本息...)
    `counter_guarantee_measures`,     -- 反担保措施(1抵押 2质押 3保证 4信用 5其他)
    `counter_guarantee_measures_memo`,-- 反担保备注
    `bank_credit_tag`,                -- 银行授信记录标识
    `project_status`,                 -- 项目状态(60保后监管 70项目逾期...)
    `surety_man`,                     -- 担保人，债权人
    `counter_guarantee_amount`,       -- 反担保物总价值
    `is_deposit_pledge`,              -- 是否存单质押（1是 2否）
    `processing_time`,                -- 受理时间：发生日期或者信息变更日期
    `contract_number`,                -- 合同编码
    `cust_deposit_received`,          -- 客户存入保证金
    `cust_deposits_paid`,             -- 客户存出保证金
    `capital_property`,               -- 资本属性(1国有控股 2民营控股 3外资控股)
    `project_end_date`,               -- 项目结束时间 yyyy-MM-dd
    `data_date`,                      -- 数据日期 yyyy-MM-dd
    `push_status`,                    -- 推送状态(0未推送 1推送中 2成功 3失败)
    `revoke_flag`,                    -- 撤销标识（1撤销）
    `project_name`,                   -- 项目名称
    `obs_date`,                       -- 推送日期
    -- `batch_no`,                    -- 推送批次号
    `create_by`,                      -- 创建者
    `update_by`                       -- 更新者
  FROM t2
WHERE data_date = to_date('${datadt}','yyyymmdd')
  ;
