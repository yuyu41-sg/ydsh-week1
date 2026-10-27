-- ============================================================
-- 第1周 · 数据质量预评估（五维度）
-- 维度：完整性 / 唯一性 / 有效性 / 一致性 / 准确性
-- 目标：输出《数据质量预评估表》所需的脏数据分布
-- 用法：beeline -u jdbc:hive2://localhost:10000 -f 01_quality_check.sql
-- ============================================================

-- ---------- 一、完整性（空值率）----------
-- 用户信息表
SELECT 'ods_user' AS tbl, 'age'   AS col,
       SUM(CASE WHEN age  IS NULL OR age  = '' THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM ydsh_ods.ods_user
UNION ALL
SELECT 'ods_user', 'email',
       SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END), COUNT(*)
FROM ydsh_ods.ods_user;

-- 商品信息表：上架日期缺失
SELECT 'ods_product' AS tbl, 'launch_date' AS col,
       SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END) AS null_cnt,
       COUNT(*) AS total
FROM ydsh_ods.ods_product;

-- ---------- 二、唯一性（主键重复）----------
SELECT 'ods_user'           AS tbl, 'user_id'    AS pk, COUNT(*) - COUNT(DISTINCT user_id)    AS dup_cnt FROM ydsh_ods.ods_user
UNION ALL
SELECT 'ods_product',         'product_id',  COUNT(*) - COUNT(DISTINCT product_id)  FROM ydsh_ods.ods_product
UNION ALL
SELECT 'ods_store',           'store_id',    COUNT(*) - COUNT(DISTINCT store_id)    FROM ydsh_ods.ods_store
UNION ALL
SELECT 'ods_order',           'order_id',    COUNT(*) - COUNT(DISTINCT order_id)    FROM ydsh_ods.ods_order
UNION ALL
SELECT 'ods_order_item',      'item_id',     COUNT(*) - COUNT(DISTINCT item_id)     FROM ydsh_ods.ods_order_item
UNION ALL
SELECT 'ods_user_behavior',   'behavior_id', COUNT(*) - COUNT(DISTINCT behavior_id) FROM ydsh_ods.ods_user_behavior;

-- 订单主表：具体重复了哪些 order_id（取前 20 条看看）
SELECT order_id, COUNT(*) AS c
FROM ydsh_ods.ods_order
GROUP BY order_id
HAVING COUNT(*) > 1
LIMIT 20;

-- ---------- 三、有效性（取值合法性 / 范围）----------
-- 年龄异常：NULL、<1、>120
SELECT COUNT(*) AS age_invalid
FROM ydsh_ods.ods_user
WHERE age IS NULL OR age < 1 OR age > 120;

-- 商品售价异常：负数 / 超大值
SELECT COUNT(*) AS price_invalid
FROM ydsh_ods.ods_product
WHERE price < 0 OR price > 100000;

-- 订单金额异常：负数 / 超大值
SELECT COUNT(*) AS pay_invalid
FROM ydsh_ods.ods_order
WHERE pay_amount < 0 OR pay_amount > 1000000;

-- 订单明细数量异常：<=0 或超大
SELECT COUNT(*) AS qty_invalid
FROM ydsh_ods.ods_order_item
WHERE quantity <= 0 OR quantity > 50;

-- 枚举取值抽查（业务逻辑错误前置观察）
SELECT 'gender'         AS col, gender         AS val, COUNT(*) FROM ydsh_ods.ods_user     GROUP BY gender
UNION ALL
SELECT 'member_level',  member_level,  COUNT(*) FROM ydsh_ods.ods_user     GROUP BY member_level
UNION ALL
SELECT 'order_status',  order_status,  COUNT(*) FROM ydsh_ods.ods_order    GROUP BY order_status
UNION ALL
SELECT 'pay_type',      pay_type,      COUNT(*) FROM ydsh_ods.ods_order    GROUP BY pay_type
UNION ALL
SELECT 'channel',       channel,       COUNT(*) FROM ydsh_ods.ods_order    GROUP BY channel
UNION ALL
SELECT 'category',      category,      COUNT(*) FROM ydsh_ods.ods_product  GROUP BY category
UNION ALL
SELECT 'behavior_type', behavior_type, COUNT(*) FROM ydsh_ods.ods_user_behavior GROUP BY behavior_type;

-- ---------- 四、一致性（关联完整性）----------
-- 订单里的 user_id 是否都能在用户表找到
SELECT COUNT(*) AS order_no_user
FROM ydsh_ods.ods_order o
LEFT JOIN ydsh_ods.ods_user u ON o.user_id = u.user_id
WHERE u.user_id IS NULL;

-- 订单里的 store_id 是否都能在门店表找到
SELECT COUNT(*) AS order_no_store
FROM ydsh_ods.ods_order o
LEFT JOIN ydsh_ods.ods_store s ON o.store_id = s.store_id
WHERE s.store_id IS NULL;

-- 订单明细里的 order_id 是否都能在订单主表找到
SELECT COUNT(*) AS item_no_order
FROM ydsh_ods.ods_order_item i
LEFT JOIN ydsh_ods.ods_order o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ---------- 五、准确性（日期/手机号格式不一致）----------
-- 注册日期格式分布（含 2023-11-25 / 2023/11/25 / 20231125 等）
SELECT
  CASE
    WHEN register_date LIKE '%-%' THEN 'yyyy-mm-dd'
    WHEN register_date LIKE '%/%' THEN 'yyyy/mm/dd'
    WHEN register_date REGEXP '^[0-9]{8}$' THEN 'yyyyMMdd'
    ELSE 'other'
  END AS fmt,
  COUNT(*) AS cnt
FROM ydsh_ods.ods_user
GROUP BY
  CASE
    WHEN register_date LIKE '%-%' THEN 'yyyy-mm-dd'
    WHEN register_date LIKE '%/%' THEN 'yyyy/mm/dd'
    WHEN register_date REGEXP '^[0-9]{8}$' THEN 'yyyyMMdd'
    ELSE 'other'
  END;

-- 手机号格式：带分隔符 vs 纯数字
SELECT
  CASE WHEN phone LIKE '%-%' THEN 'dashed' ELSE 'plain' END AS fmt,
  COUNT(*) AS cnt
FROM ydsh_ods.ods_user
GROUP BY CASE WHEN phone LIKE '%-%' THEN 'dashed' ELSE 'plain' END;
