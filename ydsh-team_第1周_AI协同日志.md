# 第 1 周 AI 协同日志

- 团队：ydsh-team　成员：张宇（20230308059）　填写日期：2026-10-30

---

## 一、使用的 AI 工具 / 模型

- 工具名称：WorkBuddy（AI 智能体助手）　模型版本：内置大模型（对话 + 代码执行 + 文件操作）
- 辅助环境：Docker Desktop（apache/hive:4.0.0、mysql:8.0）、Git 2.56、Apache Hive 4.0（beeline）

---

## 二、AI 协同记录表（至少 5 条）

| 序号 | 提问 / 任务描述 | AI 产出摘要 | 人工修改与验证 | 是否采纳 |
|------|----------------|-------------|----------------|----------|
| 1 | 按手册搭建 Docker+Hive+MySQL 环境，一步步带我做 | 生成 docker-compose.yml（MySQL 元数据库 + hive-metastore + hive-server 三容器编排，含健康检查与依赖顺序） | 逐行核对了端口映射与服务依赖关系；发现本机 3306 被占，确认 AI 把宿主机侧改为 3307:3306 的方案合理 | 是 |
| 2 | beeline 连接报 Connection refused，日志贴给你看 | 诊断出两点：HS2 未等 Metastore 就绪、未配 metastore 地址；给出 SERVICE_OPTS=thrift://hive-metastore:9083 并建议等待启动 | 自己执行 docker logs 确认 HS2 就绪日志后重连成功，验证了诊断正确 | 是 |
| 3 | 帮我写 6 张 ODS 表建表语句和 CSV 导入脚本 | 生成 create_ods.sql（含 skip.header.line.count='1' 跳表头）与 load_ods.sql（含 UNION ALL 行数校验） | 逐字段对照《模拟数据字典》核对表名、类型、顺序无误；导入后亲手跑 count(*) 确认 6 表行数与字典一致 | 是 |
| 4 | 写五维数据质量评估 SQL | 生成 quality_check.sql（完整性/唯一性/有效性/一致性/准确性 30 余条检查）；首次运行时把 Hive 不支持的 LEFT ANTI JOIN 改写为 LEFT JOIN ... WHERE 右表.主键 IS NULL | 逐条审读了改写后 SQL 与原意的等价性；对 order_id 重复结果用手工 group by 查询交叉验证（600 条冗余 = 586 组：573×2、12×3、1×4） | 是 |
| 5 | 写缺失值填充和订单去重脚本 | 生成 missing_value.sql（年龄按 1~120 有效均值填充、email 填 unknown 并打标）与 dedup.sql（ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_time DESC) 保留最新一条） | 讨论并确认了"保留最新一条"符合业务语义；跑完后亲自核验 null_age=0、15600→15000、removed_cnt=600 与评估数闭环 | 是 |
| 6 | 系统没有 git 命令，SSH 配置完怎么推送到 GitHub | 指导从国内镜像（npmmirror）下载 Git for Windows 静默安装，配置 user.name/email，生成 ed25519 密钥并添加到平台，git push -u origin main | 自行完成安装与密钥添加（涉及账号操作由本人执行）；push 成功后到 GitHub 网页确认提交可见 | 是 |
| 7 | hive-server 重启就崩，日志说 "HiveServer2 running as process 7" | 诊断残留 PID 文件问题，建议 docker compose 重建容器并重灌数据；同时给出宿主机重启后的标准恢复流程 | 按流程重建容器后重灌全链路，行数与清洗结果全部复验通过 | 是 |
| 8 | 按提交清单核对交付物并打包 | 差距分析（缺 xlsx 质量表、AI 日志、脚本改名），生成数据质量预评估表.xlsx、本日志，5 个 SQL 按清单规范重命名，重打提交压缩包 | 逐项对照清单核对文件名与内容；人工补拍 7 张环境关键截图并提供姓名/团队信息 | 是 |

> 说明：8 条记录均为真实过程。凡涉及远程推送、账号操作、业务语义判断（如去重保留策略）的决策均由本人确认后执行。

---

## 三、AI 产出成果清单

- **由 AI 生成的内容**：docker-compose.yml；sql/ods/create_ods.sql、load_ods.sql；sql/quality/quality_check.sql；sql/clean/missing_value.sql、dedup.sql；数据质量预评估表.xlsx；README.md、环境搭建笔记.md、执行步骤.md 初稿；.gitignore
- **由人工编写的内容**：7 张环境关键截图的拍摄与挑选；团队信息、姓名学号等个人信息；对 AI 产出的全部确认决策与账号操作
- **人机协作完成的内容**：报错诊断（AI 定位原因 → 本人执行验证）；数据清洗策略（AI 给方案 → 本人确认业务语义 → 双方对账验证）；交付物整理（AI 生成初稿 → 本人核对清单逐项确认）

---

## 四、问题与解决

- **遇到的问题**：① MySQL 容器起不来（3306 被占）；② beeline 连接被拒；③ 元数据被 Derby 误初始化、容器重建即丢；④ Hive 不支持 LEFT ANTI JOIN；⑤ hive-server 重启即崩（残留 PID）；⑥ 系统无 git 命令；⑦ Git Bash 传容器路径报 No FileSystem for scheme "E"
- **AI 是否有效解决**：全部有效解决（7/7），且每个问题 AI 都给出了可复现的解决步骤而非临时补丁
- **最终如何解决**：① 端口映射改 3307:3306；② 补 metastore 地址配置 + 等待服务就绪；③ IS_RESUME=true + 远程 Metastore；④ 改写为 LEFT JOIN + IS NULL；⑤ 重建容器；⑥ 镜像下载静默安装；⑦ MSYS_NO_PATHCONV=1。所有解法均已记入《环境搭建笔记.md》沉淀为团队知识

---

## 五、反思与总结

- **AI 协同带来的价值**：报错诊断效率提升最明显——日志贴进去几秒钟定位根因（如端口冲突、PID 残留），纯手查文档预计多花一倍以上时间；样板代码（建表/导入/评估脚本）一次成型，人工只需核对业务语义
- **AI 的局限与风险（准确性 / 合规性 / 依赖）**：① AI 生成的 SQL 语法可能不被特定引擎支持（LEFT ANTI JOIN 即翻车），必须实机验证；② 对业务语义无判断力（"重复订单保留哪条"需人拍板）；③ 长会话有口径漂移风险——本次就发现评估表"600 组"应为"600 条冗余（586 组）"，靠人工交叉查询才纠正；④ 涉及账号、远程推送的操作不能交给 AI 自主执行
- **本次协作中我的能力提升**：学会了读容器日志定位启动链路问题（依赖顺序、服务就绪 ≠ 容器 Up）；掌握了 Hive 窗口函数去重与空值/异常值治理的完整方法论；建立了"AI 产出 → 人工验证 → 沉淀笔记"的工作习惯
- **对 AI 协同的改进建议**：让 AI 产出脚本时同步附上"验证清单"（跑什么命令、预期什么输出），人核起来更快；跨会话的长任务应在文档里显式记录口径定义，避免统计口径前后不一致
