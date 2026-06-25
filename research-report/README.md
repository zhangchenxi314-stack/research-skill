1|# Research Skill
2|
3|基于 Hermes Agent + agent-browser 的每日科技研报自动生成 skill。从企业内网科技网站搜索关键词、归纳趋势、生成结构化 Markdown 日报。
4|
5|## 适用环境
6|
7|| 维度 | 要求 |
8||------|------|
9|| 操作系统 | Windows 10 / 11 |
10|| 运行时 | Hermes Agent（已安装） |
11|| 浏览器 | agent-browser CLI + Chrome for Testing |
12|| 网络 | 可访问目标企业内网网站（VPN / 内网环境） |
13|| 凭据 | 无需存储密码——用户在浏览器中手动登录一次，skill 复用 cookie 会话 |
14|
15|## 快速开始
16|
17|```
18|1. 将 research-report/ 文件夹拷贝到 Windows 主机
19|2. 双击 scripts/setup.bat 完成环境检测和 skill 安装
20|3. 在 Chrome 中手动登录所有目标网站一次（cookie 自动保存）
21|4. 编辑 config/sites.json，用浏览器 DevTools 验证所有 CSS 选择器
22|5. 对 Hermes 说出下方场景对应的提示词
23|```
24|
25|## 项目结构
26|
27|```
28|research-report/
29|├── README.md                          # 本文档
30|├── REQUIREMENTS.md                    # 需求分析报告
31|├── OPTIMIZE_REPORT.md                 # 优化建议 + 风险清单
32|├── config/
33|│   └── sites.json                     # 网站列表 + 关键词 + 调度时间
34|├── scripts/
35|│   ├── setup.bat                      # Windows 部署脚本
36|│   └── setup.sh                       # macOS 开发辅助
37|├── skills/research-report/
38|│   ├── SKILL.md                       # skill 定义（Agent 执行指南）
39|│   └── references/
40|│       └── agent-browser-guide.md     # agent-browser 命令参考
41|└── reports/
42|    └── EXAMPLE.md                     # 研报格式示例
43|```
44|
45|## 使用场景与提示词
46|
47|以下提示词直接复制给 Hermes Agent 即可，无需修改（Agent 会自动读取配置文件中的路径和参数）。
48|
49|### 场景一：首次安装与注册定时任务
50|
51|注册后每天按 `sites.json` 中设定的时间自动执行。
52|
53|```
54|加载 research-report。读取 config/sites.json 中的 schedule 字段，
55|使用 cronjob 工具注册一个名为 research-report-daily 的每日定时任务。
56|任务工作目录为当前项目根目录。
57|```
58|
59|### 场景二：手动触发一次研报（测试用）
60|
61|不等待定时触发，立即执行一次完整的搜索和报告生成。
62|
63|```
64|加载 research-report。读取 config/sites.json，对每个启用的网站
65|用 agent-browser 搜索 global_keywords 中的关键词，提取结果后
66|按内容主题动态归纳，生成 reports/YYYY-MM-DD.md 格式的研报。
67|所有内容必须来源于网页实际提取，禁止编造。案例按时间从新到旧排列。
68|```
69|
70|### 场景三：修改调度时间
71|
72|修改 `config/sites.json` 中的 `schedule` 字段后，更新已注册的定时任务。
73|
74|```
75|加载 research-report。读取 config/sites.json 获取新的 schedule，
76|使用 cronjob 工具更新 research-report-daily 的调度时间。
77|```
78|
79|### 场景四：调整关键词或网站
80|
81|修改 `config/sites.json` 后无需重新注册，下次定时触发自动生效。如需立即验证：
82|
83|```
84|加载 research-report。我已更新了 config/sites.json 中的关键词/网站，
85|请手动执行一次搜索，验证新配置是否能正常提取到内容。
86|```
87|
88|### 场景五：检查定时任务状态
89|
90|```
91|加载 research-report。使用 cronjob 工具查看 research-report-daily
92|的运行状态，告诉我最近一次执行的时间和生成的报告路径。
93|```
94|
95|### 场景六：单站调试
96|
97|验证某个网站的登录态和搜索选择器是否正常。
98|
99|```
100|加载 research-report。用 agent-browser 打开 {网站名}，检测登录态。
101|如果已登录，搜索关键词「大模型」，提取前 3 条结果，展示标题和链接。
102|不要生成完整报告，仅验证搜索和提取流程。
103|```
104|
105|### 场景七：登录态过期处理
106|
107|当定时任务报告开头出现「⚠ 以下网站需要手动登录」时执行。
108|
109|```
110|我已在 Chrome 中重新登录了所有目标网站，cookie 已更新。
111|请手动触发一次研报生成，验证登录态是否恢复正常。
112|```
113|
114|## 配置说明
115|
116|`sites.json` 关键字段：
117|
118|| 字段 | 说明 |
119||------|------|
120|| `schedule` | cron 表达式，默认 `"0 9 * * *"`（每天 9:00） |
121|| `login.type` | 固定为 `"sso"`，所有网站共用统一登录 |
122|| `login.logged_in_indicator` | 用于检测登录态的 CSS 选择器 |
123|| `global_keywords` | 全局搜索关键词列表，所有网站共用 |
124|| `sites[].name` | 网站名称，用于研报中的来源标注 |
125|| `sites[].search_type` | `"url"`（直接 URL 搜索）或 `"form"`（填表搜索） |
126|| `sites[].search_selectors` | 搜索相关的 CSS 选择器，需在网站上验证 |
127|| `sites[].enabled` | `true` 启用，`false` 暂停该网站的搜索 |
128|
129|## 核心设计
130|
131|- **零密码存储**：不保存任何账号密码，用户手动登录一次后复用浏览器 cookie
132|- **SSO 统一登录**：所有内网站共用公司统一认证，一次登录全局生效
133|- **动态标题**：H1 标题根据报告内容自动提炼，不用固定的「科技行业研报」
134|- **主题归纳**：H2 标题根据实际搜索结果动态分组，不照搬搜索关键词
135|- **系统化叙事**：每条案例遵循「问题 → 方案 → 效果 → 启示」结构，用词严谨
136|- **时效优先**：搜索结果按时间排序，案例从新到旧排列
137|
138|## 依赖
139|
140|- [Hermes Agent](https://hermes-agent.nousresearch.com/docs/)
141|- [agent-browser](https://github.com/nousresearch/agent-browser) CLI
142|- Chrome for Testing（agent-browser 自动管理）
143|- 目标企业内网访问权限
144|