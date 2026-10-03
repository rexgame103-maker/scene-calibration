# 离线源码浏览页

双击 `index.html` 即可查看，不需要联网或启动服务器。

- 左侧：目录树、文件路径筛选。
- 概览：运行主线、功能模块、入口文件。
- 源码：行号、语法着色、函数 / 信号 / 场景节点索引。
- 检索：Ctrl K 搜索全部文本文件；点击结果跳到匹配行。
- 资源：原文件下载链接、图片预览、大小和 SHA-256。
- `manifest.json`：本次快照的完整文件清单与校验值。

若要让“原文件”链接、图片预览继续有效，请把整个工程一起交付，不要只拷贝此目录。只有 `index.html` 时，嵌入的文本源码、目录和检索仍可使用。

重新生成：在工程根目录运行 `python tools/build_source_review.py --date YYYY-MM-DD --zip`。生成的完整工程包位于 `deliveries/scene-calibration-source.zip`，交付文件不会被提交到 Git。

页面模板与样式分别位于 `template.html`、`viewer.css`、`viewer.js`。修改这些源文件后重新生成 `index.html`。生成页和文件清单不对自身做嵌入，避免无限递归。

交付校验：运行 `python tools/verify_source_review.py`，核对页面嵌入源码、文件清单和 ZIP 中的原始文件。页面逻辑验证位于 `tests/test_source_review.cjs`，需要 Node.js 和 jsdom；这只是开发验证依赖，离线浏览页本身不依赖这些运行环境。

仓库保留原始文件字节，避免自动换行转换导致 GitHub 下载与离线包的 SHA-256 不一致。提交前可使用 `python tools/verify_source_review.py --git-index` 检查 Git 暂存区中的文件与交付包完全相同。
