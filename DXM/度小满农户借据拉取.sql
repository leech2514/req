select sum(a.loan_amt) from (

 SELECT *
 FROM apply_base_info abi
 WHERE
     (abi.id_address LIKE '%乡%' OR abi.id_address LIKE '%村%' OR abi.id_address LIKE '%组%' OR abi.id_address LIKE '%号%'
         OR abi.id_address LIKE '%庄%' OR abi.id_address LIKE '%屯%' OR abi.id_address LIKE '%寨%' )

   AND abi.id_address NOT LIKE '%社区%' AND abi.id_address NOT LIKE '%小区%' AND abi.id_address NOT LIKE '%广场%'
   AND abi.id_address NOT LIKE '%单元%' AND abi.id_address NOT LIKE '%层%' AND abi.id_address NOT LIKE '%室%'
   AND abi.id_address NOT LIKE '%公司%' AND abi.id_address NOT LIKE '%大厦%'
   AND abi.id_address NOT LIKE '%栋%' AND abi.id_address NOT LIKE '%座%'
   AND abi.id_address NOT LIKE '%幢%' AND abi.id_address NOT LIKE '%宿舍%'
   AND abi.id_address NOT LIKE '%大院%' AND abi.id_address NOT LIKE '%巷%'
   AND abi.id_address NOT LIKE '%号%号%' AND abi.id_address NOT LIKE '%路%号%'
   AND abi.id_address NOT LIKE '%厂%号%' AND abi.id_address NOT LIKE '%号%院%'
   AND abi.id_address NOT LIKE '%号%房%' AND abi.id_address NOT LIKE '%号%楼%'
   AND abi.id_address NOT LIKE '%楼%门%' AND abi.id_address NOT LIKE '%新区%'
   AND abi.id_address NOT LIKE '%机关%' AND abi.id_address NOT LIKE '%家属院%'
   AND abi.id_address NOT LIKE '%非农%' AND abi.id_address NOT LIKE '%街%里%号%'
   AND abi.id_address NOT LIKE '%街_号%' AND abi.id_address NOT LIKE '%街__号%' AND abi.id_address NOT LIKE '%街___号%'
   AND abi.id_address NOT LIKE '%路_号%' AND abi.id_address NOT LIKE '%路__号%' AND abi.id_address NOT LIKE '%路___号%'
   AND abi.id_address NOT LIKE '%宫%号%'
   AND abi.id_address NOT LIKE '%海南%'AND abi.id_address NOT LIKE '%新疆%'AND abi.id_address NOT LIKE '%西藏%' AND abi.id_address NOT LIKE '%安徽%'AND abi.id_address NOT LIKE '%吉林%'
   and abi.id_address is not null
   AND abi.id_card NOT LIKE '46%'AND abi.id_card NOT LIKE '65%'AND abi.id_card NOT LIKE '54%' AND abi.id_card NOT LIKE '34%'AND abi.id_card NOT LIKE '22%'
   AND abi.product_no IN (
#中保
		'ZBJTTHIRD_XA3',
		'ZBJKZB-JKMDZL01',
		'ZBTCTC_TQY',
		'ZBSY202401',
		'ZBJRYZB-JRY-01',
		'ZBJZ11',
		'JTFBB',
		'JTBBWB',
		'GM5551',
		'GMNJBK5551',
		'GMZSBK5551',
		'ZBLXJKYQ1',
		'WDCASH',
		'WDCONSUME',
		'ZBHYBBYXJ001',
		'ZBQMZB-QMQB-WPXJzbqmwp',
		'ZBQSRLzbqslh001',
		'ZB-CA-BY00-2509',
		'ZBJZZB-JZ-LZ00-2508',
		'ZBJZZB-JZ-ZX00-2508',
		'ZB-WC-JMXBANK',
		#樽昊
		'ZHHXPDI0781',
		'HNGSWDCONSUME',
		'HNGSWDCASH',
		'ZH-HC-WDPDI0781',
		'ZHWACPDI0791',
		'ZHWACX201701268',
		'GSJZZH-JZ&RL-CYXJ216',
		'GSJZZH-JZ-XMXJxm_010',
		'ZHLXJKYQ',
		'ZHLXZH-LX-XMXJJKYQ2',
		'ZHZSZH-ZSWL-THBLZH-ZSWL-TH',
		'ZHZSZH-ZSWL-THBLZH-ZSWL-TH-ZFX',
		'ZHLHPPDI0791',
		'ZHLHPX201701268',
		'GSJZ09',
		'ZHDDZZRzh-dd-zzr-fm',
		'ZHDDZZRzh-dd-zzr-fmF01',
		'ZHWXKJQJLZ',
		'ZHKNchangyin_zunhao',
		'ZH-WC-DXMPDI1031',
		'GSJZZH-JZ-YGXJzhjzyg',
		'GSJZ08',
		'ZHFLzhflzyxj-api',
		'ZHJRY3200010275852453',
		'ZHKNJXchangyin_zunhao_jxqh',
		'ZHYTXQJzhytxlzbk',
		'ZHJKzhjkklbk',
		'ZHQMQJqmzhlzbkqj',
		'ZHBQXWZD001',
		'ZH-WC-ZY00-2509',
		'zhqmzaxm',
		'ZH-LHP-ZY00-2509',
		#富宸
		'FCXFxyf_zyzkfc_dd',
		'FCJK01',
		'FCJK00',
		'FCLXXJ_ZY_FC',
		'FCJKFC-JK-ZXXJ01',
		'FCJKFC-JK-ZXXJstzf01',
		'FCDFSRLFCDFSCYXJ',
		'FCDFSRL_CYCFC_FL',
		'FCFLRLfcflrlcyxj',
		'FCQMqmfcms',
		'FCMGFC-MG-ZB00-2509',
		'FC-QS-CY00-2510',
		'FC-FL-MS00-2510',
		#鼎丰
		'DFWDCASH',
		'DFJZ10',
		'DFLXXJ_ZY_DF',
		'DFLXXJ_ZY_DF3',
		'DFLXDF-LX-ZYXJ-NBTSJKYQ2',
		'DFJRY3200010275851324',
		'DFFLdffllsbk',
		'DFWXddq',
		'DFWXkkd',
		#正堂
		'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
		'ZTDFSRL_CYCFC_FL_2',
		'ZTKNchangyin_zhengtang',
		'ZTQSZT-QS-CY102507',
		'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509',
		'ZTQMRLztqmrlqd',
		'ZT-360-ZA01-2508',
		'ZTJHZT-JH-ZY00-2508',
		#昌泰
		'CTDFSCT-DFS-DHBLct-dfs-dhbl',
		'CTDFSCT-DFS-JTBLCT-DFS-THJT',
		'CTDFSCT-DFS-TH',
		#大有
		'DYDFSDY-DFS-DYGM',
		'DYFQLdydfsfm',
		'DYYTX360dyytxfm-360',
		'DY-RL-CY02-2508',
		'DY-RL-CY00-2508'


     ) order by id limit 374000,11000) a left join ln_loan_info b on a.apply_no=b.apply_no where b.id is not null;

