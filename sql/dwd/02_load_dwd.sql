-- ============================================================
-- 第2周 · 子任务6：DWD 数据加载（动态分区写入）
-- 加载源：清洗链路最终产物 dwd_order_enriched
-- ============================================================

-- 动态分区插入（Hive 开启动态分区；订单跨约 101 天，需调高分区上限）
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;
SET hive.exec.max.dynamic.partitions = 2000;
SET hive.exec.max.dynamic.partitions.pernode = 2000;

INSERT OVERWRITE TABLE ydsh_dwd.dwd_order PARTITION (order_month)
SELECT
  order_id,
  user_id,
  store_id,
  order_timestamp,
  pay_amount,
  discount_amount,
  pay_type,
  pay_name,
  order_status,
  channel,
  SUBSTR(order_date_part, 1, 7) AS order_month
FROM ydsh_dwd.dwd_order_enriched;

-- ---------- 校验 ----------
-- 1) 分区清单
SHOW PARTITIONS ydsh_dwd.dwd_order;

-- 2) 行数一致：事实表 = 清洗后订单数（15000）
SELECT
  (SELECT COUNT(*) FROM ydsh_dwd.dwd_order_enriched) AS src_cnt,
  (SELECT COUNT(*) FROM ydsh_dwd.dwd_order)          AS fact_cnt;

-- 3) 分区裁剪演示：只扫单日分区
SELECT COUNT(*) FROM ydsh_dwd.dwd_order WHERE order_month = '2024-07';
