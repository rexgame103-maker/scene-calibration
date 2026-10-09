# 第一案可交互办公室

正式入口仍为 `res://scenes/main.tscn`。它已使用新办公室的墙体、窗户、地面和痕迹；案件从清空状态开始，按照原有证据流程解锁家具。

`main` 的 `EditorOfficePreview` 节点保存完整摆放预览，编辑器中可直接查看新版办公室；运行时自动移除，由案件逻辑生成可交互家具。预览摆放与案件判定位置分别维护，调整预览不会修改案件数据。

第一案固定位置判定区域以 `main/ReconstructionZones` 保存的节点为准。在编辑器中修改 Position、Zone Size 和朝向要求，保存并重新运行即可生效；保留原有 zone_id 和 required_furniture_id。透明框表示家具原点的容许范围，不是模型包围盒。其他案件仍从案件数据创建区域。

`tools/update_main_editor_office.gd` 是重置工具，会用 JSON 模板覆盖判定区域；手动调整区域后不要运行它。正常编辑不需要执行同步工具。

这里保存的是分组后的美术组件，游戏通过 `res://scripts/office_concept_furniture.gd` 添加碰撞、吸附和关系区域：

- `desk.tscn`：桌体、桌面纸张、文件本、杯子、台灯与桌侧磨损。整组随桌子放入、移动、旋转和收纳。
- `computer.tscn`：显示器、支架、键盘全部按键与鼠标。一个库存物品、一个选择目标；点击键盘也选中电脑整体。
- `shelf.tscn`：文件柜和固定装饰，不包含三份案件文件夹；三份文件夹分别解锁、分别摆放，中层从左到右为红、灰、米色。
- 其余组件：椅子、矮柜、打印机与照片、饮水机。
- `room.tscn`：固定布景与地面痕迹，供维护使用；主场景中已保存对应节点。

检视光点打开 `scripts/scene_clue_popup.gd` 的分段动画：背景模糊、近景图从左进入、连接线、逐字描述、收集按钮。空白处点击提高播放速度，只有点击收集才授予线索；退场期间继续拦截场景输入。`SceneCluePoint` 的 Detail View Distance 和 Detail View Offset 控制近景镜头，Offset 为光点局部方向，零向量沿用主镜头方向。桌侧磨损的近景方向由 `office_concept_furniture.gd` 设置，以看清柜体侧面。验证脚本 `tests/smoke_clue_animation.gd` 覆盖播放顺序、实际空白/按钮点击、收集时机与退场；图形模式生成 `tests/clue_animation_preview.png`。

光点显示与点击共享主相机可见性判定：必须在画面内、面向线索表面且无实际模型遮挡。`Surface Normal` 为线索表面的局部朝外方向（桌侧为 +X），随家具旋转；`Minimum View Dot` 控制侧视角度阈值。零法线不限制方向，仍检查模型遮挡。遮挡检测使用网格三角面而非家具的宽大碰撞盒，避免电脑前方可见光点被碰撞盒误拦。原 DEBUG 下一步现通过 `P` 键执行，按钮隐藏；它会在玩家可用旋转范围内寻找可见视角，也不能直接绕过判定。自动摆放时播放短暂下落动画，落地后再登记重构完成。`tests/smoke_clue_visibility.gd` 覆盖背面盲点、可达视角、真实网格遮挡和实际点击；`tests/smoke_computer_clue_click.gd` 检查电脑光点交互；`tests/smoke_debug_hotkey.gd` 检查快捷键、动画、暂停、重复按键与两关结案。

桌面与柜层高度、物品占地、正确位置和调查点已匹配新尺寸。旧办公室备份位于 `res://Backups/office_before_concept_integration/`。独立概念场景仍保留供美术编辑。

验证：`res://tests/smoke_office_concept_gameplay.gd` 检查实际库存拖放提交、重力落地、键盘选中归属、桌面/柜层吸附、组合移动、案件解锁、文件夹顺序及完成提交。图形模式额外生成复原截图和新版证据照片；测试不拍照归档、不写玩家进度。

`res://tools/extract_office_gameplay_parts.gd` 是一次性迁移工具。重新运行会用概念场景重建组件和主场景，手动修改这些文件后不要直接运行。
