# 32 实时数仓与 Flink

## 32.1 实时数仓架构

```
源头（MySQL binlog / 日志）
    ↓
DataHub / Kafka（消息中间件）
    ↓
Realtime Compute for Flink（实时计算）
    ↓
MaxCompute / Hologres / MySQL（存储）
    ↓
BI / 应用
```

## 32.2 Realtime Compute for Flink

### 定位
- 阿里云实时计算引擎
- 全托管 Flink 服务
- 与 DataWorks 集成

### 特性
- SQL 开发
- 流批一体
- 状态管理
- 精确一次语义

## 32.3 实时数仓分层

```
ODS（实时入湖）→ DWD（实时清洗）→ DWS（实时汇总）→ ADS（实时应用）
```

### 存储选择
| 层 | 推荐 | 说明 |
|----|------|------|
| ODS | DataHub / MC Delta | 流式存储 |
| DWD | Hologres / MC | 支持更新 |
| DWS | Hologres / MySQL | 高频查询 |
| ADS | MySQL / Redis | 实时服务 |

## 32.4 Flink SQL 示例

### 源表
```sql
CREATE TABLE source_table (
    id BIGINT,
    user_id BIGINT,
    amount DECIMAL(18,2),
    ts TIMESTAMP(3),
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'datahub',
    'endpoint' = '...',
    'project' = '...',
    'topic' = '...'
);
```

### 结果表
```sql
CREATE TABLE result_table (
    ds STRING,
    user_id BIGINT,
    total_amount DECIMAL(18,2),
    PRIMARY KEY (ds, user_id) NOT ENFORCED
) WITH (
    'connector' = 'maxcompute',
    ...
);
```

### 实时聚合
```sql
INSERT INTO result_table
SELECT
    DATE_FORMAT(ts, 'yyyyMMdd') ds,
    user_id,
    SUM(amount) total_amount
FROM source_table
GROUP BY DATE_FORMAT(ts, 'yyyyMMdd'), user_id;
```

## 32.5 窗口函数

### 滚动窗口
```sql
SELECT
    user_id,
    TUMBLE_START(ts, INTERVAL '1' MINUTE) window_start,
    COUNT(*) cnt
FROM source_table
GROUP BY user_id, TUMBLE(ts, INTERVAL '1' MINUTE);
```

### 滑动窗口
```sql
SELECT
    user_id,
    HOP_START(ts, INTERVAL '30' SECOND, INTERVAL '1' MINUTE) window_start,
    COUNT(*) cnt
FROM source_table
GROUP BY user_id, HOP(ts, INTERVAL '30' SECOND, INTERVAL '1' MINUTE);
```

### 会话窗口
```sql
SELECT
    user_id,
    SESSION_START(ts, INTERVAL '5' MINUTE) window_start,
    COUNT(*) cnt
FROM source_table
GROUP BY user_id, SESSION(ts, INTERVAL '5' MINUTE);
```

## 32.6 实时数仓与离线数仓协同

### Lambda 架构
- 实时层：Flink + Hologres
- 离线层：DataWorks + MC
- 合并服务层

### Kappa 架构
- 全部基于流处理
- 重新消费历史数据

### 混合模式（推荐）
- 离线为主，实时为辅
- 实时计算当日指标
- 离线修正历史数据

## 32.7 注意事项

- 实时计算成本高
- 状态管理复杂
- 数据一致性保证（精确一次）
- 延迟与吞吐权衡

## 32.8 学习要点

- [ ] 理解实时数仓架构
- [ ] 掌握 Flink SQL 基本语法
- [ ] 熟悉窗口函数
- [ ] 评估实时 vs 离线
