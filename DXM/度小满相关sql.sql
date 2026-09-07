#正堂-度小满  修改进件放款 sql 流程

#1.确认导出的数据借据号与ID是否一致
select * from apply_base_info a left join ln_loan_info b on a.id = b.id where a.apply_no != b.apply_no;
#2.修改产品编码
update ln_loan_info set product_no ='DXM' WHERE 1=1;

update apply_base_info set product_no ='DXM' WHERE 1=1;

#3.修改进件信息的基础信息
update apply_base_info set partner_no = 'DXM',product_no= 'DXM',product_name = '度小满',apply_time=recon_date,apply_status = '01',cfund_channel_no='ZT-DMX-NBTS',cfund_channel_name='正堂-度小满-宁波通商', repay_way='01',year_rate='0.24'
                         ,compensate_days=0,grace_day=0,interest_free_period=0,loan_use='07';

#4.修改对账日期
update apply_base_info set recon_date =STR_TO_DATE(CONCAT('2026-05-', if(DAY(recon_date)>31,31,DAY(recon_date))), '%Y-%m-%d');

-- 修改对账日期--随机日期
UPDATE apply_base_info
SET recon_date = DATE_ADD('2026-05-01', INTERVAL FLOOR(RAND() * 31) DAY);

#5.生成借据号
update apply_base_info set apply_no =concat('DXM',recon_date,'_',LPAD(ID, 8, '0')) ,apply_time =recon_date ;

#6.根据进件信息修改放款信息的对账日期和借据号
update ln_loan_info a  left join apply_base_info b  on a.id=b.id set a.recon_date =b.recon_date,a.apply_no=b.apply_no;


#7.修改放款信息的进本信息
update ln_loan_info set loan_time = recon_date,total_term = 12,loan_month =date_format(recon_date,'%Y-%m'),loan_status='NOR',loan_req_no=apply_no,product_no ='DXM';

#8.修改放款信息的到期日
update ln_loan_info  set due_date = date_add(recon_date,INTERVAL total_term MONTH);

#9.校验是否有修改错误或不匹配的数据
select * from apply_base_info a left join ln_loan_info b on a.id = b.id where a.apply_no != b.apply_no or a.recon_date !=b.recon_date or a.loan_amt !=b.loan_amt;

select * from apply_base_info a left join ln_loan_info b on a.id = b.id where a.id_card != b.id_card;

select sum(loan_amt),count(0) from apply_base_info ;

select sum(loan_amt),count(0) from ln_loan_info;

select sum(print) from ln_plan_info;

select a.recon_date 对账日期,substr(a.apply_no,5) 截取借据号,a.apply_no 借款申请编号,a.loan_amt '进件信息-借款金额',b.contract_amt '放款信息-合同金额',b.loan_amt '放款信息-放款金额',c.act_print '还款计划所有应还本金之和',d.act_print
from (
         (select *
          from apply_base_info ) a left join ln_loan_info b on a.apply_no = b.apply_no left join (select sum(print)act_print,apply_no from  ln_plan_info group by apply_no)c
             on a.apply_no = c.apply_no left join (select sum(print)act_print,apply_no from  ln_repay_info group by apply_no)d on a.apply_no = d.apply_no)
where  a.loan_amt != b.loan_amt or a.loan_amt != c.act_print or b.loan_amt  != c.act_print or c.apply_no is null group by a.recon_date;

# 10. 查询生成数据月应还的本金
    #83961657.28
    select  sum(print) from ln_plan_info where repay_date >= '2026-05-01' and repay_date <= '2026-05-31' and status ='NOR';
    #83961657.28
    select  sum(print),count(0) from ln_repay_info where id > 227880910;
    #102332569.73
    select  sum(act_print) from ln_plan_info where repay_date >= '2025-09-01' and repay_date <= '2025-09-31' and status ='FP';
#202412
#202501 750241
insert into ln_loan_info (recon_date, product_no, apply_no, loan_req_no, loan_time, due_date, name, id_card_type, id_card, contract_amt, loan_amt, service_amt, guarantee_amt, margin_amt, compensate_amt, act_service_amt, act_guarantee_amt, act_margin_amt, act_compensate_amt, repay_day, total_term, loan_status, remark, loan_month, lend_status)   (
    select  a.recon_date, 'DXM', a.apply_no, a.apply_no, a.loan_time, a.due_date, b.name, b.id_card_type, b.id_card, a.loan_amt, a.loan_amt, b.service_amt, b.guarantee_amt, b.margin_amt, b.compensate_amt, b.act_service_amt, b.act_guarantee_amt, b.act_margin_amt, b.act_compensate_amt,  date_format(a.recon_date,'%d'), a.total_term, b.loan_status, b.remark, date_format(a.recon_date,'%Y-%m'), b.lend_status from (select * from ln_loan_info_copy1 where id>750241)a left join ln_loan_info b on a.old_apply_no = b.apply_no
);

