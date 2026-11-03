# 折叠宏 (Collapse/Fold) 规范

## 概述

本规范详细介绍如何在icenter页面中创建和使用折叠宏。

## 什么是折叠宏？

折叠宏是 icenter 提供的交互式组件，使用 HTML5 的 `<details>` 和 `<summary>` 标签实现。用户可以点击标题展开或折叠内容，常用于：
- 嵌入代码块时保持页面整洁
- 长内容的分段展示
- 详细实现细节的隐藏展示

## 适用场景

✅ **适合使用折叠宏的场景**：

1. **嵌入代码块时**（强烈推荐）：将代码块默认折叠，使页面更简洁
2. **嵌入JSON/XML/YAML配置**：数据结构默认折叠，需要时展开查看
3. **长内容的分段展示**：将长文档按章节折叠
4. **详细实现细节**：实现细节默认折叠，概要信息默认展示
5. **用户需要时才查看的辅助信息**：如FAQ、备注等

❌ **不适合使用折叠宏的场景**：

1. 简短的几句话内容
2. 始终需要显示的重要内容
3. 用户必须看到的关键信息

## ⚠️ 重要：HTML结构要求

### ❌ 错误方式

```html
<!-- 错误示例：缺少 block-id 属性 -->
<details>
    <summary>标题</summary>
    <p>折叠内容</p>
</details>
```

```html
<!-- 错误示例：summary 标签缺少样式 -->
<details block-id="abc123" open>
    <summary>标题</summary>
    <p>内容</p>
</details>
```

### ✅ 正确方式

```html
<!-- 正确格式：包含 block-id 和正确的 summary 样式 -->
<details block-id="8pMfAXSz" collapse-state="open" open>
    <summary style="margin-left: -1rem;">标题</summary>
    <p>折叠内容1</p>
    <p>折叠内容2</p>
</details>
```

## ⚠️ 完整示例：正确的HTML块结构（直接可用）

### 基础折叠宏（默认展开）

```html
<details block-id="8pMfAXSz" collapse-state="open" open>
    <summary style="margin-left: -1rem;">点击展开查看内容</summary>
    <p>这是折叠在里面的内容。</p>
    <p>可以包含任意HTML内容。</p>
</details>
```

### 默认折叠的折叠宏

```html
<details block-id="collapse02" collapse-state="closed">
    <summary style="margin-left: -1rem;">点击展开查看详情</summary>
    <p>这是默认折叠的内容。</p>
    <p>只有点击标题才会展开显示。</p>
</details>
```

### 包含代码块的折叠宏

```html
<details block-id="codeEx01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">Python代码示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:python">
def get_page_detail_by_url(page_url):
    page_info = parse_icenter_url(page_url)
    if not page_info:
        raise ValueError("parent_page_url is invalid")
    space_id = page_info["space_id"]
    page_id = page_info["page_id"]
    return raw_icenter_apis.get_page_detail(page_id, space_id)
    </pre>
    <p><br/></p>
</details>
```

### 包含JSON数据的折叠宏（推荐）

```html
<details block-id="json01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">JSON配置数据</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
{
    "api_name_en": "Query API",
    "api_name_zh": "查询接口",
    "uri": "/api/query",
    "method": "GET",
    "tags_i18n": {
        "en-US": "Query API",
        "zh-CN": "查询接口"
    }
}
    </pre>
    <p><br/></p>
</details>
```

### 包含XML数据的折叠宏

```html
<details block-id="xml01" collapse-state="closed">
    <summary style="margin-left: -1rem;">XML配置</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:xml">
<?xml version="1.0" encoding="UTF-8"?>
<config>
    <server>
        <host>localhost</host>
        <port>8080</port>
    </server>
    <database>
        <type>mysql</type>
        <name>icenter</name>
    </database>
</config>
    </pre>
    <p><br/></p>
</details>
```

### 包含YAML数据的折叠宏

```html
<details block-id="yaml01" collapse-state="closed">
    <summary style="margin-left: -1rem;">YAML配置</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:yaml">
server:
  host: localhost
  port: 8080
database:
  type: mysql
  name: icenter
  user: admin
  password: secret
    </pre>
    <p><br/></p>
</details>
```

