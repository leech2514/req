# hainanDXM.ipynb 连接 MySQL 的 3 个步骤

> 不用先去改 cnf。两种配置模式任选，都支持。

## 前置文件

所有 SQL 执行相关代码都放在独立脚本里（密码二选一配置）：

```
e:\project\req\DXM\DXM_notebook_setup.py   ← 配置+q()+%%sql 都在这里
e:\project\req\hainandxm.cnf               ← 模式A 读它（默认 USE_CNF_CONFIG=True）
```

要切到「纯 Python 字典」模式，打开 `DXM_notebook_setup.py`，把顶部一行改为 `USE_CNF_CONFIG = False`，然后在同文件下方的 `DB_CONFIG` 字典里填好 `host/port/user/password` 和库名映射。两种模式我都已独立跑通：
- 模式 A（cnf）：两库连通，hainandxm 503,407 行 / ct_dxm 94,939 行 ✅
- 模式 B（纯字典）：同上 ✅
- q() 三种参数绑定（dict :name / list %s / group 切换）✅

---

## Step 1. 在 notebook 的**第一个 code cell** 放下面这一行（加载配置）

```python
%run e:/project/req/DXM/DXM_notebook_setup.py
```

**运行后应看到类似输出**（两库 ✅ OK 就说明连接成功）：

```
========================================================
[DXM] 配置模式  : hainandxm.cnf + CONNECT_OVERRIDE
[DXM] DEFAULT_GROUP : ct_dxm
[DXM] group=hainandxm  -> root@localhost:3308/hainandxm  password=***6chars  charset=utf8mb4
[DXM] group=ct_dxm     -> root@localhost:3308/ct_dxm     password=***6chars  charset=utf8mb4
========================================================
[DXM] %%sql magic 已切换到 group=ct_dxm
...
hainandxm  ✅ OK, apply_base_info 503407 行
ct_dxm     ✅ OK, apply_base_info 94939 行
```

想再看一次配置，任何 cell 跑：
```python
print_config()
```

---

## Step 2（写法 A 推荐做加工）. 任何 code cell 里直接调用 `q()` 得到 DataFrame

```python
# ① dict 参数绑定（SQL 写 :名）—— 最常用
START_ID = 656189
df = q(
    """
    SELECT id, recon_date, apply_no, tran_rp_no, term, print, int_amt, repay_total_amt, repay_time
    FROM ln_repay_info
    WHERE id > :start_id
    ORDER BY id
    LIMIT 10;
    """,
    params={"start_id": START_ID},
    group="ct_dxm",   # group: 'ct_dxm'=昌泰 / 'hainandxm'=正堂 / 省略则走 DEFAULT_GROUP
)
df
```

```python
# ② list 参数绑定（SQL 写 %s）—— 昌泰 id 区间加工
S, E = 76500, 81000
df_loan = q(
    "SELECT id, recon_date, apply_no, loan_amt, product_no FROM ln_loan_info WHERE id >= %s AND id < %s LIMIT 10;",
    [S, E],
    group="ct_dxm",
)
df_loan
```

---

## Step 2（写法 B 临时快查）. `%%sql` 裸 SQL cell（直接写 SQL）

初始化 `%run` 完成后，**任何 code cell 第一行写 `%%sql`**，后面就是纯 SQL，不用包 Python：

```sql
%%sql
SELECT id, recon_date, apply_no, loan_amt
FROM ln_loan_info
WHERE id >= 76500 AND id < 81000
ORDER BY id
LIMIT 10;
```

`%%sql` 默认连的是 `DEFAULT_GROUP`（当前是 ct_dxm 昌泰）。想切到正堂，先跑：
```python
connect_magic('hainandxm')
```
再跑你的 `%%sql` cell 即可。

---

## 常用工具函数（%run 后全局可用）

| 函数 | 作用 | 示例 |
|------|------|------|
| `q(sql, params, group)` | 执行 SQL 返回 DataFrame | `q('select * from t where id>:x', {'x':1})` |
| `get_conn(group)` | 拿 pymysql 原生连接（要自己 close） | `with get_conn() as c: c.cursor()...` |
| `connect_magic(group)` | 切换 %%sql 当前连接的库 | `connect_magic('hainandxm')` |
| `print_config()` | 打印生效的连接配置（密码 ***） | `print_config()` |

---

## FAQ

| 问题 | 解决 |
|------|------|
| 不想用 cnf，只想在 Python 里填密码 | 编辑 `DXM_notebook_setup.py` 顶：`USE_CNF_CONFIG=False`，在 `DB_CONFIG` 字典里填好密码+库映射（host/port/user 也改那里），重启 notebook 或重新 `%run` |
| 想临时切端口/主机 | 编辑 `DXM_notebook_setup.py` 的 `CONNECT_OVERRIDE` 字典，填 `host` / `port`，其他留空——不管哪种模式都会叠加 |
| 报 `NameError: name 'q' is not defined` | 还没 `%run e:/project/req/DXM/DXM_notebook_setup.py`，或者跑过但 kernel 重启了，重跑第一步 |
| 我自己 notebook 里已经在 code cell 写了大段 SQL（比如你现在的 135 行涉农筛选） | 在 cell 最上面一行加 `%%sql` 就变成裸 SQL cell 了 |
| `%%sql` 的结果要再加工怎么办 | 用行内 magic：`res = %sql select ... limit 100;` → `res` 就是 DataFrame |
