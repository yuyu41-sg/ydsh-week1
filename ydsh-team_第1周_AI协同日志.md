# ydsh-team 第 1 周 AI 协同日志

> 课程：企业项目实战实训　|　主题：项目启动 · 环境搭建 · Git 基础 · 数据导入与数据清洗（一）
> 填写人：张宇（20230308059）　|　记录周期：2026-10-27 ~ 2026-10-30

## 一、使用的工具与模型

| 工具/模型 | 用途 |
|---|---|
| WorkBuddy（AI 智能体助手） | 任务拆解、SQL 脚本编写、报错诊断、文档与交付物生成 |
| Docker Desktop + apache/hive:4.0.0 + mysql:8.0 | 数仓运行环境（由 AI 辅助编写 docker-compose.yml 编排） |
| Git / GitHub（yuyu41-sg） | 版本管理与远程推送（AI 指导 SSH 配置与规范提交） |
| Apache Hive 4.0（beeline） | ODS 建表、数据导入、五维质量评估、清洗 SQL 执行 |

## 二、协同记录表（≥5 条）

| 序号 | 日期 | 协同事项 | 我的提问/意图 | AI 的贡献 | 产出/结果 |
|---|---|---|---|---|---|
| 1 | 10-27 | 环境编排 | 按手册一步步搭 Docker+Hive+MySQL 环境 | 编写 docker-compose.yml（MySQL 元数据库 + hive-metastore + hive-server），排查 3306 端口冲突改映射 3307 | 三容器全部 Up (healthy) |
| 2 | 10-27 | 服务连通 | beeline 连接报 Connection refused | 诊断出 HS2 未配 metastore 地址 + 未就绪两点，补 SERVICE_OPTS 指向 hive-metastore:9083 并等待启动 | beeline 连通，CREATE DATABASE ydsh_ods 成功 |
| 3 | 10-27 | ODS 导入 | 6 张 CSV 建表并导入 | 生成 create_ods.sql（skip.header.line.count）与 load_ods.sql（含 UNION ALL 行数校验），挂载 /sql 卷解决脚本路径问题 | 6 表行数与数据字典 100% 吻合 |
| 4 | 10-27 | 质量评估 | 五维扫描脚本 | 编写 quality_check.sql，并把 Hive 不支持的 LEFT ANTI JOIN 改写为 LEFT JOIN ... WHERE 右表.主键 IS NULL | 五维全部跑通，产出质量预评估表 |
| 5 | 10-27 | 数据清洗 | 缺失值与重复值处理 | 编写 missing_value.sql（年龄均值填充+email打标）与 dedup.sql（ROW_NUMBER 窗口去重） | dwd_user 校验通过；15600→15000，removed=600 与评估数吻合 |
| 6 | 10-27 | Git 协作 | 系统无 git 命令，SSH 配置后如何推送 | 指导 npmmirror 镜像下载 Git for Windows 静默安装，配置用户信息与 ed25519 密钥 | 首次 push 成功（* [new branch] main -> main） |
| 7 | 10-28 | 真实数据重灌 | 拿到课程真实 11.5 万行数据 | 全流程重灌指导：drop 重建 → 导入 → 评估 → 清洗；诊断 hive-server 残留 PID 启动崩溃并重建容器 | 真实数据行数全吻合，600 组重复订单去重闭环 |
| 8 | 10-30 | 交付整理 | 按提交清单核对补齐交付物 | 差距分析、生成《数据质量预评估表.xlsx》、SQL 脚本按清单规范改名、生成本协同日志、打包提交压缩包 | 7 项提交物全部齐备 |

## 三、产出成果清单

1. `README.md` —— 团队信息、角色分工、项目目标、阶段计划、技术栈、快速开始
2. `环境搭建笔记.md` —— 9 个真实问题与解决方案（端口冲突、HS2 连通、Derby 误初始化、脚本挂载、LEFT ANTI JOIN、Git 安装、SSH 推送、PID 残留、MSYS 路径转换）
3. `docker-compose.yml` + `.gitignore` —— 可复现的数仓环境编排与版本管理规范
4. `sql/ods/create_ods.sql、load_ods.sql` —— 6 张 ODS 表建表 + 导入脚本，行数校验通过
5. `sql/quality/quality_check.sql` + 《数据质量预评估表.md/.xlsx》—— 五维量化扫描结果
6. `sql/clean/missing_value.sql、dedup.sql` —— 缺失值填充与 ROW_NUMBER 去重，前后行数对账吻合
7. `执行步骤.md` —— 手册 9 步分步执行记录（含实测结果与踩坑）
8. 远程仓库 ydsh-week1（GitHub），提交历史遵循 feat:/docs: 规范

## 四、问题与解决

| 问题 | 原因 | 解决方式 | AI 参与度 |
|---|---|---|---|
| MySQL 容器起不来 | 宿主机 3306 被占 | 映射改 3307:3306 | AI 定位日志并给出改法 |
| beeline Connection refused | HS2 未就绪且未配 metastore | 补 SERVICE_OPTS + 等待启动 | AI 诊断 |
| 元数据用 Derby 初始化、重建即丢 | 入口脚本默认行为 | IS_RESUME=true + 远程 metastore | AI 诊断 |
| Hive 报 LEFT ANTI JOIN 不支持 | Hive 4.0 语法限制 | 改写 LEFT JOIN + IS NULL | AI 改写 |
| hive-server 重启即崩 | 残留 PID 文件（process 7） | docker compose 重建容器 | AI 读日志定位 |
| Git Bash 传 /sql 路径报 No FileSystem for scheme "E" | MSYS 路径转换 | MSYS_NO_PATHCONV=1 | AI 定位 |
| `git` 命令不存在 | 系统未装 Git | 镜像下载 + 静默安装 | AI 全程指导 |

## 五、反思与总结

1. **AI 擅长的事**：报错日志诊断（省去大量盲试时间）、样板代码生成（SQL 脚本/编排文件一次成型）、流程化任务拆解。本周环境搭建如果纯手查文档，预计要多花一倍时间。
2. **AI 需要人把关的事**：对业务语义的判断（如"订单去重该保留哪条"需要人确认按 order_time 降序保留最新）；提交到远程仓库等外部动作必须人确认后再执行。
3. **踩坑沉淀**：容器 Up ≠ 服务就绪，要看日志确认；元数据（MySQL 持久）与表数据（容器本地盘）分开理解，重建容器后重跑导入即可。
4. **下周计划**：把 AI 产出的脚本逐条人工核读一遍，理解每个 SQL 的执行计划与索引/分区影响，避免"能跑但不懂"。

## 六、AI 使用合规声明

本周所有 AI 辅助产出（SQL 脚本、文档、环境配置）均经本人逐条验证执行后才纳入仓库；远程仓库提交、推送等外部操作均由本人确认触发。AI 仅作为效率工具，理解与责任由团队成员承担。
