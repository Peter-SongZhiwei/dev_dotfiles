# 思维导图 (Mindmap) 规范

## 概述

本规范详细介绍如何在icenter页面中嵌入思维导图。

> ✅ **2026-10-09 复核修正**：思维导图有**两种可用方式**，优先用第一种：
> 1. **PlantUML `@startmindmap`（首选）**——`create_plantuml_block` 直接生成，实测校验通过且页面渲染为正常思维导图（浏览器截图确认）；样式基线同其他 PlantUML 图（`!theme cerulean` + `skinparam backgroundColor #FFFFFF` + `skinparam defaultFontColor #000000`）。
> 2. **内嵌图片标签 + `data-mindmapping`（备选）**——本文档以下内容，适用于必须使用"可点击编辑的导图组件"形态时。
>
> 早前"禁止用 PlantUML 实现思维导图"的结论**已不成立**。

## 方式二：内嵌图片标签 + data-mindmapping（备选）

icenter2.0 使用内联图片标签来嵌入思维导图组件。

⚠️ **关键限制**：思维导图的 `src` 属性必须是**真实的icenter平台图片URL**，这个URL需要通过以下方式获取：
1. 在icenter页面编辑器中创建思维导图，然后复制图片URL
2. 或者使用已存在的思维导图图片URL作为模板

## 思维导图HTML结构（icenter2.0版本 - 正确格式）

```html
<p style="" tag-start="p">思维导图<br/>
<img block-id="2SXKvBLj" 
     border="" 
     data-inline="true" 
     data-mindmapping='{"meta":{"name":"demo"},"format":"node_array","data":[{"id":"root","topic":"中心主题","expanded":true,"isroot":true},{"id":"sub1","topic":"分支主题 1","expanded":true,"parentid":"root","direction":"right"},{"id":"8a1799618d6e3872","topic":"子主题 1","expanded":false,"parentid":"sub1"},{"id":"8a179840662499ab","topic":"分支主题 2","expanded":true,"parentid":"root","direction":"right"},{"id":"8a1799a7b7b04055","topic":"子主题 1","expanded":false,"parentid":"8a179840662499ab"},{"id":"8a17989102869ed1","topic":"分支主题 3","expanded":true,"parentid":"root","direction":"left"},{"id":"8a1799dd04147207","topic":"子主题 1","expanded":false,"parentid":"8a17989102869ed1"}]}' 
     data-unique-id="01k49f76y5dech2vsg99n1q4r89gdcdw" 
     dpiheight="96" 
     dpiwidth="96" 
     filename="image.png" 
     filesize="undefined" 
     height="269" 
     href="" 
     inline="true" 
     originheight="269" 
     originwidth="773" 
     pageid="undefined" 
     sourcegraphids="" 
     src="https://icenterapi.zte.com.cn/group3/M05/41/89/CimMFmicBpKAVGtTAABOFfsJSWc575.jpg?w=773&h=269" 
     style="width:773px;height:269px;" 
     tag="img" 
     title="" 
     unit="px" 
     uuid="img-oINPSeNk" 
     width="773"/></p>
```

## ⚠️ 关键：如何获取思维导图图片URL

由于思维导图需要使用icenter平台生成的真实图片URL，建议采用以下方式：


### 方式1：使用现有URL作为模板

以下URL为icenter平台已有的思维导图图片，可作为参考：
```
https://icenterapi.zte.com.cn/group3/M05/AF/83/CimMFmjH9dSAPF_zAABX6KYMamQ265.jpg
https://icenterapi.zte.com.cn/group3/M05/41/89/CimMFmicBpKAVGtTAABOFfsJSWc575.jpg
```

### 重要说明

⚠️ **禁止使用**：
- ❌ `src="data:image/png;base64,..."` (base64占位符)
- ❌ `src=""` (空属性)
- ❌ 其他非icenter平台的图片URL

