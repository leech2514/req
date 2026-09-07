# 10 MC 数据类型与 DDL

## 10.1 数据类型体系

### 基本类型
| 类型 | 说明 | 示例 |
|------|------|------|
| `TINYINT` | 1 字节整数 | 1 |
| `SMALLINT` | 2 字节整数 | 1 |
| `INT` | 4 字节整数 | 1 |
| `BIGINT` | 8 字节整数 | 1 |
| `FLOAT` | 单精度浮点 | 1.0 |
| `DOUBLE` | 双精度浮点 | 1.0 |
| `DECIMAL(p,s)` | 精确数值，p≤38 | 1.00 |
| `BOOLEAN` | 布尔 | true |
| `STRING` | 字符串（无长度限制） | "abc" |
| `VARCHAR(n)` | 变长字符串 | "abc" |
| `CHAR(n)` | 定长字符串 | "abc" |
| `BINARY` | 二进制 | - |
| `DATE` | 日期 | 2026-08-13 |
| `DATETIME` | 日期时间（无时区） | 2026-08-13 10:00:00 |
| `TIMESTAMP` | 时间戳（带时区） | 2026-08-13 10:00:00.000 |

### 复杂类型
| 类型 | 说明 | 示例 |
|------|------|------|
| `ARRAY<T>` | 数组 | `[1,2,3]` |
| `MAP<K,V>` | 键值对 | `{"a":1}` |
| `STRUCT<...>` | 结构体 | `named_struct("a",1)` |

## 10.2 DDL - 建表语法

### 基本建表
```sql
CREATE TABLE IF NOT EXISTS table_name (
    col1 BIGINT COMMENT '字段说明',
    col2 STRING COMMENT '字段说明',
    col3 DECIMAL(18,2) COMMENT '金额'
)
COMMENT '表说明'
PARTITIONED BY (ds STRING COMMENT '分区字段')
LIFECYCLE 365;
```

### 分桶表
```sql
CREATE TABLE table_name (...)
PARTITIONED BY (ds STRING)
CLUSTERED BY (col1) SORTED BY (col2) INTO 32 BUCKETS;
```

### 外部表（OSS）
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS table_name (
    col1 STRING
)
STORED AS ORC
LOCATION 'oss://bucket/path/';
```

## 10.3 视图

### 普通视图
```sql
CREATE VIEW IF NOT EXISTS view_name AS
SELECT col1, col2 FROM table_name WHERE col3 > 0;
```

### 物化视图
```sql
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_name
LIFECYCLE 7
AS SELECT col1, COUNT(*) FROM table_name GROUP BY col1;
```

## 10.4 表操作

```sql
-- 删除表
DROP TABLE IF EXISTS table_name;

-- 修改表注释
ALTER TABLE table_name SET COMMENT '新注释';

-- 增加字段
ALTER TABLE table_name ADD COLUMNS (new_col STRING COMMENT '新字段');

-- 修改字段
ALTER TABLE table_name CHANGE COLUMN old_col new_col STRING COMMENT '说明';

-- 删除分区
ALTER TABLE table_name DROP IF EXISTS PARTITION (ds='20260101');

-- 合并分区
ALTER TABLE table_name MERGE PARTITION ...
```

## 10.5 注意事项

- 分区字段 **不** 出现在字段定义中
- 单表分区数上限 6 万
- VARCHAR 单字段长度上限 8MB（建议长文本用 STRING）
- DECIMAL 精度上限 38
- 不支持主键、外键、索引（概念不同）
- DDL 是 **不可回滚** 的（DROP/ALTER 慎用）

## 10.6 学习要点

- [ ] 区分内部表与外部表的使用场景
- [ ] 理解分区与分桶的区别
- [ ] 熟悉物化视图的查询改写机制
- [ ] 掌握 ALTER 的限制（不支持删字段、改类型有限制）
