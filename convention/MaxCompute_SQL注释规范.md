# MaxCompute / DataWorks SQL 脚本注释规范

> 适用范围：本规范下所有迁移到 MaxCompute + DataWorks 的 SQL 脚本，包括 DDL（建表/建视图）、DML（ETL/写入）、DQL（查询/校验）、DCL（权限/资源）。
> 生效日期：2026-08-25
> 负责人：数仓组

---

## 一、总则

1. **每个 SQL 文件必须以「文件头注释块」开头**，置于 DROP / CREATE / INSERT 等任何可执行语句之前。
2. **脚本体内关键逻辑必须用行内注释说明**，不允许出现"裸 SQL"。
3. **注释语言**：统一中文。字段名、函数名、SQL 关键字保留英文原样。
4. **分隔符**：枚举值注释中的多值分隔统一使用中文分号 `；`，不使用换行或英文逗号。
5. **占位符**：未确定的字段值使用 `<name>`、`<tbd>` 等尖括号占位符，禁止留空。

---

## 二、文件头注释块（必备）

### 2.1 通用字段（所有脚本类型必填）

| 字段 | 含义 | 示例 |
|------|------|------|
| 脚本名称 | 文件名（不含扩展名） | `business_control_page_guide_ddl.sql` |
| 层级 | 数仓分层 | `ODS / DWD / DWS / ADS / DIM` |
| 业务域 | 业务分类 | `风控/管控域`、`海南正堂/担保报送` |
| 功能描述 | 一句话说明脚本作用 | `业务管控规则表日全量快照入仓` |
| 调度参数 | DataWorks 节点参数 | `datadt=$bizdate` |
| 负责人 | 维护人 | `<name>` |
| 创建日期 | YYYY-MM-DD | `2026-08-25` |
| 修订记录 | 变更历史（按时间倒序或正序均可，团队约定） | 见 2.3 节 |

### 2.3 修订记录格式

#### 2.3.1 字段结构（固定 5 列，对齐）

```
--   YYYY-MM-DD  <负责人>  <类型>  <关联单号/需求>  <变更说明>
```

| 列 | 含义 | 取值 |
|----|------|------|
| 日期 | 变更日期 | YYYY-MM-DD |
| 负责人 | 变更人 | 与"负责人"字段相同命名规范 |
| 类型 | 变更类型 | `新建` / `修改` / `修复` / `新增字段` / `删除字段` / `重构` / `回滚` |
| 关联单号 | 需求/缺陷单号 | `#REQ-1234` / `#BUG-5678` / `-`（无关联时填短横线） |
| 变更说明 | 一句话描述 | 必填，避免"改了点东西"这类无信息描述 |

#### 2.3.2 推荐格式（多行展开，便于阅读）

```sql
-- 修订记录:
--   2026-08-25  <name>  新建脚本    -                  新建脚本，业务管控规则表入仓
--   2026-09-10  <name>  修复       #BUG-1001          修复分区裁剪失效，原 GETDATE() 改为 ${bizdate}
--   2026-10-01  <name>  新增字段    #REQ-1234          新增 predict_loan_amount 字段，对应业务需求
```

#### 2.3.3 简化格式（条目较少时可用）

```sql
-- 修订记录:
--   2026-08-25  新建  <name>  首版入库脚本
--   2026-09-10  修复  <name>  WHERE 条件调整，触发分区裁剪
```

#### 2.3.4 规则

1. **每次提交 PR / 修改脚本，必须新增一行修订记录**，不允许直接覆盖旧记录。
2. **记录按时间正序排列**（旧的在上，新的在下），便于追溯演进。
3. **类型字段必填**，且使用上表的标准化取值。
4. **关联单号**有则填，无则填 `-`，禁止留空。
5. **变更说明** 必须能回答"改了什么、为什么改"，禁止"调整"/"优化"这类无信息描述。
6. 新建脚本首条记录固定为 `新建脚本`。

### 2.4 按脚本类型补充字段

#### DDL 类（建表/建视图/建函数）
补充字段：源表、目标表、表类型、主键、分区字段、迁移说明

#### DML 类（INSERT / MERGE / UPDATE）
补充字段：源表、目标表、调度周期、增量方式（全量 full / 增量 incr）、写入模式（INSERT OVERWRITE / INSERT INTO / MERGE INTO）

