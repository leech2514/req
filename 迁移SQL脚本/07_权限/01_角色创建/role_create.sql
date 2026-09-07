-- ===================================================
-- 脚本名称: role_create.sql
-- 类型: 角色创建
-- 功能: 创建项目级角色，用于 RBAC 权限管理
-- 执行环境: MaxCompute Project
-- 负责人: <name>
-- 创建日期: <YYYY-MM-DD>
-- ===================================================

-- 1. 创建角色
CREATE ROLE IF NOT EXISTS role_dwd_developer;
CREATE ROLE IF NOT EXISTS role_dws_developer;
CREATE ROLE IF NOT EXISTS role_ads_developer;
CREATE ROLE IF NOT EXISTS role_dim_developer;
CREATE ROLE IF NOT EXISTS role_data_reader;
CREATE ROLE IF NOT EXISTS role_data_admin;

-- 2. 角色说明
-- role_dwd_developer: DWD 层开发权限（读写 DWD 表）
-- role_dws_developer: DWS 层开发权限
-- role_ads_developer: ADS 层开发权限
-- role_dim_developer: DIM 层开发权限
-- role_data_reader:   只读权限（运维/分析）
-- role_data_admin:    数据管理员（DDL + 权限管理）

-- 3. 为角色授权（示例）
-- DWD 开发者：读写 DWD 表
GRANT Read, Describe, Select, Alter, Update, Drop
ON TABLE dwd_trade_order_di
TO ROLE role_dwd_developer;

-- 数据读者：只读
GRANT Read, Select, Describe
ON TABLE dwd_trade_order_di
TO ROLE role_data_reader;

-- 4. 将角色授予用户
-- GRANT ROLE role_dwd_developer TO USER RAM$<account>:<subuser>;
-- GRANT ROLE role_data_reader TO USER RAM$<account>:<subuser>;
