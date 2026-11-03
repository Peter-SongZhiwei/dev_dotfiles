# HTML编辑宏 (HtmlCodeDisplayMacro) 规范

## 概述

HTML编辑宏（HtmlCodeDisplayMacro）是icenter平台提供的一个强大的功能，允许用户直接插入原始HTML代码。通过这个宏，用户可以添加自定义格式、嵌入多媒体元素、创建静态图表等。

## 核心限制

**必须遵守：**
1. ❌ 禁止使用 `<style>` 标签 - 只能用行内样式
2. ❌ 禁止使用 `<script>` 标签 - 不允许JavaScript
3. ❌ 禁止**手写** `<canvas>` 和 `<svg>` 标签（`create_chart_block`/`generate_chart` 生成的宏内部 SVG 属正常用法）
4. ✅ 必须使用HTML编辑宏包裹
5. ✅ **必须在图表上标注数值** - 所有数据点、柱子、扇形等必须显示具体数值

## HTML编辑宏标准结构

### 完整HTML结构（调用接口时传入的content）

```html
<div ze-root="zeRoot" style="">
  <p tag-start="p" style=""><br /></p>
  <div tag-start="blockMacro" 
       class="ze-macro" 
       macro-key="HtmlCodeDisplayMacro" 
       enable-ai-create="n" 
       enable-ai-check="n" 
       selected="true" 
       macro-id="01k8开头的32字符随机ID" 
       block-id="8字符随机ID"
       block-title="块名称（如：团队成员表格）"
       block-tags="标签1,标签2"
       style="">
    <div tag-start="block" class="ze-macro-body" ze-root="zeRoot" style="">
      <p tag-start="p" style="">
        {&quot;htmlCode&quot;:&quot;转义后的HTML内容&quot;}
      </p>
    </div>
  </div>
  <p tag-start="p" style=""><br /></p>
  <p tag-start="p" style=""><br /></p>
</div>
```

**⚠️ 重要说明：**
- `ze-root="zeRoot"` 为**非必需**属性（2026-09-30 实测：服务端保存时会删除它；`create_chart_block`
  生成的宏不含 ze-root，页面渲染正常）。写与不写都不影响渲染
- ⚠️ **必须添加 block-title 属性**: 每个块都必须设置块名称，如 `block-title="团队成员表格"`
- ⚠️ **建议添加 block-tags 属性**: 块的标签（可选），如 `block-tags="表格,团队"`
- HTML编辑宏内部使用 `{&quot;htmlCode&quot;:&quot;...&quot;}` 格式（JSON字符串）
- JSON 字符串中的双引号使用 HTML 实体编码 `&quot;` 表示
- 如果页面包含多个块/图表，可以在最外层 `<div ze-root="zeRoot" style="">` 内添加多个块

### ID生成规则

- `block-id`: 8个字符，大小写字母混合，如 `PlyqGHCO`
- `macro-id`: 32个字符，以`01k8`开头 + 小写字母数字，如 `01k8wqzgwq0fttv9pg357k6bx2hw6mq7`

### 布局技巧：并排显示多个图表

⚠️ **重要**：HTML编辑宏的div默认会占据整行，因此**不能创建多个宏来实现图表并排**。正确的做法是：**在一个HTML编辑宏内部使用flex布局组织多个图表**。

#### 实现方法

在HTML编辑宏的htmlCode内容中，使用以下结构：

```html
<div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
    <h1 style="text-align: center; color: #333; margin-bottom: 30px;">总标题</h1>
    
    <!-- 关键：使用flex布局的容器来包裹多个图表 -->
    <div style="display: flex; justify-content: space-around; align-items: flex-start; gap: 20px; flex-wrap: wrap;">
        
        <!-- 第一个图表 -->
        <div style="flex: 1; min-width: 400px; max-width: 600px; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
            <h2 style="text-align: center; color: #333; font-size: 18px;">第一个柱状图</h2>
            <!-- 图表内容 -->
        </div>
        
        <!-- 第二个图表 -->
        <div style="flex: 1; min-width: 400px; max-width: 600px; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
            <h2 style="text-align: center; color: #333; font-size: 18px;">第二个折线图</h2>
            <!-- 图表内容 -->
        </div>
        
    </div>
</div>
```

