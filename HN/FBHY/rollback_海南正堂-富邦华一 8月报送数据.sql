-- ============================================================================
-- 脚本名称: rollback_海南正堂-富邦华一 8月报送数据.sql
-- 功能描述: 精确回滚《海南正堂-富邦华一 8月报送数据.sql》8 月手工报送数据
-- 执行环境: DMS（test_zxbs_db，MySQL 语法）
-- 回滚依据: 按各表主键 + ddate 精确删除，不影响其他月份/项目数据
--   1. ads_hain_g28_recover_detail  按 recv_seq = COMP-FTBHY-20260831001
--   2. ads_hain_g27_comp_detail     按 comp_seq = COMP-FTBHY-20260831001
--   3. ads_hain_g23_1_risk_share    按 cont_no  = HT-FTBHY-202608001
--   4. ads_hain_g23_detail          按 cont_no  = HT-FTBHY-202608001
-- 说明:     原脚本 G11 INSERT 已注释（客户 7 月已报送），无需回滚
-- 删除顺序: 与原 INSERT 顺序相反（G28 → G27 → G23_1 → G23）
-- 报表月份: 2026-08（ddate = 2026-08-31）
-- 生成日期: 2026-09-16
-- ============================================================================

-- 1. 回滚 ads_hain_g28_recover_detail（回收明细，1 行）
DELETE FROM test_zxbs_db.ads_hain_g28_recover_detail
WHERE recv_seq = 'COMP-FTBHY-20260831001'
  AND ddate    = '2026-08-31';

-- 2. 回滚 ads_hain_g27_comp_detail（代偿明细，1 行）
DELETE FROM test_zxbs_db.ads_hain_g27_comp_detail
WHERE comp_seq = 'COMP-FTBHY-20260831001'
  AND cont_no  = 'HT-FTBHY-202608001'
  AND ddate    = '2026-08-31';

-- 3. 回滚 ads_hain_g23_1_risk_share（风险分担，1 行）
DELETE FROM test_zxbs_db.ads_hain_g23_1_risk_share
WHERE cont_no = 'HT-FTBHY-202608001'
  AND ddate   = '2026-08-31';

-- 4. 回滚 ads_hain_g23_detail（担保明细，1 行）
DELETE FROM test_zxbs_db.ads_hain_g23_detail
WHERE cont_no = 'HT-FTBHY-202608001'
  AND ddate   = '2026-08-31';
