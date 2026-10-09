extends Control
## Native controls matching design/case_files_newspaper. Coordinates use 1600 × 900.
const ATLAS = preload("res://assets/ui/case_briefing_newspaper/newspaper_modules.png")
const INK := Color("302820")
var category: OptionButton
var evidence_list: VBoxContainer
var return_button: Button
var detail_category: Label
var detail_title: Label
var description: RichTextLabel
var photo_frame: PanelContainer
var photo_texture: TextureRect
var caption: Label
var result: Label
var count: Label
var photo_heading: Label
var result_rule: ColorRect
var serif: SystemFont
var sans: SystemFont

func build(summary: Dictionary) -> void:
	name = "NewspaperArchive"
	size = Vector2(1600, 900)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["SimSun", "Noto Serif CJK SC", "serif"])
	sans = SystemFont.new()
	sans.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	var archive_theme := Theme.new()
	archive_theme.default_font = sans
	theme = archive_theme
	art(Rect2(28,364,710,445), Rect2(380,48,1176,802))
	# Blank paper strips conceal the source's printed rules under live content.
	var grain := Control.new()
	grain.clip_contents = true
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(grain, Rect2(443,113,1060,697))
	for i in 5:
		var strip := TextureRect.new()
		strip.texture = region(Rect2(70,646,630,113))
		strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		strip.flip_v = i % 2 == 1
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grain.add_child(strip)
		strip.position = Vector2(0,i*190)
		strip.size = Vector2(1060,190)
	label("案件资料", Rect2(48,38,285,53),38,Color("e9dec9"),true)
	label("CASE ARCHIVE",Rect2(50,96,280,24),12,Color("a89b85"))
	rule(Rect2(50,132,275,1))
	var case_title := label(String(summary.get("title","案件资料")),Rect2(50,155,287,40),25,Color("e9dec9"),true)
	var heading_size := 25
	while heading_size > 14 and serif.get_string_size(tr(case_title.text), HORIZONTAL_ALIGNMENT_LEFT, -1, heading_size).x > 287:
		heading_size -= 1
	case_title.add_theme_font_size_override("font_size", heading_size)
	var subtitle := label(String(summary.get("subtitle","")),Rect2(50,198,285,42),14,Color("a99e8c"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.size = Vector2(285,42)
	category = OptionButton.new()
	for value: String in ["全部","案情描述","现场照片","证物"]:
		category.add_item(value)
	category.set_item_text(0,"全部资料")
	skin_button(category)
	var popup := category.get_popup()
	popup.add_theme_stylebox_override("panel",style(Rect2(462,924,299,61),true))
	popup.add_theme_color_override("font_color",INK)
	popup.add_theme_color_override("font_hover_color",INK)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("b99b7560")
	popup.add_theme_stylebox_override("hover",hover)
	place(category,Rect2(45,254,292,55))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	place(scroll,Rect2(45,335,292,380))
	evidence_list = VBoxContainer.new()
	evidence_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	evidence_list.add_theme_constant_override("separation",17)
	scroll.add_child(evidence_list)
	count = label("",Rect2(54,731,275,24),13,Color("9d907b"))
	return_button = Button.new()
	return_button.text = "←   返回现场                    Esc"
	skin_button(return_button)
	place(return_button,Rect2(45,786,292,57))
	label("现场档案",Rect2(449,118,580,27),17,Color("665440"),true)
	label("CITY INVESTIGATION BUREAU",Rect2(449,149,590,23),11,Color("76644d"))
	art(Rect2(770,258,492,64),Rect2(1162,115,315,41))
	rule(Rect2(449,193,1030,1))
	detail_category = label("",Rect2(449,208,1028,24),14,Color("874b3c"))
	detail_title = label("",Rect2(449,242,1028,52),40,INK,true)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	art(Rect2(770,352,300,15),Rect2(449,299,1028,5))
	photo_frame = PanelContainer.new()
	photo_frame.name = "EvidencePhotograph"
	var frame_style := style(Rect2(462,924,299,61), true)
	frame_style.content_margin_left = 18
	frame_style.content_margin_right = 18
	frame_style.content_margin_top = 18
	frame_style.content_margin_bottom = 42
	photo_frame.add_theme_stylebox_override("panel",frame_style)
	place(photo_frame,Rect2(435,330,694,464))
	photo_texture = TextureRect.new()
	photo_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo_frame.add_child(photo_texture)
	caption = label("",Rect2(453,759,658,25),14,Color("6b5c48"),true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	photo_heading = label("照片说明",Rect2(1170,349,290,33),21,INK,true)
	description = RichTextLabel.new()
	description.bbcode_enabled = false
	description.add_theme_color_override("default_color",INK)
	description.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	description.scroll_active = true
	place(description,Rect2(1170,396,290,131))
	result_rule = rule(Rect2(1170,536,290,1))
	result = label("",Rect2(1170,555,290,115),18,Color("526047"))
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label("CASE FILE",Rect2(1356,778,122,20),10,Color("7c6c56")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	set_photo_mode(false)

func set_photo_mode(is_photo: bool) -> void:
	photo_frame.visible = is_photo
	caption.visible = is_photo
	photo_heading.visible = is_photo
	description.position = Vector2(1170,396) if is_photo else Vector2(461,359)
	description.size = Vector2(290,131) if is_photo else Vector2(987,194)
	description.add_theme_font_size_override("normal_font_size",18 if is_photo else 28)
	description.add_theme_constant_override("line_separation",12 if is_photo else 18)
	if is_photo:
		description.add_theme_font_override("normal_font",sans)
	else:
		description.add_theme_font_override("normal_font",serif)
	result_rule.position = Vector2(1170,536) if is_photo else Vector2(460,564)
	result_rule.size = Vector2(290 if is_photo else 988,1)
	result.position = Vector2(1170,555) if is_photo else Vector2(460,593)
	result.size = Vector2(290,115) if is_photo else Vector2(988,75)
	result.add_theme_font_size_override("font_size",18 if is_photo else 16)
	description.scroll_to_line(0)

func place(control: Control, rect: Rect2) -> void:
	add_child(control)
	control.position = rect.position
	control.size = rect.size

func label(value: String, rect: Rect2, font_size: int, color: Color, use_serif := false) -> Label:
	var control := Label.new()
	control.text = value
	control.clip_text = true
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_theme_font_size_override("font_size",font_size)
	control.add_theme_color_override("font_color",color)
	if use_serif: control.add_theme_font_override("font",serif)
	place(control,rect)
	return control

func rule(rect: Rect2) -> ColorRect:
	var control := ColorRect.new()
	control.color = Color("6c5c4980")
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(control,rect)
	return control

func art(source: Rect2, rect: Rect2) -> void:
	var control := TextureRect.new()
	control.texture = region(source)
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(control,rect)

static func region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = rect
	texture.filter_clip = true
	return texture

static func style(rect: Rect2, sliced := false) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = region(rect)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_texture_margin(side,12 if sliced else 0)
		box.set_content_margin(side,12)
	box.content_margin_left = 26
	box.content_margin_right = 20
	return box

static func skin_button(button: Button, selected := false) -> void:
	var source := Rect2(1168,457,350,88) if selected else Rect2(459,832,312,83)
	for state in ["normal","hover","pressed","disabled"]:
		var box := style(source,true)
		if state == "hover": box.modulate_color = Color(1.08,1.05,1.0)
		if state == "pressed": box.modulate_color = Color("cfbaa0")
		button.add_theme_stylebox_override(state,box)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(key,Color("f0e5d2") if selected else Color("3e3328"))
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
