-- ============================================================
-- 第2周 · 子任务1：枚举字段标准化
-- 思路：先扫描取值分布 → case when 映射为规范中文值域 → 验证收敛
-- 覆盖字段：
--   ods_user      : gender, member_level
--   ods_order     : order_status, pay_type, channel
--   ods_user_behavior : behavior_type
--   ods_product   : category/brand 去首尾空格、统一小写
-- ============================================================

-- ---------- 第一步：扫描各枚举字段现有取值分布（清洗前基准） ----------
-- 运行时保留输出，写入《数据质量清洗报告》"清洗前"列
SELECT 'user.gender' AS field, CAST(gender AS STRING) AS val, COUNT(*) AS cnt
FROM ydsh_ods.ods_user GROUP BY gender
UNION ALL
SELECT 'user.member_level', CAST(member_level AS STRING), COUNT(*)
FROM ydsh_ods.ods_user GROUP BY member_level
UNION ALL
SELECT 'order.order_status', CAST(order_status AS STRING), COUNT(*)
FROM ydsh_ods.ods_order GROUP BY order_status
UNION ALL
SELECT 'order.pay_type', CAST(pay_type AS STRING), COUNT(*)
FROM ydsh_ods.ods_order GROUP BY pay_type
UNION ALL
SELECT 'order.channel', CAST(channel AS STRING), COUNT(*)
FROM ydsh_ods.ods_order GROUP BY channel
UNION ALL
SELECT 'behavior.behavior_type', CAST(behavior_type AS STRING), COUNT(*)
FROM ydsh_ods.ods_user_behavior GROUP BY behavior_type;

-- ---------- 第二步：枚举标准化 + 生成标准表 ----------
-- 用户表：gender/member_level 标准化（基于第1周 dwd_user，保留缺失值处理成果）
DROP TABLE IF EXISTS ydsh_dwd.dwd_user_std;
CREATE TABLE ydsh_dwd.dwd_user_std AS
SELECT
  user_id,
  user_name,
  CASE
    WHEN gender IN ('男','M','male','Male','m')             THEN '男'
    WHEN gender IN ('女','F','female','Female','f')         THEN '女'
    WHEN gender IS NULL OR gender = '' OR gender = '未知'    THEN '未知'
    ELSE '未知'
  END AS gender,
  age,
  city,
  province,
  register_date,
  CASE
    WHEN LOWER(TRIM(member_level)) IN ('金卡会员','gold','platinum','钻石会员','diamond') THEN '金卡会员'
    WHEN LOWER(TRIM(member_level)) IN ('银卡会员','silver')  THEN '银卡会员'
    WHEN LOWER(TRIM(member_level)) IN ('铜卡会员','bronze')  THEN '铜卡会员'
    WHEN TRIM(member_level) = '' OR member_level IS NULL     THEN '普通会员'
    ELSE '普通会员'
  END AS member_level,
  phone,
  email,
  email_missing_flag
FROM ydsh_dwd.dwd_user;