insert into apply_base_info (recon_date, apply_no, name, id_card, id_card_type, id_address, id_expiry_date, mobile, gender, educational, address_time, address, detail_address, house_condition, car_condition, annual_income, is_pay_security, debts, often_email, marry_status, has_children, salary_date, industry, unit_name, unit_address, unit_detail_address, unit_telphone, contact_a_ref, contact_a_name, contact_a_mobile, contact_b_ref, contact_b_name, contact_b_mobile, work_years, apply_ref, is_common_apply, ent_name, ent_id, ent_create_date, legal_name, industry_code, industry_divide, ent_type, area_name, registration_authority, person_number, registered_address, business_scope, contact_c_name, contact_c_ref, contact_c_mobile, last_year_begin_total_assets, last_year_begin_total_liabilities, last_year_end_total_assets, last_year_end_total_liabilities, last_year_annual_income, is_tree_year_tax_penalty, litigation_amt, is_enforcement, is_dishonesty, is_high_consumption, is_business_abnormal, is_stock_equity_freeze, is_administrative_penalty, account_name, card_no, pre_mobile, partner_no, loan_use, loan_amt, loan_period, face_merchants, facce_supply_param, face_card_compare, product_no, product_name, apply_time, loan_title, apply_status, guarantee_type, buis_mode, rev_guarantee_type, guarantee_scope, cfund_channel_no, cfund_channel_name, pay_way, repay_way, year_rate, service_rate, guarantee_rate, margin_rate, compensate_rate, act_year_rate, period_service_rate, period_guarantee_rate, period_margin_rate, period_compensate_rate, oint_rate, oguarantee_rate, define_rate, adv_define_rate, compensate_days, grace_day, interest_free_period, create_time, credit_no, credit_apply_no)
    (select a.recon_date, a.apply_no, b.name, b.id_card, b.id_card_type, b.id_address, b.id_expiry_date, b.mobile, b.gender, b.educational, b.address_time, b.address, b.detail_address, b.house_condition, b.car_condition, b.annual_income, b.is_pay_security, b.debts, b.often_email, b.marry_status, b.has_children, b.salary_date, b.industry, b.unit_name, b.unit_address, b.unit_detail_address, b.unit_telphone, b.contact_a_ref, b.contact_a_name, b.contact_a_mobile, b.contact_b_ref, b.contact_b_name, b.contact_b_mobile, b.work_years, b.apply_ref, b.is_common_apply, b.ent_name, b.ent_id, b.ent_create_date, b.legal_name, b.industry_code, b.industry_divide, b.ent_type, b.area_name, b.registration_authority, b.person_number, b.registered_address, b.business_scope, b.contact_c_name, b.contact_c_ref, b.contact_c_mobile, b.last_year_begin_total_assets, b.last_year_begin_total_liabilities, b.last_year_end_total_assets, b.last_year_end_total_liabilities, b.last_year_annual_income, b.is_tree_year_tax_penalty, b.litigation_amt, b.is_enforcement, b.is_dishonesty, b.is_high_consumption, b.is_business_abnormal, b.is_stock_equity_freeze, b.is_administrative_penalty, b.account_name, b.card_no, b.pre_mobile, 'ZT-DXM', b.loan_use, a.loan_amt, a.total_term, b.face_merchants, b.facce_supply_param, b.face_card_compare,'DXM', '度小满', a.recon_date, b.loan_title, b.apply_status, b.guarantee_type, b.buis_mode, b.rev_guarantee_type, b.guarantee_scope, 'ZT-DMX-NBTS', '正堂-度小满-宁波通商', b.pay_way,'01', '0.24', b.service_rate, b.guarantee_rate, b.margin_rate, b.compensate_rate, b.act_year_rate, b.period_service_rate, b.period_guarantee_rate, b.period_margin_rate, b.period_compensate_rate, b.oint_rate, b.oguarantee_rate, b.define_rate, b.adv_define_rate, 0, 0, 0, a.recon_date, b.credit_no, b.credit_apply_no
     from (select * from ln_loan_info_copy1 where id>750241) a left join apply_base_info b on a.old_apply_no = b.apply_no) ;


