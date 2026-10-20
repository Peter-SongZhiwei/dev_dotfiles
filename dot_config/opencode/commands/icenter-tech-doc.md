---
description: 生成 iCenter 技术文档页面，自动遵循 icenter-page-guide skill 规范
---

# iCenter 技术文档生成命令

用户输入：$ARGUMENTS

## 页面生成方式（必须遵守）

> ⚠️ **绝对规则：任何时候都必须通过「先创建基本页面 → 再逐块追加内容」的方式生成页面。**
> 禁止使用 `create_page_by_url_with_content` 一次性写入完整内容（哪怕内容很短）。禁止使用 `update_page_by_url_with_content` 覆盖已有页面。

**正确流程（唯一允许的方式）：**

1. 调用 `create_page_by_url` 创建一个最小骨架页面（HTML 文件内容仅含 `<div ze-root="zeRoot"><p><br/></p></div>`）。
   ⚠️ **不要在 content 里写页面标题** —— 标题由 `title` 参数承载，内容里再写会导致标题重复显示（与 `icenter-page-guide` 错误 15 一致）。
2. 将技术文档的每个章节作为独立的 content block，通过 `create_block_by_url` 逐个追加到页面中。
   ⚠️ **每个块的正文开头必须写 `<h2>章节名</h2>`**：`block-title` 只是块管理元数据（存为 div 属性），**不产生页面目录**；`query_page_chapter_tree_by_url` 的章节树**只从内容中的标题元素（h2/h3/h4）生成**。只设 `block-title` 而内容无标题元素 → 页面左侧目录为空（实测案例见 `icenter-page-guide` 错误 23）。

**禁止的方式：**
- ❌ `create_page_by_url_with_content` — 一次性写入完整内容

## PlantUML 图表（必须遵守）

> ⚠️ **绝对规则：所有 PlantUML 图表必须使用 `create_plantuml_block` 操作一步创建。**
> 禁止使用 `generate_plantuml` + `create_block_by_url` 两步方式。禁止在 HTML 内容中手写 PlantUML 宏。

### PlantUML 图表类型选择

**iCenter 使用开源 PlantUML（https://plantuml.com/zh/），支持所有 PlantUML 图表类型。** 你必须根据具体内容选择合适的图表类型，而不是局限于某几种：

| 内容场景 | 推荐图表类型 | 语法关键字 |
|---------|------------|-----------|
| 接口调用流程、消息交互、请求-响应链路 | **时序图 (Sequence)** | `participant`/`actor`/`database`/`->`/`alt`/`else`/`end` |
| 业务流程、算法逻辑、审批流转 | **活动图 (Activity)** | `start`/`stop`/`if`/`else`/`endif`/`fork`/`while` |
| 系统架构、模块关系、微服务拓扑 | **组件图 (Component)** | `component`/`rectangle`/`package`/`interface` |
| 类继承关系、接口设计、数据模型 | **类图 (Class)** | `class`/`interface`/`enum`/`abstract`/`extends`/`implements` |
| 状态机、生命周期、状态流转 | **状态图 (State)** | `state`/`[*]`/`-->` |
| 部署架构、网络拓扑、节点分布 | **部署图 (Deployment)** | `node`/`artifact`/`cloud`/`database` |
| 项目排期、迭代计划、里程碑 | **甘特图 (Gantt)** | `@startgantt`/`@endgantt`/`requires`/`then` |
| 功能场景、用户角色与操作 | **用例图 (Use Case)** | `usecase`/`actor`/`-->` |
| 知识结构、分类层级、脑图 | **思维导图 (MindMap)** | `@startmindmap`/`@endmindmap`/`*`/`**` |
| 数据结构、JSON/YAML 结构展示 | **JSON/YAML 图** | `@startjson`/`@startyaml` |
| 数据库表关系、ER 图 | **类图** 或 **组件图** | 用 `class` 表示表，关联线表示外键 |

**选择原则**：
- 描述"谁和谁怎么交互"→ 时序图
- 描述"先做什么后做什么，有什么分支"→ 活动图
- 描述"系统由哪些模块组成"→ 组件图
- 描述"数据之间什么关系"→ 类图
- 描述"状态之间怎么切换"→ 状态图
- 一张图表达不清楚时，用多张不同类型的图组合展示

### 创建方式（唯一允许）

直接调用 `create_plantuml_block`，只需提供原始 PlantUML 文本和目标页面 URL，MCP 后端自动完成语法校验、宏封装、块创建：

```
execute(operation="create_plantuml_block", params={
  "page_url": "<目标页面URL>",
  "title": "图表标题",
  "content": "@startuml\n...原始PlantUML内容...\n@enduml",
  "strict": true
})
```

- `strict` 参数默认 `true`，**必须显式传 `true`** 确保严格模式校验开启
- `skip_validation` 默认 `false`（进行校验），**不要传 `true`** 除非确认校验误报
- `block_title`、`block_tags`、`block_id`、`position` 可选，未指定时自动生成
- 甘特图使用 `@startgantt`/`@endgantt` 而非 `@startuml`/`@enduml`
- 思维导图使用 `@startmindmap`/`@endmindmap`

