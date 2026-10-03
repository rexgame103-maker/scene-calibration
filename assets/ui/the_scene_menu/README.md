# THE SCENE 开始界面

独立透明 PNG：face.png（人物）、ink.png（墨迹边框）、title.png（主标题与其墨迹底条）、button.png（无文字黑色按钮底）、button_selected.png（选中状态）。按钮中文文字由 Godot Button 绘制，可通过翻译表切换。主标题按要求保留为图片。

source_sheet.png 是美术生成的分层提取源，洋红色只是源文件的处理底色；游戏仅引用处理后的 RGBA 素材，不引用此源图。

入口场景：scenes/start_menu/start_menu_office.tscn，引用玩家工作室 player_studio_concept.tscn 作为实时背景。点击开始/继续进入现有可游玩的 calibrator_studio.tscn。

根节点“循环镜头”可调整 Camera Target、Camera Direction、Nearest Distance、Farthest Distance、Travel Cycle Seconds、Sway Distance、Sway Roll Degrees。默认距离 6.2–7.4，完整往返 32 秒，位移晃动 0.16，倾斜 0.8 度。每一端使用余弦曲线减速并反向，切换游戏时停止循环，交由转场镜头控制。

设置包含主音量、全屏和背景镜头运动开关，保存到 user://the_scene_options.cfg。无有效存档时继续按钮不可用；已有存档时开始游戏先确认是否重置，继续则直接保留进度进入工作室。

验证：tests/smoke_the_scene_menu.gd 检查透明素材、四按钮、背景场景、镜头上下限、设置打开关闭及进入游戏，并生成 tests/the_scene_menu_far.png 和 the_scene_menu_near.png。

工具：extract_the_scene_menu.gd 为生成源做透明通道处理和分片；build_the_scene_menu.gd 重建开始界面（会覆盖开始场景，手动调整后勿随意重跑）。这些工具不会重建工作室。
