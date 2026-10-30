# 云购生活新零售数据仓库项目 实训周志

| 项目 | 内容 |
|---|---|
| **周次** | 第 1 周（2026-10-27 ～ 2026-10-30） |
| **团队名称** | ydsh-team |
| **姓名/学号** | 张宇（20230308059） |
| **本周主题** | 环境搭建 + 数据接入 + 数据质量评估与初步清洗 |

---

## 一、本周工作目标

1. 搭建大数据实训基础环境（Docker + MySQL 8.0 + Apache Hive 4.0）
2. 按照《模拟数据字典》完成 6 张 ODS 层表的建表与数据导入
3. 对接入数据完成五维数据质量预评估（完整性/唯一性/有效性/一致性/准确性）
4. 完成缺失值填充与订单去重两项初步清洗，产出 DWD 层干净表
5. 初始化 Git 仓库并推送远程，建立规范化提交习惯

## 二、本周完成工作

### 1. 环境搭建（周一～周二）

- 编写 `docker-compose.yml`，编排 3 个容器：MySQL（元数据库）、hive-metastore、hive-server（apache/hive:4.0.0）
- 通过健康检查与依赖顺序（mysql → metastore → hiveserver2）保证启动稳定性
- 验证 beeline 连接与元数据持久化：`ydsh_ods` / `ydsh_dwd` 库在容器重建后依然保留

### 2. ODS 建表与数据接入（周二～周三）

- 依据数据字典编写 `sql/ods/create_ods.sql`：ods_user、ods_product、ods_store、ods_order、ods_order_item、ods_user_behavior 共 6 张外部表，字段/类型/顺序逐字段核对
- 编写 `sql/ods/load_ods.sql` 导入课程真实数据（共 11.5 万行），行数校验全部吻合：

| 表 | ods_user | ods_product | ods_store | ods_order | ods_order_item | ods_user_behavior |
|---|---|---|---|---|---|---|
| 行数 | 1000 | 600 | 60 | 15600 | 37549 | 60000 |

### 3. 五维数据质量预评估（周三）

编写 `sql/quality/quality_check.sql`，对真实数据完成五维评估，关键发现：

- **完整性**：ods_user.age 空 51 条、email 空 193 条、ods_product.launch_date 空 11 条
- **唯一性**：ods_order.order_id 存在 **600 条冗余记录（586 组重复）**，其余 5 表主键唯一
- **有效性**：pay_amount 异常 601 条、quantity 异常 1081 条、price 异常 36 条；gender/order_status/pay_type 等枚举字段存在大面积中英文混用
- **一致性**：订单→用户、订单→门店、明细→订单 三组外键孤儿记录均为 0
- **准确性**：register_date 混用 3 种日期格式（875/100/25），phone 存在带分隔符格式 102 条

评估结果整理为《数据质量预评估表.xlsx》，并制定每项问题的清洗策略。

### 4. 数据清洗与 DWD 落地（周四）

- `sql/clean/missing_value.sql`：dwd_user 生成，age 用均值填充、email 缺失打标，校验 `null_age=0, bad_age=0, total=1000`
- `sql/clean/dedup.sql`：基于 `ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_time DESC)` 保留最新记录，15600 → 15000，removed_cnt=600 与评估发现的冗余条数**完全吻合**，主键唯一性闭环验证通过

### 5. 工程化与文档（周五）

- 初始化 Git 仓库，配置 `.gitignore`（忽略 CSV 数据/密钥/日志），以 `feat:` / `docs:` / `fix:` 规范提交 10 次，推送 GitHub 远程
- 补齐交付物：README.md、环境搭建笔记.md（附 7 张关键截图）、AI 协同日志、执行步骤.md，并按提交清单要求规范脚本命名与打包

## 三、本周遇到的问题与解决

| # | 问题 | 原因分析 | 解决方案 |
|---|---|---|---|
| 1 | MySQL 容器启动失败，3306 端口被占 | 宿主机已有本地 MySQL 服务占用 | compose 端口映射改为 3307:3306 |
| 2 | beeline 连接秒拒（Connection refused） | hive-server 未配置 metastore 地址，且未等 HS2 就绪 | SERVICE_OPTS 加 `-Dhive.metastore.uris=thrift://hive-metastore:9083`，启动后延时再连 |
| 3 | hive-server 误初始化 Derby 元数据 | 启动脚本默认走 schematool init | 加 `IS_RESUME: "true"` 跳过重复初始化 |
| 4 | beeline `!run` 报 No such file or directory | sql 脚本目录未挂载进容器 | compose 增加 `./sql:/sql` 卷，路径统一改为 `/sql/...` |
| 5 | 质量评估脚本 LEFT ANTI JOIN 报语法错误 | Hive 4.0 不支持 LEFT ANTI JOIN 写法 | 改写为 `LEFT JOIN ... WHERE 右表.key IS NULL` |
| 6 | 宿主机重启后 hive-server 启动即崩（残留 PID） | 容器非正常关闭残留 "running as process" 记录 | `docker compose up -d --force-recreate` 重建容器（表结构在 MySQL 未丢） |
| 7 | Git Bash 下 `/sql` 路径被自动转换为宿主机盘符路径 | MSYS 路径转换机制 | 命令前加 `export MSYS_NO_PATHCONV=1` |

## 四、本周产出物

- `docker-compose.yml` + 环境搭建笔记（含 7 张关键截图）
- `sql/ods/create_ods.sql`、`load_ods.sql`（6 表建表 + 11.5 万行导入校验）
- `sql/quality/quality_check.sql` + 《数据质量预评估表.xlsx》
- `sql/clean/missing_value.sql`、`dedup.sql`（DWD 层 dwd_user / dwd_order）
- GitHub 远程仓库（规范提交历史）+ README + AI 协同日志

## 五、学习心得与反思

1. **环境问题本质是"依赖与状态"问题**。本周 7 个坑里有 5 个与容器状态/依赖顺序相关（端口占用、服务就绪、元数据初始化、PID 残留、路径转换）。学会看容器日志定位根因，比反复重启有效得多。
2. **数据质量评估先于清洗**。"600 条冗余 vs 586 组"的口径事件让我意识到：指标定义必须写清统计口径（COUNT(*) - COUNT(DISTINCT) 是冗余行数，不是重复组数），否则汇报数字会被误解。
3. **清洗后必须闭环校验**。removed_cnt 与评估数吻合、distinct = total_rows 这类双向校验，是证明"清洗没有误删"的关键证据，已固化为脚本的固定输出。
4. **待改进**：枚举标准化（中英文映射）和数值异常值处理还未做，列入下周计划；对 Hive 窗口函数和 Tez 执行引擎的调优理解还比较浅，需要补强。

## 六、下周计划

1. 枚举字段标准化：制定 gender/order_status/pay_type/channel/member_level 的映射表并落地清洗脚本
2. 数值异常值处理：pay_amount / quantity / price 的异常检测与修复策略（截断/剔除/标记）
3. 格式统一：register_date 三种日期格式归一、phone 去分隔符
4. 开始 DWD/DWS 分层建模准备，按任务书推进第 2 周内容
