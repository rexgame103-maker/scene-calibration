# 第二关交互美术

案件 `gallery_case_002.json` 通过 `noir_gallery` 模式加载本目录的房间和六件家具。游戏入口仍为正常案件入口，无需运行静态展示场景。

`room.tscn` 包含固定建筑、柜子、推车、收纳标记、遮光天花板和环境灯。六件可移动设备已移出房间，获得线索后生成。`scripts/gallery_concept_furniture.gd` 保留原有物理与光影校准逻辑，同时加载新模型，匹配交互范围；画作、刮刀和损伤检视点跟随修复桌。

标准目标布局已与概念场景对应；真实布局及案件调查顺序保留。摄影与损伤判定仍读取真实节点，未绕过光源方向、投影长度或反射强度要求。

第二关照片已由新交互场景重新拍摄。`tests/render_gallery_integration.gd` 运行第二、第三关完整流程，并输出标准/实际布局截图及第二关资料照片。`tests/smoke_office_concept_gameplay.gd` 验证第一关回归。

静态参考场景 `gallery_restored_concept.tscn` 保留。修改其固定建筑或家具后，运行 `tools/extract_gallery_parts.gd` 才会更新此处美术；该操作覆盖拆分场景。
