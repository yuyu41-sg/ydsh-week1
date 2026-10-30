-- ============================================================
-- 第1周 · 清洗（一）：重复值检测与去重
-- 策略：订单主表按 order_id 分区，按 order_time 倒序取最新一条（rn=1）
--       区分“整行重复”和“主键重复但字段不同”两类，统一保留一条
-- 实现：生成 DWD 明细层 dwd_order
-- 用法：beeline -u jdbc:hive2://localhost:10000 -f 02_dedup.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dwd;

DROP TABLE IF EXISTS ydsh_dwd.dwd_order;
CREATE TABLE ydsh_dwd.dwd_order AS
SELECT
  order_id,
  user_id,
  store_id,
  order_date,
  order_time,
  pay_amount,
  discount_amount,
  pay_type,
  order_status,
  channel
FROM (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY order_time DESC
    ) AS rn
  FROM ydsh_ods.ods_order
) t
WHERE rn = 1;

-- 校验：去重后 order_id 不再重复
SELECT
  COUNT(*)                 AS total_rows,
  COUNT(DISTINCT order_id) AS distinct_orders
FROM ydsh_dwd.dwd_order;

-- 对比：去重前后行数差 应 ≈ 预评估阶段发现的 order_id 重复数
SELECT
  (SELECT COUNT(*) FROM ydsh_ods.ods_order)           AS before_cnt,
  (SELECT COUNT(*) FROM ydsh_dwd.dwd_order)           AS after_cnt,
  (SELECT COUNT(*) FROM ydsh_ods.ods_order)
    - (SELECT COUNT(*) FROM ydsh_dwd.dwd_order)       AS removed_cnt;
