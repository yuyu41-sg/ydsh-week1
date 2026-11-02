-- ============================================================
-- 第2周 · 子任务6：DWD 层维度建模（星型模型）
-- 事实表：dwd_order（按 order_date 分区 + 按 user_id 分 4 桶，ORC）
-- 维度表：dim_user / dim_product / dim_store / dim_date（ORC）
-- 说明：第1周的 dwd_order 为 TEXTFILE 非分区表，本脚本重建为分区表
--       （第2周清洗链路最终产物为 dwd_order_enriched，加载源用它）
-- ============================================================

-- ---------- 1. 维度表 ----------
DROP TABLE IF EXISTS ydsh_dwd.dim_user;
CREATE TABLE ydsh_dwd.dim_user
STORED AS ORC AS
SELECT
  user_id,
  user_name,
  gender,
  age,
  city,
  province,
  region,
  register_date,
  member_level,
  level_name,
  discount_rate
FROM ydsh_dwd.dwd_user_enriched;

DROP TABLE IF EXISTS ydsh_dwd.dim_product;
CREATE TABLE ydsh_dwd.dim_product
STORED AS ORC AS
SELECT
  product_id,
  product_name,
  category,
  sub_category,
  brand,
  price,
  cost,
  status,
  launch_date
FROM ydsh_dwd.dwd_product_fmt;

DROP TABLE IF EXISTS ydsh_dwd.dim_store;
CREATE TABLE ydsh_dwd.dim_store
STORED AS ORC AS
SELECT
  store_id,
  store_name,
  province,
  city,
  district,
  open_date,
  area,
  manager
FROM ydsh_ods.ods_store;

-- 时间维度表：由订单日期去重生成（年/月/日/星期/是否周末）
DROP TABLE IF EXISTS ydsh_dwd.dim_date;
CREATE TABLE ydsh_dwd.dim_date
STORED AS ORC AS
SELECT DISTINCT
  order_date_part                                              AS date_key,
  SUBSTR(order_date_part, 1, 4)                                AS year,
  SUBSTR(order_date_part, 1, 7)                                AS month,
  SUBSTR(order_date_part, 9, 2)                                AS day,
  pmod(DATEDIFF(order_date_part, '2024-01-01') + 1, 7)         AS day_of_week_idx,
  CASE WHEN pmod(DATEDIFF(order_date_part, '2024-01-01') + 1, 7) IN (6, 0)
       THEN 1 ELSE 0 END                                       AS is_weekend
FROM ydsh_dwd.dwd_order_tmp
WHERE order_date_part IS NOT NULL;

-- ---------- 2. 事实表（分区 + 分桶 + ORC） ----------
DROP TABLE IF EXISTS ydsh_dwd.dwd_order;
CREATE TABLE ydsh_dwd.dwd_order (
  order_id         STRING,
  user_id          STRING COMMENT '外键 → dim_user',
  store_id         STRING COMMENT '外键 → dim_store',
  order_timestamp  STRING,
  pay_amount       DOUBLE COMMENT '度量',
  discount_amount  DOUBLE COMMENT '度量',
  pay_type         STRING,
  pay_name         STRING,
  order_status     STRING,
  channel          STRING
)
PARTITIONED BY (order_month STRING)
CLUSTERED BY (user_id) INTO 4 BUCKETS
STORED AS ORC;
