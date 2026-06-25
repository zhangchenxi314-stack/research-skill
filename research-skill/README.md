# Research Skill

基于 Hermes Agent + agent-browser 的每日科技研报自动生成 skill。从企业内网科技网站搜索关键词、归纳趋势、生成结构化 Markdown 日报。

## 适用环境

| 维度 | 要求 |
|------|------|
| 操作系统 | Windows 10 / 11 |
| 运行时 | Hermes Agent（已安装） |
| 浏览器 | agent-browser CLI + Chrome for Testing |
| 网络 | 可访问目标企业内网网站（VPN / 内网环境） |
| 凭据 | 无需存储密码——用户在浏览器中手动登录一次，skill 复用 cookie 会话 |

## 快速开始

```
1. 将 research-skill/ 文件夹拷贝到 Windows 主机
2. 双击 scripts/setup.bat 完成环境检测和 skill 安装
3. 在 Chrome 中手动登录所有目标网站一次（cookie 自动保存）
4. 编辑 config/sites.json，用浏览器 DevTools 验证所有 CSS 选择器
5. 对 Hermes 说出下方场景对应的提示词
```

## 项目结构

```
research-skill/
├── README.md                          # 本文档
├── REQUIREMENTS.md                    # 需求分析报告
├── OPTIMIZE_REPORT.md                 # 优化建议 + 风险清单
├── config/
│   └── sites.json                     # 网站列表 + 关键词 + 调度时间
├── scripts/
│   ├── setup.bat                      # Windows 部署脚本
│   └── setup.sh                       # macOS 开发辅助
├── skills/research-skill/
│   ├── SKILL.md                       # skill 定义（Agent 执行指南）
│   └── references/
│       └── agent-browser-guide.md     # agent-browser 命令参考
└── reports/
    └── EXAMPLE.md                     # 研报格式示例
```

## 使用场景与提示词

以下提示词直接复制给 Hermes Agent 即可，无需修改（Agent 会自动读取配置文件中的路径和参数）。

### 场景一：首次安装与注册定时任务

注册后每天按 `sites.json` 中设定的时间自动执行。

```
加载 research-skill。读取 config/sites.json 中的 schedule 字段，
使用 cronjob 工具注册一个名为 research-skill-daily 的每日定时任务。
任务工作目录为当前项目根目录。
```

### 场景二：手动触发一次研报（测试用）

不等待定时触发，立即执行一次完整的搜索和报告生成。

```
加载 research-skill。读取 config/sites.json，对每个启用的网站
用 agent-browser 搜索 global_keywords 中的关键词，提取结果后
按内容主题动态归纳，生成 reports/YYYY-MM-DD.md 格式的研报。
所有内容必须来源于网页实际提取，禁止编造。案例按时间从新到旧排列。
```

### 场景三：修改调度时间

修改 `config/sites.json` 中的 `schedule` 字段后，更新已注册的定时任务。

```
加载 research-skill。读取 config/sites.json 获取新的 schedule，
使用 cronjob 工具更新 research-skill-daily 的调度时间。
```

### 场景四：调整关键词或网站

修改 `config/sites.json` 后无需重新注册，下次定时触发自动生效。如需立即验证：

```
加载 research-skill。我已更新了 config/sites.json 中的关键词/网站，
请手动执行一次搜索，验证新配置是否能正常提取到内容。
```

### 场景五：检查定时任务状态

```
加载 research-skill。使用 cronjob 工具查看 research-skill-daily
的运行状态，告诉我最近一次执行的时间和生成的报告路径。
```

### 场景六：单站调试

验证某个网站的登录态和搜索选择器是否正常。

```
加载 research-skill。用 agent-browser 打开 {网站名}，检测登录态。
如果已登录，搜索关键词「大模型」，提取前 3 条结果，展示标题和链接。
不要生成完整报告，仅验证搜索和提取流程。
```

### 场景七：登录态过期处理

当定时任务报告开头出现「⚠ 以下网站需要手动登录」时执行。

```
我已在 Chrome 中重新登录了所有目标网站，cookie 已更新。
请手动触发一次研报生成，验证登录态是否恢复正常。
```

## 配置说明

`sites.json` 关键字段：

| 字段 | 说明 |
|------|------|
| `schedule` | cron 表达式，默认 `"0 9 * * *"`（每天 9:00） |
| `login.type` | 固定为 `"sso"`，所有网站共用统一登录 |
| `login.logged_in_indicator` | 用于检测登录态的 CSS 选择器 |
| `global_keywords` | 全局搜索关键词列表，所有网站共用 |
| `sites[].name` | 网站名称，用于研报中的来源标注 |
| `sites[].search_type` | `"url"`（直接 URL 搜索）或 `"form"`（填表搜索） |
| `sites[].search_selectors` | 搜索相关的 CSS 选择器，需在网站上验证 |
| `sites[].enabled` | `true` 启用，`false` 暂停该网站的搜索 |

## 核心设计

- **零密码存储**：不保存任何账号密码，用户手动登录一次后复用浏览器 cookie
- **SSO 统一登录**：所有内网站共用公司统一认证，一次登录全局生效
- **动态标题**：H1 标题根据报告内容自动提炼，不用固定的「科技行业研报」
- **主题归纳**：H2 标题根据实际搜索结果动态分组，不照搬搜索关键词
- **系统化叙事**：每条案例遵循「问题 → 方案 → 效果 → 启示」结构，用词严谨
- **时效优先**：搜索结果按时间排序，案例从新到旧排列

## 依赖

- [Hermes Agent](https://hermes-agent.nousresearch.com/docs/)
- [agent-browser](https://github.com/nousresearch/agent-browser) CLI
- Chrome for Testing（agent-browser 自动管理）
- 目标企业内网访问权限