#### DQL 类（SELECT / 校验）
补充字段：源表、用途（对账/抽样/排查）、是否一次性

#### DCL 类（权限/资源）
补充字段：操作对象、授权主体、操作类型（GRANT/REVOKE/ADD JAR）

---

## 三、注释块格式

### 3.1 推荐样式（带边框 + 字段对齐）

```sql
-- ============================================================================
-- 脚本名称: business_control_page_guide_ddl.sql
-- 层级:     ODS
-- 业务域:   风控/管控域
-- 功能描述: 业务管控-页面使用说明（日全量入仓）
-- 源表:     f_prd_spark_db.business_control_page_guide
-- 目标表:   business_control_page_guide
-- 表类型:   普通分区表（STORED AS aliorc，非事务）
-- 主键:     无（MC 不支持原生主键约束）
-- 分区字段: pt (STRING, yyyymmdd)
-- 调度参数: datadt=$bizdate
-- 调度周期: 日
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- 迁移说明:
--   1. VARCHAR → STRING
--   2. INT → BIGINT
--   3. 删除 PRIMARY KEY / KEY 二级索引
--   4. 新增 PARTITIONED BY (pt) + LIFECYCLE 365
-- ============================================================================
```

### 3.2 简化样式（DQL/临时脚本可用）

```sql
-- ------------------------------------------------------------
-- 脚本名称: tmp_check_loan_balance.sql
-- 用途:     排查中恒信合车金融在贷余额异常
-- 源表:     prd_spark_db.dwd_auto_zf_rent_plan_d
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- ------------------------------------------------------------
```

---

## 四、脚本体内注释规范

### 4.1 CTE / 子查询段落注释

每个 `WITH ... AS (...)` 的 CTE 块前必须有一行注释，说明该 CTE 的用途：

```sql
WITH loan_balance AS (
    -- 计算每个账单的在贷本金、已还本金、未还本金
    SELECT ...
),
nearest_term AS (
    -- 取每个账单最近一期已到期/已实还的期次
    SELECT ...
)
```

### 4.2 字段注释（DDL）

DDL 中每个字段必须带 `COMMENT`，注释需包含：
- 字段含义
- 单位（金额/比例/天数等）
- 枚举值（如有，用 `；` 分隔）
- 转换说明（迁移场景下，如 `原 INT → BIGINT`）

```sql
project_rule_id  BIGINT  COMMENT '业务管控规则ID（原主键，原 bigint → BIGINT）',
status           STRING  COMMENT '状态：1-计算在贷中；2-等待风险确认；3-等待装入确认；...；17-删除规则驳回',
predict_loan_amount DECIMAL(18,2) COMMENT '预估导入在贷金额，单位：元（原 DOUBLE → DECIMAL 避免精度漂移）',
```

### 4.3 关键逻辑注释

涉及业务规则、状态机、关联条件、过滤条件的关键 SQL 必须有行内注释：

```sql
-- 状态机：os_principal=0 视为解保(90)，否则保后监管(60)
CASE
    WHEN b.os_principal = 0 THEN '90'
    ELSE '60'
END AS loan_status,

-- 仅取每个账单最近一期（rn=1）
WHERE rn = 1
```

### 4.4 风险提示注释

存在已知风险点（分区裁剪未生效、类型假设、重跑会重复等）的，必须在该语句上方或文件头注明：

```sql
-- ⚠️ 风险：pt <= TO_CHAR(GETDATE(),'yyyymm') 中 GETDATE() 是运行时函数，
--         MC 无法在编译期做分区裁剪，建议改用调度参数 ${bizmonth}
WHERE pt <= TO_CHAR(GETDATE(), 'yyyymm')
```

---

## 五、调度参数引用格式

- **统一使用 `${param}`** 格式，不用 `$param` 或 `@param`，避免与文本混排时歧义。
- 在 SQL 中引用：`WHERE ds = '${bizdate}'`
- 在文件头注明：`调度参数: bizdate=$bizdate`
- DataWorks 节点「调度配置 > 参数」按 `key=value` 配置，`value` 用 DataWorks 内置变量（`$bizdate`、`$bizmonth`、`$bizyear` 等）。

