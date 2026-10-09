# 室内盆栽叶片

`scenes/props/indoor_plant_foliage.tscn` 是场景盆栽和家具盆栽共用的叶片组件。根节点放在花盆的土面上；工作室和办公室旧花盆的土面高度为 0.405。

12 片尖端叶片有弧面、中央隆起和不同的倾角，下层外展、上层直立。弯曲叶柄和叶片分别合并成一个网格，共 3024 个三角面，运行时不生成几何。双面叶片材质通过 UV 绘制细叶脉，`stylized_material_locked` 保留其材质，避免场景通用材质覆盖。

- 调整叶形和排列：`tools/build_indoor_foliage.gd` 的 `LEAVES` 参数。
- 调整叶色：`leaf_material.tres` 的 `paint`。
- 重新烘焙网格：Godot `--headless --path <工程目录> --script res://tools/build_indoor_foliage.gd`。
- 花盆可购买模型：`scenes/studio/player_parts/studio_plant.scn`。
- 单独预览：Godot `--path <工程目录> --script res://tools/preview_plant_model.gd`，输出 `tests/plant_model_after.png`；追加 `-- studio` 可预览工作室中的盆栽。
