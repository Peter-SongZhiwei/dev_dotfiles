# 块(Block)更新完整指南

## 核心规则速查

| 规则 | 创建块 (`create_block`) | 更新块 (`update_block`) |
|------|------------------------|------------------------|
| content 格式 | HTML **含**块属性（`block-type="custom"` 必需） | 纯 HTML 内容体，**不含**块属性；传了整体块 HTML 会被**自动剥离外层并提示** |
| 块定位 | position + targetBlockId（before/after 时用） | targetBlockId / targetBlockTitle / targetBlockTags，**多个条件为 AND（交集）语义** |
| 支持类型 | 所有 | **仅** content block（`block-type="custom"`）；标题/宏/表格/图片/纯文本一律不可更新 |
| block_id | 返回值包含 `block_id`（未写则自动生成注入） | 用创建时拿到的 `block_id` 定位最稳；没记录时用 `query_updatable_blocks` 查（**章节树返回的标题块 id 不能用于更新**） |
| 最小示例 | `<div block-type="custom"><p>内容</p></div>` | `<p>新内容</p>` |

> 2026-09-30 依据真实页面实测重写补充，新增内容见文末「八、实测补遗」。

---

## 一、更新块的核心原理

### API 请求体结构

```json
{
    "targetBlockId": "JD68UmZ6",
    "targetBlockTitle": "name1",
    "targetBlockTags": ["tag1", "tag2"],
    "block": {
        "attributes": { "key1": "value1" },
        "body": "<p>纯HTML内容</p>"
    }
}
```

**关键点：**
- `block.body`：**纯 HTML 内容体**，不包含块属性（block-id、block-type 等）
- `block.attributes`：块属性（blockTitle、blockTags），通过 `new_block_title`/`new_block_tags` 参数传入
- 块定位：`targetBlockId`（推荐）、`targetBlockTitle`、`targetBlockTags` 三选一
- **仅支持 content block**（`block-type="custom"`），不支持其他类型块

---

## 二、更新块 vs 创建块：content 格式对比

### 创建块（create_block）

创建新块时，块属性必须**嵌入在 HTML content 中**：

```html
<!-- ✅ 正确：block-type="custom" 为必需属性 -->
<div block-type="custom">
    <p>这是块的内容</p>
</div>

<!-- ✅ 正确：带完整属性的内容块 -->
<div block-id="abc123de" block-type="custom" block-title="标题" block-tags="tag1,tag2">
    <p>这是块的内容</p>
</div>

<!-- ❌ 错误：缺少 block-type，只会生成普通文本，不会成为独立块 -->
<p>这是文本，不是块</p>
```

### 更新块（update_block）

更新已有块时，content **不能**包含块属性：

```html
<!-- ✅ 正确：纯 HTML 内容 -->
<p>新内容</p>

<!-- ✅ 正确：可以包含其他 HTML 标签 -->
<p>段落一</p>
<p>段落二</p>
<div class="ze-macro" macro-key="PlantUmlMacro">...</div>

<!-- ❌ 错误：包含了 block-id 等块属性 -->
<div block-id="abc123de" block-type="custom">
    <p>这会导致嵌套块问题</p>
</div>
```

---

## 三、块定位方式

| 方式 | 参数 | 推荐度 | 说明 |
|------|------|--------|------|
| 块 ID | `target_block_id` | ⭐⭐⭐ 推荐 | ID 唯一，精确匹配 |
| 块标题 | `target_block_title` | ⭐⭐ 可用 | 可能匹配多个块 |
| 块标签 | `target_block_tags` | ⭐ 慎用 | 可能匹配多个块 |

**警告：** `target_block_title` 或 `target_block_tags` 匹配到多个块时，**所有匹配块都会被同时更新**。始终优先使用 `target_block_id`。

**⚠️ 多个定位条件是 AND（交集）语义（2026-09-30 实测）**：同时传 `target_block_id` + `target_block_title`/`target_block_tags` 时，
服务端要求**全部条件同时命中**才更新；任一不匹配就整体失败（报 `未指定内容块，请检查传参`，旧版本报 `tag.name.mismatch`）。
**建议：只传 `target_block_id` 一个条件。**

---

## 四、在内容块中更新嵌套的 PlantUML 宏

### 场景说明

PlantUML 宏可能位于两种位置：

