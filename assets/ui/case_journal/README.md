# 案件资料档案册

`book.png` 是真实 RGBA 透明底背景，包含档案册、照片纸框、文件纸、夹子、胶带和底部分页便签。这些固定装饰合并为一张背景，照片与所有文字由游戏独立绘制；没有文字烘焙到图片。

`source.png` 是内置 imagegen 基于已确认效果图提取的无字原始美术，背景清理工具为 `tools/import_case_journal.gd`。正式界面只引用 book.png。

界面：`scripts/case_file_ui.gd`。背景：`shaders/case_journal_blur.gdshader`，直接采样当前游戏画面做模糊，不使用概念图背景。打开期间隐藏底层 HUD 的显示，关闭时恢复。采用 1280×720 基准等比适配，默认字体，独立可翻译 Label/Button，长正文可滚动。

生成提示要点：从确认图提取打开的双页档案册，保留旧黑色封皮、米色纸张、两侧金属夹、照片纸框、文件叠页、回形针、胶带、鼠尾草绿便签及两个标签；移除照片及全部文字、印章和徽标，正面视角便于放置运行时文本，外部透明，保持克制旧纸质感。

验证：`tests/smoke_case_journal.gd` 验证 alpha、字体、分类、照片/文档切换、关闭恢复 HUD、重新打开重置及 Escape 返回；截图 `tests/journal_photo.png`。
