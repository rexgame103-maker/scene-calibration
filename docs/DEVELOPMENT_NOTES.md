# 错位现场 · 开发记录与操作说明

本文件保留项目开发期间的详细操作与历史说明。当前启动入口、模块职责和交付方式请先阅读根目录 `README.md` 与 `docs/SOURCE_GUIDE.md`。

第一案办公室已接入新的漫画风场景，入口仍为 `scenes/main.tscn`。桌面纸张随桌子整体摆放，显示器、键盘和鼠标作为一个电脑物品摆放；案件照片、空间判定和吸附尺寸已同步更新。分组说明见 `scenes/cases/office_parts/README.md`。独立美术概念场景仍保留，替换前的办公室保存在 `Backups/office_before_concept_integration/`。

这是一个使用 Godot 4.7 制作的可运行房间布置原型。场景已经接入外部地面、墙体以及工作桌、电脑、办公椅、台灯、饮水机、文件柜、打印机、文件夹和纸张等正式模型。

编辑器预摆工作桌和高文件柜时，直接使用 `scenes/可拖入场景_工作桌.tscn` 与 `scenes/可拖入场景_高文件柜.tscn`。`assets/models` 下的 GLB 只是无脚本源模型，直接拖入不会出现碰撞、吸附和预览参数。

主镜头使用轻微透视的长焦构图，在保留 2.5D 等距观感的同时提供适度的近大远小效果。

## 界面语言

开始菜单的 `Settings → Language` 可选择 `English` 或 `简体中文`，首次启动默认英语。选择即时生效，并保存到 `user://the_scene_options.cfg` 的 `interface/language`；声音和显示设置共用此文件，修改设置时保留已有字段。

`GameLanguage` 在其他 Autoload 之前加载语言偏好与 `data/localization/en.json`。英文表以原始中文为键，涵盖菜单、工作室、电脑、家具、案件正文、调查提示与结案页。新增文案时在表中补充对应英文；格式字符串的 `%d`、`%s` 等参数须保留相同数量和顺序。

`scripts/ui_translation.gd` 接入 Godot 原生 `TranslationServer`，也处理已有界面先格式化再赋给控件的金额、数量、家具名称、已读标识和多行资料按钮。控件的原始文字保留给类别筛选等逻辑，案件 ID 与玩家存档使用原来的字段。绘制照片字幕时显式调用 `tr()`。

语言检查使用独立的临时工程与用户目录：`tools/run_audio_smoke.ps1 -Tests smoke_language_settings,smoke_language_saved`。检查默认语言、即时切换、动态文字、资料筛选、英文布局和重启后的偏好读取。

## 操作

- 游戏开始时，编辑器中预先摆好的家具会作为案发现场家具保留原姿态
- 单击现场家具会弹出操作菜单；重新放置的家具提供“检视 / 旋转 / 收纳”三个选项，初始现场家具需要先收纳才能旋转
- 家具栏初始为空；点击左上方“案件资料”查看警方资料，获得线索后对应家具会自动解锁并加入家具栏
- 从家具栏拖出的家具初始为直立状态；家具会直接跟随鼠标自由移动，不再吸附到格子中心
- 拖拽尚未确认时按 `Q` / `E` 可绕 Y 轴分别旋转 `-90°` / `+90°`，每次按键只转一档
- 电脑、台灯和红蓝文件夹拖到工作桌范围时会自动吸附并限制在桌面内；吸附后会稳定附着在真实桌面高度
- 松开放置后，家具会从地面上方进入刚体状态，在重力作用下自然落到地面；家具之间也会发生物理碰撞，稳定后自动休眠
- 从家具菜单点击“旋转”后才会显示红、绿、蓝三条旋转环，分别代表 X、Y、Z 轴；按住对应旋转环并拖动鼠标即可连续旋转
- 旋转模式会冻结家具并锁住背包、灯光、家具移动等其他操作；没有点中旋转环时也不会误触发家具拖拽
- 松开旋转环后仍停留在旋转模式，可以继续调整其他轴；点击上方“确定”后才会退出旋转、重新启用重力并返回默认全景
- 案发现场初始家具不能直接拖动，必须先收纳；重新放置后的家具可以再次拖动移动
- 家具选中后按 `Delete` 或 `Backspace` 也会执行收纳
- 点击空地、按 `Esc` 或点击左上角“返回全景”可恢复房间总览
- 近景查看时按住鼠标左键拖动可上下、左右环绕家具；水平方向限制为 `±45°`，垂直方向限制为 `±22°`
- 近景查看时按住鼠标中键拖动可平滑平移观察中心；水平限制为 `±2.2 米`，垂直限制为 `±1.35 米`，返回全景后自动复位
- 近景查看时使用鼠标滚轮缩放；缩放被限制在近景范围内，不会无限拉近或退回全景
- 近景查看期间家具编辑和仓库操作会锁定；返回全景动画完成后才会恢复
- 拖拽阶段使用 `Q/E` 调整水平朝向；放置完成后仍可通过彩色 XYZ 旋转环调整三个轴向
- 鼠标右键或 `Esc` 取消当前放置
- `Ctrl + Z` 撤销上一件重新放置的家具，并将它退回背包；初始现场家具不能被直接撤销
- 右侧底部“全部收纳”会把场景中的家具统一放回背包

