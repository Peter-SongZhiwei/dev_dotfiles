---
name: save-knowledge-in-icenter
description: >
  知识沉淀技能：将会话中的成功经验通过icenter-mcp提供的工具和操作保存到个人iCenter知识库。自动触发（AI完成复杂任务后提示）或手动触发（用户说"保存经验"、"沉淀知识"等）。支持按分类组织知识文档。
---

# 知识沉淀 — 保存成功经验到iCenter知识库

## 触发方式

### 自动触发

当AI判断当前会话包含**较为复杂的成功经验**时，主动提示用户：

> "这个任务已完成。我注意到我们在解决这个问题的过程中积累了有价值的经验。要不要将这次的成功经验沉淀到个人知识库，方便以后借鉴？"

**自动触发的判断标准**（满足任一即可）：
- 涉及多步骤操作（≥3个操作）
- 包含成功的问题解决方案
- 涉及代码生成、配置、脚本
- 有可复用的关键决策

### 手动触发

用户可通过以下方式触发：
- 说"保存经验"、"沉淀知识"、"记一下这个方法"

## 完整流程

### 第 1 步：分析会话

分析当前会话内容，识别：
1. **任务目标**：用户要完成什么
2. **成功经验**：哪些做法有效
3. **关键决策**：为什么这样做
4. **可复用成果**：代码、配置、路径

如果会话没有实质性成功经验（如只是简单问答），告知用户不适合沉淀。

### 第 2 步：确定分类

根据任务内容自主判断合适的分类（仅供参考）：
- 代码生成 / 问题排查 / 工具使用 / 架构设计 / 自动化 / 知识管理

向用户确认分类是否合适，或让用户选择其他分类。

### 第 3 步：确定父页面 URL

**按以下优先级确定父页面**：
1. **用户提示词指定**：如果用户说"把页面生成在 XXX 下面"，从描述中提取父页面位置
2. **环境变量**：`ICENTER_MCP_KNOWLEDGE_BASE_PAGE_URL` 环境变量
3. **默认写死值**：`https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/1e740ca24aaf11f1981559c5a32a326e/view`
   ⚠️ 这是**技能作者个人空间**里的页面，**除作者本人外所有用户都会收到"此操作未授权"**。

**⚠️ 未授权时的处理（非作者用户）**：这是权限问题，**不要重试**。告知用户：
"默认知识库位于他人的个人空间，你无权写入。请提供**你自己的**知识库父页面链接，
或设置环境变量 `ICENTER_MCP_KNOWLEDGE_BASE_PAGE_URL` 指向你的知识库（建议与默认页同结构：
一个"知识库总入口"页面 + 分类子页面）。" 用户提供后以该页面为父页面重新执行。

### 第 4 步：确保分类页面存在

1. 使用 `execute("get_child_pages_by_url", {"parent_url": "<第3步确定的父页面URL>"})` 获取已有子页面列表
2. 检查目标分类页面是否已存在
3. 如果分类页面不存在，创建新的分类页面：

注意：分类页面类似于一个文件夹，只起到分类的作用，创建分类页面时，分类页面的标题就是分类的名称，例如“代码生成”，分类页面的内容为空。

```
操作: create_page_by_url_with_content
参数:
  title: "代码生成"
  content: ""
  parent_url: "https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/1e740ca24aaf11f1981559c5a32a326e/view"
```

### 第 5 步：创建知识文档页面

在分类页面下创建知识文档：
1. 创建知识文档页面框架（页面标题**不含时间**，iCenter 会自动记录创建时间）：

```
操作: create_page_by_url_with_content
参数:
  title: "XXX问题排查总结"
  content: "<h1>XXX问题排查总结</h1><p>本文档记录了XXX问题的排查过程和解决方案。</p>"
  parent_url: "https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/<分类页面ID>/view"
```

2. 页面创建成功后，记录返回的新页面 URL
3. ⚠️ 如果知识文档包含 PlantUML 图表，`create_page_by_url_with_content` 会自动校验；如确信内容无误可传 `skip_plantuml_validation: true`

```
操作: create_page_by_url_with_content
参数:
  title: "XXX问题排查总结"
  content: "<h1>XXX问题排查总结</h1><p>本文档记录了XXX问题的排查过程和解决方案。</p><div class=\"ze-macro\" macro-key=\"PlantUmlMacro\" ...>...</div>"
  parent_url: "https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/<分类页面ID>/view"
  skip_plantuml_validation: true
```

### 第 6 步：分块创建内容

**必须逐个创建块**，禁止使用 `create_page_by_url_with_content` 一次性创建整个页面。

