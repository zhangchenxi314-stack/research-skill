---
name: research-skill
description: "Use when the user asks to research, scrape, or generate a daily tech report from configured websites. Handles scheduled web scraping via agent-browser, keyword search, and Markdown report generation."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [research, scraping, reporting, agent-browser, scheduled]
---

# Research Skill — 每日科技研报生成

## Overview

从 `config/sites.json` 中配置的科技网站自动搜索关键词、提取最新内容，生成带原文链接的 Markdown 日报。

**核心设计**：不存储密码。用户在浏览器中**手动登录一次**，skill 复用持久化的浏览器 cookie 会话。登录过期时提示用户重新登录。

**铁律**：研报中所有内容必须严格来源于目标网站的实际搜索结果。禁止凭空生成、编造标题、虚构案例、补全摘要。提取不到的内容宁可留空，绝不能伪造。

**每天独立执行**：每次 cron 触发都是一次全新的搜索。禁止复用前一天或任何历史研报中的内容。如果某个方向今天没有搜到新内容，就不写这个方向的 H2，绝不拿昨天的东西凑数。

**防复用措施（强制执行）**：
1. **禁止读取 `reports/` 目录**：不读、不参考、不打开任何历史研报文件。只从今天的搜索结果中取材。
2. **每条内容都有出处**：研报中每条案例的标题和链接必须来自今天 agent-browser snapshot/extract 的实际输出。如果写不出来出处，说明内容是编的。

## When to Use

- 每天定时自动执行（通过 cronjob）
- 手动触发研报生成
- 首次设置或更新网站配置后

## Workflow（每次执行）

### Step 1: 加载配置

Read `{PROJECT_DIR}/config/sites.json` — 获取 `schedule`、`global_keywords`、`sites` 列表。

### Step 2: 并行搜索每个网站

For each site where `enabled: true`, use `delegate_task` to process in parallel:

**每个子任务流程：**

1. **打开网站** — agent-browser `open` 到 `base_url`
2. **检测登录态** — `snapshot` 页面，检查是否包含全局 `login.logged_in_indicator`（如 `.user-avatar`）：
   - 出现 → 已登录（所有网站共用同一 SSO 登录态）
   - 未出现 → 未登录，停止子任务，标记 `login_status: "failed"`
3. **逐关键词搜索** — 对 `global_keywords` 中每个词，按 `search_type` 执行：
   - `search_type: "url"` — 直接 `open` 到 `search_url_template`（替换 `{keyword}`），然后用 `eval` 执行 JS 提取结果
   - `search_type: "form"` — `open` 到 `search_url` → `snapshot` 找输入框 → `fill` 关键词 → `click` 搜索按钮
4. **提取结果** — 用 `eval` 执行 JavaScript 从 DOM 提取（**只提取实际内容，禁止编造**）：
   - 标题（`title` selector）
   - 链接（`link` selector）
   - 日期（`date` selector）
   - 摘要（`summary` selector），直接截取页面原文或实际摘要，**禁止 AI 补全或改写**；如页面无摘要字段，留空
5. **排序截取** — 按日期降序（最新在前），取前 `max_results_per_site` 篇。**如果有「最新」排序选项必须点击使用**，确保内容时效性
6. **返回结构化数据** — 返回 JSON 格式的结果列表（每条含标题、链接、日期、摘要、来源站点名）

### Step 3: 跨站去重

在汇总结果之前，对所有网站的结果进行跨站去重：

- **去重依据**：标题相似度 > 80%（去除标点空格后对比）
- **保留策略**：同一篇文章出现在多个网站时，保留第一个（来源 `sites.json` 中排在前面的网站）
- **记录溯源**：在保留的文章上标注「同时出现在：站点A、站点B」

### Step 4: 汇总生成研报

将所有网站的去重后结果**按内容主题动态归纳**（不是照搬关键词），生成 Markdown：

```
{PROJECT_DIR}/reports/YYYY-MM-DD.md
```

**研报格式（趋势概述 + 落地案例，主题动态归纳）：**

