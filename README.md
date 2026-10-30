# 云购生活新零售 —— 企业级数据仓库与经营分析可视化系统（第 1 周）

|   |   |
| - | - |

> 课程：企业项目实战实训　|　阶段：项目启动 · 环境搭建 · Git 基础 · 数据导入与数据清洗（一）

## 一、团队信息

| 项目    | 内容            |
| ----- | ------------- |
| 团队名称  | ydsh-team     |
| 团队口号  | 数据驱动经营，仓库成就洞察 |
| 成员与分工 | 见下表           |

| 角色     | 成员 | 职责                                 |
| ------ | -- | ---------------------------------- |
| 项目经理   | 张宇 | 进度管理、任务拆解、答辩汇报                     |
| 数据工程师  | 张宇 | Docker/Hive/MySQL 环境搭建、ODS 导入、数据清洗 |
| 数据分析师  | 张宇 | 五维数据质量评估、质量报告                      |
| 可视化工程师 | 张宇 | Superset 看板搭建                      |

## 二、项目目标

以"云购生活新零售"模拟业务数据为载体，搭建企业级数据仓库（ODS → DWD → … → 可视化），  
完成数据采集导入、质量治理与经营分析看板，最终形成可量化的经营分析可视化系统。

## 三、阶段计划

| 周次       | 主题                          | 关键产出                            |
| -------- | --------------------------- | ------------------------------- |
| 第 1 周    | 环境搭建 · Git 基础 · 数据导入与清洗（一）  | 可运行环境、ODS 6 表、质量预评估表、缺失/重复值清洗脚本 |
| 第 2 周及以后 | 数据清洗（二）、DWD/DWS 建模、指标计算、可视化 | 按课程任务书推进                        |

## 四、仓库目录结构

```
ydsh-week1/
├── README.md                     # 本文件：团队信息、分工、计划
├── docker-compose.yml            # MySQL + hive-metastore + hive-server 编排
├── .gitignore                    # 忽略 CSV/密钥/日志
├── 环境搭建笔记.md                # 交付物：环境问题与解决记录
├── 数据质量预评估表.md            # 交付物：五维质量扫描结果
├── 执行步骤.md                    # 手册 9 步分步执行记录（含实测结果）
├── data/                         # 6 张 CSV（已被 .gitignore 忽略，不入库）
│   └── generate_sample_data.py   # 样例数据生成脚本（入库，可复现）
└── sql/
    ├── ods/create_ods.sql   # ODS 建表（6 张）
    ├── ods/load_ods.sql            # 导入 + 行数校验
    ├── quality/quality_check.sql   # 五维质量评估
    └── clean/missing_value.sql     # 缺失值填充 → dwd_user
    └── clean/dedup.sql             # 订单去重   → dwd_order
```

## 五、快速开始

```bash
# 1. 启动环境（需先安装 Docker Desktop + WSL2）
cd ydsh-week1
docker compose up -d
docker ps          # 确认 mysql / hive-metastore / hive-server 三容器 Up

# 2. 建表 + 导入
docker exec -it ydsh-hiveserver2 beeline -u jdbc:hive2://localhost:10000 -f /sql/ods/create_ods.sql
docker exec -it ydsh-hiveserver2 beeline -u jdbc:hive2://localhost:10000 -f /sql/ods/load_ods.sql

# 3. 质量评估 + 清洗
docker exec -it ydsh-hiveserver2 beeline -u jdbc:hive2://localhost:10000 -f /sql/quality/quality_check.sql
docker exec -it ydsh-hiveserver2 beeline -u jdbc:hive2://localhost:10000 -f /sql/clean/missing_value.sql
docker exec -it ydsh-hiveserver2 beeline -u jdbc:hive2://localhost:10000 -f /sql/clean/dedup.sql
```

## 六、提交规范

采用 Conventional Commits：`feat:` 新功能、`fix:` 修复、`docs:` 文档、`chore:` 杂项。

## 七、本周成果速览

- ✅ Docker/Hive/MySQL 三容器可运行，beeline 连通
- ✅ 6 张 ODS 表建成并导入，行数校验通过
- ✅ 五维质量评估完成（详见 `数据质量预评估表.md`）
- ✅ 缺失值填充（dwd_user）与订单去重（dwd_order）校验通过（45 → 42，removed=3）