| 业务场景 | 节点参数配置 | SQL 中引用 |
|---------|------------|-----------|
| 日粒度 T-1 | `bizdate=$bizdate` | `ds = '${bizdate}'` |
| 月粒度上月 | `bizmonth=$bizmonth` | `pt <= '${bizmonth}'` |
| 自定义日期 | `datadt=20260831` | `ds = '${datadt}'` |

---

## 六、DDL 注释特殊要求

1. **每个字段必须有 COMMENT**，不允许裸字段。
2. **关键字段必须有转换说明**（迁移场景）：
   - 类型变更：`原 INT → BIGINT`
   - 约束移除：`原 NOT NULL 移除（MC 不支持字段级约束）`
   - 索引移除：`原 KEY pk_xxx 移除`
   - 默认值移除：`原 DEFAULT '0' 移除`
3. **表级 COMMENT 必填**，描述表的业务用途。
4. **分区字段必须在 PARTITIONED BY 中带 COMMENT**。

---

## 七、DML 注释特殊要求

1. **写入模式必须在文件头注明**：`INSERT OVERWRITE` / `INSERT INTO` / `MERGE INTO`。
2. **MERGE INTO 必须注明 ON 条件的分区谓词**，避免全分区扫描：
   ```sql
   -- ON 条件包含分区谓词 t.ds = s.ds，避免全表扫描（ODPS-0130071）
   ON t.project_code = s.project_code
      AND t.contract_number = s.contract_number
      AND t.ds = s.ds
   ```
3. **WITH 子句每个 CTE 必须有用途注释**。
4. **关键 JOIN / WHERE 条件必须有业务说明**。

---

## 八、禁止事项

1. ❌ 禁止裸 SQL（无任何注释的脚本）
2. ❌ 禁止 COMMENT 含换行符（MC 不支持多行 COMMENT，必须合并为一行，用 `；` 分隔）
3. ❌ 禁止字段类型/约束变更未在注释中说明（迁移场景）
4. ❌ 禁止使用 `$param` 或 `@param` 引用调度参数
5. ❌ 禁止文件头注释块与第一行可执行 SQL 之间无空行分隔
6. ❌ 禁止 COMMIT / ROLLBACK 语句（MC 自动事务，不支持显式提交）

---

## 九、示例

### 9.1 DDL 完整示例

```sql
-- ============================================================================
-- 脚本名称: business_control_page_guide_ddl.sql
-- 层级:     ODS
-- 业务域:   风控/管控域
-- 功能描述: 业务管控-页面使用说明（日全量入仓）
-- 源表:     f_prd_spark_db.business_control_page_guide
-- 目标表:   business_control_page_guide
-- 表类型:   普通分区表（STORED AS aliorc，非事务）
-- 分区字段: pt (STRING, yyyymmdd)
-- 调度参数: datadt=$bizdate
-- 调度周期: 日
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- 修订记录:
--   2026-08-25  <name>  新建脚本  -          新建脚本，业务管控-页面使用说明入仓
--   2026-09-10  <name>  修复      #BUG-1001  调整 LIFECYCLE 从 365 → 730（合规要求）
-- 迁移说明:
--   1. bigint NOT NULL AUTO_INCREMENT → BIGINT（移除 NOT NULL、AUTO_INCREMENT）
--   2. varchar(N) → STRING
--   3. int → BIGINT（规范 6.5.3）
--   4. datetime → TIMESTAMP
--   5. 删除 PRIMARY KEY / KEY 索引
--   6. 删除 DISTRIBUTE BY HASH / STORAGE_POLICY / ENGINE / TABLE_PROPERTIES
--   7. 新增 PARTITIONED BY (pt) + LIFECYCLE 730
-- ============================================================================

DROP TABLE IF EXISTS business_control_page_guide;

CREATE TABLE IF NOT EXISTS business_control_page_guide (
    id           BIGINT COMMENT '主键（原 bigint NOT NULL AUTO_INCREMENT → BIGINT）',
    page_path    STRING COMMENT '页面路由(不含basePath, 如 /yewuguankong/control-rules)',
    page_name    STRING COMMENT '页面名称',
    title        STRING COMMENT '说明条目标题',
    content      STRING COMMENT '说明条目内容',
    sort_order   BIGINT COMMENT '排序(同页面内升序)（原 int → BIGINT）',
    status       STRING COMMENT '状态(0正常 1删除)',
    create_by    STRING COMMENT '创建人',
    create_time  TIMESTAMP COMMENT '创建时间（原 datetime → TIMESTAMP）',
    update_by    STRING COMMENT '更新人',
    update_time  TIMESTAMP COMMENT '更新时间（原 datetime → TIMESTAMP）'
)
COMMENT '业务管控-页面使用说明'
PARTITIONED BY (
    pt STRING COMMENT '业务日期 yyyymmdd'
)
STORED AS aliorc
TBLPROPERTIES ('columnar.nested.type' = 'true')
LIFECYCLE 365
;
```

