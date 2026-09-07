# -*- coding: utf-8 -*-
"""
度小满 Notebook 连接配置（独立脚本，不依赖 notebook 环境也能跑）。

用法 A（推荐）：在 hainanDXM.ipynb 的第一个代码 cell 里执行：
    %run e:/project/req/DXM/DXM_notebook_setup.py
之后全局可用：
    q(sql, params, group)  -> DataFrame     # 执行 SQL
    get_conn(group)         -> Connection    # 取 pymysql 连接
    connect_magic(group)    -> None          # 切换 %%sql 的库
    print_config()          -> None          # 打印当前生效的连接参数（密码***)
用法 B：作为普通脚本运行，自检两库连通：
    python DXM_notebook_setup.py

双轨配置（任选一种，本文件开头改开关即可）：
    USE_CNF_CONFIG = True   读取 ../hainandxm.cnf（默认，密码不硬编码）
    USE_CNF_CONFIG = False  直接使用下方 DB_CONFIG 字典（纯 Python 配置）
"""
from __future__ import annotations

import configparser
import os
import re
from pathlib import Path
from typing import Any
from urllib.parse import quote_plus

import pandas as pd
import pymysql

# ==========================================================================
# ***** [可编辑区 开始] *****
# ==========================================================================

# --- 0) 双轨开关 ---
# True : 读取 cnf（密码不进本文件，默认推荐）
# False: 完全不用 cnf，直接读下方 DB_CONFIG 字典（你希望的"纯 Python 配置"模式）
USE_CNF_CONFIG = True

# --- 1) USE_CNF_CONFIG = True 时使用 ---
PROJECT_ROOT = Path(r"e:\project\req")
CNF_PATH = PROJECT_ROOT / "hainandxm.cnf"
# cnf 读出来后再叠 CONNECT_OVERRIDE；留空即完全使用 cnf。
CONNECT_OVERRIDE: dict[str, Any] = {
    # 'host': 'localhost',
    # 'port': 3308,
    # 'user': 'root',
    # 'password': '******',   # ⚠️ 改密码请去 hainandxm.cnf；仅临时切换时填
    # 'database': 'ct_dxm',
}

# --- 2) USE_CNF_CONFIG = False 时使用（完全不用 cnf，纯 Python 字典） ---
#    DATABASES 的 key = group 名称（hainandxm=正堂 / ct_dxm=昌泰），value = 实际库名。
DB_CONFIG: dict[str, Any] = {
    "host": "localhost",
    "port": 3308,
    "user": "root",
    "password": "",  # ⚠️ 纯 Python 模式需手动填入密码；优先使用 hainandxm.cnf（USE_CNF_CONFIG=True）
    "DATABASES": {
        "hainandxm": "hainandxm",
        "ct_dxm":    "ct_dxm",
    },
}

# --- 3) 默认 group：不传 group 时连哪个库 ---
DEFAULT_GROUP: str = "ct_dxm"   # 'ct_dxm' 昌泰 / 'hainandxm' 正堂

# ==========================================================================
# ***** [可编辑区 结束]  下方不需改动 *****
# ==========================================================================

_cached_conn_args: dict[str, dict[str, Any]] = {}
_cached_read_cfg_from_cnf: dict | None = None


def _read_cfg_from_cnf() -> dict[str, dict]:
    """读取 hainandxm.cnf，返回 {'client':{...}, 'client_hainandxm':{...}, ...}"""
    global _cached_read_cfg_from_cnf
    if _cached_read_cfg_from_cnf is not None:
        return _cached_read_cfg_from_cnf
    if not CNF_PATH.exists():
        raise FileNotFoundError(
            f"[DXM] USE_CNF_CONFIG=True 但找不到 {CNF_PATH}。"
            "请把 USE_CNF_CONFIG 改为 False 并在 DB_CONFIG 字典里填参数。"
        )
    cfg = configparser.ConfigParser()
    ok = cfg.read(CNF_PATH, encoding="utf-8")
    assert ok, f"读取 cnf 失败: {CNF_PATH}"
    _cached_read_cfg_from_cnf = {s: dict(cfg.items(s)) for s in cfg.sections()}
    return _cached_read_cfg_from_cnf


