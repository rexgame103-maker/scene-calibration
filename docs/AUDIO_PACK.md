# 错位现场 · 纸页与痕迹

本套包含 **41 类事件、47 个 WAV**，其中 3 条是约 20 秒的环境循环。使用已经安装的 Stable Audio 3 Medium 本地工具制作，没有安装另一套工具。

## 文件

- `试听.html`：分组逐项试听；环境条目自动循环。
- `精选试听.wav` / `全部音效试听.wav`：按推荐初始增益拼接的试听，不是游戏素材。
- `试听时间轴.csv`：全部试听对应时间。
- `sound_bank.json`：事件 ID、Godot 资源路径、变体、推荐增益、冷却时间和空间化类型。
- 六个英文分类文件夹：成品 WAV，44.1 kHz / PCM 16 位；家具与设备为单声道，界面与环境为双声道。
- `制作记录.json`：原始提示词、随机种子、候选评分、裁切与增益；原始候选保留在工具输出目录 `_candidates`，不放入成品 ZIP 和游戏项目。

## 已接入游戏

素材在 `assets/audio/scene_calibration/`，运行入口是自动加载的 `scripts/game_audio.gd`。开始界面、工作室、三起案件共用播放管理器；界面操作用 `AudioStreamPlayer`，家具和设备用 `AudioStreamPlayer3D`。环境循环已经设置 Forward。

同一事件有多个变体时随机选择，并避免紧接着重复。播放器读取 `gain_db` 和 `cooldown_ms`，声音池限制为 16 个二维声音和 12 个空间声音。桌柜拖移达到 0.8 米才播放短摩擦音；桌面设备不播放地面摩擦。场景环境交叉淡入淡出，场景离开时停止家具和设备声。暂停时家具与设备声暂停，界面仍可发声，环境音降低 12 dB，恢复时回到用户设置。

开始界面 → 设置中可分别调整 **主音量、音效音量、环境音量**，并开关鼠标悬停音效（默认关闭）。设置保存在 `user://the_scene_options.cfg`，不影响案件存档。UI/SFX 进入 Effects 总线；环境音进入独立 Ambience 总线；都汇入 Master。

- 工作室、开始背景：`amb_studio`；第一关办公室：`amb_office`；第二关修复室：`amb_gallery`。背景不是配乐，没有剧情对白。
- 报纸按钮、档案、照片和暂停：`paper_click` / `page_turn` / `dossier_open` / `paper_cancel`。悬停音默认可关闭。
- 终端界面与新委托：`terminal_click` / `terminal_window_open` / `mail_arrive`。邮件提示只在有新邮件时触发。
- 家具落地根据材质选择 `place_wood` / `place_chair` / `place_cabinet` / `place_metal` / `place_small` / `place_paper`，常规落地不表示答案正确。
- `placement_invalid` 只用于碰撞等禁止摆放条件；不能用来提示家具与答案区域是否匹配。
- `clue_discover` 必须沿用可见性和观察角度判定；隐藏痕迹不播放。`clue_collect` 在玩家收集成功后播放；重复打开已读资料不重复播发现音。
- `case_complete` 在结案弹窗首次显示时播放；拍摄成功用 `camera_shutter`，写入相册和完成案件记录用 `archive_stamp`。委托接取、购买成功、新邮件、终端打开与关闭均接入相应事件。
- 电脑工作日志调查播放短键盘声，第二关灯光工作台的开关播放 `lamp_toggle`。打印机上的照片是已打印资料，查看时播放照片纸声。
- `printer_print`、`water_dispenser`、`coffee_brew`、`projector_start` 已随资源包导入，但当前游戏没有对应的实际设备使用交互，作为后续扩展保留。放置这些设备时播放材质落地声。

新增交互可调用 `GameAudio.play("event_id")`；家具使用 `GameAudio.play_placement(kind, global_position)`。已有自动按钮点击音时，可用 `GameAudio.bind_button(button, "")` 关闭通用音，再在成功回调中播放语义音，避免一点击叠加两次按钮音。事件增益、变体和冷却在 `sound_bank.json` 中调整，材质映射在 `game_audio.gd` 中调整。

## 运行验证

使用 Godot 4.7.2 检查资源导入，以及实际按钮输入、无效摆放、材质落地、档案查看、重复查看、暂停、场景淡入淡出、两个音量滑块与保存。划痕可见性测试使用真实 OpenGL 渲染，检查隐藏面和遮挡时无发现音、可见时点击才播放、收集只播放一次；电脑光点真实点击流程同时回归。

Windows 可运行 `tools/run_audio_smoke.ps1`（可通过 `-Godot` 指定可执行文件）。它创建临时测试项目和独立 `user://` 存档目录，复用现有资源，不覆盖实际游戏存档。