| 位置 | 结构 | 可更新？ |
|------|------|---------|
| **独立 PlantUML 宏块** | `<div class="ze-macro" macro-key="PlantUmlMacro">` 直接在页面根级 | ❌ 不能 |
| **内容块中的 PlantUML** | PlantUML 宏嵌套在 `<div block-type="custom">` 内部 | ✅ 可以 |

### 正确做法

**通过更新父级内容块来间接更新 PlantUML：**

1. 查询页面详情获取完整 HTML：`get_page_detail_by_url`
2. 定位内容块（`block-type="custom"`）中的 PlantUML 宏
3. 构造新的 PlantUML JSON（修改 `syntax` 字段）
4. 用 `update_block_by_url` 更新内容块，content 为块内的完整 HTML

### 示例

页面结构：
```html
<div block-id="JD68UmZ6" block-type="custom" tag-start="div">
    <div block-id="WAZhriyg" class="ze-macro" macro-key="PlantUmlMacro" tag-start="blockMacro">
        <div class="ze-macro-body" tag-start="block">
            <div block-id="LZf8n5V0" class-name="plantuml-source" type="highlight">
                <p>
                    <span>{"syntax":"@startuml\nAlice -> Bob: Hello\n@enduml\n",...}</span>
                </p>
            </div>
        </div>
    </div>
</div>
```

更新操作：
```python
execute("update_block_by_url", {
    "page_url": "页面URL",
    "target_block_id": "JD68UmZ6",  # 内容块的ID，不是PlantUML的macro ID
    "content": """<div block-id="WAZhriyg" class="ze-macro" ... macro-key="PlantUmlMacro" tag-start="blockMacro" ze-root="zeRoot">
        <div class="ze-macro-body" tag-start="block">
            <div block-id="LZf8n5V0" class-name="plantuml-source" type="highlight">
                <p><span>{"syntax":"@startuml\\nAlice -> Bob: Updated Hello\\n@enduml\\n",...}</span></p>
            </div>
        </div>
    </div>"""
})
```

**关键原则：**
- `target_block_id` 指向**父级内容块**（block-type="custom"），不是 PlantUML macro 自身的 ID
- `content` 是内容块内的**完整 HTML**（包括 ze-macro 结构），不是纯 PlantUML 代码
- PlantUML 宏结构（`ze-macro`、`ze-macro-body`、`plantuml-source`）必须**完整保留**
- 只修改 `<span>` 内 JSON 中的 `syntax` 字段即可更新图表内容
- 实践表明：`update_block_by_url` 更新内容块中的 PlantUML 宏时，**宏结构不会被剥离**，图表正常渲染

### 更新后如何校验（避免误判为失败）

服务端保存块时会对 HTML 做**规范化**，因此把回读内容与本地文件**逐字节比对一定不相等**，不要据此判定失败。实测会被改写的部分：

| 被改写项 | 变化 |
|---------|------|
| 样式属性 | `style="margin-left: -1rem;"` → `margin-left:-1rem;margin-left: -1rem;`（追加合并） |
| `data-from` | `manual-input` → `copy-input` |
| 宏标识 | `macro-id` **重新生成**（每次更新都换新值），属性顺序也可能调整 |

**正确的校验方式（两层）**：
1. **语义比对**：提取宏内 `<span>` 中的 JSON，`json.loads` 后与本地期望值做 `==` 深度比较（PlantUML 源码逐行一致即成功）；
2. **嵌套宏检测**：对每个 `<div class="ze-macro-body">` 做 div 栈配对取出其范围，确认内部**不再出现** `class="ze-macro"`（出现即为嵌套，图表会渲染失败）。

补充：`update_block_by_url` 的 `content` **只能内联传参**（无 file 路径参数）。含大量反斜杠的 PlantUML 源码建议先用脚本生成 JSON 转义后的字符串再内联，避免手工转义出错。

---

## 五、禁止事项