select  a.* from (
SELECT recon_date, apply_no, name, id_card, id_card_type, id_address, id_expiry_date, mobile, gender, educational, address_time, address, detail_address, house_condition, car_condition, annual_income, is_pay_security, debts, often_email, marry_status, has_children, salary_date, industry, unit_name, unit_address, unit_detail_address, unit_telphone, contact_a_ref, contact_a_name, contact_a_mobile, contact_b_ref, contact_b_name, contact_b_mobile, work_years, apply_ref, is_common_apply, ent_name, ent_id, ent_create_date, legal_name, industry_code, industry_divide, ent_type, area_name, registration_authority, person_number, registered_address, business_scope, contact_c_name, contact_c_ref, contact_c_mobile, last_year_begin_total_assets, last_year_begin_total_liabilities, last_year_end_total_assets, last_year_end_total_liabilities, last_year_annual_income, is_tree_year_tax_penalty, litigation_amt, is_enforcement, is_dishonesty, is_high_consumption, is_business_abnormal, is_stock_equity_freeze, is_administrative_penalty, account_name, card_no, pre_mobile, partner_no, loan_use, loan_amt, loan_period, face_merchants, facce_supply_param, face_card_compare, product_no, product_name, apply_time, loan_title, apply_status, guarantee_type, buis_mode, rev_guarantee_type, guarantee_scope, cfund_channel_no, cfund_channel_name, pay_way, repay_way, year_rate, service_rate, guarantee_rate, margin_rate, compensate_rate, act_year_rate, period_service_rate, period_guarantee_rate, period_margin_rate, period_compensate_rate, oint_rate, oguarantee_rate, define_rate, adv_define_rate, compensate_days, grace_day, interest_free_period, create_time, credit_no, credit_apply_no
FROM apply_base_info abi
WHERE
    (abi.id_address LIKE '%乡%' OR abi.id_address LIKE '%村%' OR abi.id_address LIKE '%组%' OR abi.id_address LIKE '%号%'
        OR abi.id_address LIKE '%庄%' OR abi.id_address LIKE '%屯%' OR abi.id_address LIKE '%寨%' )

  AND abi.id_address NOT LIKE '%社区%' AND abi.id_address NOT LIKE '%小区%' AND abi.id_address NOT LIKE '%广场%'
  AND abi.id_address NOT LIKE '%单元%' AND abi.id_address NOT LIKE '%层%' AND abi.id_address NOT LIKE '%室%'
  AND abi.id_address NOT LIKE '%公司%' AND abi.id_address NOT LIKE '%大厦%'
  AND abi.id_address NOT LIKE '%栋%' AND abi.id_address NOT LIKE '%座%'
  AND abi.id_address NOT LIKE '%幢%' AND abi.id_address NOT LIKE '%宿舍%'
  AND abi.id_address NOT LIKE '%大院%' AND abi.id_address NOT LIKE '%巷%'
  AND abi.id_address NOT LIKE '%号%号%' AND abi.id_address NOT LIKE '%路%号%'
  AND abi.id_address NOT LIKE '%厂%号%' AND abi.id_address NOT LIKE '%号%院%'
  AND abi.id_address NOT LIKE '%号%房%' AND abi.id_address NOT LIKE '%号%楼%'
  AND abi.id_address NOT LIKE '%楼%门%' AND abi.id_address NOT LIKE '%新区%'
  AND abi.id_address NOT LIKE '%机关%' AND abi.id_address NOT LIKE '%家属院%'
  AND abi.id_address NOT LIKE '%非农%' AND abi.id_address NOT LIKE '%街%里%号%'
  AND abi.id_address NOT LIKE '%街_号%' AND abi.id_address NOT LIKE '%街__号%' AND abi.id_address NOT LIKE '%街___号%'
  AND abi.id_address NOT LIKE '%路_号%' AND abi.id_address NOT LIKE '%路__号%' AND abi.id_address NOT LIKE '%路___号%'
  AND abi.id_address NOT LIKE '%宫%号%'
  AND abi.id_address NOT LIKE '%海南%'AND abi.id_address NOT LIKE '%新疆%'AND abi.id_address NOT LIKE '%西藏%' AND abi.id_address NOT LIKE '%安徽%'AND abi.id_address NOT LIKE '%吉林%'
  and abi.id_address is not null
  AND abi.id_card NOT LIKE '46%'AND abi.id_card NOT LIKE '65%'AND abi.id_card NOT LIKE '54%' AND abi.id_card NOT LIKE '34%'AND abi.id_card NOT LIKE '22%'
  AND abi.product_no IN (
 #中保
		'ZBJTTHIRD_XA3',
		'ZBJKZB-JKMDZL01',
		'ZBTCTC_TQY',
		'ZBSY202401',
		'ZBJRYZB-JRY-01',
		'ZBJZ11',
		'JTFBB',
		'JTBBWB',
		'GM5551',
		'GMNJBK5551',
		'GMZSBK5551',
		'ZBLXJKYQ1',
		'WDCASH',
		'WDCONSUME',
		'ZBHYBBYXJ001',
		'ZBQMZB-QMQB-WPXJzbqmwp',
		'ZBQSRLzbqslh001',
		'ZB-CA-BY00-2509',
		'ZBJZZB-JZ-LZ00-2508',
		'ZBJZZB-JZ-ZX00-2508',
		'ZB-WC-JMXBANK',
		#樽昊
		'ZHHXPDI0781',
		'HNGSWDCONSUME',
		'HNGSWDCASH',
		'ZH-HC-WDPDI0781',
		'ZHWACPDI0791',
		'ZHWACX201701268',
		'GSJZZH-JZ&RL-CYXJ216',
		'GSJZZH-JZ-XMXJxm_010',
		'ZHLXJKYQ',
		'ZHLXZH-LX-XMXJJKYQ2',
		'ZHZSZH-ZSWL-THBLZH-ZSWL-TH',
		'ZHZSZH-ZSWL-THBLZH-ZSWL-TH-ZFX',
		'ZHLHPPDI0791',
		'ZHLHPX201701268',
		'GSJZ09',
		'ZHDDZZRzh-dd-zzr-fm',
		'ZHDDZZRzh-dd-zzr-fmF01',
		'ZHWXKJQJLZ',
		'ZHKNchangyin_zunhao',
		'ZH-WC-DXMPDI1031',
		'GSJZZH-JZ-YGXJzhjzyg',
		'GSJZ08',
		'ZHFLzhflzyxj-api',
		'ZHJRY3200010275852453',
		'ZHKNJXchangyin_zunhao_jxqh',
		'ZHYTXQJzhytxlzbk',
		'ZHJKzhjkklbk',
		'ZHQMQJqmzhlzbkqj',
		'ZHBQXWZD001',
		'ZH-WC-ZY00-2509',
		'zhqmzaxm',
		'ZH-LHP-ZY00-2509',
		#富宸
		'FCXFxyf_zyzkfc_dd',
		'FCJK01',
		'FCJK00',
		'FCLXXJ_ZY_FC',
		'FCJKFC-JK-ZXXJ01',
		'FCJKFC-JK-ZXXJstzf01',
		'FCDFSRLFCDFSCYXJ',
		'FCDFSRL_CYCFC_FL',
		'FCFLRLfcflrlcyxj',
		'FCQMqmfcms',
		'FCMGFC-MG-ZB00-2509',
		'FC-QS-CY00-2510',
		'FC-FL-MS00-2510',
		#鼎丰
		'DFWDCASH',
		'DFJZ10',
		'DFLXXJ_ZY_DF',
		'DFLXXJ_ZY_DF3',
		'DFLXDF-LX-ZYXJ-NBTSJKYQ2',
		'DFJRY3200010275851324',
		'DFFLdffllsbk',
		'DFWXddq',
		'DFWXkkd',
		#正堂
		'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
		'ZTDFSRL_CYCFC_FL_2',
		'ZTKNchangyin_zhengtang',
		'ZTQSZT-QS-CY102507',
		'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509',
		'ZTQMRLztqmrlqd',
		'ZT-360-ZA01-2508',
		'ZTJHZT-JH-ZY00-2508',
		#昌泰
		'CTDFSCT-DFS-DHBLct-dfs-dhbl',
		'CTDFSCT-DFS-JTBLCT-DFS-THJT',
		'CTDFSCT-DFS-TH',
		#大有
		'DYDFSDY-DFS-DYGM',
		'DYFQLdydfsfm',
		'DYYTX360dyytxfm-360',
		'DY-RL-CY02-2508',
		'DY-RL-CY00-2508'
    ) order by id limit 374000,11000)a left join ln_loan_info b on a.apply_no=b.apply_no where b.id is not null;;

