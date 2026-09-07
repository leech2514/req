# 01 MaxCompute 概览

## 1.1 产品定位

MaxCompute（原 ODPS，Open Data Processing Service）是阿里云自研的 **企业级 SaaS 模式云数据仓库**，自 2009 年起支撑阿里集团内部双 11 等核心场景，2009 年后对外商用。

核心能力：
- 海量数据仓库（PB 级存储与计算）
- 离线批处理 + 准实时交互式分析
- 多种计算模型（SQL / MapReduce / Graph / Spark / Mars）
- 与 DataWorks 深度集成的开发治理能力

## 1.2 核心特性

| 特性 | 说明 |
|------|------|
| 分布式存储 | 跨多节点存储，自动容错，三副本冗余 |
| 分布式计算 | 自研 DAG 执行引擎 + C++ Volt 优化器 |
| 多租户 | 项目（Project）隔离 + 工作空间 |
| SQL 兼容 | Hive-like 语法，扩展了窗口/复杂数据类型 |
| Serverless | 用户无需运维集群，按需/包年付费 |
| 生态集成 | 与 DataWorks、Flink、PAI、Hologres 深度集成 |
| 安全合规 | 多种权限模型 + 数据保护伞 + 存储加密 |

## 1.3 架构层次

```
┌──────────────────────────────────────────────┐
│     客户端 / SDK / JDBC / DataWorks IDE      │
├──────────────────────────────────────────────┤
│     计算层（SQL/MR/Graph/Spark/Mars/ML）       │
│     ├─ LLVM-based Volt 执行引擎              │
│     ├─ CBO 优化器                            │
│     └─ 动态 DAG 调度                         │
├──────────────────────────────────────────────┤
│     元数据层（Catalog / Tunnel / Schema）     │
├──────────────────────────────────────────────┤
│     存储层（盘古分布式文件系统）               │
│     ├─ 列式存储（DWARF / ORC / Parquet）      │
│     ├─ 自动压缩 + 索引                       │
│     └─ 多副本容错                            │
├──────────────────────────────────────────────┤
│     底层基础设施（盘古存储 / 伏羲调度）        │
└──────────────────────────────────────────────┘
```

### 关键自研技术
- **盘古（Pangu）**：分布式文件系统，提供高可靠存储
- **伏羲（Fuxi）**：资源调度与作业调度系统
- **女娲（Nuwa）**：服务发现与配置管理
- **伏羲 Job Scheduler**：DAG 作业调度
- **Volt**：基于 LLVM 的 C++ 执行引擎，性能远超 Java 实现

## 1.4 核心概念

| 概念 | 说明 |
|------|------|
| Project | 项目空间，最大隔离单位 |
| Table | 表，分为内部表与外部表 |
| Partition | 分区，逻辑数据划分 |
| Resource | 资源（jar/py/file） |
| Function | 函数（内建/UDF） |
| Instance | 任务执行实例 |
| Tunnel | 数据上传下载通道 |
| Schema | 新版本中的命名空间（Project 下细分） |

## 1.5 计算模型

- **SQL**：最常用，覆盖 90% 场景，支持 Hive-like 语法 + 扩展
- **MapReduce**：Java MR 作业，复杂 ETL（逐步被 Spark 替代）
- **Graph**：图计算框架
- **Spark on MaxCompute**：托管 Spark，兼容原生 API
- **Mars**：基于 GPU 的科学计算库（兼容 numpy/pandas）
- **MCQA（交互式分析）**：秒级响应的查询模式
- **Hologres 联邦查询**：行存实时查询

## 1.6 与其他产品关系

- **DataWorks**：开发治理平台，MC 的"IDE"
- **Flink**：实时计算，可与 MC 联动（实时写 MC Delta 表）
- **PAI**：机器学习，直接读 MC 数据训练
- **DLF**：数据湖构建，MC 通过外部表访问 OSS
- **Hologres**：实时数仓，可与 MC 元数据共享
- **Quick BI**：BI 工具，直连 MC 出报表

---

## 1.7 MaxCompute vs Hive vs Spark 对比

### 1.7.1 总体定位对比

