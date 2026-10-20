# 代码块与数据结构嵌入规范

## 概述

本规范详细介绍如何在icenter页面中嵌入代码片段、JSON、XML、YAML等数据结构。

## ⚠️ 重要规则

**代码块必须使用 `<pre class="prettyprint linenums brush:语言">` 格式，并始终嵌套在 `<details>` 折叠宏中！**

折叠展示时，`<details>` 可以包裹代码块，block-id 属性应直接放在 `<details>` 标签上（而非内部结构中）。

> ⚠️ **两条 2026-10-09 实测补充：**
> 1. **可更新性**：折叠宏（连同里面的代码块）要能被后续 `update_block` 更新，**必须整体包在内容块里**：
>    `<div block-type='custom' block-title='…'><details …>…</details></div>`；裸 `<details>` 无法更新。
> 2. **默认态**：`collapse-state="open" open` 在页面阅读态**仍渲染为折叠态**（实测），
>    代码默认不可见——需要"一眼看到"的代码请勿折叠，或接受用户需手动展开。

## 适用场景

✅ **适合嵌入代码块和数据结构的场景**：

1. **API 接口的请求/响应示例**
2. **配置文件（JSON、XML、YAML）**
3. **代码示例（Python、Java、Go等）**
4. **数据库表结构 SQL**
5. **任何需要展示的结构化数据**

❌ **不适合的场景**：

1. 简短的普通文本
2. 不需要语法高亮的纯文本说明

## 支持的语言类型

| brush 属性值 | 说明 |
|-------------|------|
| python | Python 代码 |
| java | Java 代码 |
| bash / shell | Shell/Bash 命令 |
| js / javascript | JavaScript 代码 |
| go | Go 代码 |
| html | HTML 代码 |
| sql | SQL 语句 |
| yaml | YAML 配置 |
| xml | XML 数据 |

## ⚠️ 重要：HTML结构要求

### ❌ 错误方式

```html
<!-- 错误示例：缺少 brush 属性 -->
<pre class="prettyprint">
def hello():
    print("Hello")
</pre>
```

```html
<!-- 错误示例：brush 属性值不正确 -->
<pre class="prettyprint linenums brush:python3">
code here
</pre>
```

```html
<!-- 错误示例：直接嵌入代码而不用折叠宏包裹 -->
<p>Python代码：</p>
<pre class="prettyprint linenums brush:python">
def hello():
    print("Hello World")
</pre>
```

### ✅ 正确方式

```html
<!-- 正确格式：使用 brush 属性 -->
<pre class="prettyprint linenums brush:python">
def hello():
    print("Hello World")
</pre>
```

## ⚠️ 完整示例：正确的HTML块结构（直接可用）

### 1. 直接嵌入代码块（仅适用于极简短代码，**不推荐**用于技术文档）

> ⚠️ **生成 icenter 页面时，必须将代码块嵌套在 `<details>` 折叠宏中**，除非代码极简短且无需折叠。参考下方案例 2。

```html
<p>Python代码示例：</p>
<pre class="prettyprint linenums brush:python">
def get_page_detail_by_url(page_url):
    page_info = parse_icenter_url(page_url)
    if not page_info:
        raise ValueError("parent_page_url is invalid")
    space_id = page_info["space_id"]
    page_id = page_info["page_id"]
    return raw_icenter_apis.get_page_detail(page_id, space_id)
</pre>
```

### 2. 嵌入Python代码（**必须**：嵌套在折叠宏中）

```html
<details block-id="pyCode01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">Python代码示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:python">
def get_page_detail_by_url(page_url):
    page_info = parse_icenter_url(page_url)
    if not page_info:
        raise ValueError("parent_page_url is invalid")
    space_id = page_info["space_id"]
    page_id = page_info["page_id"]
    return raw_icenter_apis.get_page_detail(page_id, space_id)
    </pre>
    <p><br/></p>
</details>
```

### 3. 嵌入Java代码（嵌套在折叠宏中）