select recon_date, product_no, b.apply_no, loan_req_no, loan_time, due_date, name, id_card_type, id_card, contract_amt, loan_amt, service_amt, guarantee_amt, margin_amt, compensate_amt, act_service_amt, act_guarantee_amt, act_margin_amt, act_compensate_amt, repay_day, total_term, loan_status, remark, loan_month, lend_status, create_time, update_time from (

SELECT  apply_no FROM apply_base_info abi
WHERE
    (abi.id_address LIKE '%乡%' OR abi.id_address LIKE '%村%' OR abi.id_address LIKE '%组%' OR abi.id_address LIKE '%号%'
        OR abi.id_address LIKE '%庄%' OR abi.id_address LIKE '%屯%' OR abi.id_address LIKE '%寨%' )

  AND abi.id_address NOT LIKE '%社区%' AND abi.id_address NOT LIKE '%小区%' AND abi.id_address NOT LIKE '%广场%'
  AND abi.id_address NOT LIKE '%单元%' AND abi.id_address NOT LIKE '%层%' AND abi.id_address NOT LIKE '%室%'
  AND abi.id_address NOT LIKE '%公司%' AND abi.id_address NOT LIKE '%大厦%'
  AND abi.id_address NOT LIKE '%栋%' AND abi.id_address NOT LIKE '%座%'
  AND abi.id_address NOT LIKE '%幢%' AND abi.id_address NOT LIKE '%宿舍%'
  AND abi.id_address NOT LIKE '%大院%' AND abi.id_address NOT LIKE '%巷%'
  AND abi.id_address NOT LIKE '%号%号%' AND abi.id_address NOT LIKE '%路%号%'
  AND abi.id_address NOT LIKE '%厂%号%' AND abi.id_address NOT LIKE '%号%院%'
  AND abi.id_address NOT LIKE '%号%房%' AND abi.id_address NOT LIKE '%号%楼%'
  AND abi.id_address NOT LIKE '%楼%门%' AND abi.id_address NOT LIKE '%新区%'
  AND abi.id_address NOT LIKE '%机关%' AND abi.id_address NOT LIKE '%家属院%'
  AND abi.id_address NOT LIKE '%非农%' AND abi.id_address NOT LIKE '%街%里%号%'
  AND abi.id_address NOT LIKE '%街_号%' AND abi.id_address NOT LIKE '%街__号%' AND abi.id_address NOT LIKE '%街___号%'
  AND abi.id_address NOT LIKE '%路_号%' AND abi.id_address NOT LIKE '%路__号%' AND abi.id_address NOT LIKE '%路___号%'
  AND abi.id_address NOT LIKE '%宫%号%'
  AND abi.id_address NOT LIKE '%海南%'AND abi.id_address NOT LIKE '%新疆%'AND abi.id_address NOT LIKE '%西藏%' AND abi.id_address NOT LIKE '%安徽%'AND abi.id_address NOT LIKE '%吉林%'
  and abi.id_address is not null
  AND abi.id_card NOT LIKE '46%'AND abi.id_card NOT LIKE '65%'AND abi.id_card NOT LIKE '54%' AND abi.id_card NOT LIKE '34%'AND abi.id_card NOT LIKE '22%'
  AND abi.product_no IN (
#中保
		'ZBJTTHIRD_XA3',
		'ZBJKZB-JKMDZL01',
		'ZBTCTC_TQY',
		'ZBSY202401',
		'ZBJRYZB-JRY-01',
		'ZBJZ11',
		'JTFBB',
		'JTBBWB',
		'GM5551',
		'GMNJBK5551',
		'GMZSBK5551',
		'ZBLXJKYQ1',
		'WDCASH',
		'WDCONSUME',
		'ZBHYBBYXJ001',
		'ZBQMZB-QMQB-WPXJzbqmwp',
		'ZBQSRLzbqslh001',
		'ZB-CA-BY00-2509',
		'ZBJZZB-JZ-LZ00-2508',
		'ZBJZZB-JZ-ZX00-2508',
		'ZB-WC-JMXBANK',
		#樽昊
		'ZHHXPDI0781',
		'HNGSWDCONSUME',
		'HNGSWDCASH',
		'ZH-HC-WDPDI0781',
		'ZHWACPDI0791',
		'ZHWACX201701268',
		'GSJZZH-JZ&RL-CYXJ216',
		'GSJZZH-JZ-XMXJxm_010',
		'ZHLXJKYQ',
		'ZHLXZH-LX-XMXJJKYQ2',
		'ZHZSZH-ZSWL-THBLZH-ZSWL-TH',
		'ZHZSZH-ZSWL-THBLZH-ZSWL-TH-ZFX',
		'ZHLHPPDI0791',
		'ZHLHPX201701268',
		'GSJZ09',
		'ZHDDZZRzh-dd-zzr-fm',
		'ZHDDZZRzh-dd-zzr-fmF01',
		'ZHWXKJQJLZ',
		'ZHKNchangyin_zunhao',
		'ZH-WC-DXMPDI1031',
		'GSJZZH-JZ-YGXJzhjzyg',
		'GSJZ08',
		'ZHFLzhflzyxj-api',
		'ZHJRY3200010275852453',
		'ZHKNJXchangyin_zunhao_jxqh',
		'ZHYTXQJzhytxlzbk',
		'ZHJKzhjkklbk',
		'ZHQMQJqmzhlzbkqj',
		'ZHBQXWZD001',
		'ZH-WC-ZY00-2509',
		'zhqmzaxm',
		'ZH-LHP-ZY00-2509',
		#富宸
		'FCXFxyf_zyzkfc_dd',
		'FCJK01',
		'FCJK00',
		'FCLXXJ_ZY_FC',
		'FCJKFC-JK-ZXXJ01',
		'FCJKFC-JK-ZXXJstzf01',
		'FCDFSRLFCDFSCYXJ',
		'FCDFSRL_CYCFC_FL',
		'FCFLRLfcflrlcyxj',
		'FCQMqmfcms',
		'FCMGFC-MG-ZB00-2509',
		'FC-QS-CY00-2510',
		'FC-FL-MS00-2510',
		#鼎丰
		'DFWDCASH',
		'DFJZ10',
		'DFLXXJ_ZY_DF',
		'DFLXXJ_ZY_DF3',
		'DFLXDF-LX-ZYXJ-NBTSJKYQ2',
		'DFJRY3200010275851324',
		'DFFLdffllsbk',
		'DFWXddq',
		'DFWXkkd',
		#正堂
		'HNZT-JZ-ZZRhnzt-jz-zyxj-zgcbk',
		'ZTDFSRL_CYCFC_FL_2',
		'ZTKNchangyin_zhengtang',
		'ZTQSZT-QS-CY102507',
		'ZTJHZT-JH-ZYQDZT-JH-ZYQD00-2509',
		'ZTQMRLztqmrlqd',
		'ZT-360-ZA01-2508',
		'ZTJHZT-JH-ZY00-2508',
		#昌泰
		'CTDFSCT-DFS-DHBLct-dfs-dhbl',
		'CTDFSCT-DFS-JTBLCT-DFS-THJT',
		'CTDFSCT-DFS-TH',
		#大有
		'DYDFSDY-DFS-DYGM',
		'DYFQLdydfsfm',
		'DYYTX360dyytxfm-360',
		'DY-RL-CY02-2508',
		'DY-RL-CY00-2508'
    ) order by id limit 374000,11000)a left join ln_loan_info b on a.apply_no=b.apply_no where b.id is not null ;


select sum(loan_amt)
from apply_base_info where apply_no like 'DXM%';
select sum(loan_amt)
from ln_loan_info where apply_no like 'DXM%';
select sum(print)计划 from ln_plan_info where apply_no like 'DXM%';
select sum(print) from ln_repay_info where apply_no like 'DXM%';


select sum(print)计划 from ln_plan_info where apply_no like 'DXM%'  and  act_repay_date >= '2026-04-01' and act_repay_date <= '2026-04-30' and status = 'NOR';


select sum(print)计划 from ln_plan_info where apply_no like 'DXM%'  and  repay_date >= '2026-05-01' and repay_date <= '2026-05-31' and status = 'NOR';

select sum(print) from ln_repay_info where apply_no like 'DXM%' and recon_date >= '2025-03-01' and recon_date <= '2025-03-31';


select sum(print)计划 from ln_plan_info where apply_no like 'CTDXM%'  and  repay_date >= '2025-07-01' and repay_date <= '2025-07-31' and status = 'NOR';


