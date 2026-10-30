---
name: icenter-page-guide
description: icenter页面创建与更新综合指南。适配icenter MCP v4.x（当前 v4.0.1 实测）双工具架构（discover + execute），覆盖53个操作。SKILL.md为主入口索引，具体宏组件规范按需加载references/目录下文件。
---

# icenter-mcp_page-guide

## 前置条件

操作前确认：MCP 已配置，调用 `discover()` 可返回操作列表。未配置时终止流程，参考 [icenter MCP 安装指南](https://i.zte.com.cn/index/ispace/#/space/d56e91767ff44dc69a772036e2c482c8/wiki/page/2e119060c08d11f0933845f3da9a24b2/view)。

## MCP 双工具使用指南

所有操作统一使用 `execute("操作名", {参数})` 调用：

```
1. discover()              → 查看53个可用操作分类和名称
2. discover("操作名")       → 查看该操作的完整参数 schema
3. execute("操作名", {参数}) → 执行操作
```

## 操作速查表

| 场景 | 操作 |
|------|------|
| 创建子页面（内容<10000字符） | `create_page_by_url_with_content` |
| 创建子页面（内容≥10000字符） | 分块：先创建基本页面，再用 `create_block_by_url` 追加 |
| 创建页面（基于本地 md 文件） | `create_page_from_markdown` → 🌟 md 自动转 HTML，几乎不消耗 token。标题由 title 承载，文档开头一级标题自动移除（详见 `references/markdown_page.md`） |
| 更新已有块的内容（⭐ 局部更新唯一方式） | `update_block_by_url` — 通过 `target_block_id` 定位并更新指定块的内容（**优先用创建时回传的 `block_id`**；没记录时先用 `query_updatable_blocks_by_url` 查可更新块清单——**章节树给的是标题块 id，不能用于更新**；只传一个定位条件，多条件为 AND 语义）。**禁止**追加新块代替更新。仅内容块（`block-type="custom"`）可更新，详见 `references/block_update.md` §8 |
| 更新页面（小页面） | `update_page_by_url_with_content` |
| 追加内容（不覆盖已有块） | `create_block_by_url`（推荐）/ `update_page_by_url_with_content` + `append_content: true` |
| 页面详情 | `get_page_detail_by_url` |
| 子页面列表 | `get_child_pages_by_url` / `get_all_child_pages_by_url` |
| 整理页面目录树（新建目录节点 / 改名 / 归位 / 同级排序） | 见 `references/page_tree_organize.md` → 盘点与核对**优先**用 `get_all_child_pages_by_url`（2.0 descendant，一次全量、含根节点自身）；⚠️ `move_page_by_url` **省略 `pre_node_id` 的落位不可控**（随父/子 sortNo 数值关系，可能最前也可能最后），要确定位置必须显式传前驱 id |
| 搜索页面 | `search_pages` |
| 页面章节结构（标题树，只读 / 插入定位） | `query_page_chapter_tree_by_url` — 返回的是**标题块 id**，不能用于更新/删除块 |
| 可更新的内容块清单（更新/删除块前先查） | `query_updatable_blocks_by_url` — 返回内容块 id、所在章节、块内标题、内容预览等 |
| 块内容 | `query_block_content_by_url` |
| 删除块（假删除：清空内容、块对象保留） | `delete_block_by_url` |
| 上传附件 / 在页面嵌入可下载的附件 | `upload_attachment_by_url`（或 `upload_attachment`）→ `create_block_by_url` 写入 `macro_html`，见 `references/attachment.md` |
| 上传图片 / 在页面嵌入图片 | `upload_image`（本地文件或远程 URL）→ `create_block_by_url` 写入 `img_html`，见 `references/image.md` |
| 修改页面标题（不改内容，URL/页面ID 不变） | `update_page_title_by_url` |
| 移动页面（目录树节点移动、同级排序） | `move_page_by_url`（`pre_node_id` 语义与坑见 `references/page_tree_organize.md`） |
| 页面历史版本 | `get_page_histories_by_url` |
| 删除页面 | `delete_page_by_url` |
| 添加标签 | `add_tag_to_page_by_url` |
| 分享页面 | `share_page_by_url` |
| 导出Markdown | `export_page_to_markdown` |
| 模板列表/详情 | `get_templates` / `get_template_details_by_url` |
| 生成静态图表(SVG)（首选） | `create_chart_block` → 🌟 一步完成图表生成+内容块创建，AI 只需提供数据和页面 URL |
| 生成静态图表(SVG)（后补） | `generate_chart` → 仅用于需要 AI 二次加工 HTML 的场景，返回 HtmlCodeDisplayMacro 宏格式 HTML |
| 生成 PlantUML 图表（首选） | `create_plantuml_block` → 🌟 一步完成 PlantUML 图表生成+内容块创建。**必填三个参数：`page_url` + `content`（原始 PlantUML）+ `title`（图表标题）**（缺 title 会被参数校验直接拒绝）。支持所有 PlantUML 图表类型 |
| 生成 PlantUML 图表（后补） | `generate_plantuml` → 仅用于需要 AI 二次加工 HTML 的场景，返回 PlantUmlMacro 宏格式 HTML |
| 校验 PlantUML 语法 | `validate_plantuml` → 创建含 PlantUML 页面前预检，返回错误位置和修复建议 |
| 生成代码变更日志 | `generate_changelog` → 支持 timeline(时间线) / compare(对比) 两种模式，返回 HTML |

## 核心约束

| 规则 | 说明 |
|-----|------|
| **页面标题原则** | 页面标题由 `title` 参数指定，页面内容（contentBody）中**不要**重复包含标题文字。`create_page_from_markdown` 会自动移除 md 内容开头的文档一级标题（`##` 及以下章节标题保留） |
| **禁止 `<style>` 标签** | 只能用行内样式 |
| **禁止 `<script>` 标签** | 不允许JavaScript |
| **禁止 `<canvas>` 和 `<svg>`（直接使用）** | 图表通过 MCP 图表操作生成 |
| **创建静态图表（柱状图/折线图/饼图/环形图）** | 首选 `create_chart_block`（一步完成图表生成+内容块创建）。**后补** `generate_chart`（仅用于需要 AI 二次加工 HTML 的场景）。**禁止 AI 手写 HTML/CSS 图表**（坐标计算极易出错） |
| **PlantUML 图表** | iCenter 使用开源 PlantUML（https://plantuml.com/zh/），支持所有图表类型（时序图/用例图/类图/活动图/组件图/状态图/对象图/部署图/定时图/甘特图/思维导图/WBS 等）。生成前建议用 `validate_plantuml` 校验。必须包含美观样式：`!theme cerulean`、`skinparam backgroundColor #FFFFFF`、`skinparam defaultFontColor #000000` |
| **所有块必须设 `block-title`** | 用于标识块名称和后续定位。⚠️ `create_plantuml_block`/`create_chart_block` 生成的**内容块本身不带 block-title**（title 落在内层宏 div 上，`query_updatable_blocks` 里该块的 block_title 为空）——这类块只能用返回的 `block_id` 定位 |
| **代码块必须用 `<details>` 包裹** | 代码/配置/JSON等必须折叠。⚠️ 实测（2026-10-09）：`collapse-state="open" open` 的 `<details>` 在页面阅读态仍渲染为**折叠态**，不要指望默认展开 |
| **折叠宏/代码块更新必须包在内容块里** | 裸 `<details>`（不在 `block-type="custom"` 内）**无法被 update_block 更新**，创建时就写成 `<div block-type='custom'>…<details>…</details></div>`，详见 `references/block_update.md` §8.3 |
| **分块创建页面禁止用update_page覆盖** | 必须用 block 工具更新（`update_block_by_url` / `create_block_by_url`）。实测：`update_page_by_url_with_content`（不带 append_content）会把页面上所有内容块整体冲掉，只剩新正文 |
| **内容超过10000字符必须分块** | 使用 `create_block_by_url` 逐个追加 |
| **PlantUML 生成前/后必须校验** | 创建含 PlantUML 的页面会自动校验；单独校验用 `validate_plantuml`；确信内容无误时可传 `skip_plantuml_validation: true`。⚠️ **校验只识别双引号写的 `macro-key="PlantUmlMacro"`**：宏 HTML 用单引号时校验会静默返回"通过（0 个块）"，等于没校验——**待校验的宏 HTML 请用双引号** |
| **已存在块必须用 blockId 局部更新** | 当需要修改页面上已有 block 的内容时，**必须**使用 `update_block_by_url(target_block_id=块ID)` 进行局部更新。**禁止**用 `create_block_by_url`（position=end）追加新块代替更新旧块。**禁止**用 `create_plantuml_block` 追加重复图表代替更新。用户明确给了 blockId 时，必须用 `update_block_by_url` 更新该块。块 id 来源：创建返回值 → 否则 `query_updatable_blocks_by_url`（**禁止**拿章节树的标题块 id 去更新） |

## 错题本使用协议（条件触发）

**`lessons_learned.md` 是历史错误教训记录。** 根据操作类型决定是否查阅：

| 操作类型 | 是否需要查阅错题本 | 说明 |
|---------|------------------|------|
| **创建页面**（含 PlantUML/HTML 宏） | ✅ **必须** | 复杂页面易犯历史错误 |
| **更新页面**（含 PlantUML/HTML 宏） | ✅ **必须** | 修改时可能引入新错误 |
| **创建 Block**（含 PlantUML/HTML 宏） | ✅ **必须** | 块内容同样受宏组件约束 |
| **更新 Block**（含 PlantUML/HTML 宏） | ✅ **必须** | 修改块内容时需对照错题本 |
| **查询类操作**（get/search/query/export） | ❌ **不需要** | 不涉及页面内容生成 |
| **删除/分享/标签/模板操作** | ❌ **不需要** | 不涉及页面内容生成 |

### 触发条件

**当操作涉及 PlantUML 宏组件或复杂 HTML 宏时：**

| 阶段 | 动作 | 说明 |
|------|------|------|
| **开始前** | 阅读 `lessons_learned.md` | 了解历史错误模式，避免重蹈覆辙 |
| **出错时** | 查阅 `lessons_learned.md` | 匹配错误索引，查看对应修复方法 |
| **修复后** | 对比 `references/` 专题文件 | 确认修复方案符合规范 |
| **遇到新错误** | 更新 `lessons_learned.md` | 追加新错误模式，供未来参考 |

### 错误处理流程

```
页面创建/更新失败？
  1. 阅读 lessons_learned.md 错误索引，匹配错误类型
  2. 查阅对应错误详情，获取修复方法
  3. 加载 references/ 相关专题文件，确认规范
  4. 修正后重试

用户指定了需要更新的 blockId（如"mDUBZlVS 这个block有问题"）？
  ⚠️ 铁律：必须使用 update_block_by_url(target_block_id=<用户给的ID>) 更新该块
  ❌ 禁止：用 create_block_by_url 或 create_plantuml_block 在页尾追加新块
  ❌ 禁止：说"追加到结尾了，请手动删除旧块"
  ✅ 正确：构造 PlantUML 宏 HTML → update_block_by_url 直接更新原块

遇到新错误模式（错题本中没有）？
  1. 分析问题根因
  2. 修正问题
  3. 在 lessons_learned.md 末尾追加新错误记录，格式：
     ## 错误 N: 错误标题
     ### 错误模式 → ### 正确方式 → ### 快速检查方法
```

## 按需加载指令（核心机制）

**SKILL.md 只提供索引和约束。执行具体任务时，按需加载 references/ 目录下的专题文件：**

| 当需要... | 加载文件 |
|-----------|---------|
| 基于本地 md 文件创建页面 | `references/markdown_page.md` |
| 生成 PlantUML 图表（活动图/时序图/类图/状态图/甘特图/思维导图等全部类型） | `references/plantuml-guide.md` |
| 使用 HTML 宏组件（代码块/折叠/HTML嵌入） | `references/html-macros.md` |
| 生成静态图表（柱状图/折线图/饼图/环形图） | 🌟 首选 **`create_chart_block`**（一步完成）。后补 `generate_chart`（需二次加工时）。无需加载 reference 文件 |
| 生成思维导图 | `references/mindmap.md` |
| 制作数据表格 | `references/table.md` |
| 使用折叠宏 | `references/collapse.md` |
| 使用 Markdown 渲染宏 | `references/markdown_macro.md` |
| 使用下拉框宏 | `references/select_macro.md` |
| 使用内容块宏 | `references/content_block.md` |
| 上传附件 / 在页面嵌入可下载的附件 | `references/attachment.md` |
| 上传图片 / 在页面嵌入图片（含显示尺寸控制） | `references/image.md` |
| 更新块内容 / 更新块中嵌套的 PlantUML / **插入新块（定位、块归属、JSON 转义坑）** | `references/block_update.md` |
| 整理 / 重组某父页面下的子页面目录结构（盘点、建目录节点、改名、归位、同级排序） | `references/page_tree_organize.md` |
| 使用日期组件 | `references/date_component.md` |
| 使用 @提醒 功能 | `references/at_user.md` |
| 使用 HTML 编辑器宏 | `references/html_editor_macro.md` |
| 生成代码变更日志 | `references/changelog.md` |
| 生成技术文档 | `references/tech_doc.md` |
| 校验 PlantUML 语法 | 使用 `validate_plantuml` 操作进行自检 |

## 参考文件索引

所有 `references/` 目录文件及其用途：

| 文件 | 用途 |
|------|------|
| `markdown_page.md` | 基于本地 md 文件创建页面：`create_page_from_markdown` 参数、标题原则、markdown 语法转换支持范围 |
| `attachment.md` | 附件：上传本地文件到云文档库并嵌入可下载的附件宏（`udm-doc-{fileId}` 结构、显示名规则、大小/类型限制、错误处理） |
| `image.md` | 图片：上传图片到 iCenter 图床并嵌入页面（img 结构、显示尺寸控制、大小/类型限制、figure 带标题、错误处理） |
| `plantuml-guide.md` | PlantUML 图表生成：宏格式、全部图表类型（活动图/时序图/类图/状态图/组件图/甘特图/思维导图等）语法、错误模式、检查清单 |
| `html-macros.md` | HTML 宏组件：代码块/折叠宏/HTML嵌入/自定义HTML/块属性规范 |
| `mindmap.md` | 思维导图：内嵌图片标签 + data-mindmapping 属性 |
| `table.md` | 数据表格：HTML 表格 + 行内样式 |
| `code_block.md` | 代码块：`<pre>` + prettyprint 格式，嵌套在 `<details>` 中 |
| `collapse.md` | 折叠宏：`<details>` 展开/折叠内容 |
| `block_update.md` | 块更新完整指南：create/update content格式区别、content block内PlantUML更新、块定位策略（AND 语义）、**§8 实测补遗（可更新对象、`query_updatable_blocks` 取可更新块 id、静默嵌套与自动剥离、宏/折叠宏更新姿势、创建回传 block_id、错误速查）**、块插入实操要点（章节树定位、块内标题归属规则、连续插入顺序控制、单引号属性规避 JSON 转义、`<code>` 拆分行为与自动转换） |
| `page_tree_organize.md` | 页面目录树整理工作流：全量盘点（2.0 descendant）、建纯目录节点（content 传 `<p></p>`）、改名（URL 不变）、归位、**同级排序的链式插入算法**、坑清单、收尾检查清单 |
| `changelog.md` | 变更日志：通过 `generate_changelog` 操作读取 Git 日志生成，支持 timeline(时间线)/compare(对比) 两种模式 |
| `html_include_macro.md` | HTML 嵌入宏：HtmlIncludeMacro 格式和限制 |
| `html_editor_macro.md` | 自定义 HTML：HtmlCodeDisplayMacro 自由内容编辑 |
| `select_macro.md` | 下拉框宏：SelectMacro 格式和使用 |
| `content_block.md` | 内容块宏：ContentBlockMacro 格式 |
| `at_user.md` | @提醒：普通 HTML 实现 |
| `date_component.md` | 日期组件：普通 HTML 实现 |
| `markdown_macro.md` | Markdown 渲染：MarkdownMacro 格式 |
| `tech_doc.md` | 技术文档生成：结构和内容组织指南 |

## 错题本

`lessons_learned.md` 是历史错误教训记录，包含 **26 条**已知的错误模式（编号 0–25，其中 3 号含两段）。新发现的错误模式应追加到该文件，同时写入对应 `references/` 专题文件。

**错题本 ≠ 被动参考，而是主动学习工具：**
- 每次任务开始前自动阅读
- 每次失败时主动查阅
- 每次新错误时自动更新