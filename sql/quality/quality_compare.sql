-- ============================================================
-- 第2周 · 子任务4：数据质量对比（清洗前 ODS vs 清洗后 DWD）
-- 修复率口径 = (清洗前问题数 - 清洗后问题数) / 清洗前问题数
-- 输出各段结果抄入《数据质量清洗报告》
-- ============================================================

-- ============ A. 缺失值 ============
-- A1. age 缺失：清洗前(ods) vs 清洗后(最终用户表)
SELECT
  (SELECT SUM(CASE WHEN age IS NULL OR age < 1 OR age > 120 THEN 1 ELSE 0 END) FROM ydsh_ods.ods_user) AS before_cnt,
  (SELECT SUM(CASE WHEN age IS NULL OR age < 1 OR age > 120 THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_user_enriched) AS after_cnt;

-- A2. email 缺失
SELECT
  (SELECT SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) FROM ydsh_ods.ods_user) AS before_cnt,
  (SELECT SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_user_enriched) AS after_cnt;

-- A3. launch_date 缺失
SELECT
  (SELECT SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END) FROM ydsh_ods.ods_product) AS before_cnt,
  (SELECT SUM(CASE WHEN launch_date IS NULL OR launch_date = '' THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_product_fmt) AS after_cnt;

-- ============ B. 唯一性（重复订单） ============
SELECT
  (SELECT COUNT(*) FROM ydsh_ods.ods_order)                                   AS before_rows,
  (SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM ydsh_ods.ods_order)        AS before_redundant,
  (SELECT COUNT(*) FROM ydsh_dwd.dwd_order_enriched)                          AS after_rows,
  (SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM ydsh_dwd.dwd_order_enriched) AS after_redundant;

-- ============ C. 有效性（数值异常） ============
-- C1. pay_amount 异常（<0）
SELECT
  (SELECT SUM(CASE WHEN pay_amount < 0 THEN 1 ELSE 0 END) FROM ydsh_ods.ods_order) AS before_neg,
  (SELECT SUM(CASE WHEN pay_amount < 0 THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_order_enriched) AS after_neg;

-- C2. quantity 异常（<=0 或 >50，明细表）
SELECT
  (SELECT SUM(CASE WHEN quantity IS NULL OR quantity <= 0 OR quantity > 50 THEN 1 ELSE 0 END) FROM ydsh_ods.ods_order_item) AS before_cnt,
  (SELECT SUM(CASE WHEN quantity IS NULL OR quantity <= 0 OR quantity > 50 THEN 1 ELSE 0 END) FROM ydsh_ods.ods_order_item) AS after_cnt;

-- ============ D. 一致性（外键孤儿记录） ============
SELECT
  (SELECT COUNT(*) FROM ydsh_ods.ods_order o LEFT JOIN ydsh_ods.ods_user u ON o.user_id = u.user_id WHERE u.user_id IS NULL) AS before_orphan,
  (SELECT COUNT(*) FROM ydsh_dwd.dwd_order_enriched o LEFT JOIN ydsh_dwd.dwd_user_enriched u ON o.user_id = u.user_id WHERE u.user_id IS NULL) AS after_orphan;

-- ============ E. 准确性（格式） ============
-- E1. 日期不规范（非 yyyy-MM-dd）
SELECT
  (SELECT SUM(CASE WHEN register_date NOT RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 1 ELSE 0 END) FROM ydsh_ods.ods_user) AS before_cnt,
  (SELECT SUM(CASE WHEN register_date NOT RLIKE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_user_enriched) AS after_cnt;

-- E2. 手机号不规范（非 11 位纯数字）
SELECT
  (SELECT SUM(CASE WHEN phone NOT RLIKE '^[0-9]{11}$' THEN 1 ELSE 0 END) FROM ydsh_ods.ods_user) AS before_cnt,
  (SELECT SUM(CASE WHEN phone NOT RLIKE '^[0-9]{11}$' THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_user_enriched) AS after_cnt;

-- ============ F. 枚举不规范（规范化值域之外的取值数） ============
SELECT
  (SELECT SUM(CASE WHEN gender NOT IN ('男','女','未知') THEN 1 ELSE 0 END) FROM ydsh_ods.ods_user) AS before_gender,
  (SELECT SUM(CASE WHEN gender NOT IN ('男','女','未知') THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_user_enriched) AS after_gender;

SELECT
  (SELECT SUM(CASE WHEN LOWER(TRIM(pay_type)) NOT IN ('微信支付','wechat','weixin','wx','支付宝','alipay','ali','银行卡','bank_card','card','货到付款','cod','cash') THEN 1 ELSE 0 END) FROM ydsh_ods.ods_order) AS before_cnt,
  (SELECT SUM(CASE WHEN pay_type NOT IN ('微信支付','支付宝','银行卡','货到付款','其他') THEN 1 ELSE 0 END) FROM ydsh_dwd.dwd_order_enriched) AS after_cnt;