def _base_conn_args_by_group(group: str) -> dict[str, Any]:
    """根据 group 拿到 pymysql.connect() 的 kwargs（通用 + group 库名 + override 覆盖）。"""
    if group in _cached_conn_args:
        return _cached_conn_args[group]

    if USE_CNF_CONFIG:
        sections = _read_cfg_from_cnf()
        cli = sections.get("client", {})
        gsec = sections.get(f"client_{group}", {}) or {}
        database = gsec.get("database")
        if not database:
            raise KeyError(
                f"[DXM] cnf 里找不到 [client_{group}] 的 database 项。"
                f"请在 {CNF_PATH} 里添加 [client_{group}] 段，或把 USE_CNF_CONFIG 改为 False。"
            )
        port = int(cli.get("port", 3306))
        args = {
            "host":     cli.get("host", "localhost"),
            "port":     port,
            "user":     cli.get("user", "root"),
            "password": cli.get("password", ""),
            "database": database,
            "charset":  cli.get("default-character-set", "utf8mb4").split(",")[0],
            "cursorclass": pymysql.cursors.DictCursor,
        }
    else:
        databases = DB_CONFIG.get("DATABASES", {})
        database = databases.get(group)
        if not database:
            raise KeyError(
                f"[DXM] DB_CONFIG['DATABASES'] 里没有 group='{group}' 的条目。"
                f"现有 group：{list(databases)}"
            )
        args = {
            "host":     DB_CONFIG["host"],
            "port":     int(DB_CONFIG["port"]),
            "user":     DB_CONFIG["user"],
            "password": DB_CONFIG["password"],
            "database": database,
            "charset":  "utf8mb4",
            "cursorclass": pymysql.cursors.DictCursor,
        }

    # CONNECT_OVERRIDE 层覆盖（双轨都支持）
    for k, v in CONNECT_OVERRIDE.items():
        args[k] = v
    if isinstance(args.get("port"), str):
        args["port"] = int(args["port"])

    _cached_conn_args[group] = args
    return args


def get_conn(group: str | None = None) -> pymysql.Connection:
    """返回 pymysql 连接。group=None 走 DEFAULT_GROUP。"""
    group = group or DEFAULT_GROUP
    return pymysql.connect(**_base_conn_args_by_group(group))


def q(
    sql: str,
    params: dict | list | tuple | None = None,
    group: str | None = None,
) -> pd.DataFrame:
    """
    执行 SQL 并返回 DataFrame（参数绑定，防注入）。

    * params = dict 时，SQL 里写 `:name` 或 `%(name)s` 占位
    * params = list/tuple 时，SQL 里写 `%s` 占位
    * group = 'hainandxm' | 'ct_dxm' | None(默认)
    """
    conn = get_conn(group)
    try:
        if params is None:
            bound_sql, bound_params = sql, None
        elif isinstance(params, dict):
            # 将 `:name` 替换为 pymysql 原生支持的 `%(name)s`
            bound_sql = re.sub(r"(?<!:):([A-Za-z_][A-Za-z0-9_]*)", r"%(\1)s", sql)
            bound_params = params
        else:
            bound_sql, bound_params = sql, params
        with conn.cursor() as cur:
            cur.execute(bound_sql, bound_params)
            rows = cur.fetchall()
        return pd.DataFrame(rows)
    finally:
        conn.close()


