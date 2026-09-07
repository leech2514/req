# 21 DataWorks 数据开发

## 21.1 节点类型

| 类型 | 用途 | 备注 |
|------|------|------|
| ODPS SQL | 执行 MC SQL | 最常用 |
| ODPS MR | MapReduce | 复杂 ETL |
| ODPS Spark | Spark 作业 | 复杂计算 |
| Shell | 脚本任务 | 系统操作 |
| PyODPS | Python + MC | 数据处理 |
| Java | Java 程序 | 自定义逻辑 |
| 数据集成 | 同步任务 | 见 20 |
| 虚拟节点 | 占位/聚合 | 不执行 |
| Do-While | 循环 | 重复执行 |
| 分支节点 | 条件分支 | 动态调度 |
| 归并节点 | 多分支合并 | |
| SQL Component | SQL 组件复用 | |
| 临时查询 | 临时 SQL | 不调度 |

## 21.2 SQL 节点开发

### 基本结构
```sql
-- 调度参数引用
SELECT
    col1,
    col2,
    '${bizdate}' AS bizdate,
    ${bizhour} AS bizhour
FROM table_name
WHERE ds = '${bizdate}';
```

### 开发流程
1. 选择节点类型
2. 编写代码
3. 选择目标表
4. 配置调度参数
5. 调度配置
6. 测试运行
7. 提交发布

### 代码检查
- SQL 语法检查
- 安全检查（防全表扫描）
- 规范检查

## 21.3 PyODPS 节点

```python
import os

# 获取调度参数
bizdate = args['bizdate']
print(f'bizdate: {bizdate}')

# 使用 odps 内置对象
sql = f'''
SELECT * FROM orders
WHERE ds = '{bizdate}'
'''

with odps.execute_sql(sql).open_reader() as reader:
    for record in reader:
        print(record)
```

## 21.4 Shell 节点

```bash
#!/bin/bash
echo "Start: $(date)"

# 业务逻辑
curl -X POST https://api.example.com/trigger

echo "End: $(date)"
```

## 21.5 业务流程

### 概念
- 节点的逻辑分组
- 便于管理与可视化
- 不影响调度依赖

### 操作
- 拖拽节点到流程
- 连线建立依赖
- 配置流程参数

## 21.6 临时查询

- 不参与调度
- 用于开发调试
- 结果可视化展示
- 可保存为草稿

## 21.7 SQL 组件

### 概念
- 可复用的 SQL 片段
- 参数化
- 类似函数

### 示例
```sql
-- 组件定义
SELECT * FROM ${table_name} WHERE ds = '${bizdate}'

-- 调用
${component_name}(table_name='orders', bizdate='20260813')
```

## 21.8 最佳实践

- SQL 必须带分区过滤
- 避免全表扫描
- 关键字段加注释
- 复杂逻辑拆分多节点
- 使用 SQL 组件提升复用
- 开发后必须测试再发布

## 21.9 学习要点

- [ ] 熟悉各节点类型的应用场景
- [ ] 掌握 SQL 节点的开发流程
- [ ] 能编写 PyODPS 节点
- [ ] 使用 SQL 组件提升复用