### 多个折叠宏组合

```html
<p>下面是代码示例：</p>

<details block-id="multi01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">Python示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:python">
def hello():
    print("Hello World")
    </pre>
    <p><br/></p>
</details>

<details block-id="multi02" collapse-state="closed">
    <summary style="margin-left: -1rem;">JavaScript示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
function hello() {
    console.log("Hello World");
}
    </pre>
    <p><br/></p>
</details>

<details block-id="multi03" collapse-state="closed">
    <summary style="margin-left: -1rem;">Java示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:java">
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
    </pre>
    <p><br/></p>
</details>
```

### 完整的折叠宏（包含所有推荐属性）

```html
<details block-id="fullCol" 
        collapse-state="open" 
        open
        block-title="完整折叠宏示例" 
        block-tags="示例,折叠,代码">
    <summary style="margin-left: -1rem;">点击展开查看完整示例</summary>
    <p><br/></p>
    <p>这是折叠宏的完整示例。</p>
    <p>可以包含任意类型的HTML内容。</p>
    <pre class="prettyprint linenums brush:python">
# 示例代码
def example():
    return "example"
    </pre>
    <p><br/></p>
</details>
```

## 核心属性说明

| 属性名称 | 说明 | 必需 | 示例值 |
|---------|------|------|-------|
| block-id | 块的唯一标识符，8位字符 | 推荐 | `8pMfAXSz` |
| collapse-state | 折叠状态 | 是 | `open` / `closed` |
| open | 展开属性（可选，设置则默认展开） | 否 | 无值属性 |
| summary | 折叠标题，用户点击的部分 | 是 | - |

## collapse-state 属性值

| 值 | 说明 | 效果 |
|---|------|------|
| `open` | 期望默认展开 | ⚠️ **2026-10-09 实测：页面阅读态仍渲染为折叠态**（`open` 属性 + `collapse-state="open"` 均不展开），不要依赖"默认展开" |
| `closed` | 默认折叠 | 页面加载时内容隐藏（与实测一致） |

> ⚠️ **重要（2026-10-09 实测）**：通过 API 创建的 `<details>`（无论 `collapse-state="open"` 还是 `open`）
> 在页面阅读态**一律显示为折叠状态**（两个独立页面、3 个 details 元素、浏览器截图确认）。
> 因此：**需要用户直接看到的内容不要放进折叠宏**（含代码块）；折叠宏适合"按需展开"的辅助信息。

## ⚠️ 可更新性：折叠宏必须包在内容块里（2026-10-09 实测）

裸 `<details>`（页面级、不在 `block-type="custom"` 内）**无法被 `update_block_by_url` 更新**——
实测报"未指定内容块"，工具自动诊断为"折叠宏（details）且不在任何内容块内"。
要后续可改折叠态/标题/正文，创建时就写成：

```html
<div block-type='custom' block-title='…'>
  <details block-id='…' collapse-state='closed'><summary …>…</summary><p>…</p></details>
</div>
```

之后用 `update_block_by_url(target_block_id=外层内容块id, content='<details>…</details>')` 更新即可（见 `block_update.md` §8.3）。

## 创建流程

1. 确定折叠内容的标题和类型
2. 生成唯一的 block-id（8位字符）
3. 设置 collapse-state（`open` 或 `closed`）
4. 在 `<summary>` 标签中设置标题
5. 在 `<details>` 标签内添加需要折叠的内容
6. 使用 `create_block_by_url` 或 `create_page_by_url_with_content` 创建

## 注意事项

1. **⚠️ 必须设置 block-id**：便于后续管理和更新
2. **⚠️ summary 标签必须添加样式**：`style="margin-left: -1rem;"` 调整缩进
3. **✅ 建议在折叠宏中嵌入代码块**：这是折叠宏最重要的使用场景
4. **✅ 建议在折叠宏中嵌入JSON/XML/YAML**：保持页面整洁
5. **✅ block-id 建议包含有意义的标识**：如 `codeEx01`, `json01`, `yaml01` 等