-- 订单表：order_status/pay_type/channel 标准化（基于第1周去重后的 dwd_order）
DROP TABLE IF EXISTS ydsh_dwd.dwd_order_std;
CREATE TABLE ydsh_dwd.dwd_order_std AS
SELECT
  order_id,
  user_id,
  store_id,
  order_date,
  order_time,
  pay_amount,
  discount_amount,
  CASE
    WHEN LOWER(TRIM(pay_type)) IN ('微信支付','微信','wechat','weixin','wx') THEN '微信支付'
    WHEN LOWER(TRIM(pay_type)) IN ('支付宝','alipay','ali')             THEN '支付宝'
    WHEN LOWER(TRIM(pay_type)) IN ('银行卡','bank_card','card','银行卡支付') THEN '银行卡'
    WHEN LOWER(TRIM(pay_type)) IN ('货到付款','cod','cash')             THEN '货到付款'
    ELSE '其他'
  END AS pay_type,
  -- 数字码按电商通用状态流转映射：1=待支付 2=已支付 3=已发货 4=已完成（口径在报告中注明）
  CASE
    WHEN LOWER(TRIM(order_status)) IN ('已完成','完成','completed','complete','done','4','成功') THEN '已完成'
    WHEN LOWER(TRIM(order_status)) IN ('已取消','cancelled','canceled','cancel','失败')          THEN '已取消'
    WHEN LOWER(TRIM(order_status)) IN ('待支付','pending','unpaid','1')  THEN '待支付'
    WHEN LOWER(TRIM(order_status)) IN ('已支付','已付款','paid','2')     THEN '已支付'
    WHEN LOWER(TRIM(order_status)) IN ('已发货','shipped','3')          THEN '已发货'
    WHEN LOWER(TRIM(order_status)) IN ('退款中','refunding')            THEN '退款中'
    ELSE TRIM(order_status)
  END AS order_status,
  CASE
    WHEN LOWER(TRIM(channel)) IN ('app','App','APP')                    THEN 'APP'
    WHEN LOWER(TRIM(channel)) IN ('小程序','miniapp','mini_program')    THEN '小程序'
    WHEN LOWER(TRIM(channel)) IN ('门店','store','线下')                THEN '门店'
    WHEN LOWER(TRIM(channel)) IN ('官网','web','pc','PC官网','pc官网')  THEN '官网'
    ELSE TRIM(channel)
  END AS channel
FROM ydsh_dwd.dwd_order;

-- 商品表：category/sub_category/brand 去首尾空格、统一小写
DROP TABLE IF EXISTS ydsh_dwd.dwd_product_std;
CREATE TABLE ydsh_dwd.dwd_product_std AS
SELECT
  product_id,
  product_name,
  LOWER(TRIM(category))     AS category,
  LOWER(TRIM(sub_category)) AS sub_category,
  LOWER(TRIM(brand))        AS brand,
  price,
  cost,
  stock,
  status,
  launch_date
FROM ydsh_ods.ods_product;

-- 行为表：behavior_type 标准化
DROP TABLE IF EXISTS ydsh_dwd.dwd_behavior_std;
CREATE TABLE ydsh_dwd.dwd_behavior_std AS
SELECT
  behavior_id,
  user_id,
  product_id,
  CASE
    WHEN LOWER(behavior_type) IN ('pv','浏览','view','page_view') THEN '浏览'
    WHEN LOWER(behavior_type) IN ('fav','收藏','favorite')         THEN '收藏'
    WHEN LOWER(behavior_type) IN ('cart','加购','add_cart')        THEN '加购'
    WHEN LOWER(behavior_type) IN ('buy','购买','purchase')         THEN '购买'
    ELSE TRIM(behavior_type)
  END AS behavior_type,
  behavior_time,
  session_id
FROM ydsh_ods.ods_user_behavior;

-- ---------- 第三步：验证取值收敛（清洗后应各收敛到 2~5 个规范值） ----------
SELECT 'user.gender' AS field, CAST(gender AS STRING) AS val, COUNT(*) AS cnt
FROM ydsh_dwd.dwd_user_std GROUP BY gender
UNION ALL
SELECT 'user.member_level', CAST(member_level AS STRING), COUNT(*)
FROM ydsh_dwd.dwd_user_std GROUP BY member_level
UNION ALL
SELECT 'order.order_status', CAST(order_status AS STRING), COUNT(*)
FROM ydsh_dwd.dwd_order_std GROUP BY order_status
UNION ALL
SELECT 'order.pay_type', CAST(pay_type AS STRING), COUNT(*)
FROM ydsh_dwd.dwd_order_std GROUP BY pay_type
UNION ALL
SELECT 'order.channel', CAST(channel AS STRING), COUNT(*)
FROM ydsh_dwd.dwd_order_std GROUP BY channel
UNION ALL
SELECT 'behavior.behavior_type', CAST(behavior_type AS STRING), COUNT(*)
FROM ydsh_dwd.dwd_behavior_std GROUP BY behavior_type
UNION ALL
SELECT 'product.category', CAST(category AS STRING), COUNT(*)
FROM ydsh_dwd.dwd_product_std GROUP BY category;