UPDATE ln_plan_info lpi
    INNER JOIN
    (select apply_no,term,sum(print)print,sum(int_amt)int_amt,sum(repay_total_amt)repay_total_amt,recon_date
     from ln_repay_info where  product_no = 'DXM' and recon_date >='2026-04-01'  and recon_date <='2026-05-31' group by apply_no,term)lri
    ON lpi.apply_no = lri.apply_no
        and lpi.term =lri.term
SET lpi.act_repay_date = lri.recon_date,
    lpi.act_print = lri.print,
    lpi.act_int_amt=lri.int_amt,
    lpi.act_repay_total_amt = lri.repay_total_amt,
    lpi.status ='FP',
    lpi.recon_date = lri.recon_date,
    lpi.ovd_days =0
where  lpi.apply_no=lri.apply_no and lpi.term=lri.term
;

#更新应还
UPDATE ln_plan_info lpi
    INNER JOIN
    (select apply_no,term,sum(print)print,sum(int_amt)int_amt,sum(repay_total_amt)repay_total_amt,recon_date
     from ln_repay_info where  product_no = 'DXM' and recon_date >='2024-11-01'  and recon_date <='2024-12-31' group by apply_no,term)lri
    ON lpi.apply_no = lri.apply_no
        and lpi.term =lri.term
SET lpi.act_repay_date = lri.recon_date,
    lpi.act_print = lri.print,
    lpi.act_int_amt=lri.int_amt,
    lpi.act_repay_total_amt = lri.repay_total_amt,
    lpi.print = lri.print,
    lpi.int_amt=lri.int_amt,
    lpi.repay_total_amt = lri.repay_total_amt,
    lpi.status ='FP',
    lpi.recon_date = lri.recon_date,
    lpi.ovd_days =0
where  lpi.apply_no=lri.apply_no and lpi.term=lri.term
;

select * from ln_plan_info where status = 'FP' order by act_repay_date desc;

select count(0)
from (
select count(0) from ln_plan_info where status != 'FP' group by apply_no)a;

select * from ln_repay_info where  repay_type = 5 and recon_date>='2024-10-01';



update ln_repay_info  set recon_date = STR_TO_DATE(CONCAT('2024-10-', DAY(recon_date)), '%Y-%m-%d'),repay_time = STR_TO_DATE(CONCAT('2024-10-', DAY(repay_time)), '%Y-%m-%d'),repay_type=5
where apply_no in (select * from (select apply_no from ln_repay_info where recon_date >= '2024-10-31' group by apply_no  order by apply_no  limit 30000)a)
  and recon_date>='2024-10-31';

delete  from ln_loan_info_copy1 where id>
                                      750241;

#放款信息开始ID 676278 20241203；750241 20250102
update ln_loan_info_copy1 set loan_time =STR_TO_DATE(CONCAT('2024-12-', DAY(loan_time)), '%Y-%m-%d') ,due_date =date_add(loan_time,INTERVAL 1 MONTH),recon_date =loan_time,total_term = 1,apply_no =concat('DXM',recon_date,'_',LPAD(ID, 8, '0'))   where id>750241;

select * from ln_loan_info_copy1  where id>750241;

update ln_loan_info_copy1 set due_date =date_add(loan_time,INTERVAL 1 MONTH) where id>676278;

update ln_loan_info_copy1 set recon_date =loan_time where id>676278;


update ln_loan_info_copy1 set apply_no =concat('DXM',recon_date,'_',LPAD(ID, 8, '0'))where apply_no is  null and id>750241 ;

update ln_loan_info_copy1 set total_term = 1 where id>676278;
#还款计划 ID 7027048  20241101  新增10月放款
#还款计划 ID 7115348  20241203  新增11月放款;
#还款计划 ID 7189311  20250102  新增12月放款

select sum(loan_amt)
from ln_loan_info_copy1 where id>7115348;
select count(*) from (
                         select count(0)
                         from ln_plan_info where id<7115348 group by apply_no)t;

select * from (
select count(0)num
from ln_loan_info_copy1 group by apply_no)a where num>1;

