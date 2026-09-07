# ===================================================
# 脚本名称: generate_ddl.py
# 类型: 批量生成 DDL
# 功能: 根据元数据 JSON 批量生成 MaxCompute 建表 SQL
# 输入: 元数据 JSON
# 输出: 多个 DDL SQL 文件
# 负责人: <name>
# 创建日期: 2026-08-13
# ===================================================

"""
根据元数据 JSON 生成 MC DDL 脚本。

输入 JSON 格式（见 export_xihe_metadata.py 输出）:
[
  {
    "table_name": "t_order",
    "layer": "ods",
    "comment": "订单表",
    "columns": [...],
    "partitions": ["ds"],
    "lifecycle": 365
  }
]
"""

import json
import argparse
import os
from typing import Dict, List


TYPE_MAP = {
    "integer": "BIGINT",
    "bigint": "BIGINT",
    "double": "DOUBLE",
    "real": "FLOAT",
    "varchar": "STRING",
    "text": "STRING",
    "timestamp": "DATETIME",
    "date": "DATE",
    "boolean": "BOOLEAN",
    "json": "STRING",
    "decimal": "DECIMAL",
}


def normalize_type(raw: str) -> str:
    """归一化类型"""
    raw = raw.lower().strip()
    if raw.startswith("varchar") or raw.startswith("char"):
        return "STRING"
    if raw.startswith("decimal"):
        return raw.upper().replace("DECIMAL", "DECIMAL")
    return TYPE_MAP.get(raw, "STRING")


def gen_ddl(table_meta: Dict) -> str:
    """生成单张表的 DDL"""
    layer = table_meta.get("layer", "ods")
    table_name = f"{layer}_{table_meta['table_name']}_di"
    if table_meta.get("load_type") == "full":
        table_name = f"{layer}_{table_meta['table_name']}_df"

    lines = []
    lines.append(f"-- 自动生成 DDL: {table_name}")
    lines.append(f"-- 源表: {table_meta['table_name']}")
    lines.append(f"-- 说明: {table_meta.get('comment', '')}")
    lines.append("")
    lines.append(f"DROP TABLE IF EXISTS {table_name};")
    lines.append("")
    lines.append(f"CREATE TABLE IF NOT EXISTS {table_name} (")

    col_lines = []
    for col in table_meta["columns"]:
        col_type = normalize_type(col["type"])
        comment = col.get("comment", "")
        col_lines.append(f"    {col['name']:<30} {col_type:<20} COMMENT '{comment}'")
    lines.append(",\n".join(col_lines))
    lines.append(")")

    lines.append(f"COMMENT '{table_meta.get('comment', '')}'")

    partitions = table_meta.get("partitions", ["ds"])
    if partitions:
        part_lines = []
        for p in partitions:
            part_lines.append(f"    {p:<30} {'STRING':<20} COMMENT '分区字段'")
        lines.append("PARTITIONED BY (")
        lines.append(",\n".join(part_lines))
        lines.append(")")

    lifecycle = table_meta.get("lifecycle", 365)
    lines.append(f"LIFECYCLE {lifecycle}")
    lines.append(";")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="元数据 JSON 文件")
    parser.add_argument("--output-dir", default="./generated_ddl", help="输出目录")
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    with open(args.input, encoding="utf-8") as f:
        tables = json.load(f)

    for table_meta in tables:
        ddl = gen_ddl(table_meta)
        layer = table_meta.get("layer", "ods")
        filename = f"{layer}_{table_meta['table_name']}_ddl.sql"
        filepath = os.path.join(args.output_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(ddl)
        print(f"Generated: {filepath}")

    print(f"\nTotal: {len(tables)} DDL files generated.")


if __name__ == "__main__":
    main()
