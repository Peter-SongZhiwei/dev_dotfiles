---
description: 指导用户使用 icenter-mcp 的 create_chart_block 操作一步生成包含静态 SVG 图表的 iCenter 内容块
---

# iCenter 静态图表页面生成指南

> **前置要求**：生成页面前必须通过 `Skill` 工具加载 `icenter-page-guide` skill，了解块属性（`block-title`、`block-tags`）的正确 HTML 格式和核心约束。

## 一、核心原则

### 1.1 页面必须通过块追加方式生成（强制）

**所有页面生成必须采用"骨架页面 + 逐块追加"模式，禁止一次性写入全部内容。**

标准流程：
1. **创建骨架页面**：使用 `create_page_by_url_with_content` 仅写入页面标题和简要说明（控制在 2000 字符以内）
2. **逐块追加内容**：使用 `create_chart_block` / `create_block_by_url` 逐个追加内容块，每个块 `position: "end"`

禁止的做法：
- ❌ 在 `create_page_by_url_with_content` 的 `content` 中塞入全部图表和内容
- ❌ 使用 `update_page_by_url` 覆盖整个页面（会丢失已有块结构）
- ❌ 一次性写入超过 30000 字符的内容

### 1.2 图表生成首选 create_chart_block

**通过 MCP `create_chart_block` 操作一步完成。禁止 AI 手写图表 HTML/CSS。**

`create_chart_block` 是首选方案，后端使用 SVG 精确渲染图表，自动完成内容块封装和页面创建，一步到位。彻底避免了手写 HTML 时的坐标计算错误（尤其是折线图的 transform:rotate 错位、柱状图的 Y 轴刻度不均等常见问题）。

`generate_chart` 作为后补方案，仅用于需要对图表 HTML 进行二次加工的特殊场景。

## 二、首选方案：create_chart_block（一步完成）

### 调用方式

```
操作: create_chart_block
参数:
  page_url: "目标页面URL"          # 必填: 图表创建到的目标 iCenter 页面 URL
  charts: [                        # 必填: 图表规格数组，至少 1 个
    {
      chart_type: "bar",           # 必填: bar | line | pie | doughnut
      title: "图表标题",            # 必填
      labels: ["Q1", "Q2", "Q3", "Q4"],  # 必填: 数据标签列表
      values: [120, 180, 150, 200],      # 必填: 数据值列表（非负数）
      subtitle: "副标题",           # 可选，建议填写以提供数据背景
      color_scheme: "default",     # 可选，默认 default
      show_values: true,           # 可选，默认 true（在数据点上显示数值）
      value_suffix: "万元"         # 可选，默认为空。数值的单位标注
    },
    { ... }                        # 多个图表时继续添加
  ]
  layout: "1x2"                    # 可选: single | 1x2 | 2x2（默认根据 charts 数量自动选择）
  block_title: "图表块标题"         # 可选: 块标题（默认使用第一个图表的标题）
  block_tags: "图表,柱状图"         # 可选: 块标签（默认"图表,静态图表"）
  block_id: "chart01"              # 可选: 块ID（默认随机生成）
  position: "end"                  # 可选: begin | end | before | after（默认 end）
```

### 布局方式

| layout | 说明 | 自动触发条件 |
|--------|------|-------------|
| `single` | 单个图表全宽显示 | charts 长度为 1 |
| `1x2` | 一行两个图表并排（flexbox） | charts 长度为 2 |
| `2x2` | 两行两列网格（grid） | charts 长度 ≥ 3 |

不指定 `layout` 时，根据 `charts` 数量自动选择。也可以手动指定覆盖自动选择。

### 返回值

```json
{
  "success": true,
  "data": {
    "block_result": { "block_id": "...", ... },
    "layout": "1x2",
    "chart_count": 2,
    "charts_meta": [
      { "chart_type": "line", "title": "用户增长", "data_count": 6, ... },
      { "chart_type": "bar", "title": "月度订单", "data_count": 6, ... }
    ]
  },
  "message": "图表块创建成功: 2 个图表, 布局 1x2, 位置 end"
}
```