逐个追加块（统一用 `position: "end"` 追加到页面末尾）：

```
操作: create_block_by_url
参数:
  page_url: "https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/<新页面ID>/view"
  content: '<div block-id="bg01AbCd" block-title="背景" block-tags="task-info" block-type="custom" block-ai-enable="n" block-source-enable="n" block-ai-check-enable="n" block-linkage-enable="n" block-optional-enable="n" m-enable-head-map="n" m-head-map-rule="0" ccm-display-adaptation="n" block-source-first-pull="y" style=""><h2>背景</h2><p>任务来源：用户反馈XXX问题，需要排查根因。</p><p>核心挑战：日志分散、错误信息不明确。</p></div>'
  position: "end"
```

```
操作: create_block_by_url
参数:
  page_url: "https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/<新页面ID>/view"
  content: '<div block-id="sl02EfGh" block-title="解决方案" block-tags="solution" block-type="custom" block-ai-enable="n" block-source-enable="n" block-ai-check-enable="n" block-linkage-enable="n" block-optional-enable="n" m-enable-head-map="n" m-head-map-rule="0" ccm-display-adaptation="n" block-source-first-pull="y" style=""><h2>解决方案</h2><p>关键做法：通过XXX方法定位到根因。</p><p>成功要点：注意检查YYY配置项。</p></div>'
  position: "end"
```

所有块依次用 `position: "end"` 追加即可，无需 `target_block_title`。

#### 块属性设置方式（重要）

**`block-title` 和 `block-tags` 不是 `create_block_by_url` API 的参数！** 它们是 content（HTML 内容）中 `<div>` 标签的 HTML 属性。

每个块的 `content` 参数必须是以下格式的 HTML（参考 `icenter-mcp_page-guide` skill 的 `references/html-macros.md`）：

```html
<div block-id="AbCd1234" 
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
    <!-- 块的实际内容，使用 HTML 标签 -->
    <h2>标题</h2>
    <p>段落内容...</p>
</div>
```

| 属性 | 说明 | 示例 |
|------|------|------|
| `block-id` | 8 位大小写字母数字混合，唯一标识 | `bg01AbCd` |
| `block-title` | 块的名称标识，用于后续定位和查询 | `背景`、`解决方案`、`关键代码` |
| `block-tags` | 块的分类标签，逗号分隔 | `task-info`、`solution`、`code` |

**块结构规划**：

| block-title | block-tags | 内容 |
|-------------|------------|------|
| `背景` | `task-info` | 任务来源 + 核心挑战 |
| `解决方案` | `solution` | 关键做法 + 成功要点 |
| `关键决策` | `decision` | 决策依据 + 替代方案 |
| `核心成果` | `output` | 代码片段 / 配置 / 参考路径 |
| `标签` | `metadata` | 便于检索的标签列表 |

**创建顺序**：所有块依次用 `position="end"` 追加到页面末尾。`before`/`after` 仅用于在两个已有块之间插入新块的场景。

### 第 7 步：反馈结果

告知用户：
- 创建的知识文档标题
- 所在分类
- iCenter 页面链接

## 可用操作汇总

| 操作 | 用途 |
|------|------|
| `get_child_pages_by_url` | 获取分类列表/知识页面列表 |
| `search_pages` | 按关键字搜索已有知识页面（避免重复创建） |
| `create_page_by_url_with_content` | 创建分类页面/知识文档页面框架 |
| `create_block_by_url` | 逐个创建块内容 |
| `update_block_by_url` | 更新已有块内容 |
| `query_page_chapter_tree_by_url` | 查询页面块结构/章节树（用于验证，支持 `block_title` 过滤章节；旧操作名 `query_page_blocks_by_url` 在当前 MCP 版本已不存在，勿用） |

## 注意事项

- 文档标题中**不包含时间**，iCenter 会自动记录创建时间
- 分类名称尽量简短准确
- 块名称和块标签用于后续分块检索，务必设置有意义且唯一的值
- 如果用户拒绝沉淀，尊重选择不要强求
- **创建块前务必查阅 `icenter-mcp_page-guide` skill 的 `references/html-macros.md`**，了解块属性的正确 HTML 格式。`block-title` 和 `block-tags` 是 HTML 属性，不是 API 参数。

## iCenter 知识库结构

```
个人空间
└── 知识库总入口 (page_id: 1e740ca24aaf11f1981559c5a32a326e)
    ├── 代码生成
    ├── 问题排查
    ├── 工具使用
    ├── 架构设计
    ├── 自动化
    └── 知识管理
```