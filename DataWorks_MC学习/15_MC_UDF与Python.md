# 15 MC UDF 与 Python

## 15.1 UDF 类型

| 类型 | 说明 | 输入 → 输出 |
|------|------|------------|
| UDF | 普通函数 | 1 行 → 1 行 |
| UDAF | 聚合函数 | N 行 → 1 行 |
| UDTF | 表生成函数 | 1 行 → N 行 |

## 15.2 Java UDF 示例

### 编写
```java
package com.aliyun.odps.udf;
import com.aliyun.odps.udf.UDF;

public class LowerUDF extends UDF {
    public String evaluate(String s) {
        if (s == null) return null;
        return s.toLowerCase();
    }
}
```

### 打包上传
1. Maven 打包为 jar
2. DataWorks 上传资源（jar）
3. 创建函数

### 注册函数
```sql
CREATE FUNCTION lower_udf AS 'com.aliyun.odps.udf.LowerUDF'
USING 'lower_udf.jar';
```

### 使用
```sql
SELECT lower_udf(col_name) FROM table_name;
```

## 15.3 Python UDF（PyODPS）

### 安装
```bash
pip install pyodps
```

### Python UDF 示例
```python
from odps.udf import annotate

@annotate("string->string")
class LowerUDF(object):
    def evaluate(self, s):
        if s is None:
            return None
        return s.lower()
```

## 15.4 PyODPS 编程

### 连接 MC
```python
from odps import ODPS
o = ODPS('<access_id>', '<access_key>', project='<project>', endpoint='<endpoint>')
```

### 执行 SQL
```python
with o.execute_sql('SELECT * FROM dual').open_reader() as reader:
    for record in reader:
        print(record)
```

### DataFrame API
```python
from odps.df import DataFrame
df = DataFrame(o.get_table('orders'))
result = df[df.ds == '20260813'].groupby('user_id').agg(
    order_cnt=df.order_id.count(),
    total=df.amount.sum()
)
print(result.head(10))
```

### 上传下载数据
```python
# 上传
o.execute_sql('INSERT ...')

# Tunnel 下载
with o.get_table('orders').open_reader(partition='ds=20260813') as reader:
    for record in reader:
        print(record)
```

## 15.5 DataWorks 中的 Python 节点

- 创建 PyODPS 节点
- 内置 `odps` 对象
- 可调度执行

```python
# DataWorks PyODPS 节点
import os
print(os.environ.get('SKYNET_BIZDATE'))

# 使用 odps 内置对象
with odps.execute_sql('SELECT * FROM dual').open_reader() as r:
    for rec in r:
        print(rec)
```

## 15.6 应用场景

- 复杂字符串处理（内建函数不足）
- 自定义聚合逻辑
- 机器学习预处理
- 跨表复杂业务逻辑

## 15.7 注意事项

- UDF 性能低于内建函数，能用内建函数优先用
- Java UDF 性能优于 Python
- UDF jar 大小限制（一般 ≤ 500MB）
- UDF 不能访问网络（沙箱限制）

## 15.8 学习要点

- [ ] 区分 UDF/UDAF/UDTF
- [ ] 能编写简单 Java/Python UDF
- [ ] 掌握 PyODPS 基本操作
- [ ] 理解 UDF 的性能代价