| 维度 | MaxCompute | Hive | Spark |
|------|-----------|------|-------|
| 产品形态 | 云原生 SaaS 数仓 | 开源数据仓库引擎 | 开源统一分析引擎 |
| 起源 | 阿里自研（2009） | Facebook（2008） | UC Berkeley（2010） |
| 部署方式 | 全托管，免运维 | 自建集群 | 自建集群 / 托管（EMR） |
| 主要场景 | 离线数仓、湖仓一体 | 离线数仓 | 批处理、流处理、ML |
| 语言 | SQL + Java/Python UDF | SQL（HiveQL） | SQL + Scala/Python/Java/R |
| 元数据 | 内置 Catalog | Hive Metastore | 与 Hive Metastore 共用 |
| 存储 | 盘古（内置） | HDFS | HDFS / 对象存储 |
| 调度 | 伏羲 | YARN | YARN / K8s |

### 1.7.2 引擎性能对比

| 维度 | MaxCompute | Hive | Spark |
|------|-----------|------|-------|
| 执行引擎 | C++ Volt（LLVM） | Tez / MapReduce | Catalyst + Tungsten |
| 执行计划 | CBO + RBO | RBO 为主 | CBO |
| 代码生成 | LLVM 编译 | 字节码 | Whole-stage CodeGen |
| 内存管理 | 自管 | 依赖 JVM | 自管（堆外） |
| Shuffle 优化 | 伏羲原生优化 | 通用 Shuffle | Sort Shuffle / Push Shuffle |
| 单查询性能 | 最快（自研优化） | 较慢 | 较快 |
| 大规模稳定性 | 强（双 11 验证） | 一般 | 受 JVM 影响 |

### 1.7.3 SQL 语法对比

