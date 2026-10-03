# 玩家工作室纸张界面

`blank_atlas.png` 是依据用户提供的无字 UI 素材处理出的透明底母版。各个同目录 PNG 是从母版裁出的独立纹理，由 `res://tools/import_studio_dossier_ui.gd` 生成。

玩家工作室 HUD 已改成可视化场景：在 Godot 的 2D 编辑器中打开 `res://scenes/studio/studio_hud.tscn`，即可直接拖动标题板、每个功能按钮、右侧活页本、四个翻页标签、状态条以及工作模式按钮。它作为实例放在 `res://scenes/studio/calibrator_studio.tscn` 的 `StudioUI/UIRoot/StudioHUD` 下。

右侧活页本内容位于 `ArchiveInventoryPanel/EditableContent`。`FurniturePageViewport/CatalogList/CatalogSlot1` 至 `CatalogSlot4` 是四个可单独移动、缩放的卡位；重复使用的家具卡片另在 `res://scenes/studio/studio_catalog_item.tscn` 中编辑，卡片文字和图标的节点位置也可以单独调整。家具栏按 4 项分页，`FurniturePageTab1` 到 `FurniturePageTab4` 是右侧实体标签的点击区域，滚动条已关闭。

`res://scripts/calibrator_studio.gd` 只负责把场景按钮接到游戏功能并更新动态数据，运行时不再重设 HUD 控件的位置。家具卡片动态文字和图标由 `res://scripts/catalog_item.gd` 更新。素材皮肤仍来自同目录的透明 PNG。

开始新游戏与工作室电脑的重置确认共用 `res://scenes/ui/paper_confirmation_dialog.tscn`。弹窗采用左上角夹纸板 `title.png`，取消和确认使用两张贴纸 `jump_label.png`、`jump_label_alt.png`；可以在该场景中分别调整纸张、正文与按钮。按钮文字仍由 Godot 字体绘制。

界面文字均为 Godot `Label` 或 `Button`，没有写进图片。替换独立 PNG 后，Godot 编辑器会重新导入资源；运行中的游戏通常需要重新启动场景才能看到更新。
