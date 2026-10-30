# 技术文档生成规范指南

本章节介绍如何根据技术文档的不同内容类型，选择合适的展示形式，生成高质量的icenter页面。

> ℹ️ **2026-10-09 说明**：本文示例中的 PlantUML 宏写了 `macro-id="01k…"` / `ze-root="zeRoot"` 等属性——
> 这些均为**可写可不写**（`macro-key="PlantUmlMacro"` + `<p>` 内可解析 JSON 才是渲染必需，见 `plantuml-guide.md`）。
> 生成 PlantUML 时**优先用 `create_plantuml_block`**（一步生成并校验），示例中的手写宏仅作结构参考。

---

## 1. 内容类型与展示形式对照表

| 内容类型 | 推荐展示形式 | 配套使用 |
|---------|-------------|---------|
| 数据库表结构 | 折叠宏+代码块 | `<details>`+`<pre>` |
| 数据库表关系（ER图） | PlantUML 类图/实体图（`class`/`entity`，推荐）或用时序图展示关系 | 直接嵌入（iCenter 支持全部 PlantUML 图表类型，含类图/实体图） |
| JSON数据结构 | 折叠宏+代码块 | `<details>`+`<pre>` |
| YAML配置 | 折叠宏+代码块 | `<details>`+`<pre>` |
| Python/Java代码 | 折叠宏+代码块 | `<details>`+`<pre>` |
| API请求/响应 | 折叠宏+代码块 | `<details>`+`<pre>` |
| 业务流程（时序） | PlantUML时序图 | 直接嵌入 |
| 业务流程（步骤） | PlantUML活动图 | 直接嵌入 |
| 架构图 | PlantUML活动图 | 直接嵌入 |
| 决策树/条件分支 | PlantUML活动图 | 直接嵌入 |
| 概念解释 | Markdown或纯文本 | 直接使用 |
| 参数说明 | HTML表格 | 直接使用 |

---

## 2. 各类展示形式的详细规范

### 2.1 数据库表结构与ER图

#### 使用场景
- 数据库表字段说明
- 表与表之间的关联关系
- 实体与实体的对应关系

#### 推荐形式
- **表字段说明**: 折叠宏 + 代码块（Python类定义或JSON格式）
- **ER图/表关系**: PlantUML 类图/实体图（`class`/`entity` 关键字，推荐）或时序图（用 `participant`/`database` 展示关系）。iCenter 支持全部 PlantUML 图表类型（2026-06-11 确认，见 lessons_learned.md 错误 10）

#### HTML示例：数据库表字段说明

```html
<details block-id="TableUser" collapse-state="closed">
    <summary style="margin-left: -1rem;">用户表 (t_user)</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:python">
class User(Base):
    __tablename__ = 't_user'
    
    id = Column(BigInteger, primary_key=True)
    username = Column(String(64), nullable=False)
    email = Column(String(128), unique=True)
    created_at = Column(BigInteger, nullable=False)
    </pre>
    <p><br/></p>
</details>
```

#### HTML示例：数据库表关系图（时序图写法）

展示数据库表关系推荐用 PlantUML 类图/实体图（`class`/`entity`）；下面给出**时序图**的等价写法（适合需要表达调用/依赖方向时）：

```html
<div class="ze-macro" macro-key="PlantUmlMacro" macro-id="01kERDiagram" source-macro-id="01k56kdm19acb3m0f5bwkqds9h72st7y" ze-root="zeRoot">
  <div class="ze-macro-body">
    <p>{"title":"数据库表关系图","syntax":"@startuml\n!theme cerulean\nskinparam backgroundColor #FFFFFF\nskinparam defaultFontColor #000000\nskinparam sequenceParticipant underline\n\nparticipant \"Dialogue 对话表\" as D\ndatabase \"ChatRecord 聊天记录表\" as CR\ndatabase \"PendingTask 待处理任务表\" as PT\n\nD -> CR: dialogue_id (FK)\nD -> PT: dialogue_id (FK)\n@enduml","dropshadow":false,"align":"left","type":"plantuml"}</p>
  </div>
</div>
```

---

### 2.2 JSON/YAML/代码块

#### 使用场景
- JSON数据结构展示
- YAML配置文件
- Python/Java/Go等代码示例
- API请求/响应示例
- 配置项说明

#### 推荐形式
- **必须使用**: 折叠宏 `<details>` + 代码块 `<pre class="prettyprint linenums brush:语言">`
- **语言类型**: 通过brush属性指定（python, js, yaml, java, go, bash, sql, xml等）

#### HTML示例：JSON数据结构

```html
<details block-id="JsonExample" collapse-state="closed">
    <summary style="margin-left: -1rem;">ChatRequest请求结构</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:js">
{
  "dialogueId": "dialogue-123",
  "question": "用户问题",
  "data": [
    {
      "type": "button",
      "data": {"name": "确定", "click": true}
    }
  ]
}
    </pre>
    <p><br/></p>
</details>
```

#### HTML示例：Python代码

