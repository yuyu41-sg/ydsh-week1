⚠️ 本目录当前放的是【合成示例数据】，不是课程真实数据集！

文件清单（同名，方便直接被 sql/ods/02_load_ods.sql 加载）：
  ods_user.csv            30 行
  ods_product.csv         25 行
  ods_store.csv            6 行
  ods_order.csv           45 行（含重复订单，供去重演示）
  ods_order_item.csv      60 行
  ods_user_behavior.csv   40 行

这些样本由 generate_sample_data.py 按《模拟数据字典》字段与五类脏数据规格生成，
仅用于在没有真实数据前，先打通：Docker 启动 → Hive 建表 → LOAD DATA → 质量评估 → 清洗 全链路。

拿到课程真实「模拟数据」后：
  1) 删除或覆盖本目录下同名的 ods_*.csv；
  2) 把真实 CSV 放进来（文件名必须一致，否则改 02_load_ods.sql）；
  3) 重新执行导入即可，无需改动表结构或其它脚本。

注意：这些 CSV 已被 .gitignore 忽略，不会进版本库，请勿手动 git add。