### 9.2 DML 完整示例（CTE + INSERT）

```sql
-- ============================================================================
-- 脚本名称: 新G11.sql
-- 层级:     ADS
-- 业务域:   海南正堂/担保报送
-- 功能描述: G11 客户信息月度报送（按上月放款数据生成增量客户记录）
-- 源表:     prod_dw_01.dwd_cons_loan_payment_info_incr_delta
--           prod_dw_01.ods_cons_td_loan_incr_delta
--           prod_dw_01.dim_base_indiv_info_incr_t
--           hain_effective_data_interval
-- 目标表:   ads_hain_g11_cust_info
-- 写入模式: INSERT OVERWRITE TABLE
-- 调度参数: bizdate=$bizdate
-- 调度周期: 月度（每月 1 日跑上月数据）
-- 负责人:   <name>
-- 创建日期: 2026-08-25
-- 修订记录:
--   2026-08-25  <name>  新建脚本  -          新建脚本，海南正堂 G11 客户信息月度报送
--   2026-09-10  <name>  修复      #BUG-1002  WHERE 条件调整，原 GETDATE() 改 ${bizdate}，触发分区裁剪
--   2026-10-01  <name>  新增字段  #REQ-1234  新增 dual_innov_flag 双创标识字段
-- 风险提示:
--   - pt 比较的 GETDATE() 是运行时函数，无法触发分区裁剪，建议改 ${bizmonth}
--   - hain_effective_data_interval 若不在当前 project 需补 schema 前缀
-- ============================================================================

INSERT OVERWRITE TABLE ads_hain_g11_cust_info
( dbank_id, ddate, xh, cust_id, cust_name, /* ... */ update_time )

WITH filter_bill AS (
    -- 过滤有效产品+账单+客户三联，仅取报送期内、is_use='Y' 的数据
    SELECT ...
),
source_data AS (
    -- 关联客户主档，组装报送字段 + 计算 row_hash 行指纹
    SELECT ...
),
target_data AS (
    -- 取目标表每个 cust_id 的最新一条记录，计算其 row_hash
    SELECT ...
),
diff_data AS (
    -- 通过 row_hash 比对，挑出新增或修改的客户记录
    SELECT ...
)
SELECT
    'DEFAULT_BANK' AS dbank_id,
    LAST_DAY(s.loan_day) AS ddate,    -- 上月末日期
    s.xh,
    s.cust_id,
    -- ... 其余字段
    CASE WHEN t.create_time IS NULL THEN GETDATE() ELSE t.create_time END AS create_time,
    GETDATE() AS update_time
FROM diff_data s
LEFT JOIN target_data t ON s.cust_id = t.cust_id
WHERE
    -- 上月 1 号到上月末
    s.loan_day BETWEEN
        CONCAT(SUBSTR(DATEADD(GETDATE(), -1, 'mm'), 1, 7), '-01')
        AND LAST_DAY(DATEADD(GETDATE(), -1, 'mm'))
;
```

---

## 十、检查清单（提交前自查）

- [ ] 文件头注释块完整且字段对齐
- [ ] 脚本名称与文件名一致
- [ ] 修订记录已新增一行（修改/修复/新增字段等）
- [ ] 所有字段带 COMMENT（DDL）
- [ ] 类型/约束变更在注释中说明（迁移场景）
- [ ] 每个关键 SQL 段落有行内注释
- [ ] 调度参数使用 `${param}` 格式
- [ ] 风险点已注明
- [ ] 无裸 SQL、无多行 COMMENT
- [ ] 文件头与第一行可执行 SQL 之间有空行