```html
<details block-id="java01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">Java代码示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:java">
private void cacheCustomIpsInfo(JSONObject netDetectionConfig, String keyInCustomConfig,
        Map&lt;String, List&lt;DetectionIp&gt;&gt; needDetectIpInfo, String detectIpsSourceType) {
    log.info("start cacheCustomIpsInfo");
    String ipsStrFmt = netDetectionConfig.getString(keyInCustomConfig);
    if (!StringUtils.isEmpty(ipsStrFmt)) {
        List&lt;DetectionIp&gt; northCustomDetectionIps = getCustomDetectionIps(ipsStrFmt);
        needDetectIpInfo.put(detectIpsSourceType, northCustomDetectionIps);
    }
}
    </pre>
    <p><br/></p>
</details>
```

### 4. 嵌入JavaScript/JSON代码（嵌套在折叠宏中）

```html
<details block-id="json01" collapse-state="open" open>
    <summary style="margin-left: -1rem;">JSON数据结构</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
{
    "api_name_en": "Query the consistency check and synchronization results of engineering parameters",
    "api_name_zh": "查询工程参数的一致性核查和同步结果",
    "uri": "/check/checkOperationInfo",
    "method": "GET",
    "tags_i18n": {
        "en-US": "Query the consistency check and synchronization results of engineering parameters",
        "zh-CN": "查询工程参数的一致性核查和同步结果"
    }
}
    </pre>
    <p><br/></p>
</details>
```

### 5. 嵌入Shell/Bash代码（嵌套在折叠宏中）

```html
<details block-id="bash01" collapse-state="closed">
    <summary style="margin-left: -1rem;">Shell脚本</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:bash">
#!/bin/bash
name=yb
echo "Hello, $name"
    </pre>
    <p><br/></p>
</details>
```

### 6. 嵌入Go代码（嵌套在折叠宏中）

```html
<details block-id="go01" collapse-state="closed">
    <summary style="margin-left: -1rem;">Go代码示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:go">
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}
    </pre>
    <p><br/></p>
</details>
```

### 7. 嵌入HTML代码（嵌套在折叠宏中）

```html
<details block-id="html01" collapse-state="closed">
    <summary style="margin-left: -1rem;">HTML代码示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:html">
&lt;div class="container"&gt;
    &lt;h1&gt;标题&lt;/h1&gt;
    &lt;p&gt;内容&lt;/p&gt;
&lt;/div&gt;
    </pre>
    <p><br/></p>
</details>
```

### 8. 嵌入SQL代码（嵌套在折叠宏中）

```html
<details block-id="sql01" collapse-state="closed">
    <summary style="margin-left: -1rem;">SQL语句示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:sql">
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
    </pre>
    <p><br/></p>
</details>
```

### 9. 嵌入XML数据（嵌套在折叠宏中）

```html
<details block-id="xml01" collapse-state="closed">
    <summary style="margin-left: -1rem;">XML配置</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:xml">
&lt;?xml version="1.0" encoding="UTF-8"?&gt;
&lt;config&gt;
    &lt;server&gt;
        &lt;host&gt;localhost&lt;/host&gt;
        &lt;port&gt;8080&lt;/port&gt;
    &lt;/server&gt;
    &lt;database&gt;
        &lt;type&gt;mysql&lt;/type&gt;
        &lt;name&gt;icenter&lt;/name&gt;
    &lt;/database&gt;
&lt;/config&gt;
    </pre>
    <p><br/></p>
</details>
```

### 10. 嵌入YAML配置（嵌套在折叠宏中）

```html
<details block-id="yaml01" collapse-state="closed">
    <summary style="margin-left: -1rem;">YAML配置</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:yaml">
server:
  host: localhost
  port: 8080
  ssl:
    enabled: true
    cert: /path/to/cert
database:
  type: mysql
  name: icenter
  user: admin
  password: secret
logging:
  level: info
  file: /var/log/app.log
    </pre>
    <p><br/></p>
</details>
```

