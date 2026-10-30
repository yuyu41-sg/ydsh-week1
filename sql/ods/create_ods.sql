-- ============================================================
-- 第1周 · ODS 贴源层建表（6 张表）
-- 字段类型严格对齐《模拟数据字典》
-- 所有表跳过 CSV 表头：tblproperties('skip.header.line.count'='1')
-- 分隔符：逗号 ','（CSV 默认）
-- 执行顺序：先建库，再建表
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_ods;

-- (1) ods_user —— 用户信息表
CREATE TABLE IF NOT EXISTS ydsh_ods.ods_user (
  user_id        STRING,
  user_name      STRING,
  gender         STRING,
  age            INT,
  city           STRING,
  province       STRING,
  register_date  STRING,
  member_level   STRING,
  phone          STRING,
  email          STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

-- (2) ods_product —— 商品信息表
CREATE TABLE IF NOT EXISTS ydsh_ods.ods_product (
  product_id   STRING,
  product_name STRING,
  category     STRING,
  sub_category STRING,
  brand        STRING,
  price        DOUBLE,
  cost         DOUBLE,
  stock        INT,
  status       STRING,
  launch_date  STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

-- (3) ods_store —— 门店信息表
CREATE TABLE IF NOT EXISTS ydsh_ods.ods_store (
  store_id   STRING,
  store_name STRING,
  province   STRING,
  city       STRING,
  district   STRING,
  address    STRING,
  open_date  STRING,
  area       INT,
  manager    STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

-- (4) ods_order —— 订单主表（含重复订单）
CREATE TABLE IF NOT EXISTS ydsh_ods.ods_order (
  order_id         STRING,
  user_id          STRING,
  store_id         STRING,
  order_date       STRING,
  order_time       STRING,
  pay_amount       DOUBLE,
  discount_amount  DOUBLE,
  pay_type         STRING,
  order_status     STRING,
  channel          STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

-- (5) ods_order_item —— 订单明细表
CREATE TABLE IF NOT EXISTS ydsh_ods.ods_order_item (
  item_id     STRING,
  order_id    STRING,
  product_id  STRING,
  quantity    INT,
  unit_price  DOUBLE,
  discount    DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

-- (6) ods_user_behavior —— 用户行为日志表
CREATE TABLE IF NOT EXISTS ydsh_ods.ods_user_behavior (
  behavior_id   STRING,
  user_id       STRING,
  product_id    STRING,
  behavior_type STRING,
  behavior_time STRING,
  session_id    STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');
