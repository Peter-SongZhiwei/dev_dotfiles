# 附件（Attachment）规范

## 概述

在 icenter 页面中嵌入**可点击、可下载的附件**，使用"附件宏"——一段 `<a href="udm-doc-{fileId}">` 形式的 HTML。
文件本身存放于空间云文档库（cloududm），宏只是引用。

⚠️ **不要手写宏**：`fileId` / `groupKey` 只有上传接口才会返回。正确流程是用
`upload_attachment` / `upload_attachment_by_url` 操作上传本地文件，拿返回的 `macro_html`
写入页面（块或正文均可）。

## 标准流程（两步）

```bash
# ① 上传：得到 macro_html（含真实 fileId/groupKey，自动带 pageId）
icenter-everything upload_attachment_by_url --page-url "<页面url>" --file-path /path/to/report.pdf

# ② 写入页面：把 macro_html 包进块（block-type="custom" 必需）
icenter-everything create_block_by_url --page-url "<页面url>" \
  --content '<div block-type="custom"><p>附件：</p>'"$(上传返回的 macro_html)"'</div>'
```

MCP 侧对应 `upload_attachment_by_url`（或 `upload_attachment`）→ `create_block_by_url`。

## 宏 HTML 结构

```html
<p tag-start="p"><a style="" target="_blank" pageId="{页面id}" _ownid="{页面id}"
   data-from="copy-input" fileSize="{字节数}" fileName="{真实文件名}" ext="{扩展名}"
   href="udm-doc-{fileId}" _href="udm-doc-{fileId}" groupKey="{groupKey}">显示名</a></p>
```

实测结论（真实页面验证）：

| 属性 | 作用 |
|------|------|
| `<a>` 标签内文本 | **页面上的显示名**。想改名直接改这里 |
| `fileName` | 真实文件名（决定**下载时**的文件名），建议保持与文件一致 |
| `href` / `_href` | `udm-doc-{fileId}`，必须成对出现 |
| `groupKey` | 文件组 Key，渲染与下载都依赖 |
| `pageId` / `_ownid` | 页面上下文；非渲染必需，但页面内附件建议携带（上传操作会自动填入） |

- 宏可以放在 **块内**（`block-type="custom"` 的 div 中）或 **页面正文**，两者都正常渲染为附件图标链接。
- 显示名可用 `display_name` 参数在上传时指定（中文、空格均可），不影响下载文件名。

## 上传能力与限制

| 项 | 说明 |
|----|------|
| 文件大小 | 单文件 ≤ **100MB**；>2MB 自动分块上传 |
| 文件类型 | 服务端白名单（`udm/config` 的 `supportExts`，数百种：md/pdf/office/zip/图片/音视频等）；`.exe`、无扩展名会被拒绝 |
| 秒传 | 相同 md5 的文件自动秒传（内容不重复存储） |
| 文件名 | 中文文件名正常 |
| 权限 | 上传时自动按**空间组**授予读权限（`saveAuth`），空间成员可见 |

## 常见错误与处理

| 现象 | 原因 / 处理 |
|------|------------|
| `不支持的文件类型 .xxx` | 扩展名不在服务端白名单；换格式或压缩为 zip 再传 |
| `0100 不支持的文件大小或类型` | 同上（服务端原话，客户端已提前预校验并给出明确提示） |
| 页面上显示成一行普通链接文本（无附件图标） | 宏结构被破坏：检查 `href`/`_href`/`groupKey`/`fileName` 是否都是属性（而不是被当成纯文本），以及是否被 HTML 转义（`&quot;`） |
| 附件无法下载 | `groupKey` 缺失或与 `fileId` 不匹配——不要手工拼宏，用上传接口的返回值 |

## 验证方式

上传后如需确认文件真实可下载（无需打开浏览器）：

```bash
# 换临时下载链接（需认证头，不带 JSON Content-Type）
curl -s -X POST "https://idrive.zte.com.cn/zte-km-cloududm-core/file/downloadFile" \
  -H "X-Emp-No: <工号>" -H "X-Auth-Value: <token>" -H "X-Lang-Id: zh_CN" \
  -d "fileIds=<fileId>"
# 返回 bo.url 为带签名的临时地址，尽快下载
```
