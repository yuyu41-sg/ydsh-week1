-- ============================================================
-- 第1周 · ODS 数据导入（LOAD DATA）
-- 前提：6 个 CSV 已放在项目 data/ 目录下，
--      docker-compose 已将其挂载到 hive-server 容器的 /data
-- 用法（在 beeline 中执行本文件）：
--   beeline -u jdbc:hive2://localhost:10000 -f /sql/ods/02_load_ods.sql
-- 校验：每张表 count(*) 应与下方“预期行数”一致
-- ============================================================

LOAD DATA LOCAL INPATH '/data/ods_user.csv'
  INTO TABLE ydsh_ods.ods_user;

LOAD DATA LOCAL INPATH '/data/ods_product.csv'
  INTO TABLE ydsh_ods.ods_product;

LOAD DATA LOCAL INPATH '/data/ods_store.csv'
  INTO TABLE ydsh_ods.ods_store;

LOAD DATA LOCAL INPATH '/data/ods_order.csv'
  INTO TABLE ydsh_ods.ods_order;

LOAD DATA LOCAL INPATH '/data/ods_order_item.csv'
  INTO TABLE ydsh_ods.ods_order_item;

LOAD DATA LOCAL INPATH '/data/ods_user_behavior.csv'
  INTO TABLE ydsh_ods.ods_user_behavior;

-- ===== 行数校验（预期）=====
-- ods_user          1000
-- ods_product        600
-- ods_store           60
-- ods_order        15600
-- ods_order_item   37549
-- ods_user_behavior 60000

SELECT 'ods_user'           AS tbl, COUNT(*) AS cnt FROM ydsh_ods.ods_user
UNION ALL SELECT 'ods_product',       COUNT(*)      FROM ydsh_ods.ods_product
UNION ALL SELECT 'ods_store',         COUNT(*)      FROM ydsh_ods.ods_store
UNION ALL SELECT 'ods_order',         COUNT(*)      FROM ydsh_ods.ods_order
UNION ALL SELECT 'ods_order_item',    COUNT(*)      FROM ydsh_ods.ods_order_item
UNION ALL SELECT 'ods_user_behavior', COUNT(*)      FROM ydsh_ods.ods_user_behavior;
