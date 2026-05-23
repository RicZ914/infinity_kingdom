class_name UISkin
extends RefCounted

const UI_ASSET := "res://assets/ui/"

static func asset(path: String) -> String:
	return UI_ASSET + path

static func tex(path: String) -> Texture2D:
	return load(path) as Texture2D

static func texture_style(path: String, margin: int = 32, content: int = 12) -> StyleBox:
	var texture := tex(path)
	if texture == null:
		return flat_style(Color(0.075, 0.083, 0.105, 0.96), Color(0.54, 0.43, 0.22), 1, 6)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.set_texture_margin_all(margin)
	style.content_margin_left = content
	style.content_margin_right = content
	style.content_margin_top = content
	style.content_margin_bottom = content
	return style

static func flat_style(bg: Color, border: Color, border_width: int = 1, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func panel_style() -> StyleBox:
	return texture_style(asset("frame/panel_large_dark.png"), 42, 16)

static func red_panel_style() -> StyleBox:
	return texture_style(asset("frame/panel_large_red.png"), 42, 16)

static func gold_panel_style() -> StyleBox:
	return texture_style(asset("frame/panel_large_gold.png"), 42, 16)

static func icon_slot_style() -> StyleBox:
	return texture_style(asset("frame/icon_slot_gold.png"), 24, 5)

static func button_styles(button: Button, size: String = "medium") -> void:
	var prefix := "button/btn_medium"
	if size == "large":
		prefix = "button/btn_large"
	elif size == "small":
		prefix = "button/btn_small"
	elif size == "thin":
		button.add_theme_stylebox_override("normal", texture_style(asset("button/btn_thin_dark.png"), 28, 10))
		button.add_theme_stylebox_override("hover", texture_style(asset("button/btn_thin_gold.png"), 28, 10))
		button.add_theme_stylebox_override("pressed", texture_style(asset("button/btn_thin_dark.png"), 28, 10))
		button.add_theme_stylebox_override("disabled", texture_style(asset("button/btn_small_disabled.png"), 28, 10))
		_apply_button_text(button)
		return
	button.add_theme_stylebox_override("normal", texture_style(asset("%s_normal.png" % prefix), 30, 10))
	button.add_theme_stylebox_override("hover", texture_style(asset("%s_hover.png" % prefix), 30, 10))
	button.add_theme_stylebox_override("pressed", texture_style(asset("%s_pressed.png" % prefix), 30, 10))
	button.add_theme_stylebox_override("disabled", texture_style(asset("%s_disabled.png" % prefix), 30, 10))
	_apply_button_text(button)

static func label(label: Label, size: int, color: Color = Color(0.91, 0.89, 0.82)) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)

static func _apply_button_text(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.94, 0.86, 0.64))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.74))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.65, 0.42))
