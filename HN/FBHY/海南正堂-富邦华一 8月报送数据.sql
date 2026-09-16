/* 
INSERT INTO test_zxbs_db.ads_hain_g11_cust_info
(
    dbank_id,
    ddate,
    xh,
    cust_id,
    cust_name,
    biz_body,
    cust_type,
    hold_type,
    cert_type,
    cert_no,
    region,
    industry,
    ent_scale,
    emp_num,
    annual_inc,
    asset_tot,
    credit_rate,
    agri_flag,
    farmer_flag,
    new_agri_flag,
    dual_innov_flag,
    grp_uscc,
    create_time,
    update_time
)
VALUES
(
    'DEFAULT_BANK',          -- dbank_id 机构代码，和脚本保持一致
    '2026-08-31',            -- ddate 报表日期，7月月报取当月最后一天
    1,                       -- xh 序号，手动插入填1
    'FTBHY001',              -- cust_id客户编号，手动虚构唯一客户ID
    '富邦华一银行有限公司',  -- cust_name客户名称
    '富邦华一银行有限公司',  -- biz_body经营主体
    'D01',                   -- cust_type客户类型：D01‑银行业存款类金融机构
    'D',                     -- hold_type控股类型：D‑港澳台商控股企业
    'B01',                   -- cert_type证件类型：B01‑统一社会信用代码
    '913100006073684694',    -- cert_no证件号码 统一社会信用代码
    '310000',                -- region所在地区 310000‑上海
    'J66',                   -- industry所属行业 J66‑货币金融服务
    'A',                     -- ent_scale企业规模 A‑大型企业
    NULL,                    -- emp_num从业人员，无数据
    NULL,                    -- annual_inc年营业收入，无数据
    NULL,                    -- asset_tot资产总额，无数据
    NULL,                    -- credit_rate主体信用评级，无数据
    'N',                     -- agri_flag “三农”主体标志：否
    'N',                     -- farmer_flag 农户标志：否
    'N',                     -- new_agri_flag 新型农业主体标志：否
    'N',                     -- dual_innov_flag 双创双服主体标志：否
    NULL,                    -- grp_uscc所属集团统一社会信用代码
    CURRENT_TIMESTAMP,       -- create_time
    CURRENT_TIMESTAMP        -- update_time
);

 */

INSERT INTO test_zxbs_db.ads_hain_g23_detail
(
    dbank_id,
    ddate,
    project_name,
    loan_date,
    cont_no,
    biz_no,
    cust_id,
    cust_name,
    guar_type,
    biz_mode,
    guar_amt,
    loan_rate,
    guar_rate,
    guar_start,
    guar_end,
    mgr_contact,
    policy_flag,
    strategic_flag,
    first_loan_flag,
    fin_inst_code,
    fin_inst_name,
    cust_mgr,
    cust_mgr_tel,
    orig_guar_inst,
    orig_guar_amt,
    orig_guar_rate,
    od_flag,
    uncomp_amt,
    loss_amt,
    five_class,
    counter_type,
    counter_code,
    counter_name,
    counter_amt,
    rely_net_flag,
    create_time,
    update_time
)
VALUES
(
    'DEFAULT_BANK',                -- dbank_id 机构代码，和加工脚本统一
    '2026-08-31',                  -- ddate 报表日期，7月月报月末
    '海南正堂-富邦华一',           -- project_name 项目名称
    '2026-08-01',                  -- loan_date 放款日期，取担保起始日
    'HT-FTBHY-202608001',          -- cont_no 合同编号【主键，务必唯一，冲突就换号】
    'HT-FTBHY-202608001',          -- biz_no 业务编号，脚本逻辑：同cont_no
    'FTBHY001',                    -- cust_id 和G11插入的客户编号严格对应
    '富邦华一银行有限公司',        -- cust_name客户名称
    'A0101',                       -- guar_type 担保类型，和脚本默认A0101
    'A',                           -- biz_mode 业务开展方式，脚本默认A
    25634201.87,                   -- guar_amt 担保金额
    NULL,                          -- loan_rate 贷款利率无数据
    0.002000,                      -- guar_rate 担保费率，脚本默认兜底0.2
    '2026-08-01',                  -- guar_start 担保起始日期
    '2027-08-01',                  -- guar_end 担保到期日期
    '何书诺17689893638',           -- mgr_contact 项目经理联系方式，和脚本统一
    'N',                           -- policy_flag 是否政策性担保业务
    'N',                           -- strategic_flag 是否战略新兴产业
    'N',                           -- first_loan_flag 是否首贷户
    NULL,                          -- fin_inst_code 金融机构编码
    NULL,                          -- fin_inst_name 金融机构名称
    NULL,                          -- cust_mgr 经办客户经理
    NULL,                          -- cust_mgr_tel 客户经理联系方式
    NULL,                          -- orig_guar_inst 原担保机构
    NULL,                          -- orig_guar_amt 原担保金额
    NULL,                          -- orig_guar_rate 原担保费率
    'N',                           -- od_flag 是否逾期，脚本默认N
    NULL,                          -- uncomp_amt 尚未履行代偿责任金额
    NULL,                          -- loss_amt 损失金额
    NULL,                          -- five_class 五级分类
    NULL,                          -- counter_type 反担保方式
    NULL,                          -- counter_code 反担保人编码
    NULL,                          -- counter_name 反担保人名称
    NULL,                          -- counter_amt 反担保金额
    'Y',                           -- rely_net_flag 是否依托互联网，脚本默认Y
    CURRENT_TIMESTAMP,             -- create_time
    CURRENT_TIMESTAMP              -- update_time
);




