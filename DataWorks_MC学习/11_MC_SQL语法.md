# 11 MC SQL 语法

## 11.1 SELECT 基础

```sql
SELECT
    col1,
    col2,
    col3 AS alias
FROM table_name
WHERE col1 > 0
  AND col2 LIKE 'abc%'
GROUP BY col1
HAVING COUNT(*) > 1
ORDER BY col1 DESC
LIMIT 100;
```

## 11.2 JOIN

### 支持类型
- `INNER JOIN`
- `LEFT [OUTER] JOIN`
- `RIGHT [OUTER] JOIN`
- `FULL [OUTER] JOIN`
- `CROSS JOIN`
- `LEFT SEMI JOIN`（MC 特有，类似 IN）
- `LEFT ANTI JOIN`（MC 特有，类似 NOT IN）

### 语法
```sql
SELECT a.id, b.name
FROM table_a a
JOIN table_b b ON a.id = b.id
WHERE a.ds = '${bizdate}';
```

### MAPJOIN（小表广播）
```sql
SELECT /*+ MAPJOIN(b) */ a.id, b.name
FROM big_table a
JOIN small_table b ON a.id = b.id;
```

## 11.3 子查询

### 标量子查询
```sql
SELECT id, (SELECT MAX(amount) FROM orders WHERE uid = t.id) max_amt
FROM users t;
```

### IN / EXISTS
```sql
SELECT * FROM users
WHERE id IN (SELECT uid FROM orders WHERE ds='${bizdate}');

SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.uid = u.id);
```

## 11.4 CTE（WITH 子句）

```sql
WITH active_users AS (
    SELECT id FROM users WHERE status = 1
),
big_orders AS (
    SELECT uid, SUM(amount) total
    FROM orders
    GROUP BY uid
    HAVING SUM(amount) > 1000
)
SELECT a.id, b.total
FROM active_users a
JOIN big_orders b ON a.id = b.uid;
```

## 11.5 窗口函数

```sql
SELECT
    uid,
    ds,
    amount,
    ROW_NUMBER() OVER (PARTITION BY uid ORDER BY ds DESC) rn,
    SUM(amount) OVER (PARTITION BY uid ORDER BY ds
                      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) cum_amt,
    LAG(amount, 1) OVER (PARTITION BY uid ORDER BY ds) prev_amt
FROM orders;
```

## 11.6 集合操作

```sql
-- UNION（去重）
SELECT col1 FROM t1 UNION SELECT col1 FROM t2;

-- UNION ALL（不去重）
SELECT col1 FROM t1 UNION ALL SELECT col1 FROM t2;

-- INTERSECT / MINUS
SELECT col1 FROM t1 INTERSECT SELECT col1 FROM t2;
SELECT col1 FROM t1 MINUS SELECT col1 FROM t2;
```

## 11.7 DML

### INSERT
```sql
INSERT OVERWRITE TABLE target PARTITION (ds='${bizdate}')
SELECT col1, col2 FROM source WHERE ds='${bizdate}';
```

### INSERT INTO（追加）
```sql
INSERT INTO TABLE target PARTITION (ds='${bizdate}')
SELECT col1, col2 FROM source;
```

### 多路 INSERT
```sql
FROM source
INSERT OVERWRITE TABLE t1 SELECT col1 WHERE col2 > 0
INSERT OVERWRITE TABLE t2 SELECT col1 WHERE col2 <= 0;
```

### 动态分区
```sql
INSERT OVERWRITE TABLE target PARTITION (ds)
SELECT col1, ds FROM source;
```

## 11.8 注意事项

- 默认 **不能** 在 IN 子查询中直接用分区字段过滤
- ORDER BY 在分布式场景下是 **全局排序**，慎用
- 字符串连接用 `concat()`，不支持 `||`
- 类型转换用 `CAST(x AS type)`
- SQL 大小写不敏感（关键字），表/字段名大小写敏感

## 11.9 学习要点

- [ ] 熟悉 LEFT SEMI / LEFT ANTI JOIN 的应用场景
- [ ] 掌握 MAPJOIN 优化小表 JOIN
- [ ] 理解动态分区写入
- [ ] 熟练使用窗口函数解决 TopN、累计、同比环比