💡 **无法获取有效图片 URL 时**：改用 **PlantUML `@startmindmap`**（首选方式，见文档开头），或使用流程图/表格展示层级结构。

## 思维导图数据结构

```json
{
  "meta": {
    "name": "思维导图名称"
  },
  "format": "node_array",
  "data": [
    {
      "id": "root",
      "topic": "中心主题",
      "expanded": true,
      "isroot": true
    },
    {
      "id": "sub1",
      "topic": "分支主题1",
      "expanded": true,
      "parentid": "root",
      "direction": "right"
    },
    {
      "id": "8a1799618d6e3872",
      "topic": "子主题1",
      "expanded": false,
      "parentid": "sub1"
    }
  ]
}
```

## 关键要求 ⚠️ 重要

### 1. icenter2.0版本要求（推荐）

**必须包含以下关键属性**：
- `block-id`: 块级元素ID，格式如 "2SXKvBLj"
- `data-inline="true"`: 内联标识
- `inline="true"`: 内联标识
- `tag="img"`: 标签类型
- `uuid`: 唯一标识符，格式如 "img-oINPSeNk"
- `unit="px"`: 单位标识
- `dpiheight="96"` 和 `dpiwidth="96"`: DPI设置
- `filename="image.png"`: 文件名
- `src`: 必须是真实的icenter图片URL

### 2. src属性格式要求

**必须使用真实的icenter图片URL**：
```html
src="https://icenterapi.zte.com.cn/group3/M05/41/89/CimMFmicBpKAVGtTAABOFfsJSWc575.jpg?w=773&h=269"
```

⚠️ **注意**：URL后可以添加查询参数 `?w=宽度&h=高度`

**禁止使用**：
- ❌ `src="data:image/png;base64,..."` (base64占位符)
- ❌ `src=""` (空属性)
- ❌ 其他非icenter平台的图片URL

### 3. data-unique-id格式要求

**必须使用32位十六进制格式**：
```html
data-unique-id="01k49f76y5dech2vsg99n1q4r89gdcdw"
```

### 4. 节点ID格式要求

**所有节点ID必须使用32位十六进制格式**：
```json
{
  "id": "8a1799618d6e3872",  // ✅ 正确格式
  "topic": "分支主题1",
  "parentid": "root"  // 根节点可以使用"root"
}
```

**注意**：根节点使用 `"id": "root"` 而不是32位十六进制

### 5. direction属性说明

- `direction: "right"` - 右分支
- `direction: "left"` - 左分支
- 不指定direction时默认为右分支

## 常见错误 ⚠️

### 错误1：宏结构写残（json 不在 `<p>` 内 / 缺 macro-key）

❌ **错误**：宏体不是可解析 JSON，或缺少 `macro-key`（页面会原样显示 JSON 文本）
```html
<div class="ze-macro">
  <div class="ze-macro-body">
    <div class="plantuml-source">
      <p>@startmindmap ... @endmindmap</p>
    </div>
  </div>
</div>
```

✅ **正确（首选）**：交给 `create_plantuml_block` 生成，无需手写宏
```
create_plantuml_block(page_url=…, content="@startmindmap\n...\n@endmindmap", title="思维导图")
```

✅ **正确（备选，图片标签方式）**：
```html
<img data-mindmapping='{...}' src="https://icenterapi.zte.com.cn/..." ...>
```

## 创建流程

1. 需求分析 - 确定思维导图主题和内容
2. 数据结构构建 - 生成32位十六进制格式的节点ID
3. HTML内容构建 - 嵌入思维导图HTML标签
4. 页面创建 - 使用 `create_page_by_url_with_content`

## 注意事项

1. ✅ **首选 PlantUML**（`@startmindmap`，2026-10-09 实测渲染正常）；图片标签方式为备选
2. 图片标签方式禁止使用 `src="data:image/png;base64,..."` 进行占位，必须使用真实URL
3. 节点ID必须使用32位十六进制格式（根节点除外）
4. 确保所有必要的属性完整，否则无法渲染