```html
<details block-id="PythonCode" collapse-state="closed">
    <summary style="margin-left: -1rem;">PendingTask核心方法</summary>
    <p><br/></p>
    <pre class="prettyprint linenums brush:python">
def act(self, chat_request):
    task = TaskFactory.create_task(self.type)
    success, message, response_data = task.act(chat_request, self.data)
    
    # 更新ChatRecord为已操作状态
    session_repo.update_record_operation_status_by_pending_task_id(self.id, 1)
    
    return success, message, response_data
    </pre>
    <p><br/></p>
</details>
```

---

### 2.3 业务流程（时序图）

#### 使用场景
- 用户与系统的交互流程
- 服务间的调用关系
- 任务的执行顺序
- 消息的传递路径

#### 推荐形式
- **PlantUML时序图**: 使用 `actor`/`participant`/`->`/`-->`等语法

#### HTML示例：时序图

```html
<div class="ze-macro" macro-key="PlantUmlMacro" macro-id="01kSeqDiagram" source-macro-id="01k56kdm19acb3m0f5bwkqds9h72st7y" ze-root="zeRoot">
  <div class="ze-macro-body">
    <p>{"title":"用户提问处理时序图","syntax":"@startuml\n!theme cerulean\nskinparam backgroundColor #FFFFFF\nskinparam participantFontColor #000000\nskinparam sequenceParticipant underline\nskinparam arrowColor #000000\nactor User\nparticipant ChatAPI\nparticipant ConvAgent\nparticipant Coordinator\nparticipant SessionRepo\ndatabase DB\nUser->ChatAPI: 发送问题\nChatAPI->ConvAgent: copilot_chat()\nConvAgent->Coordinator: chat()\nCoordinator->SessionRepo: 查询会话\nSessionRepo->DB: 读取数据\nDB-->SessionRepo: 返回结果\nSessionRepo-->Coordinator: 返回\nCoordinator->ChatAPI: 返回响应\nChatAPI->User: SSE推送\n@enduml","dropshadow":false,"align":"left","type":"plantuml"}</p>
  </div>
</div>
```

---

### 2.4 业务流程（活动图/流程图）

#### 使用场景
- 业务流程步骤
- 条件分支决策
- 状态转换流程
- 架构组件关系

#### 推荐形式
- **PlantUML活动图**: 使用 `start`/`stop`/`if`/`else`/`fork`/`join`等语法

#### HTML示例：活动图（流程图）

```html
<div class="ze-macro" macro-key="PlantUmlMacro" macro-id="01kFlowChart" source-macro-id="01k56kdm19acb3m0f5bwkqds9h72st7y" ze-root="zeRoot">
  <div class="ze-macro-body">
    <p>{"title":"Chat接口处理流程","syntax":"@startuml\n!theme cerulean\nskinparam backgroundColor #FFFFFF\nskinparam activityFontColor #000000\nskinparam activityBackgroundColor #FFFFFF\nskinparam activityBorderColor #000000\nskinparam arrowColor #000000\nstart\n:接收ChatRequest;\nif (data是否存在?) then (否)\n:新问题处理;\nelse (是)\nif (包含按钮组件?) then (否)\n:参数处理;\nelse (是)\n:确认操作处理;\nendif\nendif\n:保存到数据库;\n:返回响应;\nstop\n@enduml","dropshadow":false,"align":"left","type":"plantuml"}</p>
  </div>
</div>
```

---

### 2.5 参数说明表格

#### 使用场景
- API参数列表
- 配置项说明
- 字段含义解释

#### 推荐形式
- **HTML表格**: 使用 `<table>`/`<thead>`/`<tbody>`/`<tr>`/`<th>`/`<td>`标签

#### HTML示例：参数表格

```html
<table class="table table-bordered" style="width: 100%; border-collapse: collapse;">
    <thead>
        <tr style="background-color: #f5f5f5;">
            <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">参数名</th>
            <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">类型</th>
            <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">必填</th>
            <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">说明</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td style="border: 1px solid #ddd; padding: 8px;">dialogueId</td>
            <td style="border: 1px solid #ddd; padding: 8px;">String</td>
            <td style="border: 1px solid #ddd; padding: 8px;">是</td>
            <td style="border: 1px solid #ddd; padding: 8px;">会话ID</td>
        </tr>
        <tr>
            <td style="border: 1px solid #ddd; padding: 8px;">question</td>
            <td style="border: 1px solid #ddd; padding: 8px;">String</td>
            <td style="border: 1px solid #ddd; padding: 8px;">是</td>
            <td style="border: 1px solid #ddd; padding: 8px;">用户问题</td>
        </tr>
    </tbody>
</table>
```

---

## 3. 技术文档的块结构建议

### 3.1 推荐的章节组织方式

对于技术文档，建议采用以下块结构：