### 11. 多个代码块组合（标准做法）

```html
<p>下面包含多个代码示例：</p>

<details block-id="multiPy" collapse-state="open" open>
    <summary style="margin-left: -1rem;">Python示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:python">
def hello():
    print("Hello World")
    </pre>
    <p><br/></p>
</details>

<details block-id="multiJs" collapse-state="closed">
    <summary style="margin-left: -1rem;">JavaScript示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
function hello() {
    console.log("Hello World");
}
    </pre>
    <p><br/></p>
</details>

<details block-id="multiJson" collapse-state="closed">
    <summary style="margin-left: -1rem;">JSON示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
{
    "name": "example",
    "version": "1.0.0"
}
    </pre>
    <p><br/></p>
</details>

<details block-id="multiYaml" collapse-state="closed">
    <summary style="margin-left: -1rem;">YAML示例</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:yaml">
name: example
version: 1.0.0
    </pre>
    <p><br/></p>
</details>
```

### 12. API文档示例（实际应用场景）

```html
<p>API接口详情：</p>

<details block-id="apiReq" collapse-state="open" open>
    <summary style="margin-left: -1rem;">请求参数</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
{
    "page_index": 1,
    "page_size": 10,
    "keyword": "search term",
    "filters": {
        "status": "active",
        "type": "document"
    }
}
    </pre>
    <p><br/></p>
</details>

<details block-id="apiResp" collapse-state="open" open>
    <summary style="margin-left: -1rem;">响应结果</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
{
    "success": true,
    "data": {
        "total": 100,
        "items": [
            {
                "id": "123",
                "title": "Document Title",
                "status": "active"
            }
        ]
    },
    "error": null
}
    </pre>
    <p><br/></p>
</details>

<details block-id="apiCurl" collapse-state="closed">
    <summary style="margin-left: -1rem;">cURL命令</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:bash">
curl -X GET "http://localhost:8080/api/documents?page_index=1&page_size=10" \
  -H "Authorization: Bearer your_token_here" \
  -H "Content-Type: application/json"
    </pre>
    <p><br/></p>
</details>
```

## 核心属性说明

| 属性名称 | 说明 | 必需 | 示例值 |
|---------|------|------|-------|
| class | CSS类名 | 是 | `prettyprint linenums brush:python` |
| brush | 语言类型 | 是 | `python`, `java`, `js`, `yaml` 等 |
| block-id | 块的唯一标识符（推荐） | 推荐 | `pyCode01` |

## 创建流程

1. 确定要嵌入的代码或数据结构类型
2. 选择合适的 brush 属性值
3. 生成唯一的 block-id（8位字符）
4. 构建 `<pre>` 标签结构
5. **推荐**：将代码块嵌套在折叠宏中
6. 使用 `create_block_by_url` 或 `create_page_by_url_with_content` 创建

## 注意事项

1. **⚠️ class 属性必须包含 `prettyprint linenums brush:语言`**：这是语法高亮显示的关键
2. **⚠️ brush 属性值必须与代码语言匹配**：否则高亮可能不正确
3. **⚠️ JSON 数据使用 `brush:js`**：不是 `brush:json`
4. **⚠️ XML 数据使用 `brush:xml`**
5. **⚠️ YAML 数据使用 `brush:yaml`**
6. **✅ 强烈建议**：将代码块和数据结构嵌套在折叠宏中，保持页面简洁
7. **✅ block-id 建议包含有意义的标识**：如 `pyCode01`, `json01`, `yaml01` 等

## HTML特殊字符转义

在嵌入HTML/XML代码时，需要对特殊字符进行转义：

| 原始字符 | 转义后 |
|---------|--------|
| < | `&lt;` |
| > | `&gt;` |
| & | `&amp;` |

示例：
```html
<!-- 嵌入HTML代码时 -->
<pre class="prettyprint linenums brush:html">
&lt;div&gt;内容&lt;/div&gt;
</pre>
```