家具使用连续坐标自由摆放；绿色预览表示可以放置，红色表示越过房间边界或与现有家具重叠。房间运行时会创建地板与两面墙的静态碰撞，新放置家具使用带摩擦力、低弹性的刚体碰撞。当前不再统计放置数量，也不会因家具数量弹出阶段完成提示。

左侧“灯光工作台”可以在游戏过程中展开并实时创建氛围，不会遮住场景中心：

- 全局亮度范围为 `0.02～1.0`，场景默认从低亮度 `0.16` 开始
- 固定编辑 `KeyLight`、`FillLight` 与 `AccentLight` 三盏灯，不允许无限增加灯光
- 单灯强度限制为 `0～4`，色温限制为 `1800K～12000K`
- 整体饱和度限制为 `0～2`，可制作黑白、低饱和或高饱和效果
- 每盏灯可在“色温模式”和“自定义颜色”之间切换
- 补光和强调光的影响范围限制为 `1～12 米`
- 补光和强调光可以调整 X/Y/Z 位置；主光可以调整水平与俯仰方向
- 灯光位置和方向最多每秒更新 30 次，降低动态阴影重算压力
- 最多同时开启两盏阴影灯，默认只有主光开启阴影
- “恢复低亮度默认”可随时还原初始灯光，不会重置家具或镜头

打开 `scenes/main.tscn` 后，房间、相机和灯光会作为完整的持久节点直接显示在 Godot 的 3D 编辑器中。

编辑器预摆桌子时，请把 `scenes/furniture/desk_furniture.tscn` 实例放到 `PlacedFurniture` 节点下面。选中桌子自身后，可在检查器的 `Desk Collision` 分组调整 `Collision Size` 和 `Collision Offset`：Size 控制蓝色框尺寸，Offset 可将整套碰撞框与吸附区域沿 XYZ 移动，蓝框顶部就是唯一的桌面吸附面。主场景中第一张预摆桌子的这两个参数会作为本局桌子模板，从家具栏拖出的桌子自动继承。`Show Collision Preview` 可控制预览显示，辅助盒不会进入游戏画面。

通过桌面吸附放置的电脑、台灯和文件等物品会记录其支撑桌子。拖动桌子或使用 XYZ 旋转桌子时，这些物品会临时保持相对位置同步跟随；确认支撑家具的移动或旋转后，桌子和桌面物品会同时恢复独立物理与重力，因此桌子倾倒时物品仍会自然碰撞、滑落。

高文件柜使用 `scenes/furniture/shelf_furniture.tscn`。它采用侧板、背板、顶底板和三块隔板组成的空心复合碰撞，并提供从上到下三层文件夹吸附面，默认高度为 `3.08 / 2.36 / 1.64 米`。在检查器的 `Cabinet Collision` 中调整柜体尺寸、偏移和板厚，在 `Folder Shelves` 中调整三层高度、统一吸附区域尺寸与偏移；蓝色框表示实体碰撞，绿色薄框表示文件夹吸附面。红蓝文件夹可在桌面与这三层之间放置，移动或旋转柜子时会同步跟随，确认后共同恢复重力。

