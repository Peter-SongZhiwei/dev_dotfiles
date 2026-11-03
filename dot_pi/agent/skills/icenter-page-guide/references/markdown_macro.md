# Markdown宏 (MarkdownMacro) 规范

## 概述

本规范详细介绍如何在icenter页面中创建和使用Markdown宏。

## 什么是Markdown宏？

Markdown宏是 icenter 提供的宏组件，用于渲染 Markdown 格式的内容。通过使用 Markdown宏，可以：
- 渲染标准的 Markdown 语法
- 从 GitHub 等平台迁移的 README 文档
- 使用 Markdown 语法编写技术文档

## 适用场景

✅ **适合使用Markdown宏的场景**：

1. **渲染 Markdown 格式的技术文档**：如从 GitHub 迁移的 README
2. **需要使用 Markdown 语法编写的内容**：如标题、列表、代码块等
3. **多平台文档同步**：一份 Markdown 多处使用
4. **结构化文档**：使用 Markdown 组织内容结构

❌ **不适合使用Markdown宏的场景**：

1. 简单的纯文本内容
2. 需要精确控制格式的复杂布局
3. 需要嵌入 icenter 特定宏的内容

## ⚠️ 重要：HTML结构要求

### ❌ 错误方式

```html
<!-- 错误示例：缺少必需的宏属性 -->
<div class="ze-macro">
    <div class="ze-macro-body">
        <p># 标题</p>
    </div>
</div>
```

```html
<!-- 错误示例：macro-id 格式不正确 -->
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="123">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText">
            <p>内容</p>
        </div>
    </div>
</div>
```

```html
<!-- 错误示例：缺少 data-node-key 属性 -->
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01k1234567890abcd">
    <div class="ze-macro-body">
        <div>
            <p>内容</p>
        </div>
    </div>
</div>
```

### ✅ 正确方式

```html
<!-- 正确格式：包含完整的宏属性 -->
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01kj9yn80n7e0edv8neycvgqammgs7p2">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># 标题</p>
        </div>
    </div>
</div>
```

## ⚠️ 完整示例：正确的HTML块结构（直接可用）

### 基础Markdown宏

```html
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01kj9yn80n7e0edv8neycvgqammgs7p2">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># icenter-mcp_page-guide Skill</p>
            <p>## 概述</p>
            <p>此Skill是icenter页面操作的综合指南。</p>
        </div>
    </div>
</div>
```

### 包含多级标题的Markdown宏

```html
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01kabcdef1234567890">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># 文档标题</p>
            <p>## 一级标题</p>
            <p>### 二级标题</p>
            <p>#### 三级标题</p>
            <p>正文内容...</p>
        </div>
    </div>
</div>
```

### 包含列表的Markdown宏

```html
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01klist001234567890">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># 功能列表</p>
            <p>## 无序列表</p>
            <p>- 项目1</p>
            <p>- 项目2</p>
            <p>- 项目3</p>
            <p>## 有序列表</p>
            <p>1. 第一项</p>
            <p>2. 第二项</p>
            <p>3. 第三项</p>
        </div>
    </div>
</div>
```

### 包含代码块的Markdown宏

```html
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01kcode001234567890">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># 代码示例</p>
            <p>```python</p>
            <p>def hello():</p>
            <p>    print("Hello World")</p>
            <p>```</p>
            <p>以上是Python代码示例。</p>
        </div>
    </div>
</div>
```

### 包含表格的Markdown宏

```html
<div class="ze-macro" macro-key="MarkdownMacro" macro-id="01ktable001234567890">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># 数据表格</p>
            <p>| 名称 | 类型 | 说明 |</p>
            <p>|------|------|------|</p>
            <p>| id | string | 唯一标识 |</p>
            <p>| name | string | 名称 |</p>
            <p>| value | number | 数值 |</p>
        </div>
    </div>
</div>
```

### 完整的Markdown宏（包含所有推荐属性）

```html
<div class="ze-macro" 
     macro-key="MarkdownMacro" 
     macro-id="01kfull000000000001"
     block-id="mdFull01"
     block-title="完整Markdown宏示例"
     block-tags="Markdown,示例,文档"
     enable-ai-check=""
     enable-ai-create="y">
    <div class="ze-macro-body">
        <div data-node-key="data-markdownText" style="border:1px dashed #D9D9D9">
            <p># 完整示例</p>
            <p>## 概述</p>
            <p>这是一个完整的Markdown宏示例。</p>
            <p>## 代码示例</p>
            <p>```python</p>
            <p>def example():</p>
            <p>    return "example"</p>
            <p>```</p>
            <p>## 列表</p>
            <p>- 项目1</p>
            <p>- 项目2</p>
            <p>- 项目3</p>
        </div>
    </div>
</div>
```

## 核心属性说明

| 属性名称 | 说明 | 必需 | 示例值 |
|---------|------|------|-------|
| macro-key | 宏类型标识 | 是 | `MarkdownMacro` |
| macro-id | 宏的标识符（服务端会改写为 32 位 `01m…`，提交值不影响渲染） | 建议 | `01kj9yn80n7e0edv8neycvgqammgs7p2` |
| data-node-key | 数据节点标识 | 是 | `data-markdownText` |
| block-id | 块的唯一标识符（推荐） | 推荐 | `md00001` |
| block-title | 块的标题（推荐） | 推荐 | `Markdown内容` |
| enable-ai-create | 是否启用AI创建 | 否 | `y` / `n` |
| enable-ai-check | 是否启用AI检查 | 否 | 空字符串表示启用 |

## macro-id 生成规则

> ✅ **2026-10-09 复核**：`macro-id` 由**服务端保存时改写**（一律变成 32 位 `01m…`），
> 提交值不参与渲染判定——实测提交 `macro-id='123'` 的 MarkdownMacro **仍正常渲染**
> （`123` 被服务端记为 `source-macro-id`）。因此"必须以 01k 开头，否则无法渲染"的说法**不成立**。

- **建议**（仅可读性）：用 32 位 `01k…` 形式，便于人工辨认；非渲染必需
- **示例**: `01kj9yn80n7e0edv8neycvgqammgs7p2`

## 创建流程

1. 准备 Markdown 内容
2. 生成唯一的 macro-id（以 `01k` 开头）
3. 构建宏HTML结构
4. 将 Markdown 内容转换为 HTML `<p>` 标签
5. 使用 `create_block_by_url` 或 `create_page_by_url_with_content` 创建

## 注意事项

1. **⚠️ macro-id 由服务端改写**（2026-10-09 复核）：提交什么值都会被改写成 `01m…`，不影响渲染；用 `01k` 前缀仅为可读性
2. **⚠️ 必须包含 data-node-key="data-markdownText" 属性**：否则内容无法正确渲染
3. **✅ 建议添加边框样式**：`style="border:1px dashed #D9D9D9"` 标识Markdown区域
4. **✅ Markdown内容转换为HTML**：每个Markdown段落需要用 `<p>` 标签包裹
5. **✅ 列表项也需要用 `<p>` 标签包裹**
