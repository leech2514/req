# 海南正堂担保报送 DMS → MaxCompute 迁移项目

> 海南正堂担保业务监管报送脚本的迁移工程：将 DMS 平台（MySQL 语法）脚本改造为 DataWorks + MaxCompute 可执行脚本。

## 项目背景

- **源平台**：阿里云 DMS（MySQL 语法 + Spark/Hologres 引擎）
- **目标平台**：阿里云 DataWorks + MaxCompute
- **业务域**：海南正堂车贷担保监管报送（G11/G23/G23_1/G23_2/G27/G28 等报表）
- **目标**：将原 DMS 脚本按 MaxCompute 语法与 Delta 事务表特性重构，支持月度调度幂等写入

## 目录结构

```
e:\project\req\
├── README.md                            # 本文件
├── .gitignore                           # 忽略 *.cnf（凭据）、*.csv（客户 PII）、IDE/日志文件
│
├── convention/                          # 项目共用规范
│   ├── 建表语句.sql                      # 全部目标表 DDL（含文件头表目录，9 大业务域分组）
│   ├── 表名映射关系.md                    # 源表 → 目标表映射清单（含分区、主键、写入模式）
│   ├── 数仓表命名规范.md                  # 分层与表名命名规范
│   ├── MaxCompute_SQL注释规范.md         # SQL 脚本头注释规范
│   └── prompt.txt                        # 迁移提示词模板
│
└── HN/                                   # 海南正堂业务脚本
    ├── DMS/                              # 源脚本（DMS/MySQL 语法，保留原貌）
    │   ├── AUTO/                         # 月度自动报送源脚本
    │   │   ├── old_auto_G11.sql   ... old_auto_G28.sql   (6 个)
    │   ├── CONS/                         # 历史归档（手工维护版本）
    │   │   ├── old_G11.sql       ... old_G28.sql         (6 个)
    │   │   └── old_G23_2.sql   (旧整版，已拆分)
    │   └── INS/                          # 一次性插入/视图脚本
    │       ├── dim_rpa_ddl.sql
    │       └── rpa.sql
    │
    ├── MC/                               # 目标脚本（MaxCompute 语法）
    │   ├── AUTO/                         # 月度增量报送脚本（本次迁移主产物）
    │   │   ├── new_auto_G11.sql     # G11 融资担保公司客户信息（row_hash 比对追加）
    │   │   ├── new_auto_G23.sql     # G23 担保业务明细（动态分区 + 专项费率 UPDATE）
    │   │   ├── new_auto_G23_1.sql   # G23_1 风险分担情况（比例固定，待业务配置）
    │   │   ├── new_auto_G23_2.sql   # G23_2 解除（解保）明细（两段写入）
    │   │   ├── new_auto_G27.sql     # G27 代偿明细（仅浙融/龙正）
    │   │   └── new_auto_G28.sql     # G28 代偿回收明细（MERGE INTO 幂等）
    │   ├── CONS/                         # 早期版本归档（按 Part 分片）
    │   │   ├── new_G11.sql  new_G23.sql  new_G23_1.sql
    │   │   ├── new_G23_2_Part1/2/3.sql  new_G27.sql  new_G28.sql
    │   └── INS/                          # 手工插入与回滚脚本
    │       ├── ins_G11.sql  ins_G23.sql  rpa.sql
    │       ├── ins_G11_insert.sql  ins_G23_insert.sql  ins_G23_2_insert.sql  ins_insert.sql
    │       ├── rollback.sql              # 按主键回滚 INS 插入数据
    │       └── dw_ins_ddl.sql            # INS 目标表 DDL
    │
    └── hainanDDL/                        # 目标表 DDL 库
        ├── new_hainanDDL.sql             # 最新统一 DDL（AUTO 报送表基准）
        ├── old_hainanDDL.sql             # 旧版整库 DDL
        ├── old_G11_DDL.sql  old_G23_DDL.sql  old_G23_1.sql
```

## 核心约定

- **表名映射**：源表 → 目标表替换规则见 [convention/表名映射关系.md](./convention/表名映射关系.md)
- **目标表 DDL**：见 [convention/建表语句.sql](./convention/建表语句.sql)（含文件头目录，便于检索）
- **脚本头注释**：每个 SQL 文件含标准头注释（脚本名/层级/业务域/功能/源表/目标表/写入模式/调度周期）
- **增量写入**：
  - 普通表用 `INSERT INTO` 追加 + `row_hash` 行指纹比对（仅追加新增/变动行）
  - Delta 事务主键表用 `INSERT INTO PARTITION(pt)` 动态分区追加
  - 需幂等的场景用 `MERGE INTO`（按主键 + 分区谓词 ON）
- **分区口径**：月度分区 `pt = yyyymm`，值取业务日期所在月末月份
- **金额单位**：源表分 → 目标元（`/100` 后 `CAST AS DECIMAL(20,2)`）
- **客户 ID**：`MD5(身份证 + 'hainan')` 生成确定性唯一串

## 使用方式

### 执行顺序（每月调度）

1. `new_auto_G11.sql` → G11 客户信息增量
2. `new_auto_G23.sql` → G23 担保明细增量（含月末费率 UPDATE）
3. `new_auto_G23_1.sql` → G23_1 风险分担比例
4. `new_auto_G23_2.sql` → G23_2 解保明细（两段）
5. `new_auto_G27.sql` → G27 代偿明细
6. `new_auto_G28.sql` → G28 代偿回收明细（依赖 G27 当月分区）

### 手工补数

`HN/MC/INS/` 下脚本用于一次性历史数据补录，配套 `rollback.sql` 按主键回滚。

## 安全提示

- `*.cnf`（数据库凭据）与 `*.csv`（含客户姓名/身份证等 PII）已加入 `.gitignore`，禁止提交
- 本仓库为 Public，提交前自检是否含敏感数据

## 关键参考

- [MaxCompute 官方文档](https://help.aliyun.com/product/27797.html)
- [DataWorks 官方文档](https://help.aliyun.com/product/30254.html)
- [Delta 事务表](https://help.aliyun.com/document_detail/204579.html)
- [表名映射关系](./convention/表名映射关系.md)

---

> 文档创建日期：2026-08-13
> 最近更新：2026-09-15（重写目录结构以反映实际仓库）
