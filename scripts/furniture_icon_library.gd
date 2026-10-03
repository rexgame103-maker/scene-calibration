@tool
class_name FurnitureIconLibrary
extends RefCounted
## Shared hand-drawn art for case catalogs, studio inventory and the shop.
const DIRECTORY := "res://assets/ui/furniture_handdrawn/"
const ALIASES := {
	"studio_computer": "computer",
	"studio_plant": "plant",
	"case_frame_office": "case_frame",
	"case_frame_gallery": "case_frame",
	"case_frame_apartment": "case_frame",
}
static var _regions: Dictionary = {}
static var _sheets: Dictionary = {}
static var _textures: Dictionary = {}

static func _load_regions() -> void:
	if _regions.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "regions.json"))
		if parsed is Dictionary:
			_regions = parsed

static func has_icon(kind: String) -> bool:
	_load_regions()
	return _regions.has(ALIASES.get(kind, kind))

static func get_icon(kind: String) -> Texture2D:
	_load_regions()
	var key := String(ALIASES.get(kind, kind))
	if not _regions.has(key):
		return null
	if not _textures.has(key):
		var entry: Dictionary = _regions[key]
		var sheet := String(entry.sheet)
		if not _sheets.has(sheet):
			_sheets[sheet] = load(DIRECTORY + sheet + ".png")
		var coordinates: Array = entry.region
		var texture := AtlasTexture.new()
		texture.atlas = _sheets[sheet]
		texture.region = Rect2(coordinates[0], coordinates[1], coordinates[2], coordinates[3])
		texture.filter_clip = true
		_textures[key] = texture
	return _textures[key]

static func fit_rect(texture: Texture2D, rect: Rect2) -> Rect2:
	var dimensions := texture.get_size()
	var factor := minf(rect.size.x / dimensions.x, rect.size.y / dimensions.y)
	var fitted := dimensions * factor
	return Rect2(rect.get_center() - fitted * 0.5, fitted)
