# 家具手绘图标

案件家具栏、工作室家具栏和电脑商店共用这套图标。图形采用墨线、排线和柔和设色，PNG 带真实透明通道，不含底板或文字。

- `office.png`：办公家具与设备。
- `objects.png`：沙发、文件、落地灯和地毯。
- `restoration.png`：修复设备、工作室桌、书架与分析板。
- `studio.png`：工作室功能设备、沙发与展示家具。
- `regions.json`：每个图标的原图裁切范围，格式为 `[x, y, width, height]`。
- `sheets.json`：各图集从左到右、从上到下的图标名称。
- `generation_prompts.json`：内置 ImageGen 生成时使用的完整提示词。

`scripts/furniture_icon_library.gd` 根据家具 kind 返回 AtlasTexture。案件和工作室图标保留可调整的槽位，并在槽位内居中、等比缩放。工作室卡片可在 `scenes/studio/studio_catalog_item.tscn` 的 `IconAnchor` 中调整图标位置和尺寸。

替换图集后可运行 `tools/analyze_furniture_icon_atlas.py` 重新计算透明图形边界；该工具只读取图片并写入坐标，不修改图像。裁切范围按图形的完整边界计算，避免切掉椅轮、灯脚和把手。

验证：`tests/smoke_furniture_handdrawn.gd` 检查家具种类覆盖、透明图集与裁切范围、家具卡片点击拖拽、工作室可编辑槽位和商店的全部家具图标。