#### 关键样式说明

- `display: flex;` - 使用flex布局
- `justify-content: space-around;` - 子元素水平均匀分布
- `align-items: flex-start;` - 子元素顶部对齐
- `gap: 20px;` - 子元素之间的间距
- `flex-wrap: wrap;` - 允许子元素换行
- `flex: 1;` - 子元素等宽
- `min-width: 400px; max-width: 600px;` - 限制子元素宽度范围

### HTML内容转义规则（最关键的部分！）

HTML编辑宏的 `htmlCode` 内容需要经过**多层转义**才能正确嵌入到 JSON 字符串中。转义过程如下：

#### 转义步骤

**第一步：准备原始 HTML 内容**

```html
<p style=""><br /></p><h2 style="text-align: center; color: #333;">标题</h2>
```

**第二步：将 HTML 标签转义为 HTML 实体**

| 原始字符 | 转义后 |
|---------|--------|
| `<` | `&lt;` |
| `>` | `&gt;` |

结果：
```
&lt;p style=&quot;&quot;&gt;&lt;br /&gt;&lt;/p&gt;&lt;h2 style=&quot;text-align: center; color: #333;&quot;&gt;标题&lt;/h2&gt;
```

**第三步：将 JSON 字符串中的双引号转义为 HTML 实体**

| 原始字符 | 转义后 |
|---------|--------|
| `"` | `&quot;` |

**第四步：将样式属性内部的反斜杠转义（如果有）**