### 参数说明

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `page_url` | ✅ 是 | - | 目标 iCenter 页面 URL |
| `charts` | ✅ 是 | - | 图表规格数组，每项包含以下子字段 |
| `charts[].chart_type` | ✅ 是 | - | `bar`(柱状图) / `line`(折线图) / `pie`(饼图) / `doughnut`(环形图) |
| `charts[].title` | ✅ 是 | - | 图表标题 |
| `charts[].labels` | ✅ 是 | - | 数据标签列表，如 `['1月','2月','3月']` |
| `charts[].values` | ✅ 是 | - | 数据值列表，如 `[100, 150, 200]`，不支持负数 |
| `charts[].subtitle` | 否 | `""` | 副标题，建议填写以说明数据来源或时间范围 |
| `charts[].color_scheme` | 否 | `"default"` | 配色方案，见下方选项 |
| `charts[].show_values` | 否 | `true` | 是否在数据点上显示数值标签 |
| `charts[].value_suffix` | 否 | `""` | 数值后缀/单位，如 `"次"`、`"%"`、`"万元"` |
| `layout` | 否 | 自动选择 | `single` / `1x2` / `2x2` |
| `block_title` | 否 | 首个图表标题 | 块标题（显示在页面章节树中） |
| `block_tags` | 否 | `"图表,静态图表"` | 块标签，逗号分隔 |
| `block_id` | 否 | 随机生成 | 块唯一标识 |
| `position` | 否 | `"end"` | 插入位置：`begin`(页首)、`end`(页尾)、`before`(目标块前)、`after`(目标块后) |

## 三、完整页面创建流程（使用 create_chart_block）

### 第一步：确认目标页面 URL

按以下优先级确定：
1. **用户提示词指定**：从用户描述中提取目标页面位置
2. **环境变量**：`ICENTER_MCP_DEFAULT_PARENT_PAGE_URL`
3. **默认值**：`https://i.zte.com.cn/index/ispace/#/space/4eabd2b22c5c422fabd4fa91d25b1506/wiki/page/1ff8a100493811f19e08a7efc0fb7ed0/view`

### 第二步：推荐图表类型

根据数据特征推荐最合适的图表类型，向用户确认后再继续。

### 第三步：创建骨架页面（仅标题和简要说明）

> ⚠️ **此步骤只创建页面骨架，不写入任何图表内容。** 所有内容后续通过块追加方式写入。

```
操作: create_page_by_url_with_content
参数:
  title: "季度销售数据分析"
  parent_url: "<父页面URL>"
  # content 仅包含标题和一段简要说明，控制在 2000 字符以内
  content: '<h1>季度销售数据分析</h1><p>以下为本季度各部门销售数据的统计图表。</p>'
```

### 第四步：通过块追加方式写入图表内容

> ⚠️ **所有内容必须通过 `create_chart_block` 或 `create_block_by_url` 逐块追加，禁止在骨架页面中直接写入图表。**

**调用 `create_chart_block` 追加图表块，`position` 始终设为 `"end"`：**

```
操作: create_chart_block
参数:
  page_url: "<新创建的页面URL>"
  charts: [
    {
      chart_type: "bar",
      title: "季度销售对比",
      labels: ["Q1", "Q2", "Q3", "Q4"],
      values: [120, 180, 150, 200],
      value_suffix: "万元",
      subtitle: "2026年度各部门销售数据",
      color_scheme: "blue"
    },
    {
      chart_type: "line",
      title: "月度增长趋势",
      labels: ["1月", "2月", "3月", "4月", "5月", "6月"],
      values: [80, 95, 112, 130, 145, 168],
      value_suffix: "万元",
      subtitle: "2026年上半年增长趋势",
      color_scheme: "green"
    }
  ]
  layout: "1x2"
  block_title: "销售数据分析图表"
  block_tags: "图表,销售,柱状图,折线图"
  position: "end"
```

多个图表块可以逐个调用 `create_chart_block` 追加：

```
# 追加第一个图表块（数据概览图表）
create_chart_block(page_url=..., charts=[{...}, {...}], layout="1x2", position="end")

# 追加第二个图表块（部门对比图表）
create_chart_block(page_url=..., charts=[{...}], layout="single", block_title="部门对比", position="end")

# 追加第三个图表块（趋势分析图表）
create_chart_block(page_url=..., charts=[{...}, {...}, {...}, {...}], layout="2x2", position="end")
```

### 第五步：追加其他内容块（可选）

如需追加数据表格、总结等非图表内容块，使用 `create_block_by_url`。

### 第六步：验证

1. 使用 `get_page_detail_by_url` 确认页面内容正确
2. 向用户报告生成结果和新页面 URL

## 四、`position` 参数说明

| position | 用途 |
|----------|------|
| `"end"` | 追加到页面末尾（**推荐**，逐个追加块时用这个就够了） |
| `"begin"` | 插入到页面开头 |
| `"before"` | 插入到目标块之前（需指定 `target_block_title`/`target_block_id`/`target_block_tags` 之一） |
| `"after"` | 插入到目标块之后（需指定 `target_block_title`/`target_block_id`/`target_block_tags` 之一） |

## 五、图表类型选择

