-- ============================================================
-- 第2周 · 子任务7：探索性数据分析（基于 DWD 层）
-- 输出各段结果抄入《探索性分析简报》
-- ============================================================

-- ---------- 1. 核心 KPI：总订单量 / 总用户数 / 总 GMV / 客单价 ----------
SELECT
  COUNT(DISTINCT order_id)                          AS total_orders,
  COUNT(DISTINCT user_id)                           AS total_users,
  ROUND(SUM(pay_amount), 2)                         AS total_gmv,
  ROUND(SUM(pay_amount) / COUNT(DISTINCT order_id), 2) AS aov,
  ROUND(SUM(pay_amount) / COUNT(DISTINCT user_id), 2)  AS arpu
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成';

-- ---------- 2. 品类销售分布 ----------
-- 订单事实表无 product_id（商品明细在 order_item），品类口径经明细表关联
SELECT
  p.category,
  COUNT(DISTINCT i.order_id)  AS orders,
  ROUND(SUM(i.unit_price * i.quantity * (1 - i.discount)), 2) AS item_sales  -- discount 为折扣率(0~1)
FROM ydsh_ods.ods_order_item i
JOIN ydsh_dwd.dim_product p ON i.product_id = p.product_id
GROUP BY p.category
ORDER BY item_sales DESC;

-- ---------- 3. 省份销售分布（门店维度） ----------
SELECT
  s.province,
  COUNT(DISTINCT o.order_id)  AS orders,
  ROUND(SUM(o.pay_amount), 2) AS sales
FROM ydsh_dwd.dwd_order o
JOIN ydsh_dwd.dim_store s ON o.store_id = s.store_id
GROUP BY s.province
ORDER BY sales DESC;

-- ---------- 4. 门店销售 TOP10 ----------
SELECT
  s.store_name,
  s.province,
  COUNT(DISTINCT o.order_id)  AS orders,
  ROUND(SUM(o.pay_amount), 2) AS sales
FROM ydsh_dwd.dwd_order o
JOIN ydsh_dwd.dim_store s ON o.store_id = s.store_id
GROUP BY s.store_name, s.province
ORDER BY sales DESC
LIMIT 10;

-- ---------- 5. 渠道订单分布 ----------
SELECT channel, COUNT(*) AS orders, ROUND(SUM(pay_amount),2) AS sales
FROM ydsh_dwd.dwd_order
GROUP BY channel ORDER BY sales DESC;

-- ---------- 6. 支付方式分布 ----------
SELECT pay_name, COUNT(*) AS orders, ROUND(SUM(pay_amount),2) AS sales
FROM ydsh_dwd.dwd_order
GROUP BY pay_name ORDER BY orders DESC;

-- ---------- 7. 窗口函数：用户累计消费（按日期递增累加） ----------
SELECT
  user_id,
  order_date,
  pay_amount,
  SUM(pay_amount) OVER (PARTITION BY user_id ORDER BY order_date) AS cum_amount
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成'
ORDER BY user_id, order_date
LIMIT 20;

-- ---------- 8. 窗口函数：用户消费排名 TOP10 ----------
SELECT
  user_id, total_amount
FROM (
  SELECT
    user_id,
    SUM(pay_amount) AS total_amount,
    ROW_NUMBER() OVER (ORDER BY SUM(pay_amount) DESC) AS rk
  FROM ydsh_dwd.dwd_order
  WHERE order_status = '已完成'
  GROUP BY user_id
) t
WHERE rk <= 10;

-- ---------- 9. 日销售趋势（近 15 天） ----------
SELECT
  order_date,
  COUNT(DISTINCT order_id)    AS orders,
  ROUND(SUM(pay_amount), 2)   AS daily_gmv
FROM ydsh_dwd.dwd_order
WHERE order_status = '已完成'
GROUP BY order_date
ORDER BY order_date DESC
LIMIT 15;
