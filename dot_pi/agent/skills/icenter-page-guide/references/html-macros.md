# HTML 宏组件指南

**适用场景**: 当需要在 iCenter 页面中使用 HTML 宏组件（代码块、折叠宏、HTML 嵌入、图表等）时加载此文件。

---

## 核心约束（所有 HTML 必须遵守）

| 规则 | 说明 |
|-----|------|
| **禁止 `<style>` 标签** | 只能用行内样式 |
| **禁止 `<script>` 标签** | 不允许 JavaScript |
| **禁止手写 `<canvas>` 和 `<svg>` 标签** | 图表统一使用 `create_chart_block`（首选）/`generate_chart`（后补）生成，其宏内部 SVG 属正常用法；PlantUML 图表使用 `PlantUmlMacro` |
| **所有 HTML 必须有效** | 嵌套正确，属性完整 |
| **所有块必须设置 `block-title`** | 用于标识块名称 |

---

## 代码块与折叠宏

### 代码块格式

代码块必须嵌套在 `<details>` 折叠宏中，禁止直接裸露在页面中：

```html
<details block-id="tsCode01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">文件描述 — 文件名</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:typescript">
// 代码内容
// HTML 特殊字符需要转义: < → &lt; > → &gt;
    </pre>
    <p><br/></p>
</details>
```

> ⚠️ **2026-10-09 实测两条**：① 想让代码块/折叠宏后续可被 `update_block` 更新，**必须把 `<details>` 整体包在
> `<div block-type='custom'>` 里**（裸 details 不可更新，见 `block_update.md` §8.3）；
> ② `collapse-state="open"`/`open` 在页面阅读态**仍显示为折叠**，代码默认不可见。

### 关键属性要点

| 元素 | 说明 |
|------|------|
| `<div block-type="custom">` 外层 | 可更新性前提：折叠宏必须包在内容块里 |
| `<details block-id="xxx" collapse-state="open" open>` | block-id 必须直接在 `<details>` 上 |
| `<summary style="margin-left: -1rem;">标题</summary>` | 调整缩进 |
| `<p><br/></p>` | `<summary>` 后加间距 |
| `<pre class="prettyprint linenums brush:语言">` | 语法高亮 |
| `<p><br/></p>` | `</pre>` 后加间距 |

### brush 属性值速查

| 格式 | 说明 |
|------|------|
| `brush:typescript` | TypeScript 代码 |
| `brush:python` | Python 代码 |
| `brush:java` | Java 代码 |
| `brush:js` | JavaScript / JSON 代码 |
| `brush:bash` | Shell / Bash 命令 |
| `brush:yaml` | YAML 配置 |
| `brush:sql` | SQL 语句 |
| `brush:html` | HTML 代码 |

### PlantUML 不需要放在 `<details>` 内

- **PlantUML 宏不需要也不应该放在 `<details>` 内** — PlantUML 应作为独立 block
- 只有代码块/配置/JSON 等需要折叠的内容才放在 `<details>` 内

---

## HTML 嵌入宏（HtmlIncludeMacro）

通过 URL 嵌入其他页面内容：

```html
<div class="ze-macro" 
     macro-key="HtmlIncludeMacro" 
     m-mode="url" 
     m-url="https://market.zte.com.cn/zte-dn-portal-ui/#/mcpSquare" 
     m-page-height="1600" 
     m-page-width="1600" 
     macro-id="01kRandom16Chars">
    <div class="ze-macro-body">
        <p><br/></p>
    </div>
</div>
```

### 常见错误

| 错误 | 正确 |
|------|------|
| 使用 `http://` 开头 | 必须使用 `https://` 开头 |
| 使用 `<iframe>` 标签 | 使用 `HtmlIncludeMacro` 宏 |
| 使用 `src` 属性指定 URL | 使用 `m-url` 属性 |
| 缺少 `m-mode="url"` | 必须设置 |
| 缺少 `m-page-height` 和 `m-page-width` | 必须设置 |

---

## 自定义 HTML 宏（HtmlCodeDisplayMacro）

用于自定义 HTML 内容（非图表场景）：

```html
<div class="ze-macro" 
     macro-key="HtmlCodeDisplayMacro" 
     macro-id="01kRandom16Chars">
    <div class="ze-macro-body">
        <!-- 自定义 HTML/CSS 内容 -->
    </div>
</div>
```

### 图表生成（重要）

**静态图表（柱状图/折线图/饼图/环形图）统一由 `create_chart_block`（首选，一步生成图表+内容块）或 `generate_chart`（后补，需二次加工时）生成。** 后端用 SVG 精确渲染，宏格式为 `HtmlCodeDisplayMacro`。

**禁止 AI 手写图表 HTML/CSS。** 手写方式（Flexbox 柱状图、绝对定位折线图、conic-gradient 饼图）极易出现坐标计算错误，已全部废弃。