| 数据特征 | 图表类型 | `chart_type` | 典型场景 |
|---------|---------|---------------|---------|
| 比较不同类别的数值大小 | **柱状图** | `bar` | 季度销售、分类统计、部门对比 |
| 展示随时间变化的趋势 | **折线图** | `line` | 月度增长、温度变化、性能指标走势 |
| 展示各部分占整体的比例 | **饼图** | `pie` | 市场份额、人员分布、预算占比 |
| 饼图变体，中心显示总计 | **环形图** | `doughnut` | 预算分配、资源占比、分类统计 |

**选择规则**：
- 有明确时间序列（月份/季度/年份）→ `line`
- 有明确分类比较（部门/产品/地区）→ `bar`
- 数据为比例/百分比且总和有意义 → `pie` 或 `doughnut`
- 多维度数据 → 使用 `create_chart_block` 的 `layout: "2x2"` 在一个块内展示多个图表，或多次调用创建多个图表块

## 六、配色方案

| 配色方案 | `color_scheme` | 适用场景 |
|---------|---------------|---------|
| 默认 | `default` | 通用场景，色彩鲜明 |
| 蓝色系 | `blue` | 企业数据、严肃报告 |
| 绿色系 | `green` | 环保、增长相关 |
| 暖色系 | `warm` | 营销、活动数据 |
| 紫色系 | `purple` | 创意、品牌展示 |
| 彩虹色 | `rainbow` | 多类别、活泼风格（饼图/环形图推荐） |

多图表页面建议使用不同配色方案以区分。

## 七、后补方案：generate_chart（仅特殊场景）

> ⚠️ `generate_chart` 仅用于需要对图表 HTML 进行二次加工的场景。其他所有场景请使用 `create_chart_block`。

### 适用场景

| 场景 | 使用方式 |
|------|---------|
| 需要在图表 HTML 前后添加自定义内容 | `generate_chart` → 拼接 HTML → `create_block_by_url` |
| 需要将图表嵌入到已有页面的特定位置 | `generate_chart` → 定位 → `create_block_by_url` |
| 需要对图表 HTML 进行二次加工 | `generate_chart` → 修改 HTML → 使用 |
| 其他所有场景 | **使用 `create_chart_block`** |

### 调用方式

```
操作: generate_chart
参数:
  chart_type: "bar"          # 必填: bar | line | pie | doughnut
  title: "图表标题"           # 必填
  labels: ["Q1", "Q2", "Q3", "Q4"]  # 必填
  values: [120, 180, 150, 200]      # 必填
  subtitle: "副标题"          # 可选
  color_scheme: "default"    # 可选
  show_values: true          # 可选
  value_suffix: "万元"       # 可选
```

### 后补方案完整流程示例

```
# 1. 生成图表 HTML
result = generate_chart(chart_type="bar", title="...", labels=[...], values=[...])

# 2. AI 对 data.html 进行二次加工（添加说明文字、表格等）
custom_html = '<p>说明文字</p>' + result.data.html

# 3. 手动创建块
create_block_by_url(page_url="...", content=custom_html, position="end")
```

## 八、多图表页面排版

| 块类型 | 内容 | 使用操作 |
|--------|------|---------|
| 标题块 | 页面标题、分析目的、时间范围 | `create_page_by_url_with_content` |
| 图表块1 | 数据概览（2张图表 1×2 布局） | `create_chart_block` |
| 图表块2 | 趋势分析（4张图表 2×2 布局） | `create_chart_block` |
| 图表块3 | 单个重点图表 | `create_chart_block` |
| 说明块（可选） | 数据来源、关键发现 | `create_block_by_url` |
| 数据块（可选） | 原始数据表格 | `create_block_by_url` |
| 总结块（可选） | 结论与建议 | `create_block_by_url` |

## 九、核心约束

- **首选 `create_chart_block`**：一步完成图表生成和内容块创建
- **禁止手写图表 HTML**：必须使用 MCP 图表操作生成
- `generate_chart` 仅用于需要二次加工 HTML 的特殊场景
- **禁止** `<style>` 标签（行内样式除外）
- **禁止** `<script>` 标签
- **禁止** 直接使用 `<canvas>` 和 `<svg>` 标签
- 父页面 URL 未确认前不允许创建页面
- `labels` 和 `values` 长度必须一致
- `values` 不支持负数
- 折线图至少需要 2 个数据点

## 十、检查清单

- [ ] 优先使用 `create_chart_block`，而非 `generate_chart` + `create_block_by_url`
- [ ] 图表 HTML 正确嵌入页面内容块（block-type="custom"）
- [ ] `labels` 与 `values` 长度一致
- [ ] 配色方案与数据主题匹配
- [ ] 多图表页面各图表配色有区分度
- [ ] 已向用户报告新页面 URL
