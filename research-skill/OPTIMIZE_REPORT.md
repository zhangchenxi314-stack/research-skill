# Research Skill — 开发完成与优化报告

## 一、项目概况

| 维度 | 说明 |
|------|------|
| 项目 | research-skill：每日定时从华为内网抓取科技内容生成研报 |
| 类型 | Hermes Agent skill（无独立代码，纯指令驱动） |
| 部署 | Windows 主机（内网环境，agent-browser + Hermes） |
| 状态 | 开发完成，待 Windows 实测 |

## 二、交付物清单

| 文件 | 行数 | 职责 |
|------|------|------|
| `skills/research-skill/SKILL.md` | ~225 | 核心 skill 定义，Agent 执行指南 |
| `skills/research-skill/references/agent-browser-guide.md` | 108 | 浏览器交互参考 |
| `config/sites.json` | 95 | 4 个网站 + 5 个关键词 + 调度配置 |
| `reports/EXAMPLE.md` | ~180 | 研报格式示例（最终版） |
| `scripts/setup.bat` | 139 | Windows 一键部署 |
| `scripts/setup.sh` | 40 | macOS 开发辅助 |
| `README.md` | 83 | 项目说明 |
| `REQUIREMENTS.md` | ~130 | 需求分析报告 |

总计 8 个文件，~1000 行。

## 三、设计决策回顾

| 决策 | 理由 | 风险 |
|------|------|------|
| 不存密码 | 安全零涉密，用户手动登录一次 | cookie 过期需人工介入 |
| 全局关键词 | 管理简单，一处改全网生效 | 无法做到网站粒度的精准搜索 |
| 动态 H2 标题 | 研报反映实际趋势而非搜索词列表 | 依赖 Agent 归纳能力 |
| skill 模式非代码 | 零依赖、易部署、易修改 | 依赖 LLM 执行质量 |
| delegate_task 并行 | 多网站并发，总耗时 = 最慢的站 | 并发数受 Hermes 限制（≤3） |
| 跨站去重 80% | 防重复但不过度合并 | 阈值可能需要实测调优 |

## 四、已知局限与风险

### 4.1 核心风险

**R1 — Agent 执行质量不可控**
- 问题：整个 skill 依赖 LLM 正确理解并执行每一步
- 影响：弱模型可能跳步、误读 selector、生成空洞内容
- 缓解：SKILL.md 反复强化关键指令（铁律、防复用、提取原则）
- 验证：Windows 上实际跑 3-5 天，对比研报质量和网站原文

**R2 — agent-browser 登录态失效**
- 问题：SSO cookie 过期后整个流程阻断
- 影响：当天无研报产出
- 缓解：Step 2 检测登录态，失败时在研报开头提醒
- 增强方向：登录失败时通过 Hermes 消息通知用户（需 gateway 配置）

**R3 — 网站改版导致 selector 失效**
- 问题：sites.json 中的 CSS 选择器依赖当前页面结构
- 影响：提取不到数据，研报为空
- 缓解：agent-browser-guide 中有文本模糊匹配的 fallback
- 增强方向：定期用 test_single_site.py 脚本验证 selector 有效性

### 4.2 内容质量局限

**L1 — 概念概述依赖 Agent 合成能力**
- 趋势概述要求从多篇文章中提炼共同主题，需要较强的归纳能力
- 弱模型可能写出泛泛的定义而非趋势洞察
- 缓解：格式规则要求「基于搜索结果提炼，不凭空编造」

**L2 — 案例描述深度受限于原文质量**
- 如果原文本身没有给出指标和效果数据，案例描述就会空洞
- 这不是 skill 的问题，但确实影响研报可读性
- 缓解：Pitfalls #9 要求「缺乏指标的案例不如直接贴原文链接」

**L3 — 搜索结果的时效排序**
- 排序依赖网站的 `sort=time` 参数，如果网站不支持或实现有问题，排序可能不准
- 缓解：Agent 拿到结果后自己再按提取到的日期做二次排序