| 原始字符 | 转义后 |
|---------|--------|
| `\` | `\\` |

#### 完整转义示例

**原始 HTML 内容：**
```html
<p style=""><br /></p><h2 style="text-align: center; color: #333;">标题</h2>
```

**转义后的完整内容（放入 htmlCode 中）：**
```json
{&quot;htmlCode&quot;:&quot;&lt;p style=\&quot;\&quot;&gt;&lt;br /&gt;&lt;/p&gt;&lt;h2 style=\&quot;text-align: center; color: #333;\&quot;&gt;标题&lt;/h2&gt;&quot;}
```

#### 转义规则速查表

| 层级 | 原始字符 | 最终转义形式 | 说明 |
|-----|---------|-------------|------|
| HTML标签 | `<` | `&lt;` | 第一层转义 |
| HTML标签 | `>` | `&gt;` | 第一层转义 |
| JSON字符串 | `"` | `&quot;` | 第二层转义 |
| 样式属性内部 | `\` | `\\` | 第三层转义（如果有） |
| 样式属性内部 | `"` | `\"` | 与第三层配合使用 |

#### ⚠️ 重要提示

1. **HTML 实体编码必须正确**：`&lt;`、`&gt;`、`&quot;` 是 HTML 实体，不是 JSON 转义
2. **样式中的双引号需要双重转义**：先在 JSON 级别用 `\"`，再在 HTML 级别确保外层用 `&quot;`
3. **检查示例对比**：请务必参考用户提供的正确示例进行对比验证

## 并排显示多个图表（重要技巧）

### 核心要点

HTML编辑宏的div默认会占据整行，因此**不能创建多个宏来实现图表并排**。正确的做法是：**在一个HTML编辑宏内部使用flex布局组织多个图表**。

### 实现方法

在HTML编辑宏的htmlCode内容中，使用以下结构：

```html
<div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
    <h1 style="text-align: center; color: #333; margin-bottom: 30px;">总标题</h1>
    
    <!-- 关键：使用flex布局的容器来包裹多个图表 -->
    <div style="display: flex; justify-content: space-around; align-items: flex-start; gap: 20px; flex-wrap: wrap;">
        
        <!-- 第一个图表 -->
        <div style="flex: 1; min-width: 400px; max-width: 600px; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
            <h2 style="text-align: center; color: #333; font-size: 18px;">第一个柱状图</h2>
            <!-- 图表内容 -->
        </div>
        
        <!-- 第二个图表 -->
        <div style="flex: 1; min-width: 400px; max-width: 600px; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
            <h2 style="text-align: center; color: #333; font-size: 18px;">第二个柱状图</h2>
            <!-- 图表内容 -->
        </div>
        
    </div>
</div>
```

## HTML编辑宏的应用场景

### 1. 静态图表 ⚠️（2026-10-09 修正）

❌ **禁止 AI 手写 HTML/CSS 图表**（Flexbox 柱状图、绝对定位折线图、conic-gradient 饼图等
坐标计算极易出错，已全部废弃）。静态图表统一使用：

- **首选**：`create_chart_block`（一步生成 SVG 图表 + 内容块）
- **后补**：`generate_chart`（需要二次加工 HTML 时），返回的宏内部自带 SVG

> SVG 例外说明：本文档"禁止使用 `<svg>` 标签"指的是**手写裸 SVG**；`create_chart_block`/
> `generate_chart` 生成的 `HtmlCodeDisplayMacro` 宏把 SVG 放在 `htmlCode` JSON 字段里，属正常用法。

### 2. 自定义布局

- 卡片式布局
- 多列排版
- 响应式设计（使用百分比）

### 3. 多媒体嵌入

- 内嵌图片（使用`<img>`标签）
- 视频嵌入（使用`<video>`标签）
- 音频嵌入（使用`<audio>`标签）

### 4. 复杂格式

- 带样式的表格
- 信息卡片
- 统计面板

## HTML编辑宏的优势

1. **灵活性高**：可以创建任何纯HTML+CSS能实现的效果
2. **安全性好**：不支持JavaScript，避免脚本攻击
3. **渲染快速**：纯CSS渲染，性能好
4. **兼容性好**：不需要额外的JS库

## 注意事项

1. **外层包裹**：`ze-root="zeRoot"` 非必需（服务端会删除该属性；实测无它也能正常渲染）
2. **属性完整**：确保所有必要的属性（block-id, macro-id, macro-key等）完整
3. **样式限制**：只能使用行内样式，不能使用`<style>`标签
4. **内容转义**：
   - htmlCode 中的 HTML 标签必须使用 HTML 实体编码：`<` → `&lt;`, `>` → `&gt;`
   - JSON 字符串中的双引号必须使用 HTML 实体编码：`"` → `&quot;`
   - 样式属性内部需要额外转义：`\` → `\\`, `"` → `\"`
5. **JSON 格式**：整体是 `{&quot;htmlCode&quot;:&quot;...&quot;}` 格式，不是 `{"htmlCode":"..."}`

## 快速检查清单

生成HTML编辑宏时，必须确认：

- [ ] （可选）外层 `<div ze-root="zeRoot">` —— 非必需，服务端会移除
- [ ] 包含 `block-id` 属性（8字符）
- [ ] 包含 `block-title` 属性（块名称，必须设置！）
- [ ] 包含 `macro-id` 属性（32字符，01k8开头）
- [ ] 包含 `macro-key="HtmlCodeDisplayMacro"` 属性
- [ ] 包含 `class="ze-macro"` 属性
- [ ] 内部有 `<div tag-start="block" class="ze-macro-body">`
- [ ] 内容使用 `<p tag-start="p">{&quot;htmlCode&quot;:&quot;...&quot;}</p>` 格式（注意是 `&quot;` 不是 `\"`）
- [ ] HTML 标签已转义：`<` → `&lt;`, `>` → `&gt;`
- [ ] JSON 双引号已转义：`"` → `&quot;`
- [ ] 样式属性内部已正确转义：`\` → `\\`, `"` → `\"`
- [ ] 没有使用 `<script>`、`<style>`、`<canvas>`、`<svg>` 标签

## 相关文档

- 静态图表请使用 `generate_chart` MCP 操作生成