```markdown
# {根据报告内容自动提炼的标题，如「AI Agent 技术动态研报」}

## 一、{主题1}
本周 Agent 相关内容集中在... ← 趋势概述（3-5句）

📌 落地案例
1. 案例介绍和背景说明，问题是什么，采用了什么方案，效果如何。

   [文章标题](链接) — 2026-04-27 — CSDN
2. 案例介绍和背景说明...

   [文章标题](链接) — 2026-03-15 — CSDN

## 二、{主题2}
...
```

**格式规则：**

- H1 标题**根据本轮报告的实际内容动态提炼**，如「AI Agent 技术动态研报」「大模型落地趋势周报」。不使用固定的「科技行业研报」
- H2 标题**根据实际搜索结果动态归纳**，加上中文序号（一、二、三...）。例如搜到部署和微调两类内容，就拆为「一、大模型业务落地」和「二、大模型训练与微调」。内容少的关键词可以合并
- 每个 H2 下先写 **一段趋势概述（3-5 句）**：提炼该主题下的共同趋势和热点方向。基于搜索结果提炼，不凭空编造
- 然后是 `📌 落地案例`，案例用数字编号（1. 2. 3.）
- 每条案例格式：**先写案例介绍**（问题背景→方案→效果），然后**空一行**，**另起一行放链接+发布时间+来源**：
  ```
  1. {企业名/团队名}在{具体场景}中面临{具体问题}。为解决该问题，该团队采用{技术方案}，通过{关键设计}实现了{核心能力}。上线后{量化指标}，目前已{当前阶段}。该实践表明{从点到面的行业启示}。

     [文章标题](链接) — 2026-04-27 — CSDN
  ```
- **叙事要求**：从具体问题切入 → 展开方案细节 → 给出量化结果 → 点出行业启示。结构统一，用词严谨，避免口语化和主观评价（如「非常出色」「令人惊叹」）
- 发布时间从页面提取，格式为 YYYY-MM-DD；如无法提取日期则省略
- **案例按时间从新到旧排列**（最新在前），确保读者先看到最新动态
- 来源站点名直接引用 `sites[].name`
- 如果所有关键词都没有搜到任何内容，整个研报显示「今日无更新」

### Step 5: 如果检测到未登录

在研报开头添加醒目的提醒块：
```
> ⚠ 以下网站需要手动登录：[site1, site2]
> 请用 Chrome 打开网站完成登录，cookie 将自动保存到浏览器 profile。
```

## agent-browser 使用要点

### 环境要求

```bash
# Chrome for Testing 路径（Windows）
set AGENT_BROWSER_EXECUTABLE_PATH=<Chrome 安装路径>

# 保持 cookie 持久化（关键！）
set AGENT_BROWSER_PROFILE=Default

# agent-browser 二进制需在 PATH 中
agent-browser --version
```

### 关键命令

```bash
# 打开页面（不是 navigate！）
agent-browser open <url>

# 获取页面快照（查找可交互元素）
agent-browser snapshot

# 点击元素（用 ref ID 或 CSS selector）
agent-browser click <@ref | selector>

# 填入文本（clear + fill，比 type 更可靠）
agent-browser fill <@ref | selector> <text>

# 执行 JavaScript 提取数据（替代 extract，后者不存在）
agent-browser eval "<JS 代码>"

# 获取元素文本
agent-browser get text <selector> --all
```

### Cookie 持久化

agent-browser 使用固定的 Chrome user-data-dir（由 `AGENT_BROWSER_PROFILE` 环境变量指定或使用默认路径）。用户手动登录后 cookie 保存在此 profile 中，后续运行自动复用。

## 调度设置

首次部署时，Agent 应自动完成 cronjob 注册。步骤：

**1. 先从 sites.json 读取 schedule：**
```
read_file("{PROJECT_DIR}/config/sites.json") → 提取 schedule 字段
```

**2. 注册 cronjob：**

```
cronjob(
  action='create',
  schedule='<从 sites.json.schedule 读取>',
  name='research-skill-daily',
  skills=['research-skill'],
  prompt='执行每日研报生成：读 config/sites.json，对每个启用的网站用 agent-browser 搜索 global_keywords 中的关键词，提取结果（只取页面上实际内容，禁止编造），跨站去重后按内容主题动态归纳生成 H1 动态标题+H2 中文序号分节的研报，输出到 reports/YYYY-MM-DD.md。如果检测到未登录，在研报开头提醒用户手动登录。',
  workdir='{PROJECT_DIR}',
  enabled_toolsets=['terminal', 'file', 'delegation', 'browser']
)
```

