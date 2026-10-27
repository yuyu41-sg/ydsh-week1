-- ============================================================
-- 第1周 · 清洗（一）：缺失值处理
-- 策略：
--   1) age：用“有效年龄均值(1~120)”填充缺失/异常值
--   2) email：缺失保留，并打 email_missing_flag 标记
-- 实现：建 DWD 明细层 dwd_user（Hive 非 ACID 表用 CTAS 生成清洗结果）
-- 用法：beeline -u jdbc:hive2://localhost:10000 -f 01_missing_value.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS ydsh_dwd;

-- 先算有效年龄均值（排除空值、负数、>120 的异常）
DROP TABLE IF EXISTS ydsh_dwd.dwd_user;
CREATE TABLE ydsh_dwd.dwd_user AS
WITH valid_age AS (
  SELECT AVG(age) AS avg_age
  FROM ydsh_ods.ods_user
  WHERE age IS NOT NULL AND age BETWEEN 1 AND 120
)
SELECT
  user_id,
  user_name,
  gender,
  -- 缺失或异常的年龄 → 用均值四舍五入填充
  CASE
    WHEN age IS NULL OR age < 1 OR age > 120
      THEN CAST(ROUND(v.avg_age) AS INT)
    ELSE age
  END AS age,
  city,
  province,
  register_date,
  member_level,
  phone,
  -- 邮箱缺失保留空串，并标记
  CASE WHEN email IS NULL OR email = '' THEN 'unknown' ELSE email END AS email,
  CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END AS email_missing_flag
FROM ydsh_ods.ods_user
CROSS JOIN valid_age v;

-- 校验：清洗后 age 应无空值、无负值、无 >120
SELECT
  SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_age,
  SUM(CASE WHEN age < 1 OR age > 120 THEN 1 ELSE 0 END) AS bad_age,
  COUNT(*) AS total
FROM ydsh_dwd.dwd_user;
