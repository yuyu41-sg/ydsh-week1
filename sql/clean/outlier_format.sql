-- ============================================================
-- 第2周 · 子任务2：异常值与格式标准化
-- 策略（对标手册：用分位数而非绝对值定阈值，避免误删正常大额订单）：
--   1) pay_amount：<0 置 0；> P99 按 P99 截断（cap），不删行
--   2) discount_amount：<0 置 0；> pay_amount 时按 pay_amount 截断
--   3) register_date：三种格式（yyyy-MM-dd / yyyy/MM/dd / yyyyMMdd）统一 yyyy-MM-dd
--   4) phone：去除 '-' 分隔符，统一 11 位纯数字
--   5) launch_date / open_date：同 register_date 规则
--   6) behavior_time：统一 yyyy-MM-dd HH:mm:ss
-- ============================================================

-- ---------- 第一步：计算阈值（先看分位数再定规则） ----------
SELECT
  PERCENTILE_APPROX(pay_amount, 0.99)      AS p99_pay,
  PERCENTILE_APPROX(pay_amount, 0.999)     AS p999_pay,
  SUM(CASE WHEN pay_amount < 0 THEN 1 ELSE 0 END) AS neg_cnt,
  SUM(CASE WHEN pay_amount > 1000000 THEN 1 ELSE 0 END) AS huge_cnt
FROM ydsh_dwd.dwd_order_std;

-- ---------- 第二步：订单表金额异常修正 ----------
-- 阈值说明（写入质量对比报告）：
--   实测 P95=4833.65、P99=5630249.08，P99/P95 跳变逾千倍 → 分位数被极值污染；
--   正常订单最大值 < 1 万，另有 302 条 10 万~千万级极端异常（与数据字典"约 200+ 超大金额"吻合）；
--   故采用「业务上限 10 万」判定异常，异常值按 P95 保守截断（保留大额订单语义）。
DROP TABLE IF EXISTS ydsh_dwd.dwd_order_fmt;
CREATE TABLE ydsh_dwd.dwd_order_fmt AS
WITH threshold AS (
  SELECT PERCENTILE_APPROX(pay_amount, 0.95) AS p95 FROM ydsh_dwd.dwd_order_std
)
SELECT
  o.order_id,
  o.user_id,
  o.store_id,
  o.order_date,
  o.order_time,
  -- 负金额 → 0；超大金额(>10万) → P95 截断
  CASE
    WHEN o.pay_amount < 0 THEN 0
    WHEN o.pay_amount > 100000 THEN ROUND(t.p95, 2)
    ELSE o.pay_amount
  END AS pay_amount,
  CASE
    WHEN o.discount_amount < 0 THEN 0
    ELSE o.discount_amount
  END AS discount_amount,
  o.pay_type,
  o.order_status,
  o.channel
FROM ydsh_dwd.dwd_order_std o
CROSS JOIN threshold t;

-- ---------- 第三步：日期格式统一（用户表） ----------
-- 三种脏格式：'2024-07-26'（已规范）/ '2024/07/26' / '20240726'
DROP TABLE IF EXISTS ydsh_dwd.dwd_user_fmt;
CREATE TABLE ydsh_dwd.dwd_user_fmt AS
SELECT
  user_id,
  user_name,
  gender,
  age,
  city,
  province,
  -- 统一为 yyyy-MM-dd
  CASE
    WHEN register_date RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN register_date
    WHEN register_date RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN REGEXP_REPLACE(register_date, '/', '-')
    WHEN register_date RLIKE '^[0-9]{8}$'
      THEN CONCAT(SUBSTR(register_date,1,4),'-',SUBSTR(register_date,5,2),'-',SUBSTR(register_date,7,2))
    ELSE NULL
  END AS register_date,
  member_level,
  -- 手机号去分隔符，统一 11 位纯数字
  REGEXP_REPLACE(phone, '[^0-9]', '') AS phone,
  email,
  email_missing_flag
FROM ydsh_dwd.dwd_user_std;