```python
# ❌ 分块页面禁止用 update_page 系列操作（会覆盖所有块内容）
update_page_by_url_with_content(page_url="...", title="...", content="...")
update_page_by_url(page_url="...", title="...", content_file_path="...")

# ❌ 更新 content 时不能包含块属性
update_block_by_url(page_url="...", target_block_id="xxx",
    content='<div block-id="xxx" block-type="custom">内容</div>')  # 错误！content中有块属性

# ❌ 不能用 update_block 更新独立 macro 块（不在 content block 内的 PlantUML）
update_block_by_url(page_url="...", target_block_id="UBy1I9Nm", ...)  # 这是独立 macro 块

# ✅ 正确：更新 content block 中的 PlantUML
update_block_by_url(page_url="...", target_block_id="JD68UmZ6", content="内层HTML（含 PlantUML 宏）")
```

---

## 六、完整操作流程

```
需要修改页面中的某个块？
  0. 优先用创建时记录的 block_id（create_* 系列都会回传 block_id）
     没有记录时再走下面：
  1. get_page_detail_by_url → 获取页面完整 contentBody HTML
  2. 在 HTML 中定位目标块
     - 是 content block（block-type="custom"）？
       → ✅ 用 update_block_by_url（target_block_id=该 content block 的 ID）
     - 是在 content block 内部的标题/宏/表格？
       → ✅ 用其【外层内容块】的 ID 更新，content 传该子结构的 HTML
     - 是独立 macro 块 / 裸 details（不在 content block 内）？
       → ❌ 无法更新，只能通过 create_block_by_url 创建**包在内容块里**的新块替代
  3. 构造 content（纯 HTML，不含外层块属性；带了也会被自动剥离并提示）
  4. execute("update_block_by_url", {page_url, target_block_id, content})
  5. 失败时先读工具返回的【自动诊断】，按提示改用正确的块 ID
```

---

## 七、块插入实操要点（2026-09-11 实战补充）

### 7.1 插入位置：先查章节树拿 blockId，别靠页面详情

`create_block_by_url` 的 `before`/`after` 定位需要 `target_block_id`（比
`target_block_title` 精确，后者可能匹配多个块）。**不要用 `get_page_detail_by_url`
去找块 ID**——富页面会返回 140K+ 字符的完整 HTML，本次实测一个 142K 字符的页面直接
超出工具输出上限（被迫落盘后再分段处理）：

```
1. query_page_chapter_tree_by_url(page_url, block_title="<目标章节标题>")   # 秒级拿到 blockId
   （不带 block_title 时返回整页块层级，可用于确认章节结构未被破坏）
2. create_block_by_url(page_url, position="before", target_block_id=<id>, content=...)
```

`before`/`after` 的语义是"插到目标块所在位置的前/后"，观感上等价于"插到目标章节之前"。

> ⚠️ 注意区分：**插入定位**可以用标题块 id（章节树）；但**更新/删除块**必须用
> 内容块（`block-type="custom"`）id——先用 `query_updatable_blocks` 获取（见 §8.1），
> 拿标题块 id 去更新会报「未指定内容块」。

### 7.2 块内标题的章节树归属（2026-10-08 修正实测）

**规则**（两组对照实验 + 真实页面复盘）：
- **页面级标题**（不在内容块内的 h1~h6）：按标题层级数值递归嵌套。
- **内容块内标题**（写在 `block-type="custom"` div 里的 h1~h6）：**统一挂到"它前面最近的
  页面级标题"之下**，与块内标题自身层级无关、彼此平级。

影响与用法：

- 用 `create_block` 追加的章节（如「六、」，标题包在内容块里）会出现在**前一个页面级标题**
  的子树下——常见困惑「六、七嵌套在五内部」即此成因（实测页面 77372a16）。
- 反向验证：在 H2「I-9」之前插入块内 H3「I-8.6」，章节树中「I-8.6」出现在「I-8」子树，
  且 `query_page_chapter_tree_by_url(block_title="I-8 …")` 能查到（2026-10-08 复测；
  本节早前"查 8. 子树看不到 8.6"的结论**未能复现，以本次为准**）。
- 要创建**与现有页面级标题平级**的章节：插入时标题**不要**用 `block-type="custom"`
  包裹（内容为纯 `<h2>…</h2><p>…</p>`）。代价：非块内容无法被 update_block 定位更新。
- 验收标准 = "正文顺序正确 + 按标题可查到 + 所在子树符合上述规则预期"。

### 7.2.1 连续插入的顺序控制（2026-10-08 实测）

