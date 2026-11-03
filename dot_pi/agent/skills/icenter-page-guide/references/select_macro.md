# 选项宏 (SelectMacro) 规范

## 概述

本规范详细介绍如何在icenter页面中创建和使用选项宏。

## 什么是选项宏？

选项宏是 icenter 提供的内联宏组件，用于在页面中显示可选择的选项。用户可以点击选择预定义的选项，常用于：
- 需要用户选择预定义选项的表单
- 状态标记（如：进行中、已完成、待审核）
- 分类选择（如：性别、类型、状态）

## 适用场景

✅ **适合使用选项宏的场景**：

1. **预定义选项的选择**：如性别、状态、类型等
2. **状态标记**：如"进行中"、"已完成"、"待审核"
3. **分类选择**：如文档分类、标签选择
4. **简短选项列表**：选项数量较少（建议不超过20个）

❌ **不适合使用选项宏的场景**：

1. 自由文本输入
2. 大量选项（超过20个）
3. 需要搜索的选项列表

## ⚠️ 重要：HTML结构要求

### ❌ 错误方式

```html
<!-- 错误示例：缺少必需的宏属性 -->
<p>性别：<span class="ze-macro">男</span></p>
```

```html
<!-- 错误示例：macro-id 格式不正确 -->
<p>状态：<inline-macro class="ze-macro" macro-key="SelectMacro" macro-id="123">
    <span>进行中</span>
</inline-macro></p>
```

```html
<!-- 错误示例：缺少 m-tag-str 属性 -->
<p>类型：<inline-macro class="ze-macro" macro-key="SelectMacro" macro-id="01k1234567890abcd">
    <span>类型A</span>
</inline-macro></p>
```

### ✅ 正确方式

```html
<!-- 正确格式：包含完整的宏属性 -->
<p>性别：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kj9yvwk5fz5hdzcn61gfv82kaapaa9"
    m-tag-str='["男","女"]'
    m-curr-select-tag="男">
    <span>男</span>
</inline-macro></p>
```

## ⚠️ 完整示例：正确的HTML块结构（直接可用）

### 基础选项宏

```html
<p>性别：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kj9yvwk5fz5hdzcn61gfv82kaapaa9"
    m-tag-str='["男","女"]'
    m-curr-select-tag="男">
    <span>男</span>
</inline-macro></p>
```

### 状态选择选项宏

```html
<p>状态：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kstatus1234567890ab"
    m-tag-str='["待审核","进行中","已完成"]'
    m-curr-select-tag="进行中">
    <span>进行中</span>
</inline-macro></p>
```

### 类型选择选项宏

```html
<p>文档类型：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kdoctype123456789a"
    m-tag-str='["技术文档","用户手册","API文档","需求文档"]'
    m-curr-select-tag="技术文档">
    <span>技术文档</span>
</inline-macro></p>
```

### 优先级选择选项宏

```html
<p>优先级：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kpriority123456789a"
    m-tag-str='["高","中","低"]'
    m-curr-select-tag="高">
    <span>高</span>
</inline-macro></p>
```

### 版本选择选项宏

```html
<p>版本：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kversion123456789ab"
    m-tag-str='["v1.0","v1.1","v2.0","v2.1","v3.0"]'
    m-curr-select-tag="v2.0">
    <span>v2.0</span>
</inline-macro></p>
```

### 多个选项宏组合使用

```html
<p>表单示例：</p>
<p>姓名：张三</p>
<p>性别：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kformsex123456789ab"
    m-tag-str='["男","女"]'
    m-curr-select-tag="男">
    <span>男</span>
</inline-macro></p>
<p>部门：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kformdept123456789"
    m-tag-str='["研发部","测试部","产品部","运维部"]'
    m-curr-select-tag="研发部">
    <span>研发部</span>
</inline-macro></p>
<p>状态：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kformstatus12345678"
    m-tag-str='["待审核","进行中","已完成","已关闭"]'
    m-curr-select-tag="进行中">
    <span>进行中</span>
</inline-macro></p>
```

### 完整的选项宏（包含所有推荐属性）

```html
<p>完整示例：<inline-macro class="ze-macro" 
    macro-key="SelectMacro" 
    macro-id="01kfullsel123456789ab"
    m-tag-str='["选项1","选项2","选项3","选项4","选项5"]'
    m-curr-select-tag="选项3"
    m-generate-tag-flag="true"
    block-id="selFull01"
    block-title="完整选项宏示例"
    block-tags="选项,示例,选择"
    enable-ai-check="n"
    enable-ai-create="n"
    style="position:relative;">
    <span>选项3</span>
</inline-macro></p>
```

## 核心属性说明

| 属性名称 | 说明 | 必需 | 示例值 |
|---------|------|------|-------|
| macro-key | 宏类型标识 | 是 | `SelectMacro` |
| macro-id | 宏的唯一标识符，必须以 "01k" 开头 | 是 | `01kj9yvwk5fz5hdzcn61gfv82kaapaa9` |
| m-tag-str | 选项列表，JSON数组格式 | 是 | `'["男","女"]'` |
| m-curr-select-tag | 当前选中的选项 | 是 | `男` |
| m-generate-tag-flag | 是否生成标签标记 | 否 | `true` / `false` |
| block-id | 块的唯一标识符（推荐） | 推荐 | `sel00001` |
| block-title | 块的标题（推荐） | 推荐 | `性别选择` |

## m-tag-str 属性格式

- **格式**: JSON 数组字符串
- **语法**: `'["选项1","选项2","选项3"]'`
- **注意**: 外层使用单引号，内层使用双引号

| 格式 | 示例 |
|------|------|
| 两个选项 | `'["男","女"]'` |
| 多个选项 | `'["待审核","进行中","已完成"]'` |
| 中文选项 | `'["高","中","低"]'` |

## macro-id 生成规则

> ⚠️ **2026-10-09 复核（推断，未对 SelectMacro 单独实测）**：块宏（MarkdownMacro 已实测）的
> `macro-id` 由**服务端保存时改写**为 `01m…` 32 位，提交值不影响渲染。SelectMacro 按同机制处理，
> 但**本项未经真实页面验证**；如遇渲染异常，优先怀疑 `m-tag-str` 等业务属性而非 macro-id。

- **建议**（仅可读性）：用 32 位 `01k…` 形式；非渲染必需
- **示例**: `01kj9yvwk5fz5hdzcn61gfv82kaapaa9`

## 创建流程

1. 确定选项列表内容
2. 生成唯一的 macro-id（以 `01k` 开头）
3. 设置 m-tag-str 属性（JSON数组格式）
4. 设置 m-curr-select-tag 属性（当前选中项）
5. 使用 `<p>` 标签包裹整个选项宏
6. 使用 `create_block_by_url` 或 `create_page_by_url_with_content` 创建

## 注意事项

1. **⚠️ macro-id 由服务端改写**（2026-10-09 复核，见上方注记）：不影响渲染；用 `01k` 前缀仅为可读性
2. **⚠️ m-tag-str 必须是有效的 JSON 数组**：格式 `'["选项1","选项2"]'`
3. **⚠️ m-curr-select-tag 必须是 m-tag-str 中的选项**：否则可能导致显示异常
4. **✅ 建议用 `<p>` 标签包裹**：确保正确定位和布局
5. **✅ 建议选项数量控制在20个以内**：选项过多影响用户体验
6. **✅ 每个选项宏需要独立的 macro-id**：同一个页面中不能重复
