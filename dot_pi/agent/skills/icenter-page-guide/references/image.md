# 图片（Image）规范

## 概述

在 icenter 页面中嵌入图片，使用 `<img>` 标签引用 iCenter **图床** URL
（`https://icenterapi.zte.com.cn/group2/.../xxx.png`）。图床为全局资源：不绑定空间/页面，
图片 URL 无需认证可直接访问，可复用到多个页面。

⚠️ **不要手拼图床 URL**：正确流程是用 `upload_image` 操作上传本地文件（或远程 URL），
拿返回的 `img_html` 写入页面（块或正文均可）。

## 标准流程（两步）

```bash
# ① 上传：得到 img_html（含图床 URL 与尺寸属性）
icenter-everything upload_image --file-path /path/to/screenshot.png

# ② 写入页面：把 img_html 包进块（block-type="custom" 必需）
icenter-everything create_block_by_url --page-url "<页面url>" \
  --content '<div block-type="custom">'"$(上传返回的 img_html)"'</div>'
```

MCP 侧对应 `upload_image` → `create_block_by_url`。

## 图片 HTML 结构

```html
<p tag-start="p"><img data-inline="true" dpiheight="96" dpiwidth="96"
   filename="{文件名}" filesize="{字节数}" height="{显示高}"
   originheight="{原图高}" originwidth="{原图宽}"
   inline="true" src="{图床URL}"
   tag="img" unit="px" width="{显示宽}"/></p>
```

实测结论（真实页面验证）：

| 项 | 说明 |
|----|------|
| 最小可用格式 | 只需 `<img src="...">` 就能渲染（服务端保存时会自动补齐属性） |
| 显示尺寸 | 由 `width`/`height` 数字属性控制；`originwidth`/`originheight` 承载原图尺寸 |
| ⚠️ 不要带 `style` 尺寸 | 提交的 img 若带 `style="width:..px;height:..px"`，服务端保存时按原图比例**重算 height**，产生 `299.52000000000004px` 这类浮点（2026-10-08 实测）；只传数字属性时服务端保持整数并自行生成 style（`_build_image_html` 已移除 style） |
| src 参数 | 服务端保存页面时会自动给 src 追加 `?w=&h=`（原图尺寸），无需手写 |
| 带标题 | `<figure><figcaption><p>标题</p></figcaption><img .../></figure>` 渲染为自动编号的图（"图/figure N"） |

## 尺寸控制（重要）

**iCenter 对图片尺寸不做自适应**——与编辑器行为一致：原图多宽，页面就显示多宽，超宽会溢出。

| 场景 | 做法 |
|------|------|
| 原图宽度 ≤ 900px（页面内容区宽） | 不传 `display_width`，用原图尺寸即可 |
| 原图较宽（>1000px） | 传 `display_width`（如 800），高度自动等比缩放；返回体会带 `hint` 提示溢出风险 |
| 需要非等比拉伸 | 上传后自行修改 img_html 的 `width`/`height` 数字属性（少见；不建议写 style 尺寸，会触发服务端重算浮点） |

## 上传能力与限制

| 项 | 说明 |
|----|------|
| 文件大小 | 单图 ≤ **10MB** |
| 文件类型 | png / jpg / jpeg / gif / bmp（图床服务端实测仅支持 JPG/JPEG/PNG/GIF/BMP；SVG/WebP/ICO 请先转 PNG） |
| 来源 | 本地文件（`file_path`）或远程 URL（`image_url`，服务端先下载再上传，超时 15 秒） |
| 尺寸解析 | 自动识别 PNG/JPEG/GIF/BMP/WebP/SVG 原图尺寸；解析失败时降级为不带尺寸的 img（仍可渲染） |

## 常见错误与处理

| 现象 | 原因 / 处理 |
|------|------------|
| `不支持的图片类型 .xxx` | 扩展名不在白名单（图床仅支持 JPG/JPEG/PNG/GIF/BMP）；转为 png 再传 |
| `图片大小 xxx 字节超过图床 10MB 上限` | 压缩图片或缩小分辨率后重传 |
| 图片在页面上不显示/裂图 | src 用了 `http://`（必须 https，否则被浏览器按混合内容拦截）；或不是图床 URL |
| 页面横向溢出、看不到图片右边缘 | 原图过宽且未指定 `display_width`；重新上传并指定宽度（如 800） |
| 远程 URL 上传报"不是图片" | 目标 URL 的 Content-Type 不是 image/*（可能是登录页/HTML） |

## 验证方式

上传后如需确认图片真实可访问（无需打开浏览器）：

```bash
curl -sI "<image_url>"   # 期望 HTTP 200 + Content-Type: image/*
```
