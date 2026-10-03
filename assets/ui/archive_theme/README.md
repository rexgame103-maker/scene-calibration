# 纸质档案 UI

基于已确认的 `../concepts/restrained_archive_v3/office_ui_mockup.png`，使用内置 imagegen 清除文字、提取背景美术；通过 `tools/import_archive_ui.gd` 拆分并转换为真实 RGBA 透明 PNG，缩小至适合九宫格边框的像素密度。

- `case_panel.png`：案件标题底板。
- `inventory_panel.png`：家具栏与家具卡片底板。
- `button.png`：常态按钮；悬停、按下、禁用由程序调色。
- `status_bar.png`：底部提示条。
- `empty_archive.png`：空家具栏的档案箱插画。
- `source/`：原始生成结果，未直接用于游戏。

文字完全由 Godot Label/Button 绘制，使用默认字体与字体回退；不在美术图中包含文案。标签保留自动翻译，家具尺寸模板通过 tr() 翻译，长文字自动换行。暂未增加正式语言包。接入文件为 scripts/archive_ui_theme.gd、scripts/main.gd、scripts/catalog_item.gd。

验证：tests/smoke_archive_ui.gd 检查真实 alpha、默认字体、案件按钮、家具解锁与拖动、临时英语翻译。运行截图在 tests/archive_ui_empty.png 与 tests/archive_ui_inventory.png。

## 原始生成提示词：背景

Extract and clean the UI ART from this reference screenshot into ONE game UI sprite atlas. Remove ALL text, letters, numbers, Chinese writing, stamps containing words, and all scene imagery. Output transparent background PNG with real alpha transparency, not a checkerboard drawing. Keep the exact reference style: restrained warm ivory aged paper, subtle texture, very thin dark brown hand-inked frame, tiny worn corner folds. No new design. Arrange exactly FOUR separate rectangular blank UI backgrounds on a 1536x1024 landscape atlas, a tidy 2x2 grid with generous empty transparent gaps so each can be cropped. Upper left: a wide blank ivory case-title panel, approximately 640x360, with the original small binder clip on upper right edge but NO label tab or text. Upper right: a tall blank ivory inventory panel approximately 370x440 with thin brown border, same reference side panel, REMOVE the archive box illustration and all internal lines/words, leaving blank paper. Lower left: a wide shallow blank ivory button/bar approximately 640x130, subtle narrow brown border and small brass tack at far left. Lower right: a small wide blank tan paper button approximately 400x130, no icons or text. All four are flat straight-on rectangles for nine-slice UI use, no perspective. Corners have minimal tiny chips like reference, not exaggerated tearing. Preserve plain central paper for separately rendered game text. The only elements in the image are those four separate blank framed paper sprites. Absolutely NO text, symbols, icons, pen marks resembling writing, watermark, background scenery, checkerboard or opaque backdrop. Real transparent empty space outside sprites.

## 原始生成提示词：空栏插画

Extract ONLY the small archive storage box illustration from the right inventory panel of this screenshot. Create a standalone UI empty-state icon: the same two closed cardboard archive boxes with lids and little rectangular label holders, three-quarter view, fine restrained sepia hand-inked contours and only a few hatching strokes. No text or letters anywhere. Omit all paper panel, frame, page folds, UI, room and other objects. Keep the quiet mature detective casebook style. Background transparent, only icon visible, no checkerboard drawing. Compact centered icon with large empty margin, square canvas. Do not add realistic textures, dark solid fills or strong shadow.

