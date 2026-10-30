# 内容块宏 (Content Block) 规范

## 概述

本规范详细介绍如何在icenter页面中创建和使用内容块宏。

## 什么是内容块宏？

内容块宏是 icenter 页面中用于组织和管理内容的基本容器单元。它是其他宏组件（如折叠宏、HTML编辑宏）的基础结构。

### 块的核心属性

| 属性名称 | 说明 | 是否必需 |
|---------|------|---------|
| block-id | 块的唯一标识符，由8位字符组成 | 推荐设置 |
| block-title | 块的标题，用于描述块的内容 | 推荐设置 |
| block-tags | 块的标签，支持多个标签（逗号分隔） | 可选 |
| block-type | 块的类型（如 custom、table、macro 等） | **必需**（缺少则只生成普通文本，不会成为独立块） |

## 适用场景

✅ **适合使用内容块宏的场景**：

1. **需要复用的内容**：如公司的保密声明、版权信息、常用联系方式等
2. **结构化的内容组织**：如技术文档中的"概述"、"功能说明"、"API参考"等章节
3. **多人协作编辑**：不同成员负责不同章节的文档
4. **包含复杂组件的内容**：如流程图、思维导图、复杂表格等
5. **需要标签化管理的内容**：如按"待审核"、"已完成"、"重要"等标签分类

❌ **不适合使用内容块宏的场景**：

1. 简单的文本段落
2. 一次性内容（不会被复用或引用）
3. 过于细粒度的内容（避免将每个句子都封装成块）

## ⚠️ 重要：HTML结构要求

### ❌ 错误方式

```html
<!-- 错误示例：缺少必要的块属性 -->
<div>
    <p>这是块的内容</p>
</div>
```

```html
<!-- 错误示例：block-id 格式不正确 -->
<div block-id="1" block-title="块">
    <p>内容</p>
</div>
```

### ✅ 正确方式

```html
<!-- 正确格式：包含完整的块属性 -->
<div block-id="oWqVZiQZ" block-type="custom">
    <p>这是具体的内容</p>
</div>
```

## ⚠️ 完整示例：正确的HTML块结构（直接可用）

### 基础内容块

```html
<div block-id="oWqVZiQZ" block-type="custom">
    <p>这是具体的内容</p>
</div>
```

### 带标题和标签的内容块

```html
<div block-id="abc123de" 
     block-type="custom" 
     block-title="项目概述" 
     block-tags="概述,简介">
    <p>这里是项目概述的详细内容。</p>
    <p>可以包含多个段落。</p>
</div>
```

### 包含多个段落的内容块

```html
<div block-id="xyz789ab" 
     block-type="custom" 
     block-title="功能说明" 
     block-tags="功能,说明,文档">
    <p>第一段内容：介绍功能的用途。</p>
    <p>第二段内容：说明功能的使用方法。</p>
    <p>第三段内容：提供使用示例。</p>
    <ul>
        <li>特性1</li>
        <li>特性2</li>
        <li>特性3</li>
    </ul>
</div>
```

### 作为其他宏外层容器的块

```html
<!-- 内容块中嵌套折叠宏 -->
<div block-id="nested01" block-type="custom" block-title="嵌套示例">
    <details block-id="collapse01" collapse-state="open" open>
        <summary style="margin-left: -1rem;">点击展开查看详情</summary>
        <p>这是折叠在里面的内容。</p>
        <p>可以包含任意HTML内容。</p>
    </details>
</div>
```

### 完整的内容块（包含所有推荐属性）

```html
<div block-id="fullBlk" 
     block-type="custom" 
     block-title="完整内容块示例" 
     block-tags="示例,完整,推荐"
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
    <h2>章节标题</h2>
    <p>这是内容块中的第一段内容。</p>
    <p>这是内容块中的第二段内容。</p>
    <h3>子章节</h3>
    <ul>
        <li>列表项1</li>
        <li>列表项2</li>
        <li>列表项3</li>
    </ul>
</div>
```

## block-id 生成规则

- **长度**: 8个字符
- **格式**: 大小写字母数字混合
- **示例**: `oWqVZiQZ`, `abc123de`, `xyz789ab`

## 创建流程

1. 确定块的内容和用途
2. 生成唯一的 block-id（8位字符）
3. 设置有意义的 block-title
4. 根据需要添加 block-tags
5. 使用 `create_block_by_url` 或 `create_page_by_url_with_content` 创建块

## 注意事项

1. **⚠️ 必须设置 block-title**：每个块都应该有清晰的标题，便于后续管理和更新
2. **⚠️ block-id 唯一性**：同一页面内的 block-id 应该唯一
3. **✅ 建议使用有意义的命名**：
   - ✅ 正确: `block-title="API接口说明"`, `block-title="技术架构流程图"`
   - ❌ 错误: `block-title="块1"`, `block-title="内容"`
4. **✅ 合理控制块的大小**：不要将整个页面作为一个块，也不要将每个段落都作为一个块