### 图表类型决策矩阵

| 图表类型 | 使用方式 | 说明 |
|---------|---------|------|
| 柱状图 | `create_chart_block` (chart_type: "bar") | SVG 渲染，自动处理坐标 |
| 折线图 | `create_chart_block` (chart_type: "line") | SVG 渲染，自动处理连线角度 |
| 饼图 | `create_chart_block` (chart_type: "pie") | SVG 渲染，自动处理百分比 |
| 环形图 | `create_chart_block` (chart_type: "doughnut") | SVG 渲染，中心空心 |
| 流程图 | `create_plantuml_block` / `PlantUmlMacro` | PlantUML Activity Diagram |
| 时序图 | `create_plantuml_block` / `PlantUmlMacro` | PlantUML Sequence Diagram |
| 甘特图 | `create_plantuml_block` / `PlantUmlMacro` | PlantUML Gantt Diagram |
| 思维导图 | `create_plantuml_block`（`@startmindmap`，2026-10-09 实测可渲染） | 备选：内嵌图片标签 |

**绝对不要尝试用 PlantUML 生成柱状图、折线图、饼图！也不要手写 HTML/CSS 图表！统一使用 `create_chart_block`（或后补 `generate_chart`）。**

---

## 块（Block）属性规范

### 基本格式

```html
<div block-id="Z29mLmzy" 
     block-title="块名称" 
     block-tags="tag1,tag2"
     block-type="custom" 
     block-ai-enable="n" 
     block-source-enable="n" 
     block-ai-check-enable="n" 
     block-linkage-enable="n" 
     block-optional-enable="n" 
     m-enable-head-map="n" 
     m-head-map-rule="0" 
     ccm-display-adaptation="n" 
     block-source-first-pull="y" 
     style="">
    <p>块的实际内容...</p>
</div>
```

### block-title 要求

| 要求 | 说明 |
|-----|------|
| **应设置** | 手工创建的内容块都应设置 `block-title`；⚠️ `create_plantuml_block`/`create_chart_block` 生成的内容块**不带** block-title（title 落在内层宏 div 上），这类块请用返回的 `block_id` 定位 |
| **命名规则** | 根据块内容含义命名 |
| ✅ 正确 | `block-title="项目概述"`, `block-title="技术架构流程图"` |
| ❌ 错误 | `block-title="块1"`, `block-title="内容"` |

### block-id 生成规则

- **长度**: 8 个字符
- **格式**: 大小写字母数字混合
- **示例**: `Z29mLmzy`, `PlyqGHCO`, `ABC12345`

---

## 块更新注意事项

### 页面创建后更新

| 页面状态 | 操作选择 |
|---------|---------|
| **已按块组织，内容较大** | 先 `query_page_chapter_tree_by_url`，再用 `update_block_by_url` |
| **分块创建的页面** | 禁止使用 `update_page_by_url_with_content` 覆盖，必须使用 block 相关工具 |
| **追加新内容** | 使用 `create_block_by_url` 追加新块 |

### 铁律

1. **分块创建的页面禁止用 `update_page` 覆盖** — 必须使用 block 相关工具
2. **禁止自己生成 HTML 文件后使用文件路径方式** — 使用内容字符串方式或分块创建
3. **内容长度判断** — 超过 10000 字符必须分块处理

---

## 生成后自检清单

### HTML 通用
- [ ] 没有 `<style>` 标签
- [ ] 没有 `<script>` 标签
- [ ] 没有手写的 `<canvas>` 和 `<svg>` 标签（`generate_chart` 返回的 HtmlCodeDisplayMacro 宏内部 SVG 除外）
- [ ] 所有标签正确闭合
- [ ] 每个块都设置了 `block-title`

### 代码块
- [ ] 代码块嵌套在 `<details>` 折叠宏中
- [ ] `<details>` 上有 `block-id`、`collapse-state="open"`、`open` 属性
- [ ] `<summary>` 有 `style="margin-left: -1rem;"`
- [ ] `<summary>` 后有 `<p><br/></p>`
- [ ] `<pre>` 后有 `<p><br/></p>`
- [ ] brush 值与代码语言匹配（JSON 用 `brush:js`，TypeScript 用 `brush:typescript`）

### HTML 嵌入宏
- [ ] URL 以 `https://` 开头
- [ ] 设置了 `m-mode="url"`
- [ ] 设置了 `m-page-height` 和 `m-page-width`
- [ ] 使用 `m-url` 属性（非 `src`）

### 块属性
- [ ] 每个块都有 `block-id`（8 位字符）
- [ ] 每个块都有有意义的 `block-title`
- [ ] HTML 特殊字符在 `<pre>` 中已转义