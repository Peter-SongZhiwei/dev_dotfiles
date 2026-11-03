# HTML包含宏 (HtmlIncludeMacro) 规范

## 概述

本规范详细介绍如何在icenter页面中创建和使用HTML包含宏。

## 什么是HTML包含宏？

HTML包含宏是 icenter 提供的宏组件，用于在页面中嵌入**外部HTML页面**。

### 与页面包含宏的区别

| 特性 | HTML包含宏 | 页面包含宏 |
|------|-----------|-----------|
| 嵌入内容 | 外部HTML页面（https开头） | iCenter空间的页面 |
| URL要求 | 必须以 `https` 开头 | iCenter内部页面 |

## 适用场景

✅ **适合使用HTML包含宏的场景**：

1. **嵌入外部HTML页面**：如企业内网/外网的Web页面
2. **展示第三方服务**：如市场页面、外部系统界面
3. **引用HTTPS网址**：需要以https开头的外部资源

❌ **不适合使用HTML包含宏的场景**：

1. 嵌入iCenter空间内的页面（应使用页面包含宏）
2. 需要嵌入HTTP（非HTTPS）页面（安全限制不支持）
3. 简单的静态内容展示

## ⚠️ 重要：HTML结构要求

### ❌ 错误方式

```html
<!-- 错误示例：缺少必需的宏属性 -->
<div class="ze-macro">
    <div class="ze-macro-body">
        <p>内容</p>
    </div>
</div>
```

```html
<!-- 错误示例：缺少 macro-key 属性 -->
<div class="ze-macro" macro-id="01k1234567890abcd">
    <div class="ze-macro-body">
        <p>内容</p>
    </div>
</div>
```

```html
<!-- 错误示例：使用HTTP而非HTTPS -->
<div class="ze-macro" macro-key="HtmlIncludeMacro" macro-id="01k1234567890abcd" m-url="http://example.com">
    <div class="ze-macro-body">
        <p>内容</p>
    </div>
</div>
```

```html
<!-- 错误示例：使用 iframe 标签包裹URL（❌ 禁止使用！） -->
<div class="ze-macro" macro-key="HtmlIncludeMacro" macro-id="01k1234567890abcd">
    <iframe src="https://example.com/page.html" width="100%" height="600"></iframe>
</div>
```

### ✅ 正确方式

```html
<!-- 正确格式：包含完整的宏属性 -->
<div class="ze-macro" 
     macro-key="HtmlIncludeMacro" 
     macro-id="01kj9yn80n7e0edv8neycvgqammgs7p2"
     m-mode="url"
     m-page-height="1600"
     m-page-width="1600"
     m-url="https://example.com/page.html">
    <div class="ze-macro-body">
        <p><br/></p>
    </div>
</div>
```

## ⚠️ 完整示例：正确的HTML块结构（直接可用）

### 基础HTML包含宏

```html
<div class="ze-macro" 
     macro-key="HtmlIncludeMacro" 
     macro-id="01kj9yn80n7e0edv8neycvgqammgs7p2"
     m-mode="url"
     m-page-height="1600"
     m-page-width="1600"
     m-url="https://market.zte.com.cn/zte-dn-portal-ui/#/mcpSquare">
    <div class="ze-macro-body">
        <p><br/></p>
    </div>
</div>
```

### 自定义尺寸的HTML包含宏

```html
<div class="ze-macro" 
     macro-key="HtmlIncludeMacro" 
     macro-id="01kabcdef1234567890"
     m-mode="url"
     m-page-height="800"
     m-page-width="1200"
     m-url="https://example.com/embedded-page.html">
    <div class="ze-macro-body">
        <p><br/></p>
    </div>
</div>
```

### 包含block属性的HTML包含宏（推荐）

```html
<div class="ze-macro" 
     macro-key="HtmlIncludeMacro" 
     macro-id="01kfull000000000001"
     block-id="htmlInc01"
     block-title="外部HTML页面嵌入"
     block-tags="HTML包含,嵌入,外部页面"
     m-mode="url"
     m-page-height="1600"
     m-page-width="1000"
     m-url="https://market.zte.com.cn/zte-dn-portal-ui/#/mcpSquare"
     enable-ai-check="n"
     enable-ai-create="n">
    <div class="ze-macro-body">
        <p><br/></p>
    </div>
</div>
```

## 核心属性说明

| 属性名称 | 说明 | 必需 | 示例值 |
|---------|------|------|-------|
| macro-key | 宏类型标识 | 是 | `HtmlIncludeMacro` |
| macro-id | 宏的唯一标识符，必须以 "01k" 开头 | 是 | `01kj9yn80n7e0edv8neycvgqammgs7p2` |
| m-mode | 模式类型 | 是 | `url` |
| m-url | 外部HTML页面URL（必须以https开头） | 是 | `https://example.com/page.html` |
| m-page-height | 页面高度（像素） | 是 | `1600` |
| m-page-width | 页面宽度（像素） | 是 | `1000` |
| block-id | 块的唯一标识符（推荐） | 推荐 | `htmlInc01` |
| block-title | 块的标题（推荐） | 推荐 | `外部HTML页面嵌入` |
| block-tags | 块的标签（推荐） | 推荐 | `HTML包含,嵌入` |
| enable-ai-check | 是否启用AI检查 | 否 | `n` |
| enable-ai-create | 是否启用AI创建 | 否 | `n` |

## macro-id 生成规则

- **前缀**: 必须以 `01k` 开头
- **长度**: 后面跟至少16位随机字符
- **格式**: 小写字母数字混合
- **示例**: `01kj9yn80n7e0edv8neycvgqammgs7p2`, `01kabcdef1234567890`

## 参数配置说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| HTML页面URL | / | 必填项，必须是以https开头的网址 |
| 页面高度px | 1600 | 嵌入页面的显示高度 |
| 页面宽度px | 1000 | 嵌入页面的显示宽度 |

## ⚠️ 特别说明

1. **URL必须以https开头**：由于安全原因，只支持HTTPS协议的网址
2. **外网访问限制**：
   - 如果嵌入的是内网地址，浏览该页面的人员必须拥有外网权限
   - 需要将内网地址加入白名单才能被外网访问
3. **白名单申请流程**：
   - 在IT网站-DMZ申请（参考：中兴云门户-域名流程）
   - 申请地址：https://it.zte.com.cn/itspweb/#/applyForm?serviceId=6007550&lang_id=2052
   - 申请通过后联系唐桂富(10229208)把内网地址加入白名单

## 创建流程

1. 确定要嵌入的外部HTML页面URL（必须https开头）
2. 确定嵌入区域的尺寸（高度和宽度）
3. 生成唯一的 macro-id（以 `01k` 开头）
4. 构建宏HTML结构
5. 使用 `create_block_by_url` 或 `create_page_by_url_with_content` 创建

## 注意事项

1. **⚠️ URL必须以 "https" 开头**：HTTP不被支持
2. **⚠️ m-mode 必须是 "url"**：表示通过URL模式嵌入
3. **✅ 建议设置 block 属性**：便于后续管理和识别
4. **✅ 根据内容调整尺寸**：根据实际嵌入页面的大小调整高度和宽度
5. **⚠️ 内网地址需要白名单**：如果要在外网访问，需要申请白名单