`position=after/before` + **固定** `target_block_id` 连续插入多个块时，新块总紧贴目标插入，
**后插入的排在前面（顺序反向）**。保持顺序：① **链式追加**——每次用上一次返回的 `block_id`
作为下一次的 `target_block_id`；② 追加到页面末尾用 `position=end`。
（工具描述已写明，实测三组对照验证。）

### 7.3 content 里的 HTML 属性一律用单引号（JSON 转义坑）

`execute` 的 `content` 参数自身是 JSON 字符串：HTML 属性若用双引号（`class="…"`），
必须逐处转义 `\"`，极易写错——**本次一次真实调用就因双引号转义问题被工具以
"could not be parsed as JSON" 直接拒绝**（约 1.8KB 的 content 全废）。改用单引号
（HTML 合法）可完全规避：

```html
<!-- ✅ 推荐：单引号属性, JSON 字符串里无需转义 -->
<div block-type='custom'><pre class='prettyprint linenums brush:yaml'>...</pre></div>
```

另：工具入参直接传 `operation` + `params` 两个字段，**不要**再包一层
`__unparsedToolInput` 之类的字段（会被判非法 JSON）。

⚠️ **单引号的唯一例外**（2026-10-09 实测）：**含 PlantUmlMacro 的 content 若要走校验，`macro-key` 必须用双引号**
（`validate_plantuml` 只识别 `macro-key="PlantUmlMacro"`，单引号会被静默漏检，见错题本错误 26）。
实用做法：先用 `create_plantuml_block`/`generate_plantuml`（内部固定双引号）生成并校验，
再按需把属性改单引号提交。

### 7.4 渲染器行为：内联 `<code>` 会被拆分/剥离（2026-10-08 更新）

- iCenter 保存页面时 `<code>` 标签样式被剥离；
- **列表项（`<li>`）内**出现 `<code>`/`<tt>`/`<kbd>` 时，该列表项内容会被**拆分为多个 `<p>`**
  （多余换行），如 `<li><code>x</code> 中文</li>` → `<li><p>x</p><p> 中文</p></li>`。
- `create_page_from_markdown`（含 skill 侧 `utils/markdown.py`）已自动把**行内 `<code>` 转为
  等宽样式 `<span style="font-family:Consolas,monospace;background-color:#f0f0f0;">`**，
  不再受上述行为影响；`<pre><code>` 代码块不受影响（2026-10-08 起）。
- 手工写内容时，需要行内代码样式请直接使用上述 `<span>` 写法，不要用 `<code>`。

---

## 八、实测补遗：更新块 API 的真实行为（2026-09-30）

> 本节结论来自临时页 30+ 组分组实验 + 审计库失败样本复盘，与工具新行为（v3.3.10）一一对应。
> 实验页面已删除。

### 8.1 唯一可更新对象 = 内容块（`block-type="custom"`）

| 页面元素 | 能否 update |
|---------|------------|
| 内容块（含嵌套内容块） | ✅ |
| 标题 h1~h6（**章节树返回的 blockId 就是标题块 id**） | ❌ 未指定内容块 |
| 宏 div（`class="ze-macro"`，含 PlantUML / HtmlCodeDisplayMacro 自身） | ❌ |
| 表格 / 图片 / 纯文本段落 / 裸 `<details>` | ❌ |

**这正是历史失败率最高的原因**：`query_page_chapter_tree` 只返回标题块 id，
AI 拿它去 update 必然失败。要更新某章节，应更新其**外层内容块**的 id。

**工具新行为**：更新失败且属于"目标解析类"错误时，会自动拉取页面 HTML 诊断，
返回 `【自动诊断】… 它属于外层内容块「XXXX」——请改用该内容块的 id 作为 target_block_id`。

**拿可更新块 id 的推荐方式（新增操作）**：更新/删除块前，先用 `query_updatable_blocks`
（或 `query_updatable_blocks_by_url`）查询页面可更新块清单——每个内容块返回 `block_id`、
`block_title`/`block_tags`、所在章节（`section_title`）、块内标题（`headings`）、
内容预览（`preview`）、成分特征（`features`：plantuml/chart/details/table/image/code）、
重复 id 与空块标记；直接从中选目标块，不必再手工解析页面 HTML（也不要用章节树的 id）。

### 8.2 content 的静默陷阱与自动兜底

