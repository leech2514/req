# 02 SQL 语法与函数差异

## 2.1 总体差异

- Xihe SQL 接近 **Presto/Trino** 语法
- MaxCompute SQL 接近 **Hive SQL** 语法
- 两者在 DDL/DML/函数命名上均有差异

## 2.2 关键语法差异

| 场景 | Xihe (Presto-like) | MaxCompute (Hive-like) | 备注 |
|------|-------------------|----------------------|------|
| 字符串引号 | 单引号 | 单引号 | 一致 |
| 标识符引号 | 双引号 | 反引号 | **需替换** |
| NULL 判断 | `IS NULL` | `IS NULL` | 一致 |
| 字符串拼接 | `||` 或 `concat()` | `concat()` | `||` 不支持 |
| 类型转换 | `CAST(x AS type)` | `CAST(x AS type)` | 类型名不同 |
| LIMIT | `LIMIT n` | `LIMIT n` | 一致 |
| 子查询别名 | 可省略 | 部分场景必须 | 注意补齐 |

## 2.3 函数差异清单

### 字符串函数
| 功能 | Xihe | MaxCompute |
|------|------|-----------|
| 长度 | `length()` | `length()` / `char_length()` |
| 大小写 | `lower()/upper()` | `lower()/upper()` |
| 分割 | `split()` | `split()` / `split_part()` |
| 替换 | `replace()` | `replace()` |
| 正则 | `regexp_like()` | `regexp()` / `regexp_extract()` |

### 日期函数
| 功能 | Xihe | MaxCompute |
|------|------|-----------|
| 当前时间 | `now()` | `getdate()` / `now()` |
| 日期差 | `date_diff()` | `datediff()` |
| 加减 | `date_add()` | `dateadd()` |
| 格式化 | `date_format()` | `date_format()` |
| 截取 | `date_trunc()` | `trunc()` / `date_trunc()` |

### 聚合/窗口函数
- 窗口函数语法基本一致：`OVER (PARTITION BY ... ORDER BY ...)`
- 注意 **窗口范围** 子句 `ROWS BETWEEN` 在 MC 中部分场景行为不同

## 2.4 注意事项

- [ ] Xihe 的 `array`/`map` 类型操作与 MC 的 UDT/复杂数据类型有差异
- [ ] 时间戳时区：Xihe 默认 UTC，MC 默认项目时区（需确认）
- [ ] 隐式类型转换规则不同，建议统一显式 CAST
- [ ] 大小写敏感性：MC 表/字段名小写敏感，需统一命名规范
