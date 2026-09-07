-- ===================================================
-- 脚本名称: smallfiles_merge.sql
-- 类型: 小文件合并
-- 功能: 合并表中过多的小文件，提升查询性能
-- 执行频率: 每周一次 / 按需执行
-- 负责人: <name>
-- 创建日期: 2026-08-13
-- ===================================================

-- 1. 查看表的小文件情况
SHOW PARTITIONS <table_name>;

-- 2. 合并指定分区的小文件
ALTER TABLE <table_name> MERGE SMALLFILES;
-- 或针对特定分区
-- ALTER TABLE <table_name> PARTITION (ds='${bizdate}') MERGE SMALLFILES;

-- 3. 会话级参数控制（在 SQL 执行前设置）
SET odps.sql.mapper.merge.small.size.avg=64;        -- 单 mapper 平均处理 64MB
SET odps.sql.mapper.merge.small.file.limit=1000;    -- 小文件阈值

-- 4. 批量合并多张表（Shell 脚本调用）
-- for table in table1 table2 table3; do
--     echo "Merging $table ..."
--     odpscmd -e "ALTER TABLE $table MERGE SMALLFILES;"
-- done
