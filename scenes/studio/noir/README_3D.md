# 深夜工作室 · 3D 漫画渲染

打开 `res://scenes/studio/noir/noir_studio_3d.tscn`，按 F6 运行。此文件才是 3D 版本；旁边的 `noir_studio.tscn` 是此前误做的 2D 版本。

房间、家具、线索墙、红线、照片、录音机、台灯、杯子、书籍和植物均为三维网格。场景树中完整保存所有节点，编辑器可直接选择、移动或编辑。没有使用整张房间插画作为背景。

## 渲染

- `res://shaders/noir_toon.gdshader`：三级明暗、硬边灯光衰减、深色基底与低强度物体空间颜料变化；盒体边缘使用不等宽黑线。
- `res://shaders/stylized_outline.gdshader`：复用现有的反向外壳描边，为曲面及导入家具提供轮廓。未修改原着色器。
- 房间主体和陈设使用专用几何；办公椅、文件柜复用项目 GLB，单独覆盖漫画材质，不修改源模型。
- 导入家具保存为本地网格节点，避免同时保存 GLB 实例与其内部节点造成名称冲突。
- 暖主光投射实时阴影，桌灯与蓝窗补光均为真实 SpotLight3D。左侧墙降低以露出房间内部。
- 使用项目原有 Compatibility 渲染器。运行该场景时启用四倍 MSAA，退出恢复之前设置。

## 操作

右键拖动旋转相机；滚轮缩放；中键平移；R 复位；L 切换桌灯；Tab 隐藏操作提示。

当前交付是独立的 3D 场景与材质渲染，不包含人物移动、物理碰撞、家具摆放玩法或原案件系统接入。项目默认入口、原有 3D 场景与原模型材质文件均未改动。

## 验证

`res://tools/render_noir_studio_3d.gd` 验证场景加载、三维节点与台灯切换，保存默认视角和旋转视角到 `res://tests/noir_studio_3d_preview.png`、`res://tests/noir_studio_3d_orbit.png`。

`res://tests/smoke_noir_scene_serialization.gd` 使用编辑器实例化模式验证加载、保存和重新加载，检查三件导入家具没有重复网格，且漫画材质保留。

`res://tools/build_noir_studio_3d.gd` 是初次搭建用的编辑辅助脚本；重新执行会重建该 3D 场景，因此手动编辑场景后不要直接重跑。