INSERT INTO test_zxbs_db.ads_hain_g23_1_risk_share
(
    dbank_id,
    ddate,
    xh,
    cont_no,
    biz_no,
    project_name,
    org_ratio,
    natl_fund_ratio,
    prov_fund_ratio,
    prov_gov_ratio,
    prov_comp_ratio,
    city_fund_ratio,
    city_gov_ratio,
    city_comp_ratio,
    county_gov_ratio,
    county_comp_ratio,
    pbank_ratio,
    big4_ratio,
    joint_stock_ratio,
    city_bank_ratio,
    rural_fin_ratio,
    ins_ratio,
    other_ratio,
    total_ratio,
    create_time,
    update_time
)
VALUES
(
    'DEFAULT_BANK',                -- dbank_id 机构代码，和加工脚本保持一致
    '2026-08-31',                  -- ddate 报表日期，和G23保持7月月报月末
    1,                             -- xh 序号
    'HT-FTBHY-202608001',          -- cont_no 【必须和G23_detail的cont_no完全一致，联合主键】
    'HT-FTBHY-202608001',          -- biz_no 业务编号，同G23
    '海南正堂-富邦华一',           -- project_name 项目名称
    1.000000,                      -- org_ratio 机构自身风险承担比例，脚本默认1（100%自担）
    0.000000,                      -- natl_fund_ratio 国家级担保基金
    0.000000,                      -- prov_fund_ratio 省级担保基金
    0.000000,                      -- prov_gov_ratio 省级人民政府
    0.000000,                      -- prov_comp_ratio 省级融资担保公司
    0.000000,                      -- city_fund_ratio 市级担保基金
    0.000000,                      -- city_gov_ratio 市级人民政府
    0.000000,                      -- city_comp_ratio 市级融资担保公司
    0.000000,                      -- county_gov_ratio 县级人民政府
    0.000000,                      -- county_comp_ratio 县级融资担保公司
    0.000000,                      -- pbank_ratio 国开及政策性银行
    0.000000,                      -- big4_ratio 四大国有行
    0.000000,                      -- joint_stock_ratio 股份制银行
    0.000000,                      -- city_bank_ratio 城商行
    0.000000,                      -- rural_fin_ratio 农村合作金融机构
    0.000000,                      -- ins_ratio 保险公司
    0.000000,                      -- other_ratio 其他机构
    1.000000,                      -- total_ratio 合计比例，和脚本逻辑总和=1
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);



INSERT INTO test_zxbs_db.ads_hain_g27_comp_detail
(
    xh,
    dbank_id,
    ddate,
    cont_no,
    biz_no,
    project_name,
    comp_type,
    comp_seq,
    comp_date,
    comp_amt,
    comp_int,
    create_time,
    update_time
)
VALUES
(
    1,                              -- xh 序号
    'DEFAULT_BANK',                 -- dbank_id 和加工脚本保持一致
    '2026-08-31',                   -- ddate 报表日期7月月末
    'HT-FTBHY-202608001',           -- cont_no 必须和G23_detail完全一致
    'HT-FTBHY-202608001',           -- biz_no 业务编号
    '海南正堂-富邦华一',            -- project_name项目名称
    'A',                            -- comp_type 代偿类型，脚本写死A
    'COMP-FTBHY-20260831001',       -- comp_seq 代偿流水号，唯一，冲突就换
    '2026-08-31',                   -- comp_date 实际代偿日期
    15519422.73,                     -- comp_amt 代偿本金
    0.00,                           -- comp_int 代偿利息，无数据填0
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);


REPLACE INTO test_zxbs_db.ads_hain_g28_recover_detail
(
    dbank_id,
    ddate,
    xh,
    project_name,
    cont_no,
    biz_no,
    recv_seq,
    recv_date,
    recv_amt,
    create_time,
    update_time
)
VALUES
(
    'DEFAULT_BANK',                 -- dbank_id
    '2026-08-31',                   -- ddate 7月月报
    1,                              -- xh 序号
    '海南正堂-富邦华一',            -- project_name
    'HT-FTBHY-202608001',           -- cont_no 和G23/G27保持一致
    'HT-FTBHY-202608001',           -- biz_no
    'COMP-FTBHY-20260831001',       -- recv_seq 复用G27的comp_seq
    '2026-08-31',                   -- recv_date 代偿日期+1天，对齐源脚本case逻辑
    15519422.73,                     -- recv_amt 代偿总金额（本金+利息）
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);