#放款信息开始ID 676278 20241203
select id, recon_date, apply_no, old_apply_no, loan_time, due_date, name, id_card, loan_amt, total_term, address
from ln_loan_info_copy1 where id>676278;

select recon_date, product_no, apply_no, term, repay_date, act_repay_date, compensate_date, compensate_type, status, ovd_days, is_compensate, print, int_amt, service_amt, guarantee_amt, margin_amt, compensate_amt, oint_amt, oguarantee_amt, define_amt, adv_define_amt, repay_total_amt, act_print, act_int_amt, act_service_amt, act_guarantee_amt, act_margin_amt, act_compensate_amt, act_oint_amt, act_oguarantee_amt, act_define_amt, act_adv_define_amt, act_repay_total_amt, compensate_print, compensate_int_amt, compensate_oint_amt, is_reduce, reduce_amt, coupon_amt, remark, loan_month, act_reduce_print, act_reduce_int_amt, act_reduce_service_amt, act_reduce_guarantee_amt, act_reduce_margin_amt, act_reduce_compensate_amt, act_reduce_oint_amt, act_reduce_oguarantee_amt, act_reduce_define_amt, act_reduce_adv_define_amt, create_time, update_time from ln_plan_info where id>7115348;

select recon_date, product_no, apply_no, term, tran_rp_no, repay_time, repay_total_amt, print, int_amt, service_amt, guarantee_amt, margin_amt, compensate_amt, oint_amt, oguarantee_amt, define_amt, adv_define_amt, reduce_print, reduce_int_amt, reduce_service_amt, reduce_guarantee_amt, reduce_margin_amt, reduce_compensate_amt, reduce_oint_amt, reduce_oguarantee_amt, reduce_define_amt, reduce_adv_define_amt, repay_type, reduce_activity_amt, reduce_compliance_amt, remark from ln_repay_info where recon_date>='2024-11-01' and recon_date<='2024-11-30';

select count(0)
from ln_loan_info_copy1 where id>676278 ;

#还款信息 ID 8056049

#20250804 还款信息 ID  224425152

select sum(print)
from ln_repay_info where id >225460264;

select sum(print)
from ln_plan_info;



select *
from ln_loan_info a left join (select apply_no,sum(print)print from ln_plan_info group by apply_no)b on a.apply_no = b.apply_no and a.loan_amt!= b.print where b.apply_no is not null ;

#新增后还款信息ID 8218312;   20250102 8860314  20250205 223409597  20250303 223507491  20250403 223604697    20250908 224655152

update ln_repay_info  set recon_date = STR_TO_DATE(CONCAT('2024-11-', DAY(recon_date)), '%Y-%m-%d'),repay_time = STR_TO_DATE(CONCAT('2024-11-', DAY(repay_time)), '%Y-%m-%d'),repay_type=1
where id >8218312
  and recon_date<='2024-11-31';

select sum(loan_amt)
from ln_loan_info;
select sum(print)计划 from ln_plan_info ;
select sum(print) from ln_repay_info;

select sum(print) from ln_plan_info where product_no = 'DXM' and status = 'NOR';


ALTER TABLE ln_loan_info_copy1 AUTO_INCREMENT = 750242;

select * from  (select  * from ln_loan_info where product_no = 'DXM' and loan_month = '2024-10')a left join ln_plan_info b on a.apply_no =b.apply_no where a.loan_amt != b.print;



select *
from ln_loan_info_copy1 where recon_date >='2024-10-01' and recon_date<='2024-10-31';


select sum(a.loan_amt),sum(b.print),sum(a.loan_amt)-sum(b.print),sum(repay_total_amt) from (
                                                                                               select * from ln_loan_info where product_no ='DXM' and loan_month = '2024-10' )a
                                                                                               left join (select apply_no,sum(print)print,sum(repay_total_amt)repay_total_amt from ln_repay_info where  product_no ='DXM'  and repay_type!=8 and recon_date<='2024-11-31' group by apply_no ) b on a.apply_no=b.apply_no;


select apply_no,sum(print)print,sum(repay_total_amt)repay_total_amt from ln_repay_info where  product_no ='DXM'  and repay_type!=8 and recon_date>='2024-11-01' and recon_date<='2024-11-31';


select * from  (select  * from ln_loan_info where product_no = 'DXM'  and total_term = 1)a left join (select apply_no,sum(print)print from ln_plan_info group by apply_no) b on a.apply_no =b.apply_no where a.loan_amt != b.print;