**3. 验证：**
```
cronjob(action='list')  # 确认 research-skill-daily 状态正常
```

## sites.json 配置说明

| 字段 | 说明 |
|------|------|
| `schedule` | cron 表达式，如 `"0 9 * * *"`（每天 9:00） |
| `login.type` | 固定为 `"sso"`，所有网站共用公司统一登录 |
| `login.logged_in_indicator` | 全局登录态检测 CSS 选择器（如 `.user-avatar`），出现即已登录 |
| `global_keywords` | 全局关键词列表，所有网站共用 |
| `max_results_per_site` | 每个网站最多保留篇数 |
| `time_range_days` | 时间范围（天） |
| `sites[].name` | 网站名称（用于研报标注） |
| `sites[].base_url` | 网站根 URL（用于登录态检测） |
| `sites[].search_type` | 搜索方式：`"url"` 直接 URL 搜索 或 `"form"` 填表搜索 |
| `sites[].search_url_template` | URL 搜索模板，`{keyword}` 占位符（search_type=url 时使用） |
| `sites[].search_url` | 搜索页 URL（search_type=form 时使用） |
| `sites[].search_selectors` | 搜索相关 CSS 选择器（search_input, search_button, result_item, title, link, date, summary） |
| `sites[].eval_script` | 可选。专门针对该网站的 JS 提取脚本。如果不提供，Agent 根据 search_selectors 自行构造 |
| `sites[].enabled` | 是否启用 |

详细 agent-browser 交互说明见 `references/agent-browser-guide.md`。

## 扩展接口（zsk 知识库预留）

`sites.json` 预留 `zsk_integration` 字段。后续填入 zsk 项目路径即可启用自动同步：

```json
{
  "zsk_integration": {
    "enabled": false,
    "zsk_project_path": "C:\\Users\\xxx\\project\\zsk",
    "auto_copy_to_zsk_reports": false
  }
}
```

## Common Pitfalls

1. **agent-browser 找不到 Chrome** — 确认 `AGENT_BROWSER_EXECUTABLE_PATH` 指向 Chrome for Testing 可执行文件
2. **登录态过期** — 内网 SSO 通常 24h 过期。每天首次执行时检查登录态
3. **选择器失效** — 网站改版后 CSS 选择器可能变化。定期检查并更新 `sites.json`
4. **夏令时 / 时区** — 确保 Windows 时区设置正确，cron 按本地时间执行
5. **跨站去重误判** — 标题相似度 80% 阈值可能导致不同文章被错误合并或相同文章未去重。如发现问题调整阈值
6. **编造内容（最严重）** — 禁止 AI 生成标题、摘要、概念介绍。所有内容必须直接从网页提取。无摘要时留空，无结果时写「今日无更新」
7. **复用旧内容** — 禁止从历史研报或前一天的结果中复制内容。每天独立搜索，搜不到就不写。昨天的内容已经在昨天的研报里了
8. **概念介绍空洞** — 概述应提炼趋势和热点，不是从训练数据中背定义
9. **案例描述太薄** — 每条案例需含问题→方案→效果→启示四个要素，结构统一
10. **叙事主观化** — 避免口语化表达和主观评价（如「非常出色」「令人惊叹」「无疑是」）。用词严谨，以事实和数据驱动叙述

## Verification Checklist

- [ ] `sites.json` 中至少配置一个启用网站
- [ ] `AGENT_BROWSER_EXECUTABLE_PATH` 环境变量已设置
- [ ] 用户已在浏览器中手动完成登录（cookie 已保存）
- [ ] `reports/` 目录存在且可写
- [ ] cronjob 已注册（`research-skill-daily`），schedule 与 sites.json 一致
- [ ] 研报格式：H1 动态标题、H2 中文序号+动态归纳、案例数字编号、介绍→链接+日期→来源
- [ ] 每条案例描述足够详实，读者无需点进原文也能了解核心内容
- [ ] 跨站重复文章已去重
- [ ] 所有内容来源于网页提取，无编造
