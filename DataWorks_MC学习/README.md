# DataWorks + MaxCompute 学习笔记

> 本目录用于系统学习阿里云 DataWorks 与 MaxCompute 的知识体系，为迁移工作提供理论支撑。

## 目录索引

### 入门基础
| 序号 | 文档 | 主题 |
|------|------|------|
| 01 | [MaxCompute 概览](./01_MaxCompute概览.md) | 定位、架构、核心概念 |
| 02 | [DataWorks 概览](./02_DataWorks概览.md) | 平台能力、模块组成、工作空间 |
| 03 | [核心概念术语表](./03_核心概念术语表.md) | Project/Table/Partition/Node/资源组 等 |

### MaxCompute 核心
| 序号 | 文档 | 主题 |
|------|------|------|
| 10 | [MC 数据类型与 DDL](./10_MC数据类型与DDL.md) | 类型系统、建表、分区、视图 |
| 11 | [MC SQL 语法](./11_MC_SQL语法.md) | SELECT/JOIN/子查询/CTE |
| 12 | [MC 内建函数](./12_MC内建函数.md) | 数学/字符串/日期/聚合/窗口 |
| 13 | [MC 分区与分桶](./13_MC分区与分桶.md) | 分区设计、分桶、聚簇 |
| 14 | [MC 物化视图](./14_MC物化视图.md) | MV 创建、查询改写、刷新 |
| 15 | [MC UDF/Python](./15_MC_UDF与Python.md) | 自定义函数、PyODPS |
| 16 | [MC 权限模型](./16_MC权限模型.md) | ACL/Policy/RBAC/Package |

### DataWorks 核心
| 序号 | 文档 | 主题 |
|------|------|------|
| 20 | [DataWorks 数据集成](./20_DataWorks数据集成.md) | 离线/实时同步、数据源、解决方案 |
| 21 | [DataWorks 数据开发](./21_DataWorks数据开发.md) | 节点类型、SQL/Shell/PyODPS |
| 22 | [DataWorks 调度配置](./22_DataWorks调度配置.md) | 周期、依赖、参数、基线 |
| 23 | [DataWorks 数据建模](./23_DataWorks数据建模.md) | 规范建模、维度建模、数据地图 |
| 24 | [DataWorks 数据治理](./24_DataWorks数据治理.md) | 数据质量、血缘、资产、安全 |
| 25 | [DataWorks 运维监控](./25_DataWorks运维监控.md) | 任务运维、告警、补数据 |

### 实战进阶
| 序号 | 文档 | 主题 |
|------|------|------|
| 30 | [数仓分层与建模实践](./30_数仓分层与建模实践.md) | ODS/DWD/DWS/ADS/DIM 设计 |
| 31 | [性能优化最佳实践](./31_性能优化最佳实践.md) | SQL 优化、表设计、资源调优 |
| 32 | [实时数仓与 Flink](./32_实时数仓与Flink.md) | Realtime Compute for Flink |
| 33 | [Lakehouse 湖仓一体](./33_Lakehouse湖仓一体.md) | MC + OSS + DLF |
| 34 | [常见场景案例](./34_常见场景案例.md) | 用户画像、订单分析、AB 实验 |

## 学习路径建议

### 第 1 阶段：概念建立（1 周）
1. 通读 01、02、03 建立整体认知
2. 官方文档：MaxCompute 产品概述、DataWorks 产品概述

### 第 2 阶段：MC 深入（2 周）
1. 学习 10-16 系列
2. 在沙箱环境练习 DDL/DML/函数
3. 完成 1 个简单数仓 demo

### 第 3 阶段：DataWorks 实战（2 周）
1. 学习 20-25 系列
2. 完成一个端到端数据流：源头 → ODS → DWD → ADS → 报表
3. 配置调度、参数、基线

### 第 4 阶段：迁移应用（持续）
1. 学习 30-34 系列
2. 结合迁移项目，应用最佳实践
3. 持续补充实战笔记

## 参考资源

- [MaxCompute 官方文档](https://help.aliyun.com/product/27797.html)
- [DataWorks 官方文档](https://help.aliyun.com/product/30254.html)
- [阿里云大数据学院](https://edu.aliyun.com)
- [MaxCompute 开发者社区](https://developer.aliyun.com/group/maxcompute)