## 制作与检查

每类生成两个不同种子的候选；根据有效能量、动作时长和削波情况选择或保留变体。单次音去除直流分量、裁掉多余前后段、加短淡入淡出、保留少量静音边界并统一电平。循环使用 0.8 秒等功率交叉淡化，校验首尾跳变。波形评分不等于人耳音色判断，逐项试听用于确认音色；没有声明已由人工听审。

来源：Powered by Stability AI / Stable Audio 3 Medium，使用本地缓存模型 `a30034d70bd58f6e6f967ef28ecaa6c52c185d6c`。模型的 Stability AI Community License 与 Gemma 条款随工具安装目录保留；本说明不额外授予素材独占权。

## 事件清单

| ID | 音效 | 数量 | 用途类别 | 推荐增益 |
|---|---|---:|---|---:|
| `paper_hover` | 纸签轻触 | 1 | 纸张界面 | -12 dB |
| `paper_click` | 纸张按钮 | 2 | 纸张界面 | -7 dB |
| `page_turn` | 档案翻页 | 1 | 纸张界面 | -7 dB |
| `dossier_open` | 展开案件档案 | 1 | 纸张界面 | -6 dB |
| `dossier_close` | 合上案件档案 | 1 | 纸张界面 | -7 dB |
| `photo_pick` | 拿起照片 | 2 | 纸张界面 | -7 dB |
| `archive_stamp` | 归档盖章 | 1 | 纸张界面 | -4 dB |
| `paper_confirm` | 纸面确认 | 1 | 纸张界面 | -6 dB |
| `paper_cancel` | 纸面取消 | 1 | 纸张界面 | -8 dB |
| `terminal_click` | 终端按键 | 2 | 电脑终端 | -9 dB |
| `terminal_window_open` | 终端打开窗口 | 1 | 电脑终端 | -9 dB |
| `terminal_window_close` | 终端关闭窗口 | 1 | 电脑终端 | -10 dB |
| `mail_arrive` | 新委托邮件 | 1 | 电脑终端 | -7 dB |
| `shop_purchase` | 购买设备确认 | 1 | 电脑终端 | -8 dB |
| `terminal_unavailable` | 终端操作不可用 | 1 | 电脑终端 | -10 dB |
| `furniture_pickup` | 提起家具 | 1 | 家具摆放 | -6 dB |
| `furniture_rotate` | 转动家具 | 1 | 家具摆放 | -8 dB |
| `place_wood` | 木质桌柜落地 | 2 | 家具摆放 | -4 dB |
| `place_chair` | 座椅落地 | 2 | 家具摆放 | -6 dB |
| `place_cabinet` | 厚重柜体落地 | 1 | 家具摆放 | -4 dB |
| `place_metal` | 金属设备落地 | 1 | 家具摆放 | -6 dB |
| `place_small` | 桌面小物摆放 | 2 | 家具摆放 | -7 dB |
| `place_paper` | 文件资料摆放 | 1 | 家具摆放 | -7 dB |
| `drag_wood` | 短距离家具拖移 | 1 | 家具摆放 | -8 dB |
| `placement_invalid` | 摆放碰撞提示 | 1 | 家具摆放 | -8 dB |
| `inspect_focus` | 进入物件检视 | 1 | 案件调查 | -10 dB |
| `clue_discover` | 发现可见痕迹 | 1 | 案件调查 | -9 dB |
| `clue_collect` | 收集并记录线索 | 1 | 案件调查 | -7 dB |
| `item_unlock` | 新物件解锁 | 1 | 案件调查 | -8 dB |
| `camera_shutter` | 拍摄复原照片 | 1 | 案件调查 | -5 dB |
| `case_complete` | 案件归档完成 | 1 | 案件调查 | -6 dB |
| `crt_boot` | 老式终端启动 | 1 | 办公设备 | -8 dB |
| `keyboard_type` | 短句键盘输入 | 1 | 办公设备 | -9 dB |
| `printer_print` | 打印旧照片 | 1 | 办公设备 | -8 dB |
| `water_dispenser` | 饮水机接水 | 1 | 办公设备 | -8 dB |
| `lamp_toggle` | 台灯开关 | 1 | 办公设备 | -8 dB |
| `coffee_brew` | 咖啡机短萃取 | 1 | 办公设备 | -9 dB |
| `projector_start` | 档案投影仪启动 | 1 | 办公设备 | -9 dB |
| `amb_studio` | 工作室安静底噪 | 1 | 室内环境 | -10 dB |
| `amb_office` | 空办公室室内底噪 | 1 | 室内环境 | -10 dB |
| `amb_gallery` | 修复室空调底噪 | 1 | 室内环境 | -10 dB |