| 块序号 | 块标题 | 内容类型 |
|-------|--------|---------|
| 1 | 概述/简介 | 纯文本/Markdown |
| 2 | 核心概念 | 纯文本/Markdown |
| 3 | 数据结构 | 折叠宏+代码块 |
| 4 | 数据库设计 | 折叠宏+代码块+ER图 |
| 5 | 业务流程 | PlantUML时序图/活动图 |
| 6 | 核心代码 | 折叠宏+代码块 |
| 7 | API接口 | 折叠宏+代码块+表格 |
| 8 | 常见问题 | 纯文本/折叠宏 |

### 3.2 每个块的HTML结构

```html
<div block-id="Block001" 
     block-title="章节标题" 
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
    
    <h2>章节标题</h2>
    <p>章节内容介绍...</p>
    
    <!-- 代码示例 -->
    <details block-id="Code001" collapse-state="closed">
        <summary style="margin-left: -1rem;">代码示例</summary>
        <p><br/></p>
        <pre class="prettyprint linenums brush:python">
# 代码内容
        </pre>
        <p><br/></p>
    </details>
    
    <!-- PlantUML图 -->
    <div class="ze-macro" macro-key="PlantUmlMacro" macro-id="01kDiagram01" source-macro-id="01k56kdm19acb3m0f5bwkqds9h72st7y" ze-root="zeRoot">
      <div class="ze-macro-body">
        <p>{"title":"图标题","syntax":"@startuml\n...@enduml","dropshadow":false,"align":"left","type":"plantuml"}</p>
      </div>
    </div>
    
</div>
```

---

## 4. 完整的技术文档生成示例

以下是一个完整的技术文档页面生成示例，展示了各种内容类型的组合使用：

```html
<!-- 基础页面创建 -->
标题: 用户认证系统技术文档
内容: <div ze-root="zeRoot"><h1>用户认证系统技术文档</h1><p>本文档介绍...</p></div>

<!-- 块1: 系统概述 -->
块内容:
<div block-id="Overview01" block-title="系统概述" block-tags=" overview" block-type="custom" ...>
    <h2>1. 系统概述</h2>
    <p>用户认证系统负责处理用户的注册、登录、登出等功能...</p>
</div>

<!-- 块2: 数据库设计 -->
块内容:
<div block-id="Database01" block-title="数据库设计" block-tags=" database,design" block-type="custom" ...>
    <h2>2. 数据库设计</h2>
    <p>系统使用以下数据库表...</p>
    
    <!-- 表结构: 折叠宏+代码块 -->
    <details block-id="UserTable" collapse-state="closed">
        <summary style="margin-left: -1rem;">用户表 (t_user)</summary>
        <p><br/></p>
        <pre class="prettyprint linenums brush:python">
class User(Base):
    __tablename__ = 't_user'
    id = Column(BigInteger, primary_key=True)
    username = Column(String(64), unique=True)
    password_hash = Column(String(128))
        </pre>
        <p><br/></p>
    </details>
    
    <!-- ER图: PlantUML类图 -->
    <div class="ze-macro" macro-key="PlantUmlMacro" macro-id="01kER01" ...>
      <div class="ze-macro-body">
        <p>{"title":"数据库ER图","syntax":"@startuml\n!theme cerulean\nskinparam backgroundColor #FFFFFF\nskinparam defaultFontColor #000000\nclass User {...}\nclass Role {...}\nUser \"*\" --> \"*\" Role\n@enduml","dropshadow":false,"align":"left","type":"plantuml"}</p>
      </div>
    </div>
</div>

<!-- 块3: 业务流程 -->
块内容:
<div block-id="Flow01" block-title="业务流程" block-tags=" flow,business" block-type="custom" ...>
    <h2>3. 业务流程</h2>
    
    <!-- 时序图 -->
    <div class="ze-macro" macro-key="PlantUmlMacro" macro-id="01kSeq01" ...>
      <div class="ze-macro-body">
        <p>{"title":"登录流程时序图","syntax":"@startuml\n!theme cerulean\nskinparam backgroundColor #FFFFFF\nskinparam defaultFontColor #000000\nactor User\nparticipant LoginAPI\n...@enduml","dropshadow":false,"align":"left","type":"plantuml"}</p>
      </div>
    </div>
</div>

<!-- 块4: API接口 -->
块内容:
<div block-id="API01" block-title="API接口" block-tags=" api,interface" block-type="custom" ...>
    <h2>4. API接口</h2>
    
    <!-- 请求示例 -->
    <details block-id="LoginReq" collapse-state="closed">
        <summary style="margin-left: -1rem;">登录请求示例</summary>
        <p><br/></p>
        <pre class="prettyprint linenums brush:js">
{
  "username": "user@example.com",
  "password": "encrypted_password"
}
        </pre>
        <p><br/></p>
    </details>
    
    <!-- 响应示例 -->
    <details block-id="LoginResp" collapse-state="closed">
        <summary style="margin-left: -1rem;">登录响应示例</summary>
        <p><br/></p>
        <pre class="prettyprint linenums brush:js">
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
        </pre>
        <p><br/></p>
    </details>
</div>
```
