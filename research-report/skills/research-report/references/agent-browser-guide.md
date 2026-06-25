# agent-browser 交互参考

## 工作模式

agent-browser 用 Chrome for Testing 驱动网页交互。操作流程：

1. `open` 到目标 URL
2. `snapshot` 获取页面可交互元素（每个元素有 ref ID，如 `@e12`）
3. 通过 ref ID 或 CSS selector 执行 `click` / `fill`
4. `eval` 执行 JavaScript 提取数据

**关键**：selectors 是指南，实际操作可通过 ref ID 或 CSS selector。snapshot 后根据 selector 描述的文案/特征找到对应 ref。对于 JS 渲染的页面（如 CSDN），`read` 命令效果有限，优先用 `eval`。

## Cookie 持久化

所有网站共用公司统一 SSO，用户手动登录一次后 cookie 全局生效。

```bash
# 使用 Default Chrome profile（复用真实浏览器的登录态）
agent-browser --profile Default open <url>
# 或设置环境变量
set AGENT_BROWSER_PROFILE=Default
```

## 搜索流程（按 search_type）

### search_type = "url"

直接用 URL 模板搜索，用 `eval` 提取结果：

```bash
# 1. 打开搜索结果页
agent-browser open "https://so.csdn.net/so/search?q=大模型&t=all"

# 2. eval 提取结果（CSDN 示例）
agent-browser eval "
JSON.stringify(
  Array.from(document.querySelectorAll('.so-result-list h3 a')).slice(0,10).map(a => {
    const item = a.closest('.list-item');
    return {
      title: a.textContent?.trim(),
      href: a.href,
      summary: item?.querySelector('.item-bd__cont')?.textContent?.trim()?.substring(0,200) || ''
    };
  })
)"
```

### search_type = "form"

需要先填搜索框再提交：

```bash
# 1. 打开搜索页面
agent-browser open "https://example.com"

# 2. snapshot 找搜索框 ref
agent-browser snapshot
# 输出: @e5: textbox "#search-input"

# 3. 填入关键词（fill = clear + type）
agent-browser fill @e5 "大模型"

# 4. 点击搜索按钮
agent-browser click @e8
# 输出: @e8: button ".search-btn" "搜索"

# 5. snapshot 获取结果列表
agent-browser snapshot

# 6. eval 提取内容
agent-browser eval "<JS 提取代码>"
```

## 登录检测

每次执行只检测登录态：

```bash
# 打开第一个网站（带 profile 复用 cookie）
agent-browser --profile Default open "https://3ms.huawei.com"

# snapshot 检查
agent-browser snapshot

# 判断：查找全局 login.logged_in_indicator（如 .user-avatar）
# - 出现 → 已登录，继续执行
# - 未出现 → 未登录，停止当前 tick，在研报开头提醒用户手动登录
```

**未登录的处理**：
- 不要尝试自动登录
- 在子任务结果中标记 `login_status: "failed"`
- 汇总时在研报开头显示提醒块

## 结果提取策略

**推荐方式**：用 `eval` 执行 JS 从 DOM 直接提取结构化数据，一次拿到标题、链接、摘要。

```javascript
// 通用提取模板
JSON.stringify(
  Array.from(document.querySelectorAll('<result_item selector>')).slice(0,10).map(item => {
    return {
      title: item.querySelector('<title selector>')?.textContent?.trim() || '',
      href: item.querySelector('<link selector>')?.href || '',
      summary: item.querySelector('<summary selector>')?.textContent?.trim()?.substring(0,300) || '',
      date: item.querySelector('<date selector>')?.textContent?.trim() || ''
    };
  })
)
```

**备选方式**：用 `get text --all` 提取所有匹配元素的文本。

| 字段 | 提取方法 |
|------|---------|
| 标题 | `eval` JS 提取 `title` selector |
| 链接 | 从 title 元素的 href 属性获取，确保是绝对 URL |
| 日期 | `eval` JS 提取 `date` selector |
| 摘要 | `eval` JS 提取 `summary` selector → 直接截取，不加工不补全 |

**提取原则**（核心）：
- 只提取页面上实际存在的内容
- 摘要为空就为空，不编造
- 链接无效就跳过该条
- 标题为空就跳过该条

## 翻页处理

如果搜索结果有多页，默认只取第 1 页（前 `max_results_per_site` 条在大部分网站的第一页就能覆盖）。

## CSDN 专用 Selector

```json
{
  "search_type": "url",
  "search_url_template": "https://so.csdn.net/so/search?q={keyword}&t=all",
  "search_selectors": {
    "result_item": ".so-result-list .list-item",
    "title": "h3 a",
    "link": "h3 a[href]",
    "date": ".item-ft span",
    "summary": ".item-bd__cont"
  },
  "eval_script": "Array.from(document.querySelectorAll('.so-result-list h3 a')).slice(0,10).map(a => ({ title: a.textContent.trim(), href: a.href, summary: (a.closest('.list-item')?.querySelector('.item-bd__cont')?.textContent?.trim() || '').replace(/(\d+[\.\d万+]*)\s*.{2,20}?\d{4}-\d{2}(-\d{2})?$/g, '').trim() }))",
  "note": "摘要末尾带有阅读量/作者/日期，eval 中用正则清理。如需日期可从 item-ft span 单独提取。"
}
```

## 错误处理

| 错误 | 处理 |
|------|------|
| open 超时 | 重试 1 次，仍失败则跳过该网站 |
| snapshot 找不到 selector | 尝试用文本模糊匹配（如找包含"搜索"的按钮） |
| eval 无结果 | 尝试不同的 selector 组合，或改用 `get text` |
| 搜索无结果 | 标记该关键词结果为 0，继续下一个关键词 |
| read 返回空 | JS 渲染页面需用 eval，read 只适合静态内容 |