文件柜参数会自动同步到 `scenes/furniture/shelf_collision_profile.cfg`，作为家具栏文件柜的共享默认配置；场景中存在预摆文件柜时，本局仍优先使用该预摆实例的配置。柜体点击区域同样采用空心侧板与隔板结构，因此鼠标可以穿过正面开口选中文件夹，文件夹放入柜内后仍可检视、收纳、移动和旋转。

## 案件资料、线索与家具解锁

当前第一案的数据集中配置在 `data/cases/office_case_001.json`：

- `clues`：线索定义，包含 `id`、`title`、`description`、`type` 与初始 `is_discovered`
- `evidence`：案件描述、照片或证物资料；`clue_ids` 决定查看该资料时获得哪些线索
- `furniture_unlocks`：家具解锁定义；`required_clues` 决定需要哪些线索，`catalog_kind` 对接现有 `FurnitureFactory.CATALOG`

`CaseManager` 是在 `project.godot` 注册的 Autoload，负责防止重复获得线索、查询线索、发送 `clue_discovered` / `furniture_unlocked` 信号，以及维护资料查看和家具解锁状态。UI 只读取案件数据，不包含“某张照片解锁某件家具”的硬编码。

新增一条“查看资料后解锁家具”的内容时：先在 `FurnitureFactory.CATALOG` 中配置可生成家具，再在案件 JSON 的 `clues` 添加线索、在 `evidence.clue_ids` 填入线索 ID，最后在 `furniture_unlocks.required_clues` 中引用同一 ID。`catalog_kind` 使用现有家具生成类型；面向案件内容的 `furniture_id` 可以保持独立，例如 `office_chair` 对接当前生成类型 `chair`。

### 第一关：蓝色档案失窃案

第一关已经形成完整数据驱动流程：警局委托简报 → 空办公室 → 第一批资料解锁桌椅 → 桌椅重构发现桌侧磨损 → 三条信息确认白色矮柜 → 设备记录恢复打印机与饮水机 → 墙面色差、压痕和旧照片恢复书柜 → 红色、灰色与普通文件归架 → 调查无法填补的书柜空位 → 公司登记册确认蓝色档案缺失 → 痕迹顺序推断后续混乱是掩护 → 提交完整现场 → 案件结算。

- 第一关内容配置：`data/cases/office_case_001.json`
- 委托、提交与结算 UI：`scripts/first_case_flow_ui.gd`
- 灰色和普通文件：由 `FurnitureFactory` 使用基础几何体生成，可继续替换为正式 GLB
- 固定痕迹：`scenes/main.tscn/PrimitiveRoom/FixedSceneDetails`
- 最终提交检查的是当前所有 ReconstructionZone 是否仍然成立，以及最终推论线索是否已获得；历史上曾经摆对但提交前移走不会通过

## 现场重构区域与步骤

3D 房间使用 `ReconstructionZone`（`Area3D`）作为后台空间条件。区域只在编辑器中显示半透明预览，运行游戏时不会显示，也不会因条件满足而变色或给出“正确”提示。

- 固定桌子区域：`scenes/main.tscn/ReconstructionZones/DeskOriginalZone`
- 椅子相对区域：`scenes/furniture/desk_furniture.tscn/ChairRelationZone`
- 可复用区域场景：`scenes/reconstruction/reconstruction_zone.tscn`

选中区域根节点后，可在 Inspector 配置：

- `Condition/Zone Id`：步骤条件引用的唯一 ID
- `Condition/Required Furniture Id`：需要进入区域的案件家具 ID
- `Condition/Zone Type`：固定位置或家具关系
- `Bounds/Zone Size`：允许的空间范围；节点 Transform 控制区域位置和旋转
- `Orientation/Require Orientation`：是否检查朝向
- `Orientation/Orientation Tolerance Degrees`：允许角度误差
- `Orientation/Target Yaw Degrees`：相对于区域朝向的目标水平角
- `Runtime State/Is Satisfied`：运行时后台状态，不用于向玩家提示答案

