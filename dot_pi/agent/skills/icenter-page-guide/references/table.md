# 数据表格 (Table) 规范

## 概述

本规范详细介绍如何在icenter页面中嵌入数据表格。

## 表格机制

icenter使用标准HTML表格标签来嵌入数据表格：

### 表格HTML结构

```html
<table block-id="UF7Eyfih" 
       col-count="6" 
       row-count="3" 
       interlaced="disabled"
       style="border-top:1px solid #bfbfbf;border-left:1px solid #bfbfbf;display:table;table-layout:fixed;border-collapse:collapse;">
    <tr>
        <th class="line-number">#</th>
        <th valign="top">列标题1</th>
        <th valign="top">列标题2</th>
    </tr>
    <tr>
        <td class="line-number">1</td>
        <td>数据1</td>
        <td>数据2</td>
    </tr>
</table>
```

### 表格属性说明

|| 属性名称 | 说明 | 示例值 |
|---------|------|-------|
| block-id | 块的唯一标识符（8位字符） | UF7Eyfih |
| col-count | 列数量 | 6 |
| row-count | 行数量 | 3 |
| interlaced | 是否隔行变色 | enabled / disabled |
| uuid | 表格唯一标识符 | table-xxx |
| style | 行内样式 | 边框、布局等CSS属性 |

### 表格样式关键属性

- **border**: 边框样式，如 `1px solid #bfbfbf`
- **display**: 使用 `table` 或 `table-layout:fixed` 固定布局
- **border-collapse**: 使用 `collapse` 合并边框
- **textAlign**: 文本对齐方式，如 `center`, `left`, `right`
- **background-color**: 背景色，如 `rgba(233,237,240,0.5)` 用于表头

### 表格类型

#### 1. 序号列表格

- **特点**：包含自动编号的序号列
- **适用场景**：数据列表展示、API接口列表、功能清单
- **结构特征**：
  - 序号列：`<th class="line-number">#</th>`
  - 序号单元格：`<td class="line-number">1</td>`

#### 2. 无序号列表格

- **特点**：不包含序号列，直接从数据开始
- **适用场景**：数据录入表单、配置表格、统计信息

#### 3. 固定宽度表格

- **特点**：设置固定的表格和列宽度
- **适用场景**：需要精确布局的场景、统计报表
- **属性示例**：`col-width="317,419,214,213"`, `width="1164"`

### 表头样式

表头通常具有以下样式特征：

```html
<th style="border-right:1px solid #bfbfbf;border-bottom:1px solid #bfbfbf;
           display:table-cell;padding:5px 18px 5px 10px;
           font-weight:bold;textAlign:center;
           background-color:rgba(233,237,240,0.5);
           vertical-align:top;" 
    valign="top">
    <p>列标题</p>
</th>
```

### 单元格样式

```html
<td style="border-right:1px solid #bfbfbf;border-bottom:1px solid #bfbfbf;
          display:table-cell;padding:6px 10px;">
    <p>单元格内容</p>
</td>
```

## 创建流程

1. 需求分析 - 确定表格主题和内容
2. 表格类型选择 - 选择合适的表格类型
3. 数据结构设计 - 确定列数和列标题
4. HTML内容构建 - 嵌入表格HTML结构
5. 页面创建 - 使用 `create_page_by_url_with_content`

## 注意事项

1. 确保使用正确的HTML表格语法，避免表格渲染失败
2. 表格样式正确：必须包含所有必要的样式属性和CSS类
3. 表格复杂度：避免过于复杂的表格，影响渲染性能
4. **block-id建议设置**：为表格块设置唯一标识符，便于后续管理
5. **隔行变色**：可通过 `interlaced="enabled"` 启用，增强可读性