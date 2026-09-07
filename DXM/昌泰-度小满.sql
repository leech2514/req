update apply_base_info set partner_no = 'CTDXM',product_no= 'CTDXMXYXJ',product_name = '昌泰-度小满-兴业消金',apply_time=recon_date,apply_status = '01',cfund_channel_no='CT-DXM-XYXJ',cfund_channel_name='昌泰-度小满-兴业消金'
WHERE 1=1;

update ln_loan_info set product_no ='CTDXMXYXJ' WHERE 1=1;
143171505.00

set @startId ='46000';
set @endId ='56000';

select *
from apply_base_info where id>=81000 and id<84500;

select *
from ln_loan_info where id>=81000 and id<84500;



select sum(loan_amt),count(0)
from apply_base_info where id>=81000 and id<84500;


select sum(loan_amt),count(0)
from ln_loan_info where id>=81000 and id<84500;




update apply_base_info set recon_date =STR_TO_DATE(CONCAT('2026-06-', if(DAY(recon_date)>30,30,DAY(recon_date))), '%Y-%m-%d') where id>=81000 and id<84500;

update apply_base_info set apply_no =concat('CTDXM',recon_date,'_',LPAD(ID, 8, '0')) ,apply_time =recon_date where id>=81000 and id<84500;

update ln_loan_info abi inner join apply_base_info lli on abi.id = lli.id  set abi.recon_date = lli.recon_date,abi.apply_no=lli.apply_no where lli.id>=81000 and lli.id<84500;


update ln_loan_info set  loan_time = recon_date,due_date =date_add(recon_date,INTERVAL total_term MONTH),loan_month =date_format(recon_date,'%Y-%m'),loan_status='NOR',repay_day = date_format(recon_date,'%d')  where id>=81000 and id<84500;


select * from apply_base_info a left join ln_loan_info b on a.id = b.id where a.apply_no != b.apply_no or a.recon_date !=b.recon_date or a.loan_amt !=b.loan_amt;

select count(0),sum(loan_amt),loan_month
from ln_loan_info where id>=81000 and id<84500 group by loan_month;


UPDATE ln_plan_info lpi
    INNER JOIN
    (select apply_no,term,sum(print)print,sum(int_amt)int_amt,sum(repay_total_amt)repay_total_amt,recon_date
     from ln_repay_info where  product_no = 'CTDXMXYXJ' and recon_date >='2026-04-01'  and recon_date <='2026-06-30' group by apply_no,term)lri
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

set @startId ='81000';
set @endId ='84500';

select a.recon_date 对账日期,a.apply_no 借款申请编号,a.loan_amt '进件信息-借款金额',b.contract_amt '放款信息-合同金额',b.loan_amt '放款信息-放款金额',c.act_print '还款计划所有应还本金之和',d.act_print
from (
         (select *
          from apply_base_info where id>=@startId and id<@endId) a left join ln_loan_info b on a.apply_no = b.apply_no left join (select sum(print)act_print,apply_no from  ln_plan_info group by apply_no)c
             on a.apply_no = c.apply_no left join (select sum(print)act_print,apply_no from  ln_repay_info group by apply_no)d on a.apply_no = d.apply_no) where a.loan_amt !=c.act_print;

select sum(loan_amt)
from ln_loan_info where apply_no like 'CTDXM%';

select sum(loan_amt)
from apply_base_info where apply_no like 'CTDXM%';


select sum(print)
from ln_plan_info ;


#57432949.82
select sum(print)
from ln_repay_info where apply_no like 'CTDXM%' and recon_date >='2026-04-01';

select sum(print)
from ln_repay_info where apply_no like 'CTDXM%' and id>523071;

select sum(print)
from ln_plan_info where apply_no like 'CTDXM%' and repay_date >='2026-02-01' and repay_date <='2026-03-31';


#57432949.82
select sum(print)
from ln_plan_info where apply_no like 'CTDXM%'and repay_date >='2026-04-01' and repay_date <='2026-06-30';


select sum(act_print)
from ln_plan_info where apply_no like 'CTDXM%'and repay_date >='2026-04-01' and repay_date <='2026-06-30';

select sum(print)
from ln_plan_info where apply_no like 'CTDXM%'and id> 255921;

select * from ln_loan_info  where id>=20700 and id<25500 and total_term<1;

select * from apply_base_info  where id>=20700 and id<25500;

13976711.28

select sum(print) from ln_repay_info where  id >'225276';


select * from ln_repay_info where apply_no like 'CTDXM%' and recon_date >='2025-02-01' order by  id;

update ln_loan_info set total_term =12 where total_term<1;


select * from ln_plan_info where date_format(repay_date,'%Y-%m') ='2025-04' and term =1 order by id;

#13567060.55
#20250806 12573389.45   20250910 12156128.75
select  sum(print),count(0) from ln_repay_info where id >'129295';


select sum(print) from ln_plan_info where repay_date >='2025-08-01' and recon_date<='2025-08-31' and status = 'NOR';

#20945891.12  21364682.16

310773210.63
select sum(print),count(0) from ln_plan_info  ;

select sum(loan_amt),count(0) from ln_loan_info  where id<60000;

select sum(loan_amt),count(0) from apply_base_info where id>=32000 and id<35000;

select sum(loan_amt),count(0) from ln_loan_info  where id>=32000 and id<35000;

#11120045.09
#20250806 12573389.45  12156128.75
select sum(print),count(0) from ln_plan_info where act_repay_date >='2025-08-01' and act_repay_date<='2025-08-31';

select sum(act_print),count(0) from ln_plan_info where act_repay_date >='2025-08-01' and act_repay_date<='2025-08-31';

select * from ln_repay_info where recon_date >= '2025-12-01' order by id;

select * from ln_repay_info where  id > 265040;

select * from ln_plan_info where  id > 691065;

select * from ln_plan_info where apply_no = 'CTDXM2025-12-15_00064200';