家具关系区域放在作为参照物的家具节点下面，因此会自动跟随参照家具。本案的 `ChairRelationZone` 位于办公桌前方，要求 `office_chair` 进入；桌子移动或旋转后，该关系区域会同步更新。

重构步骤配置在 `data/cases/office_case_001.json` 的 `reconstruction_steps`。一个步骤通过 `zone_ids` 组合多个区域，通过 `reward_clue_ids` 绑定首次完成时解锁的线索。例如 `office_workstation` 同时要求桌子固定区域和椅子关系区域成立，首次完成后获得 `clue_office_workstation`，继而让 `evidence_office_photo_02` 变为可见。

`ReconstructionManager` 只在家具放置、移动、旋转、移除以及 Area3D 进入/离开事件发生时重新判断，不在 `_process()` 中每帧遍历家具。已经完成过的步骤会保留完成记录，即使家具后来被移出导致当前条件变回 false，也不会反复发送完成信号或重复奖励线索。

## 在编辑器中调整场景

房间已经实体化并保存进 `scenes/main.tscn`，不需要运行游戏即可选择和修改：

- `KeyLight`：控制整体方向光、主阴影和日光方向
- `FillLight`：控制左侧补光的颜色、能量、范围与位置
- `AccentLight`：控制右后方局部强调光
- `SceneEnvironment`：控制背景色、环境光、色调映射和雾
- `PrimitiveRoom/ImportedArchitecture`：包含可单独选择的约 `6.69 × 6.69 米` 方形地面、后墙和左墙正式模型
- `PrimitiveRoom` 中隐藏的 `Floor`、`Walls`、`WallPanels` 与 `Trim`：旧基础几何体备份

场景文件保存的是低亮度初始灯光。编辑器中仍可直接调整三盏灯和 `SceneEnvironment`；游戏中的灯光工作台只修改本次游玩状态。

## 主要文件

- `scenes/main.tscn`：主场景入口
- `scenes/start_menu/start_menu_office.tscn`：开始界面的完整工作室展示，固定实例化成品美术场景，不读取新游戏的空布局
- `scenes/studio/calibrator_studio.tscn`：玩家实际经营和搭建的工作室；新游戏为空房，库存中的起始家具由玩家自行摆放
- `scenes/studio/player_studio_empty_shell.scn`：直接从完整工作室复制并删除陈设后的空房母版，保留原始 10.2 × 8.6 米尺寸、墙地、环境、遮光天花、窗雾和灯光层级
- `scenes/studio/player_parts/`：从完整工作室美术场景拆出的压缩家具资源，供动态家具栏、拖放、购买和存档系统实例化
- `tools/export_player_studio_build_parts.gd`：从完整工作室重新导出动态搭建资源的工具；工作桌保留纸张与桌灯，电脑组合包含显示器、键盘和鼠标
- `scripts/main.gd`：房间生成、界面和放置系统
- `scripts/furniture_factory.gd`：家具资源加载、尺寸校正与碰撞体生成
- `scripts/catalog_item.gd`：右侧家具栏中的可拖拽家具卡片
- `scripts/case_manager.gd`：案件状态、线索发现、资料查看与家具解锁
- `scripts/case_file_ui.gd`：案件资料列表和正文/照片查看界面
- `scripts/reconstruction_zone.gd`：可复用的固定位置、相对位置与朝向区域
- `scripts/reconstruction_manager.gd`：区域状态查询、步骤组合、单次触发和线索奖励
- `scripts/scene_clue_point.gd`：监听重构事件并提供场景调查线索的通用组件
- `scripts/scene_clue_popup.gd`：场景线索标题与正文的简洁查看窗口
- `data/cases/office_case_001.json`：第一案的全部线索、资料和家具解锁关系

## 开始界面工作室预览

打开 `scenes/start_menu/start_menu_office.tscn` 可以调整开始界面。镜头朝向玩家工作室窗户，左侧为深色渐变上的标题和菜单。背景直接实例化家具齐全的 `player_studio_concept.tscn`，使用原工作室的模型、窗户材质、百叶窗和灯光，不会因为新游戏的工作室布局为空而变空。该场景是 `project.godot` 的启动入口。