| 特性 | MaxCompute | Hive | Spark SQL |
|------|-----------|------|-----------|
| 标识符引号 | 反引号 `` ` `` | 反引号 | 反引号 |
| 字符串拼接 | `concat()` | `concat()` / `\|\|` | `concat()` / `\|\|` |
| 类型转换 | `CAST` | `CAST` | `CAST` |
| 日期差 | `datediff(d1,d2,'dd')` | `datediff(d1,d2)` | `datediff(end,start)` |
| 当前时间 | `getdate()` / `now()` | `current_timestamp` | `current_timestamp` |
| 子查询 IN | 支持 | 支持 | 支持 |
| CTE | 支持 | 支持 | 支持 |
| 窗口函数 | 完整 | 完整 | 完整 |
| MAPJOIN | `/*+ MAPJOIN */` | `/*+ MAPJOIN */` | 自动 Broadcast |
| LEFT SEMI JOIN | 支持 | 支持 | 支持 |
| 动态分区 | 支持 | 支持 | 支持 |
| INSERT 多路 | 支持 | 支持 | 支持 |
| 物化视图 | 原生 + 自动改写 | 3.0+ 支持 | 不支持自动改写 |

### 1.7.4 存储与表特性

| 特性 | MaxCompute | Hive | Spark |
|------|-----------|------|-------|
| 内部表 | 支持 | 支持 | 支持 |
| 外部表 | 支持（OSS/Hologres） | 支持（HDFS） | 支持 |
| 分区表 | 支持（≤6万分区） | 支持 | 支持 |
| 分桶 | 支持（CLUSTERED BY） | 支持 | 支持 |
| 主键 | 不支持（业务保证） | 不支持 | 不支持 |
| 索引 | 不支持（靠分区/分桶） | 支持（有限） | 不支持 |
| 物化视图 | 原生 + 自动改写 | 3.0+ | 不支持 |
| ACID 事务 | 支持（Delta 表） | 0.14+ | Delta Lake / Iceberg |
| 存储格式 | DWARF（默认）/ ORC | Text/ORC/Parquet | Parquet/ORC |
| 压缩 | 自动 | 手动配置 | 手动配置 |
| 生命周期 | `LIFECYCLE n` 自动回收 | 无原生支持 | 无原生支持 |

### 1.7.5 资源与调度对比

| 维度 | MaxCompute | Hive | Spark |
|------|-----------|------|-------|
| 资源模型 | Serverless，按需 | YARN 队列 | YARN/K8s 队列 |
| 资源隔离 | Project + 工作空间 | 队列 | 队列 |
| 多租户 | 原生支持 | 依赖 YARN | 依赖 YARN |
| 优先级 | 支持任务优先级 | 队列优先级 | 队列优先级 |
| 弹性伸缩 | 自动 | 手动扩容 | 手动扩容 |
| 并发控制 | 自动 | 依赖 YARN | 依赖 YARN |
| 任务排队 | 内置 | YARN 调度 | YARN 调度 |

### 1.7.6 开发与运维对比

| 维度 | MaxCompute | Hive | Spark |
|------|-----------|------|-------|
| 开发工具 | DataWorks（一站式） | Hive CLI / Beeline | spark-sql / Notebook |
| 调度 | DataWorks 调度 | Airflow / DolphinScheduler | Airflow / DolphinScheduler |
| 元数据 | 数据地图 + 血缘 | Hive Metastore | Hive Metastore |
| 监控 | DataWorks 治理大盘 | 自建 | 自建 |
| 权限管理 | ACL/RBAC/Policy/Package | SQL Grant | SQL Grant |
| 数据安全 | 数据保护伞 + 脱敏 | Ranger | Ranger |
| 成本 | 按量/包年 | 自建集群成本 | 自建集群成本 |

### 1.7.7 适用场景对比

#### MaxCompute 适合
- ✅ 阿里云生态内的离线数仓
- ✅ 不想运维集群的团队
- ✅ PB 级数据规模
- ✅ 规范化数仓开发（配合 DataWorks）
- ✅ 对稳定性要求高（金融、电商）

#### Hive 适合
- ✅ 已有 Hadoop 集群
- ✅ 完全开源栈
- ✅ 自主可控需求
- ✅ 与 HDFS 生态深度集成

#### Spark 适合
- ✅ 批流统一处理
- ✅ 机器学习 / 图计算
- ✅ 内存计算场景
- ✅ 多语言开发（Scala/Python）
- ✅ 与开源生态（Delta/Iceberg）结合

### 1.7.8 性能基准参考

> 注：以下为经验性参考，实际性能受数据量、SQL 复杂度、集群规格影响。

| 场景 | MaxCompute | Hive (Tez) | Spark SQL |
|------|-----------|------------|-----------|
| 1TB 全表 COUNT | ~10s | ~60s | ~30s |
| 1TB 聚合 GROUP BY | ~30s | ~120s | ~60s |
| 10TB JOIN 1GB | ~60s | ~300s | ~150s |
| 复杂多表 JOIN | CBO 优化最优 | 较慢 | 较快 |
| 实时小查询 | MCQA 秒级 | 分钟级 | 秒级 |
| 高并发查询 | 优秀 | 受限 | 受限 |

### 1.7.9 迁移自 Hive 的注意事项

如果之前用 Hive，迁移到 MaxCompute 时关注：
- 标识符引号：一致（反引号）
- 字符串拼接：`\|\|` 不支持，改 `concat()`
- 日期函数：参数与返回值有差异，需逐个核对
- UDF：Hive UDF 不能直接复用，需重新打包上传
- 集群概念消失：不再关心 YARN 队列、HDFS 路径
- 资源管理：从"队列分配"改为"资源组 + Serverless"
- 数据搬迁：通过 OSS 中转或 DataWorks 数据集成

### 1.7.10 迁移自 Spark 的注意事项

如果之前用 Spark，迁移到 MaxCompute 时关注：
- Spark SQL 大部分可平迁，注意函数差异
- DataFrame API 改用 PyODPS 或 Spark on MC
- 流处理：Structured Streaming → Flink on MC
- ML：Spark MLlib → PAI
- 自建集群运维 → 全托管，成本模型变化

---

## 1.8 学习要点

- [ ] 理解 Project/Table/Partition 三级结构
- [ ] 区分内部表与外部表的使用场景
- [ ] 了解 Tunnel 与 SQL 两种数据进出方式
- [ ] 掌握 MC 与 DataWorks 的协作关系
- [ ] 对比 MC 与 Hive/Spark 的差异，明确选型依据
- [ ] 理解 Serverless 与自建集群的本质区别
