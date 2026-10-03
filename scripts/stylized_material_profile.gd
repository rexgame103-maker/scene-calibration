@tool
extends Resource
class_name StylizedMaterialProfile


@export_category("Identity / 匹配")
@export var profile_id := "default"
@export var display_name := "默认手绘材质"
@export var role_ids: PackedStringArray = PackedStringArray(["furniture"])
@export var material_name_contains: PackedStringArray = PackedStringArray()
@export var priority := 0

@export_category("Colors / 颜色")
@export_color_no_alpha var base_color := Color("9a8b78")
@export_color_no_alpha var secondary_color := Color("685d52")
@export_color_no_alpha var paint_highlight_color := Color("c2b39b")
@export_color_no_alpha var stain_color := Color("342d29")
@export_color_no_alpha var wear_color := Color("c7ae86")
@export_range(0.0, 1.0, 0.01) var source_color_influence := 0.0

@export_category("Paint / 笔触与旧漆")
@export_range(0.0, 0.5, 0.005) var color_variation := 0.24
@export_range(0.2, 10.0, 0.05) var brush_scale := 2.4
@export_range(0.0, 1.0, 0.01) var brush_strength := 0.52
@export_range(0.0, 1.0, 0.01) var patina_strength := 0.36
@export_range(0.0, 1.0, 0.01) var stain_strength := 0.16
@export_range(0.0, 1.0, 0.01) var wear_strength := 0.12
@export_range(0.2, 12.0, 0.1) var wear_scale := 3.4
@export_range(0.0, 1.0, 0.01) var authored_desk_wear := 0.0

@export_category("Grid / 瓷砖网格")
@export var grid_enabled := false
@export_color_no_alpha var grid_color := Color("3f3934")
@export_range(0.1, 4.0, 0.05) var grid_cell_size := 1.0
@export_range(0.002, 0.25, 0.002) var grid_line_width := 0.035
@export_range(0.0, 1.0, 0.01) var grid_strength := 0.72
@export_range(0.0, 0.35, 0.01) var grid_tile_variation := 0.08
@export var grid_offset := Vector2.ZERO

@export_category("Surface / 表面")
@export_range(0.0, 1.0, 0.01) var roughness := 0.82
@export_range(0.0, 1.0, 0.01) var specular := 0.22

@export_category("Outline / 描边")
@export var outline_enabled := true
@export_color_no_alpha var outline_color := Color("17100d")
@export_range(0.0, 0.06, 0.001) var outline_width := 0.009


func matches(role: String, material_name: String) -> bool:
	var normalized_material := material_name.to_lower()
	for pattern: String in material_name_contains:
		if not pattern.is_empty() and normalized_material.contains(pattern.to_lower()):
			return true
	return role in role_ids
