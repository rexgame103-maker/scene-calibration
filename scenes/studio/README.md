# 玩家工作室

窗光雾效：WindowLightMist 的材质参数 Density 控制浓度（当前 0.22），Mist Color 控制光雾颜色，隐藏节点即可关闭。使用兼容渲染器可运行的局部体积积分材质，带缓慢雾流、窗边和光束末端渐隐，并在可见家具表面截止。它是为当前窗口位置与入射方向设计的美术光雾，不是自动随所有灯光生成的引擎体积雾；更改窗户位置或太阳方向后需同步调整材质与节点。相机应位于光雾盒外。

工作区局部灯光集中在 WorkspaceLighting：WindowCoolFill（窗边冷光）、EvidenceBoardWarmWash（线索板暖光）、ModelShelfWarmPool（沙盘灯光）、MonitorCoolBounce（屏幕反光）。可以分别调整能量和范围，保留暗部层次。`tools/relight_player_studio.gd` 只更新这些灯光与台灯参数，不重建家具布局。

打开 `player_studio_concept.tscn`，按 F6 运行当前场景。独立静态场景，没有交互，也未替换游戏入口。

家具按父节点分组：InvestigationDesk（桌面电脑、键盘、纸张、台灯）、DeskChair、MiniatureWorkbench、ArchiveBookcase、WindowBookcase、PrinterCabinet、LeatherSofa、CoffeeTable、FloorLamp。移动父节点即可整体摆放。

光影：WarmKey 是左窗斜射暖光；InvestigationDesk/DeskLampPool 是桌面局部照明；FloorLamp/SofaLampPool 是沙发暖光；CoolFill 控制暗部可见度。CeilingLightBlocker 只投射阴影、不显示，避免顶光铺满地面，请保留。灯光不要移进灯杆或灯罩实体内部，否则会被自身挡住。

参考图：`assets/player_studio/concept_reference.png`。实际渲染预览：`tests/player_studio_concept_preview.png`。

材质和导入网格单独存放在 `assets/player_studio/meshes/`。美术采用现有分层明暗、黑色描边材质；当前版本是参考图的三维搭建，细部与概念画存在差异。

`tools/build_player_studio_concept.gd` 是生成脚本，重新运行会覆盖这个场景及其生成资源；手动调整场景后请勿直接重跑。`tools/render_player_studio_concept.gd` 用于加载检查和截图，不覆盖场景。
