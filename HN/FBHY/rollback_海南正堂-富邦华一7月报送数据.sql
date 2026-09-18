-- ============================================================================
-- 脚本名称: rollback_海南正堂-富邦华一.sql
-- 功能描述: 精确回滚《海南正堂-富邦华一.sql》7 月手工报送数据
-- 执行环境: DMS（test_zxbs_db，MySQL 语法）
-- 回滚依据: 按各表主键 + ddate 精确删除，不影响其他月份/项目数据
--   1. ads_hain_g28_recover_detail  按 recv_seq = COMP-FTBHY-20260729001
--   2. ads_hain_g27_comp_detail     按 comp_seq = COMP-FTBHY-20260729001
--   3. ads_hain_g23_1_risk_share    按 cont_no  = HT-FTBHY-202607001
--   4. ads_hain_g23_detail          按 cont_no  = HT-FTBHY-202607001
--   5. ads_hain_g11_cust_info       按 cust_id  = FTBHY001
-- 删除顺序: 与原 INSERT 顺序相反（G28 → G27 → G23_1 → G23 → G11）
-- 报表月份: 2026-07（ddate = 2026-07-31）
-- 生成日期: 2026-09-16
-- ============================================================================

-- 1. 回滚 ads_hain_g28_recover_detail（回收明细，1 行）
DELETE FROM test_zxbs_db.ads_hain_g28_recover_detail
WHERE recv_seq = 'COMP-FTBHY-20260729001'
  AND ddate    = '2026-07-31';

-- 2. 回滚 ads_hain_g27_comp_detail（代偿明细，1 行）
DELETE FROM test_zxbs_db.ads_hain_g27_comp_detail
WHERE comp_seq = 'COMP-FTBHY-20260729001'
  AND cont_no  = 'HT-FTBHY-202607001'
  AND ddate    = '2026-07-31';

-- 3. 回滚 ads_hain_g23_1_risk_share（风险分担，1 行）
DELETE FROM test_zxbs_db.ads_hain_g23_1_risk_share
WHERE cont_no = 'HT-FTBHY-202607001'
  AND ddate   = '2026-07-31';

-- 4. 回滚 ads_hain_g23_detail（担保明细，1 行）
DELETE FROM test_zxbs_db.ads_hain_g23_detail
WHERE cont_no = 'HT-FTBHY-202607001'
  AND ddate   = '2026-07-31';

-- 5. 回滚 ads_hain_g11_cust_info（客户信息，1 行；加 ddate 限定仅删 7 月行）
DELETE FROM test_zxbs_db.ads_hain_g11_cust_info
WHERE cust_id = 'FTBHY001'
  AND ddate   = '2026-07-31';