def print_config() -> None:
    """打印当前生效的连接配置（密码脱敏）。便于肉眼确认。"""
    print("=" * 56)
    print(f"[DXM] 配置模式  : {'hainandxm.cnf + CONNECT_OVERRIDE' if USE_CNF_CONFIG else 'DB_CONFIG 字典（纯Python）'}")
    print(f"[DXM] DEFAULT_GROUP : {DEFAULT_GROUP}")
    for g in (DEFAULT_GROUP,) if False else ("hainandxm", "ct_dxm"):
        try:
            args = _base_conn_args_by_group(g)
        except Exception as ex:
            print(f"[DXM] group={g:<10} ❌ 配置异常: {ex}")
            continue
        pwd = args.get("password")
        pwd_show = "***" + str(len(pwd)) + "chars" if pwd else "(空)"
        print(
            f"[DXM] group={g:<10} -> {args['user']}@{args['host']}:{args['port']}/{args['database']}"
            f"  password={pwd_show}  charset={args.get('charset')}"
        )
    if CONNECT_OVERRIDE:
        print(f"[DXM] CONNECT_OVERRIDE 生效字段：", end="")
        parts = []
        for k, v in CONNECT_OVERRIDE.items():
            parts.append(f"{k}={'***' if k=='password' else v}")
        print(", ".join(parts))
    print("=" * 56)


# --------------------------------------------------------------------------
# ipython-sql %%sql magic 支持（仅 notebook 环境下有 get_ipython() 时生效）
# --------------------------------------------------------------------------
def _engine_url(group: str | None = None) -> str:
    group = group or DEFAULT_GROUP
    c = _base_conn_args_by_group(group)
    return (
        f"mysql+pymysql://{c['user']}:{quote_plus(str(c['password']))}"
        f"@{c['host']}:{c['port']}/{c['database']}?charset=utf8mb4"
    )


_magic_inited = False


def _init_magic_if_inside_ipython() -> None:
    """在 notebook 里跑 %run 本脚本时自动注册 %%sql magic 并连上 DEFAULT_GROUP。"""
    global _magic_inited
    if _magic_inited:
        return
    try:
        ipy = get_ipython()  # type: ignore[name-defined]
    except NameError:
        return  # 不是 notebook / ipython 环境，跳过
    try:
        ipy.run_line_magic("load_ext", "sql")
    except Exception:
        print("[DXM] 提示：未安装 ipython-sql，%%sql 魔法不可用。安装：pip install ipython-sql sqlalchemy")
        return
    try:
        ipy.run_line_magic("config", "SqlMagic.autopandas = True")
        ipy.run_line_magic("config", "SqlMagic.displaylimit = 50")
    except Exception:
        pass
    connect_magic(DEFAULT_GROUP, _ipy=ipy)
    _magic_inited = True


def connect_magic(group: str | None = None, _ipy=None) -> None:
    """切换 %%sql magic 当前连接的库；_ipy 内部用，外部不必传。"""
    group = group or DEFAULT_GROUP
    url = _engine_url(group)
    if _ipy is None:
        try:
            _ipy = get_ipython()  # type: ignore[name-defined]
        except NameError:
            print("[DXM] connect_magic() 仅在 notebook / ipython 环境下生效。")
            return
    try:
        _ipy.run_line_magic("sql", url)
        print(f"[DXM] %%sql magic 已切换到 group={group}")
    except Exception as ex:
        print(f"[DXM] %%sql magic 切库失败（group={group}）：{ex}")


def self_check() -> None:
    """独立脚本模式：打印配置 + 两库各查 apply_base_info 行数。"""
    print_config()
    print("\n----- 两库连通性自检 -----")
    for g in ("hainandxm", "ct_dxm"):
        try:
            n = q("select count(*) as cnt from apply_base_info", group=g)["cnt"][0]
            print(f"{g:<10} ✅ OK, apply_base_info {n} 行")
        except Exception as ex:
            print(f"{g:<10} ❌ FAIL: {type(ex).__name__}: {ex}")


# %run 本脚本 / 直接 import / python 直接跑，三种入口都兼容
_init_magic_if_inside_ipython()

if __name__ == "__main__":
    self_check()
