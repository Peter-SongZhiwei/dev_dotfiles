# 变更日志 (Changelog) 生成指南

## 功能概述

通过 `generate_changelog` 操作读取 Git 日志，生成代码变更信息的 HTML 片段。支持两种模式：

- **时间线模式 (timeline)**：按时间范围展示提交记录
- **对比模式 (compare)**：对比两个 Git 引用（tag/branch/commit）之间的差异

## 操作参数

通过 `execute` 工具调用（完整参数 schema 可通过 `discover("generate_changelog")` 查看）：

```
操作: generate_changelog
参数:
  mode: "timeline"           # 必填: timeline(时间线) 或 compare(对比)
  repo_path: "/path/to/repo" # 可选，默认当前目录
  since: "2026-01-01"       # 可选，开始时间 (YYYY-MM-DD)，timeline 模式使用
  until: "2026-12-31"       # 可选，结束时间 (YYYY-MM-DD)，timeline 模式使用
  from_ref: "v1.0.0"        # 可选，起始 Git 引用 (tag/branch/commit)，compare 模式使用
  to_ref: "v1.1.0"          # 可选，结束 Git 引用 (tag/branch/commit)，compare 模式使用
  max_count: 100            # 可选，最大提交数，默认 100
  include_merges: false     # 可选，是否包含 merge 提交，默认 False
```

## 使用示例

### 时间线模式

生成指定时间范围内的所有提交记录：

```
操作: generate_changelog
参数:
  mode: "timeline"
  repo_path: "/home/10217503@zte.intra/01_project/ybtools/MCP/icenter-mcp"
  since: "2026-01-01"
  until: "2026-12-31"
  max_count: 50
```

### 对比模式

对比两个版本/分支之间的差异：

```
操作: generate_changelog
参数:
  mode: "compare"
  repo_path: "/home/10217503@zte.intra/01_project/ybtools/MCP/icenter-mcp"
  from_ref: "HEAD~10"
  to_ref: "HEAD"
```

## 返回格式

操作成功时返回：

```json
{
    "success": True,
    "data": {
        "html": "<div class=\"changelog\">...</div>",
        "count": 10,
        "mode": "timeline"
    },
    "message": "生成变更日志成功 - 共 10 条提交"
}
```

## HTML 输出样式

```html
<div class="changelog">
  <h2>变更日志</h2>
  <div class="changelog-meta">时间范围: 2026-01-01 ~ 2026-12-31 | 共 5 条提交</div>
  <div class="changelog-entries">
    <div class="entry">
      <span class="entry-date">2026-05-07 09:38</span>
      <span class="entry-author">10217503</span>
      <span class="entry-message">优化静态图表生成操作</span>
      <span class="entry-branch">5077862</span>
    </div>
  </div>
</div>
```

## 嵌入 iCenter 页面

返回的 HTML 可以直接嵌入 iCenter 页面：

```
1. 调用 generate_changelog 获取 HTML
   操作: generate_changelog
   参数: {mode: "timeline", since: "2026-01-01", until: "2026-12-31"}
   → 得到 data.html

2. 嵌入页面内容
   content = "<h1>项目变更日志</h1>" + changelog_result.data.html

3. 创建页面
   操作: create_page_by_url_with_content
   参数: {title: "变更日志", content: content, parent_url: "https://i.zte.com.cn/..."}
```

## 错误处理

| 场景 | error |
|------|-------|
| 模式无效 | `不支持的模式: {mode}，可选: timeline, compare` |
| 路径无效 | `路径 '{repo_path}' 不是 Git 仓库` |
| Git 引用无效 | `Git 引用 '{from_ref}' 不存在` |
| 无提交记录 | `指定范围内没有提交记录` |

## 适用场景

- **版本发布说明**：自动生成版本间的变更记录
- **周报/月报**：汇总代码提交情况
- **代码审查**：对比分支差异，展示变更概要
- **项目文档**：维护项目的变更历史
