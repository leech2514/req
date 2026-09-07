# -*- coding: utf-8 -*-
"""
DXM_notebook_setup.py 的用法示例（可直接运行，无 notebook 依赖）。

展示：
 1) 改配置模式（cnf 模式 / 纯 Python 字典模式）
 2) print_config() 看生效参数
 3) q() + dict 参数绑定
 4) q() + list 参数绑定
 5) q() + 切换 group 到正堂
"""
import sys
sys.path.insert(0, r"e:\project\req\DXM")

import DXM_notebook_setup as dxm

# ===== 模式选择（二选一，改这里即可） =====
MODE = "CNF"       # "CNF" 读 cnf + override 层（推荐）
# MODE = "DICT"    # "DICT" 纯 Python 字典，完全不读 cnf

if MODE == "DICT":
    dxm.USE_CNF_CONFIG = False
    dxm._cached_conn_args.clear()
    dxm._cached_read_cfg_from_cnf = None

print_config = dxm.print_config
q = dxm.q

print_config()

# ----------------------------------------------------------
# 1. 昌泰库：还款明细 id > 656189（dict 绑定 :name 风格）
# ----------------------------------------------------------
START_ID = 656189
df1 = q(
    """
    SELECT id, recon_date, apply_no, tran_rp_no, term,
           print, int_amt, repay_total_amt, repay_time
    FROM ln_repay_info
    WHERE id > :start_id
    ORDER BY id
    LIMIT 5;
    """,
    params={"start_id": START_ID},
    group="ct_dxm",
)
print("\n【demo1】昌泰 ln_repay_info id > START_ID 前 5 行：")
print(df1.to_string(index=False))

# ----------------------------------------------------------
# 2. 昌泰库：放款 id 区间 [76500, 81000)（list 绑定 %s 风格）
# ----------------------------------------------------------
S, E = 76500, 81000
df2 = q(
    """
    SELECT id, recon_date, apply_no, loan_amt, product_no, repay_day, due_date
    FROM ln_loan_info
    WHERE id >= %s AND id < %s
    ORDER BY id
    LIMIT 5;
    """,
    [S, E],
    group="ct_dxm",
)
print(f"\n【demo2】昌泰放款 id [{S}, {E}) 前 5 行：")
print(df2.to_string(index=False))

# ----------------------------------------------------------
# 3. 正堂库：4 月对账的四表一致性（进件=放款=计划本金之和=明细本金之和）
# ----------------------------------------------------------
d1 = "2026-04-01"
df3 = q(
    """
    SELECT
      SUM(a.loan_amt)            AS sum_apply,
      SUM(b.loan_amt)            AS sum_loan,
      IFNULL(SUM(c.act_print),0) AS sum_plan_print,
      IFNULL(SUM(d.act_print),0) AS sum_repay_print,
      COUNT(DISTINCT a.apply_no) AS apply_cnt,
      COUNT(DISTINCT b.apply_no) AS loan_cnt
    FROM apply_base_info a
    LEFT JOIN ln_loan_info b USING (apply_no)
    LEFT JOIN (SELECT apply_no, SUM(print) act_print FROM ln_plan_info GROUP BY apply_no) c USING (apply_no)
    LEFT JOIN (SELECT apply_no, SUM(print) act_print FROM ln_repay_info GROUP BY apply_no) d USING (apply_no)
    WHERE a.recon_date BETWEEN :d1 AND LAST_DAY(:d1)
      AND b.product_no = 'DXM';
    """,
    params={"d1": d1},
    group="hainandxm",
)
print(f"\n【demo3】正堂 2026-04 对账 四表金额一致性：")
print(df3.to_string(index=False))