-- ---------- 第四步：日期格式统一（商品表 / 行为表） ----------
DROP TABLE IF EXISTS ydsh_dwd.dwd_product_fmt;
CREATE TABLE ydsh_dwd.dwd_product_fmt AS
SELECT
  product_id, product_name, category, sub_category, brand,
  price, cost, stock, status,
  CASE
    WHEN launch_date RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN launch_date
    WHEN launch_date RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' THEN REGEXP_REPLACE(launch_date, '/', '-')
    WHEN launch_date RLIKE '^[0-9]{8}$'
      THEN CONCAT(SUBSTR(launch_date,1,4),'-',SUBSTR(launch_date,5,2),'-',SUBSTR(launch_date,7,2))
    ELSE NULL
  END AS launch_date
FROM ydsh_dwd.dwd_product_std;

-- behavior_time 统一为 yyyy-MM-dd HH:mm:ss
-- 兼容：'2024-07-26 14:30:00'（已规范）/ '2024/07/26 14:30:00' / '2024-07-26 14:30'（缺秒）/ '2024/07/26 14:30' / '20240726143000'
DROP TABLE IF EXISTS ydsh_dwd.dwd_behavior_fmt;
CREATE TABLE ydsh_dwd.dwd_behavior_fmt AS
SELECT
  behavior_id, user_id, product_id, behavior_type,
  CASE
    WHEN behavior_time RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$' THEN behavior_time
    -- 斜杠分隔 + 缺秒 → 换分隔符并补 ':00'
    WHEN behavior_time RLIKE '^[0-9]{4}[/-][0-9]{2}[/-][0-9]{2} [0-9]{2}:[0-9]{2}$'
      THEN CONCAT(REGEXP_REPLACE(SUBSTR(behavior_time, 1, 10), '/', '-'), ' ', SUBSTR(behavior_time, -5), ':00')
    WHEN behavior_time RLIKE '^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
      THEN REGEXP_REPLACE(behavior_time, '/', '-')
    WHEN behavior_time RLIKE '^[0-9]{14}$'
      THEN CONCAT(SUBSTR(behavior_time,1,4),'-',SUBSTR(behavior_time,5,2),'-',SUBSTR(behavior_time,7,2),' ',
                  SUBSTR(behavior_time,9,2),':',SUBSTR(behavior_time,11,2),':',SUBSTR(behavior_time,13,2))
    ELSE behavior_time
  END AS behavior_time,
  session_id
FROM ydsh_dwd.dwd_behavior_std;

-- ---------- 第五步：格式校验 ----------
-- 日期应 100% 是 yyyy-MM-dd；手机号应 100% 是 11 位纯数字
SELECT
  SUM(CASE WHEN register_date IS NULL THEN 1 ELSE 0 END) AS bad_register_date,
  SUM(CASE WHEN phone NOT RLIKE '^[0-9]{11}$' THEN 1 ELSE 0 END) AS bad_phone,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_user_fmt;

SELECT
  SUM(CASE WHEN launch_date IS NULL THEN 1 ELSE 0 END) AS bad_launch_date,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_product_fmt;

-- 金额校验：无负值、无超大值
SELECT
  SUM(CASE WHEN pay_amount < 0 THEN 1 ELSE 0 END) AS neg_pay,
  MAX(pay_amount) AS max_pay,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_order_fmt;

-- 行为时间校验：应 100% 是 yyyy-MM-dd HH:mm:ss
SELECT
  SUM(CASE WHEN behavior_time NOT RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$' THEN 1 ELSE 0 END) AS bad_time,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_behavior_fmt;

-- ---------- 第六步：明细表数量异常修正 ----------
-- quantity <= 0 或 NULL → 修正为 1（至少购买 1 件）；> 50 → 截断为 50（业务上限）
DROP TABLE IF EXISTS ydsh_dwd.dwd_order_item;
CREATE TABLE ydsh_dwd.dwd_order_item AS
SELECT
  item_id,
  order_id,
  product_id,
  CASE
    WHEN quantity IS NULL OR quantity <= 0 THEN 1
    WHEN quantity > 50 THEN 50
    ELSE quantity
  END AS quantity,
  unit_price,
  discount
FROM ydsh_ods.ods_order_item;

-- 校验：无异常数量
SELECT
  SUM(CASE WHEN quantity IS NULL OR quantity <= 0 OR quantity > 50 THEN 1 ELSE 0 END) AS bad_qty,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_order_item;
