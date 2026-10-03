# 错位现场 / Scene Calibration

使用 **Godot 4.7 / GDScript** 制作的现场重构推理游戏。玩家在工作室接取案件，通过照片、资料与场景痕迹解锁家具，恢复空间关系并完成调查。

## 源码审核入口

- **[源码导览](docs/SOURCE_GUIDE.md)**：启动流程、目录结构、模块关系、核心代码索引。
- **[离线浏览说明](review/README.md)**：目录树、带行号的完整文本源码、函数 / 节点导航和全文检索。
- **[文件校验清单](review/manifest.json)**：实际文件路径、字节数与 SHA-256。
- **[开发记录与操作说明](docs/DEVELOPMENT_NOTES.md)**：详细交互规则、编辑器配置与历史说明。

下载完整工程后，双击 `review/index.html` 即可离线审阅源码。GitHub 上可直接阅读 `.gd`、`.tscn`、`.json` 与 `.gdshader` 文件；浏览页的 HTML 请下载到本地打开。

## 启动工程

1. 安装 Godot 4.7，导入根目录 `project.godot`。
2. 等待首次资源导入完成后按 **F5**。
3. 从开始菜单进入工作室，在电脑中查看委托并接取案件。

实际启动入口：`scenes/start_menu/start_menu_office.tscn`。案件现场共用 `scenes/main.tscn`，玩家工作室位于 `scenes/studio/calibrator_studio.tscn`。当前渲染配置为 `gl_compatibility`。

## 源码结构

```text
scene-calibration/
├── project.godot          # 工程配置、启动入口与六个 Autoload
├── scripts/              # 游戏逻辑、输入、家具系统、存档与运行时 UI
├── scenes/               # 开始菜单、工作室、案件现场和界面节点
├── data/
│   ├── cases/            # 案件、线索、资料、解锁与重构步骤
│   └── progression/      # 案件进程与工作室商品
├── assets/               # 模型、图片、字体、照片与 UI 图集
├── materials/            # Godot 材质资源
├── shaders/              # 着色器与手绘画面效果
├── tests/                # 功能验证脚本与预览
├── tools/                # 资源处理、场景渲染与源码交付工具
├── design/               # 设计稿与界面参考
├── docs/                 # 源码导览与开发记录
└── review/               # 可离线打开的源码浏览页
```

## 建议阅读顺序

1. [project.godot](project.godot)：确认入口与全局管理器。
2. [game_flow.gd](scripts/game_flow.gd)：工作室、开始菜单和案件之间的切换。
3. [case_manager.gd](scripts/case_manager.gd) 与 [第一案数据](data/cases/office_case_001.json)：线索、资料和家具解锁。
4. [main.gd](scripts/main.gd) 与 [furniture_factory.gd](scripts/furniture_factory.gd)：家具创建与现场交互。
5. [reconstruction_manager.gd](scripts/reconstruction_manager.gd)：空间条件与案件重构步骤。
6. [player_profile.gd](scripts/player_profile.gd)：进度、库存和布局存档。

## 离线交付与验证

运行 `python tools/build_source_review.py --date YYYY-MM-DD --zip` 可以重新生成源码浏览页、文件清单和 `deliveries/scene-calibration-source.zip`。生成过程只读取项目源码，不改写游戏逻辑。

工程保留运行所需的模型、图片、场景、导入设置与 `.uid`。Godot 导入缓存、Git 内部目录、本地旧备份与交付 ZIP 不提交。

`tests/` 中包含不同阶段的验证脚本。收录测试文件不等于所有测试均通过；应以所选测试的实际运行日志为准。

此仓库未新增开源授权协议。源码公开展示不改变原有代码与素材的授权条件。