- `StartCamera`：直接在 3D 编辑器调整并保存位置、旋转角度和 `Fov`，运行时以保存的构图为运动起点，不会被固定的目标或方向覆盖。
- 场景根节点 Inspector 的“循环镜头”：`Loop Push In Distance` 设置沿镜头前方的推进距离（默认 0.45 米），`Travel Cycle Seconds` 设置往返周期（默认 48 秒，前 24 秒缓慢推进，后 24 秒平滑返回）；`Sway Distance`、`Sway Rotation Degrees`、`Sway Roll Degrees` 调整轻微位移、俯仰偏转和侧倾。`Camera Motion Enabled` 或游戏设置的“背景镜头运动”关闭时，镜头恢复到场景中保存的构图；已保存的游戏设置优先于 Inspector 的默认开关。
- `StudioBackground`：直接使用原工作室场景，开始界面没有新增窗帘、窗外模型或灯光。
- `StartMenuUI/UIRoot`：可在 2D 编辑器调整标题、说明和四个菜单按钮的位置、尺寸、颜色与字体。`NewspaperStack` 以已有 `newspaper_modules.png` 的透明模块组成三张错位倾斜的纸，深色菜单文字印在纸面上；各 `Paper` 的位置、旋转和尺寸可以直接手动调整。纸张与阴影均忽略鼠标输入，悬停及焦点反馈由原生按钮处理。`Atmosphere` 为背景提供左侧暗角。

`tools/build_window_start_menu.gd` 是当前布局的重建脚本；手动调整直接保存场景即可，重建会覆盖场景中的手动布局，但保留已保存的 `StartCamera` 位置、角度和视野。

“开始游戏”会锁定菜单操作，让 `StartCamera` 平滑向工作室推进，同时淡出至黑屏；随后进入可交互的玩家工作室 `scenes/studio/calibrator_studio.tscn`，再从黑色淡入游戏画面。“结束游戏”会退出当前运行实例。跨场景黑屏由 Autoload `SceneTransition` 统一管理。

在工作室或案件现场的普通界面中按 `Esc` 会打开全局暂停小窗口，可以继续游戏、回到开始界面或退出游戏。检视、资料、电脑界面或正在摆放家具时，`Esc` 优先退出当前局部操作。

## 电脑邮箱界面

`scenes/ui/terminal_mail_client.tscn` 可在 2D 编辑器直接调整邮件区：`Toolbar` 是工具栏，`Panes/Messages` 是邮件列表，`Panes/Reader` 是发件人、收件人、主题和正文，`Status` 是底部邮件数量。运行时可以拖动列表与正文之间的分隔条；正文较长时在白色阅读窗内滚动。

`assets/ui/computer_terminal/classic_mail_theme.tres` 控制六个应用共用的方角灰色按钮、凹槽内容框、选中行和字体；窗口外框、相册、商店、案件索引、小游戏和系统工具由 `scripts/studio_computer_ui.gd` 构建。收件箱显示当前可用邮件，已读邮件按已读状态筛选，已归档显示已完成案件的邮件。

打开邮件并在正文末尾停留 1.2 秒后自动标为已读；长邮件须滚到末尾，离开或关闭邮箱会取消计时，也可以点击“标为已读”。阅读不会自动接取案件。邮箱入口的 10 像素小红点只在有未读邮件时显示，最后一封读完后隐藏，有新邮件时重新出现。已读状态写入原有存档，刷新状态不会重建阅读窗或重置正文滚动位置。

## 当前资产尺寸

- 工作桌：约 `3.17 × 1.70 × 1.73 米`
- 老式电脑：源模型约 `1.86 × 0.99 × 1.94 米`，为适配桌面按 `0.72` 倍校正为约 `1.34 × 0.72 × 1.40 米`
- 办公椅：约 `1.26 × 2.16 × 1.39 米`
- 台灯：约 `0.34 × 0.80 × 0.34 米`
- 饮水机：约 `0.61 × 2.00 × 0.49 米`
- 矮文件柜：约 `0.97 × 1.49 × 0.64 米`
- 打印机：约 `1.28 × 2.09 × 1.28 米`
- 高文件柜：约 `2.00 × 3.83 × 0.86 米`
- 蓝/红文件夹：约 `0.36 × 0.56 × 0.17 米`
- 散落纸张：透明底板约 `2.49 × 0.10 × 2.03 米`，按纹理实际可见区域计算的交互尺寸约为 `1.84 × 0.10 × 1.84 米`；模型保持原始 `1.0` 倍比例
## 场景线索点（SceneCluePoint）

