# 俯视手绘工作室

在 Godot 中打开 `res://scenes/studio/noir/noir_studio.tscn`，按 **F6** 运行当前场景。项目默认入口及原有场景保持不变。

这一版是独立的 **2D 美术与点击调查原型**。背景使用本次生成的 1536 × 1024 工作室插画，保留原图比例，窗口变化时自动居中。六个独立 Polygon2D 节点定义调查范围，录音机优先于桌面响应。底部显示调查文案。

- 单击物件：调查；单击空处：关闭调查。
- 滚轮：以鼠标位置为中心缩放，范围 1–2.5 倍。
- 鼠标中键拖动：移动画面。
- R 或“返回全景”：恢复构图。

画中的家具和灯光目前烘焙在背景内，尚未拆成可移动家具，不提供角色行走、动态遮挡或接入原有案件/建造系统。调查不修改存档。

素材：`res://assets/art/noir_studio/studio_background.png`。
脚本：`res://scripts/noir_studio/noir_studio.gd`。
验证与截图：`res://tools/render_noir_studio.gd`，输出 `res://tests/noir_studio_preview.png`。