| content 形态 | 旧行为 | 新行为（v3.3.10+） |
|-------------|--------|-------------------|
| 纯 HTML 内容体 | ✅ 正常替换 | 不变 |
| 外层 `<div ze-root="zeRoot">` | 服务端自动剥掉 | 不变 |
| **外层 `<div block-type="custom">`**（整体块复制/回写） | ⚠️ 静默嵌套出一层新块；若 block-id 与目标相同还会产生**重复 id**，导致该 id 后续"仅改标题/标签"更新永久失败（`按照id匹配到多个块`） | **自动剥离外层**，只用内部 HTML 更新，并在 `content_adjustments` 里提示 |
| 内部含 `block-id`/`block-type`（非最外层） | ⚠️ 生成嵌套块 | 不阻断，但 `content_adjustments` 给出嵌套警告 |
| 更新时给出 content | 整体替换块内 HTML | 可自愈历史重复 id（内层重复块被整体替换掉） |

**⚠️ 查询结果不能原样回写**：`query_block_content` 对宏块返回的是**文本投影**
（PlantUmlMacro → `<pre><code class="language-plantuml">`；图表宏 → 裸 SVG），
不是真实宏结构。把查询结果的 `content` 原样当 update 的 content 写回，会**丢宏**并产生嵌套。

### 8.3 宏类更新的正确姿势（实测通过）

| 场景 | 正确做法 |
|------|---------|
| 流程图（PlantUmlMacro） | `generate_plantuml` 生成**内层宏 HTML** → `update_block_by_url(target_block_id=外层内容块id, content=该 HTML)`；也可直接把 `_build_plantuml_block_html` 的整体块 HTML 传给 update（外层会被自动剥离） |
| 静态图表（HtmlCodeDisplayMacro） | `generate_chart` 生成的内层宏 HTML → update；同上 |
| 折叠宏（`<details>`） | **必须包在内容块里才能更新**：`create_block` 时写成 `<div block-type="custom" block-id=…><details block-id=… collapse-state="open">…</details></div>`，之后更新该内容块、content 传 `<details>…</details>` 即可改折叠态/summary/正文 |
| 宏自身的 block-id | ❌ 不能作为定位依据：宏 div 的 `block-id`、`macro-id`、`source-macro-id` **每次更新都会重新生成**；稳定的只有外层内容块 id |

**裸 `<details>`（不在内容块内）不可更新**——这是历史上只能整页重写的场景；
现在请在创建时就包进内容块。

### 8.4 创建侧：让创建结果可追踪（v3.3.10+）

- `create_block` / `create_block_by_url`：HTML 未写 `block-id` 时**自动注入一个并回传**
  （返回体新增 `block_id` 字段）；已写则原样回传。
- `create_plantuml_block` / `create_chart_block`：返回体新增 `block_id` 与 `update_hint`。
  ⚠️ 注意（2026-10-09 实测）：这两个操作生成的**内容块不带 `block-title`**（`block_title` 落在内层宏 div 上），
  在 `query_updatable_blocks` 里该块 `block_title` 为空——**定位只能用 `block_id`，不要按标题找**。
- **实践约定：创建后立刻记下 `block_id`**，后续局部更新直接用它，不再靠从页面 HTML 里"猜"；
  若确实没记录，用 `query_updatable_blocks` 查询可更新块清单（见 8.1）。

### 8.5 失败错误速查（含工具给出的建议文案）

| 服务端错误 | 真实含义 | 处理 |
|-----------|---------|------|
| `未指定内容块，请检查传参` | id 不存在 / 不是内容块 / 多条件 AND 冲突 | 按 8.1 改用外层内容块 id，或只保留一个定位条件 |
| `missing.block.match.condition` | 一个定位条件都没传 | 至少传 `target_block_id` |
| `请求参数错误，请检查后重试` | 定位有了，但 content/标题/标签全空 | 至少给一项可更新内容 |
| `按照id匹配到多个块，不允许更新` | 页面存在重复 block-id（历史嵌套造成） | 对该块做一次**带 content** 的更新（整体替换可自愈），或改用标题/标签定位 |
| `tag.name.mismatch`（旧版本） | 定位条件 AND 冲突 | 只保留 `target_block_id` |
| HTTP 419 / 504 | 网关入口拒绝 / 超时 | 工具已对 502/503/504/超时自动重试；仍失败则稍后再试 |
