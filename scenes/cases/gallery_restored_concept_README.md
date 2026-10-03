# 第二关修复室 · 静态美术场景

打开 `res://scenes/cases/gallery_restored_concept.tscn`，按 F6 预览。该文件为独立的可编辑 3D 场景，不会替换主场景或案件配置；无运行时搭建脚本、交互、判定框。

参考图：`assets/gallery_scene/concept_reference.png`。

每件家具均为根节点下独立 Node3D：RestorationTable（桌面画作、尺、刮刀、颜料、笔筒随桌移动）、RestorationStool、StandardColdLight（含真实冷光）、PhotographyTripod、MetalReflector、HalogenInspectionLamp（收纳状态不发光）、FlatFileCabinet、MaterialsCabinet、SpareFrameRack、SupplyTrolley。建筑在 Architecture；地面收纳标记与推车擦痕独立。

沿用第一关 noir_toon 材质和黑色描边。相机为正交视角。原始构建工具 `tools/build_gallery_restored_concept.gd` 会重写本场景，编辑器手工调整后请勿重新运行该工具，除非需要重新生成。

验证与截图：`tools/render_gallery_concept.gd` / `tests/gallery_concept_preview.png`。检查了家具编组、无碰撞交互、PackedScene 打包及实际渲染。

光影修订：本场景现使用独立 gallery_toon.gdshader，降低暗部自发光；WarmKey 为侧后方暖光投影，CoolFill 为低强度冷色补光，ColdWorkLight 朝向桌面。tools/relight_gallery.gd 可在保留场景布局的情况下重新应用这组参数；重新构建场景后需要再执行该工具。
遮光修订：Architecture/CeilingLightBlocker 使用 Shadows Only，只参与遮光、不挡俯视镜头。墙体恢复投影，玻璃保持透光；主光从侧窗方向进入。桌灯缩小照射范围并开启阴影，桌面遮挡其向地面漏光。CoolFill 为低强度室内反弹光近似。