update ln_repay_info lri inner join
    (select a.* from  (select  * from ln_loan_info where product_no = 'DXM' and loan_month = '2024-11' and total_term = 1)a left join (select apply_no,sum(print)print from ln_plan_info group by apply_no) b on a.apply_no =b.apply_no where a.loan_amt != b.print)b
    on lri.apply_no = b.apply_no set print = b.loan_amt,int_amt= b.loan_amt*0.02,lri.repay_total_amt =b.loan_amt+b.loan_amt*0.02 where lri.recon_date>='2024-12-01' and lri.recon_date<='2024-12-31' and term=1;
;



update ln_repay_info lri inner join (
    select b.id from (
    select * from ln_loan_info where product_no ='DXM' and substr(id_card,1,2) = '51' )a
    left join (select apply_no,print,id from ln_repay_info where  product_no ='DXM' and  recon_date > '2024-12-31' and repay_type!=8  limit 90000) b
    on a.apply_no=b.apply_no  where b.apply_no is not null)b on lri.id = b.id set lri.recon_date = STR_TO_DATE(CONCAT('2024-12-', DAY(lri.recon_date)), '%Y-%m-%d'),lri.repay_time = STR_TO_DATE(CONCAT('2024-12-', DAY(lri.repay_time)), '%Y-%m-%d') where recon_date > '2024-12-31';


select sum(b.print) from (
                     select * from ln_loan_info where product_no ='DXM' and substr(id_card,1,2) = '51' )a
                     left join (select apply_no,print,id from ln_repay_info where  product_no ='DXM' and  recon_date > '2024-12-31' and repay_type!=8 limit 90000)b on a.apply_no=b.apply_no  where b.apply_no is not null;

#584874240.54
select sum(print) from ln_plan_info where repay_date <='2025-01-31' and status ='NOR';

select b.* from (
select * from ln_plan_info where repay_date <='2025-01-31' and status ='NOR')a left join ln_repay_info b on a.apply_no =b.apply_no and a.term = b.term where b.id is not null;


#584874240.54
select sum(print) from ln_repay_info where repay_time <='2025-01-31' and repay_time>='2025-01-01';

select * from ln_repay_info where repay_time <='2025-01-31' and repay_time>='2025-01-01';


update apply_base_info a  left join ln_loan_info b  on a.apply_no=b.apply_no set a.id = b.id ,a.recon_date =b.recon_date;


select  sum(print),count(0) from ln_repay_info where id >'223770536';

select sum(print) from ln_plan_info;

select sum(loan_amt) from apply_base_info ;

select sum(loan_amt) from ln_loan_info;

select * from ln_repay_info where recon_date >= '2025-04-01' order by id;

#100096977.36
select  sum(print) from ln_repay_info where recon_date >= '2025-07-01' and recon_date <= '2025-06-30';

select  count(0),sum(print) from ln_repay_info where id > 226410154;


select  sum(print) from ln_plan_info where repay_date >= '2026-02-01' and repay_date <= '2026-02-28' and status ='NOR';

select  sum(print) from ln_plan_info where act_repay_date >= '2026-05-01' and act_repay_date <= '2026-05-31';

select  * from ln_plan_info where act_repay_date >= '2025-05-01' and act_repay_date <= '2025-05-31';


select  * from ln_repay_info where recon_date >= '2025-06-01' and recon_date <= '2025-06-30';






select * from ln_plan_info where apply_no like 'DXM%' and term =12  and status ='NOR' order by recon_date;

select count(0),sum(print) from ln_plan_info where apply_no like 'DXM%' and repay_date <= '2026-02-28' and status ='NOR';


select sum(print) from ln_repay_info where Id <=226410154;


select  substr(apply_no,4, 7),sum(print) from ln_plan_info where repay_date >= '2026-02-01' and repay_date <= '2026-02-28' and status ='NOR' group by substr(apply_no,4, 7);


#原本的 2月份还款开始ID  226410154


#还款计划  8月放款补的开始ID371998926   还款信息开始 ID 226700593

UPDATE ln_repay_info
SET recon_date = CONCAT('2026-02-', LPAD(DAY(recon_date), 2, '0')),
    repay_time = CONCAT('2026-02-', LPAD(DAY(repay_time), 2, '0'))

WHERE Id >226700593;