### 4.3 平台局限

**P1 — Mac 无法完整测试**
- agent-browser 和 Chrome for Testing 在 Mac 上需要额外配置
- 内网网站 Mac 无法访问
- 缓解：setup.sh 仅做开发辅助，不期望能跑通完整流程

**P2 — 首个真实网站调试成本高**
- sites.json 中的 URL 和 selector 需要在实际网站上用 DevTools 验证
- 四个网站 × 两种搜索方式 × 多个 selector = 预计 1-2 小时调试

## 五、优化方向

### 短期（部署前）

| 编号 | 优化项 | 优先级 | 说明 |
|------|--------|--------|------|
| S1 | 验证 sites.json 选择器 | 高 | 在 Windows 上用 Chrome DevTools 逐个确认 selector 能匹配到元素 |
| S2 | 确认登录 SSO 流程 | 高 | 用 agent-browser 手动测试一次：打开网站 → 检测登录态 → 确认 logged_in_indicator 正确 |
| S3 | 单站端到端测试 | 高 | 选一个网站（建议 3ms），手动跑一次搜索→提取→生成研报的完整流程 |

### 中期（运行 1-2 周后）

| 编号 | 优化项 | 说明 |
|------|--------|------|
| M1 | 调优跨站去重阈值 | 根据实际去重效果调整 80% 阈值 |
| M2 | 调整 global_keywords | 根据研报内容质量和覆盖度增减关键词 |
| M3 | 登录过期自动通知 | 配置 Hermes gateway 消息推送，登录过期时主动提醒 |
| M4 | 研报质量评分 | 人工对比 3-5 天研报和网站原文，评估信息密度和准确度 |

### 长期（稳定运行后）

| 编号 | 优化项 | 说明 |
|------|--------|------|
| L1 | zsk 知识库对接 | 启用 `zsk_integration`，研报自动纳入 zsk JSON 知识库 |
| L2 | 多维度搜索 | 每个网站支持独立关键词列表（当前为全局统一） |
| L3 | 搜索结果分页 | 当第一页不足 10 篇时自动翻页 |
| L4 | 研报趋势追踪 | 对比连续多天的研报，标注「持续热点」「新出现」「热度下降」 |

## 六、部署 Checklist

在 Windows 上执行以下步骤：

```
[ ] 1. 将 research-skill/ 文件夹拷贝到 Windows 主机
[ ] 2. 安装 agent-browser + Chrome for Testing
[ ] 3. 设置 AGENT_BROWSER_EXECUTABLE_PATH 环境变量
[ ] 4. 安装 Hermes Agent
[ ] 5. 运行 scripts/setup.bat
[ ] 6. 编辑 config/sites.json，用 DevTools 验证所有 selector
[ ] 7. 手动用 Chrome 登录所有目标网站一次
[ ] 8. 单站测试：对 Hermes 说「用 agent-browser 打开 3ms 搜索大模型，提取前 3 条」
[ ] 9. 注册 cronjob：对 Hermes 说「加载 research-skill，读 sites.json 注册定时任务」
[ ] 10. 手动触发一次：cronjob action='run' job_id=<research-skill-daily>
[ ] 11. 检查 reports/ 生成的研报格式和内容质量
[ ] 12. 观察 3-5 天，确认稳定运行
```

## 七、实测 TODO

部署后在 Windows 上执行这些验证：

1. **登录态持久性**：第一天手动登录后，第二天 cron 是否还能自动通过登录检测？
2. **搜索结果准确性**：随机抽 5 篇文章，去原网站验证标题/链接/摘要是否一致
3. **去重效果**：同一篇文章是否在跨站去重中被正确处理？
4. **研报可读性**：找一位同事读一遍，是否能快速了解本周技术动态？
5. **执行耗时**：从 cron 触发到研报生成，总耗时多少？是否有优化空间？