`SceneCluePoint` 是场景内可复用的调查点，不包含任何具体案件解锁逻辑。它只监听一次性的重构步骤完成事件，并在玩家调查后把配置的 `clue_id` 交给 `CaseManager`。

通用场景位于 `res://scenes/clues/scene_clue_point.tscn`，脚本位于 `res://scripts/scene_clue_point.gd`。在 Inspector 中可以配置：

- `Clue Point Id`：调查点自身的唯一标识。
- `Clue Id`：点击后交给 `CaseManager` 的线索 ID，必须存在于当前案件 JSON 的 `clues` 中。
- `Title` / `Description`：调查窗口显示的标题与正文。
- `Required Reconstruction Step Id`：负责解锁此调查点的重构步骤 ID。
- `Is Unlocked`：不依赖步骤、开局直接显示时才手动勾选。
- `Is Discovered`：运行时状态，通常保持未勾选。
- `Hide After Discovered`：调查完成后是否隐藏光点。
- `Show Only During Inspection`：开启后只在对应家具的检视近景中显示，当前默认开启。
- `Inspection Furniture Id`：线索点不在家具节点下面时，可填写它所属家具的 `furniture_id`；留空时自动使用父级家具。
- `Show Preview In Editor`：即使运行时尚未解锁，也在编辑器中显示光点，便于摆放。

创建新调查点时，把该场景拖入主场景或某件家具节点下，设置上述字段即可。放在家具节点下时，家具移动和旋转后调查点会跟随家具。组件通过 `ReconstructionManager.reconstruction_step_completed(step_id)` 被动解锁，不在 `_process()` 中轮询；一旦解锁，即使对应空间关系后来失效也不会重新锁定。默认情况下，全景只记录解锁状态而不显示光点；进入所属家具的检视近景后才显示，返回全景立即隐藏。

场景线索与家具解锁的绑定仍配置在案件数据中。例如：

```json
{
  "furniture_id": "small_cabinet",
  "catalog_kind": "small_shelf",
  "display_name": "白色活动柜",
  "is_unlocked": false,
  "required_clues": ["clue_desk_side_wear"],
  "unlock_mode": "all",
  "inventory_amount": 1
}
```

这条链路是：`SceneCluePoint` 调查 → `CaseManager.discover_clue()` → `clue_discovered` / 家具条件评估 → `furniture_unlocked` → 现有家具栏增加对应物品。

## UI 文本边界检查

运行 `tools/run_audio_smoke.ps1 -Tests smoke_ui_text_fit`，使用真实渲染器和独立测试存档检查中英文界面，窗口尺寸为 1280×720、1024×600、2048×1055。覆盖开始菜单、设置、重置确认、三个案件的资料分类与照片、参考图、家具菜单和检视/旋转、调光、结算、暂停、工作室家具分页，以及六个电脑软件的普通、最大化和最小化状态。

检查按钮时必须扣除各状态的内容边距、图标和下拉箭头，测量文字本身的宽高；检查标签时须检查更外层的卡片，避免布局容器伸出纸框却被判定通过。滚动区域允许内容延伸，但卡片内部的文字不能延伸。原先超长的参考按钮与多行按钮溢出均保留为检查器的回归样例。

参考栏使用短标题，两列排列；完整资料名称保留在悬停提示。运行后，`tests/ui_text_fit_report.json` 保存问题列表，`tests/ui_text_fit_coverage.json` 保存具体覆盖状态，`tests/ui_reference_fit_en.png` 保存英文参考栏截图。新增界面或动态提示也要加入覆盖状态，不能仅凭已有状态通过就声称所有 UI 均已验证。
