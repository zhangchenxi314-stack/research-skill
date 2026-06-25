# 研报 Skill 需求分析报告 v4（最终版）

## 一、背景与定位

- 替换现有 `researching-and-reporting` skill（效果不佳），全新重写
- 部署在 Windows 电脑，开发在 Mac 本机（/Users/zcx/project/research-report/）
- 每日定时从华为内网科技网站搜索关键词、生成简明 Markdown 研报

## 二、需求总览（全部已确认）

| 编号 | 需求 | 决策 |
|------|------|------|
| R1 | 定时调度 | Hermes cronjob，调度时间在 sites.json 的 `schedule` 字段设置 |
| R2 | 关键词 | **全局统一**，所有网站共用 `global_keywords` |
| R3 | 排序截取 | 时间降序 → 热度降序 → 前 10 篇 |
| R4 | 网站配置 | 独立 `config/sites.json`，四个华为内网站预填 |
| R5 | 研报格式 | Markdown，**按关键词分组**，每个关键词下「📌 落地案例」在前、「文章」在后，含标题+链接+日期+2-3句摘要 |
| R6 | 内网登录 | **用户手动登录一次，skill 复用浏览器 cookie 会话** |
| R7 | 凭据 | 不存密码，浏览器 profile 持久化 cookie |
| R8 | 执行效率 | 并行多网站 + 会话复用 |
| R9 | 研报命名 | 按日期独立文件：`reports/YYYY-MM-DD.md` |
| R10 | 跨站去重 | 标题相似度 > 80% 视为重复，保留第一个站点结果 |
| R11 | 元信息 | 不需要生成时间戳/执行耗时等元信息 |
| R12 | zsk 联动 | 预留扩展接口，暂不启用 |

## 三、技术方案

### 3.1 凭据方案

不做密码存储。用户手动登录一次 → 浏览器 cookie 持久化 → skill 每次复用。

- agent-browser 使用固定 Chrome user-data-dir
- 首次：用户手动打开网页完成登录，cookie 写入 profile
- 后续：skill 自动检测登录态，有效则跳过登录，过期则提示用户重新登录

### 3.2 整体流程

```
cronjob 按 sites.json schedule 触发
    → 加载 sites.json（网站列表 + 关键词）
    → 并行处理每个启用的网站：
        1. agent-browser 打开网站
        2. 检测登录态（过期则提醒用户）
        3. 逐关键词搜索
        4. 提取标题/摘要/链接/日期
        5. 排序去重取前 10
    → 汇总 → 生成 reports/YYYY-MM-DD.md
```

### 3.3 文件结构

```
research-skill/
├── SKILL.md                    # skill 定义
├── config/
│   └── sites.json              # 网站 + 调度 + 关键词
├── scripts/
│   └── setup.bat               # Windows 初始化脚本
├── reports/                    # 每日研报
│   └── 2026-06-25.md
├── README.md
└── REQUIREMENTS.md
```

### 3.4 sites.json 结构

```json
{
  "schedule": "0 9 * * *",
  "global_keywords": ["大模型", "Agent", "RAG", "MCP"],
  "max_results_per_site": 10,
  "time_range_days": 7,
  "sites": [
    {
      "name": "3ms",
      "base_url": "https://3ms.huawei.com",
      "search_url_template": "https://3ms.huawei.com/search?q={keyword}&sort=time",
      "selectors": { "search_input": "...", "result_item": "...", ... },
      "enabled": true
    }
  ]
}
```

### 3.5 研报输出格式（已确认）

```markdown
# 科技行业研报 — 2026-06-25

## 大模型
📌 落地案例
- [搜索推荐团队基于 DeepSeek-V3 的意图理解重构](链接) — 06-24 — 3ms
  将搜索意图分类从规则引擎迁移到大模型推理，线上准确率从 82% 提升至 94%。

文章
1. [大模型训练稳定性：Loss Spike 根因分析与修复](链接) — 06-25 — 3ms
   总结了 loss spike 的三类根因，给出检测脚本和修复策略。
2. [大模型长上下文窗口的位置编码研究](链接) — 06-23 — 2012实验室
   比较了 RoPE、ALiBi、NoPE 在 128K 上下文下的表现。

## AI Agent
📌 落地案例
- [SRE 团队基于多 Agent 的告警自愈系统](链接) — 06-24 — 3ms
  三个 Agent 协作完成告警分级→诊断→修复，MTTR 从 45min 降至 8min。
```

规则：H2 按关键词分，每条含标题+链接+日期+来源站点，案例无编号、文章有编号，跨站去重。

### 3.6 扩展接口（zsk 预留）

- 研报输出路径和格式保持与 zsk 的 `reports/` 兼容
- sites.json 预留 `zsk_integration` 字段，后续填入 zsk 项目路径即可启用自动同步
- 不增加任何依赖，纯路径配置即可打通

## 四、确认状态

全部 12 项需求已对齐确认，详见第二章需求总览。

## 五、开发计划

| 阶段 | 内容 | 状态 |
|------|------|------|
| P1 | 项目骨架 + SKILL.md | ← 当前 |
| P2 | sites.json 模板 + 解析 | 待开始 |
| P3 | 单站搜索抓取 | 待开始 |
| P4 | 多站并行 + 研报生成 | 待开始 |
| P5 | cronjob 注册 | 待开始 |
| P6 | Windows 部署测试 | 待开始 |
| P7 | 优化报告 | 待开始 |
