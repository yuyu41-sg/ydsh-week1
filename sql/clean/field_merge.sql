-- ============================================================
-- 第2周 · 子任务3：字段拆分合并与编码映射
--   1) order_date + order_time → order_timestamp（yyyy-MM-dd HH:mm:ss）
--   2) province + city → region
--   3) 建编码映射维度表 dim_member_level / dim_pay_type，
--      并通过 JOIN 完成"编码 → 中文名称"转换（演示编码表关联映射）
-- ============================================================

-- ---------- 1. 订单时间戳合并 ----------
-- 注意：order_date 也存在三种脏格式（第1周仅清洗了 register_date），先归一再拼接
DROP TABLE IF EXISTS ydsh_dwd.dwd_order_tmp;
CREATE TABLE ydsh_dwd.dwd_order_tmp AS
SELECT
  order_id,
  user_id,
  store_id,
  CONCAT(
    -- order_date 归一为 yyyy-MM-dd
    CASE
      WHEN order_date RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN order_date
      WHEN order_date RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN REGEXP_REPLACE(order_date, '/', '-')
      WHEN order_date RLIKE '^[0-9]{8}$'
        THEN CONCAT(SUBSTR(order_date,1,4),'-',SUBSTR(order_date,5,2),'-',SUBSTR(order_date,7,2))
      ELSE NULL
    END,
    ' ',
    order_time) AS order_timestamp,
  pay_amount,
  discount_amount,
  pay_type,
  order_status,
  channel,
  -- 分区键使用归一后的日期
  CASE
    WHEN order_date RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN order_date
    WHEN order_date RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN REGEXP_REPLACE(order_date, '/', '-')
    WHEN order_date RLIKE '^[0-9]{8}$'
      THEN CONCAT(SUBSTR(order_date,1,4),'-',SUBSTR(order_date,5,2),'-',SUBSTR(order_date,7,2))
    ELSE NULL
  END AS order_date_part
FROM ydsh_dwd.dwd_order_fmt;

-- 校验：order_timestamp 应 100% 是 yyyy-MM-dd HH:mm:ss
SELECT
  SUM(CASE WHEN order_timestamp NOT RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
      THEN 1 ELSE 0 END) AS bad_ts,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_order_tmp;

-- ---------- 2. 用户区域字段合并（province + city → region） ----------
DROP TABLE IF EXISTS ydsh_dwd.dwd_user_full;
CREATE TABLE ydsh_dwd.dwd_user_full AS
SELECT
  user_id,
  user_name,
  gender,
  age,
  city,
  province,
  CONCAT(province, '_', city) AS region,
  register_date,
  member_level,
  phone,
  email,
  email_missing_flag
FROM ydsh_dwd.dwd_user_fmt;

-- ---------- 3. 编码映射维度表 ----------
DROP TABLE IF EXISTS ydsh_dwd.dim_member_level;
CREATE TABLE ydsh_dwd.dim_member_level (
  level_code   STRING COMMENT '编码：gold/silver/bronze/normal',
  level_name   STRING COMMENT '中文名称',
  discount_rate DOUBLE COMMENT '折扣率'
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

DROP TABLE IF EXISTS ydsh_dwd.dim_pay_type;
CREATE TABLE ydsh_dwd.dim_pay_type (
  pay_code   STRING COMMENT '编码：wechat/alipay/card/cod',
  pay_name   STRING COMMENT '中文名称'
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
TBLPROPERTIES ('skip.header.line.count'='1');

-- 映射数据通过 LOAD DATA 导入（文件位于 data/dim/ 下，随仓库提交）
LOAD DATA LOCAL INPATH '/data/dim/dim_member_level.csv' OVERWRITE INTO TABLE ydsh_dwd.dim_member_level;
LOAD DATA LOCAL INPATH '/data/dim/dim_pay_type.csv'     OVERWRITE INTO TABLE ydsh_dwd.dim_pay_type;

-- ---------- 4. 关联编码表，完成编码 → 中文名称转换 ----------
DROP TABLE IF EXISTS ydsh_dwd.dwd_order_enriched;
CREATE TABLE ydsh_dwd.dwd_order_enriched AS
SELECT
  t.order_id,
  t.user_id,
  t.store_id,
  t.order_timestamp,
  t.pay_amount,
  t.discount_amount,
  t.order_date_part,
  t.pay_type,
  p.pay_name,
  t.order_status,
  t.channel
FROM ydsh_dwd.dwd_order_tmp t
LEFT JOIN ydsh_dwd.dim_pay_type p
  ON t.pay_type = p.pay_code;

-- 用户表同样关联会员等级编码表
DROP TABLE IF EXISTS ydsh_dwd.dwd_user_enriched;
CREATE TABLE ydsh_dwd.dwd_user_enriched AS
SELECT
  u.user_id,
  u.user_name,
  u.gender,
  u.age,
  u.city,
  u.province,
  u.region,
  u.register_date,
  u.member_level,
  m.level_name,
  m.discount_rate,
  u.phone,
  u.email,
  u.email_missing_flag
FROM ydsh_dwd.dwd_user_full u
LEFT JOIN (
  SELECT level_code,
         MAX(level_name) AS level_name,
         MAX(discount_rate) AS discount_rate
  FROM ydsh_dwd.dim_member_level
  GROUP BY level_code
) m ON u.member_level = m.level_code;

-- 校验：关联命中率（level_name 非空比例）
SELECT
  SUM(CASE WHEN level_name IS NULL THEN 1 ELSE 0 END) AS miss_level,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_user_enriched;