**禁止的方式：**
- ❌ `generate_plantuml` + `create_block_by_url` — 两步方式
- ❌ 手动在 HTML 内容中写 `<ac:structured-macro ac:name="PlantUmlMacro">` 宏
- ❌ 只用一两种图表类型表达所有内容 — 必须根据场景选择合适的类型

**预检校验（可选）：**
- 创建前可调用 `validate_plantuml` 预检语法：
  ```
  execute(operation="validate_plantuml", params={"content": "@startuml\n...\n@enduml", "strict": true})
  ```
- 校验失败时根据返回的 `error` 信息修正后重试

## 核心约束（必须遵守）

- 禁止 `<style>` 标签，只能用行内样式
- 禁止 `<script>` 标签
- 禁止 `<canvas>` 和 `<svg>` 标签（手写；`create_chart_block` 内部使用不受此限）
- 所有块必须设置 `block-title`
- 代码块必须用 `<details>` 折叠宏包裹
- PlantUML 图表必须作为独立 block，使用 `create_plantuml_block` 一步创建（strict=true）
- PlantUML 支持所有图表类型，必须根据内容场景选择合适的类型（见上方类型选择表）

## 任务解析

从用户输入中提取：
1. **技术文档主题**：用户要生成什么内容的技术文档
2. **父页面 URL**：`create_page_by_url` 的 `parent_url` 参数（可选，未提供时使用默认值）

## 执行流程

### 第一步：确定父页面 URL

按以下优先级确定：
1. **用户提示词指定**：如果用户说"把页面生成在 XXX 下面"，从描述中提取父页面位置
2. **环境变量**：`ICENTER_MCP_DEFAULT_PARENT_PAGE_URL` 环境变量
3. **默认值**：`https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/3b2a9aa3493811f19e082f67d5fc6cca/view`

### 第二步：学习规范

1. 阅读 `~/.claude/skills/icenter-page-guide/SKILL.md` 了解 MCP 操作方式和核心约束
2. 阅读 `~/.claude/skills/icenter-page-guide/lessons_learned.md` 查阅历史错误模式，避免重蹈覆辙
3. 按需加载 `~/.claude/skills/icenter-page-guide/references/` 下的专题文件：
   - `tech_doc.md` — 技术文档结构和内容组织
   - `plantuml-guide.md` — PlantUML 图表类型、语法、样式规范（**必读**，包含所有图表类型的语法速查和常见错误）
   - `html-macros.md` — HTML 宏组件规范（代码块、折叠、块属性）
   - `table.md` — 数据表格规范
   - `changelog.md` — 如需生成代码变更日志，使用 `generate_changelog` 操作

### 第三步：学习参考示例页面

在生成包含 PlantUML 等宏组件的页面之前，必须先查看以下示例页面学习正确的 HTML 格式：

```
https://i.zte.com.cn/index/ispace/#/space/d56e91767ff44dc69a772036e2c482c8/wiki/page/44823e16333711f1bfc417b24443f7ea/view
```

使用 `get_page_detail_by_url` 操作获取该页面的完整内容作为格式参考：

```
execute(operation="get_page_detail_by_url", params={"page_url": "https://i.zte.com.cn/index/ispace/#/space/d56e91767ff44dc69a772036e2c482c8/wiki/page/44823e16333711f1bfc417b24443f7ea/view"})
```

### 第四步：生成技术文档

技术文档内容要求：

1. **数据设计部分**：不要纯文本描述，结合数据表格 + PlantUML 类图/实体图展示数据库表设计
2. **代码逻辑部分**：涉及重要代码时，结合代码片段 + 关键配置文件 + 核心数据结构，使用 `<details>` 折叠宏嵌入，并标注文件本地路径
3. **流程与架构**：根据内容场景选择合适的 PlantUML 图表类型（时序图/活动图/组件图/部署图/状态图等），使用 `create_plantuml_block` 操作创建
4. **变更日志**：如需展示代码变更历史，使用 `generate_changelog` 操作自动生成
5. **页面创建方式**：采用 **block 追加** 的方式生成页面

### 第五步：生成后检查

1. 检查所有 PlantUML 图表类型选择是否与内容场景匹配（参照上方类型选择表）
2. 检查所有 PlantUML 语法是否符合规范（参照 `plantuml-guide.md` 的语法速查和常见错误表）
3. 检查 PlantUML 样式是否完整（`skinparam defaultFontColor #000000`、`!theme cerulean` 等）
4. 检查 HTML 宏组件是否符合约束（无 `<style>`、`<script>` 等）

### 第六步：错误处理与错题本更新

如果页面创建失败或 PlantUML 渲染异常：
1. 查阅 `~/.claude/skills/icenter-page-guide/lessons_learned.md` 匹配历史错误
2. 修复后重试
3. 如果是新错误模式，在错题本末尾追加记录，格式：
   ```markdown
   ## 错误 N: 错误标题（★2026-XX-XX★）
   ### 错误模式
   **问题描述**：...
   ### 正确方式
   **修复方法**：...
   ### 快速检查方法
   ...
   ```

### 第七步：二次检查与报告

更新完成后，再次确认所有 PlantUML 宏和 HTML 宏组件均正确渲染，确认无误后向用户报告生成结果和新页面 URL。
