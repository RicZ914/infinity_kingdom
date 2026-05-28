class_name UICardFx
extends RefCounted

const DEFAULT_FLOAT_OFFSET := Vector2(6.0, 4.0)
const DEFAULT_ROTATION_MAX := 2.8
const DEFAULT_ACTIVE_SCALE := 1.028
const DEFAULT_SHEEN_ALPHA := 0.12
const DEFAULT_GLOW_COLOR := Color(0.96, 0.88, 0.68, 1.0)
const DEFAULT_GLOW_ACTIVE_ALPHA := 0.05
const DEFAULT_SHEEN_WIDTH := 74.0
const DEFAULT_SHEEN_PADDING_X_RATIO := 0.16
const DEFAULT_SHEEN_PADDING_Y := 28.0
const DEFAULT_SHEEN_SHIFT_X := 22.0
const DEFAULT_SHEEN_SHIFT_Y := 10.0
const DEFAULT_SHEEN_ROTATION := -16.0

static func install(button: Button, options: Dictionary = {}) -> Control:
	if button == null:
		return null
	if button.has_meta("card_fx_tilt_root"):
		sync(button)
		return button.get_meta("card_fx_tilt_root") as Control
	var config := _config_from(options)
	var tilt_root := Control.new()
	tilt_root.name = "TiltRoot"
	tilt_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	tilt_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tilt_root)

	var glow := ColorRect.new()
	glow.name = "Glow"
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = _with_alpha(config["glow_color"], 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tilt_root.add_child(glow)

	var sheen := ColorRect.new()
	sheen.name = "Sheen"
	sheen.color = Color(1.0, 1.0, 1.0, 0.0)
	sheen.rotation_degrees = config["sheen_rotation_degrees"]
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tilt_root.add_child(sheen)

	button.set_meta("card_fx_config", config)
	button.set_meta("card_fx_tilt_root", tilt_root)
	button.set_meta("card_fx_glow", glow)
	button.set_meta("card_fx_sheen", sheen)
	button.set_meta("card_fx_pinned", false)
	button.resized.connect(func() -> void: sync(button))
	sync(button)
	return tilt_root

static func bind(button: Button, preview_callback: Callable = Callable()) -> void:
	if button == null or button.has_meta("card_fx_bound"):
		return
	button.set_meta("card_fx_bound", true)
	button.focus_entered.connect(func() -> void:
		_invoke(preview_callback)
		set_active(button, true)
		update_tilt(button, button.size * 0.5)
	)
	button.mouse_entered.connect(func() -> void:
		_invoke(preview_callback)
		set_active(button, true)
	)
	button.focus_exited.connect(func() -> void:
		if button.is_hovered():
			return
		if is_pinned(button):
			set_active(button, true)
			reset_tilt(button)
			return
		set_active(button, false)
		reset_tilt(button)
	)
	button.mouse_exited.connect(func() -> void:
		if button.has_focus():
			return
		if is_pinned(button):
			set_active(button, true)
			reset_tilt(button)
			return
		set_active(button, false)
		reset_tilt(button)
	)
	button.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			update_tilt(button, (event as InputEventMouseMotion).position)
	)

static func sync(button: Button) -> void:
	if button == null or not button.has_meta("card_fx_tilt_root"):
		return
	var tilt_root := button.get_meta("card_fx_tilt_root") as Control
	var sheen := button.get_meta("card_fx_sheen") as ColorRect
	var config: Dictionary = _config(button)
	if tilt_root != null:
		tilt_root.pivot_offset = button.size * 0.5
	if sheen != null:
		var sheen_padding_y := float(config["sheen_padding_y"])
		sheen.position = Vector2(button.size.x * float(config["sheen_padding_x_ratio"]), -sheen_padding_y)
		sheen.size = Vector2(float(config["sheen_width"]), button.size.y + sheen_padding_y * 2.0)

static func set_active(button: Button, active: bool) -> void:
	if button == null or not button.has_meta("card_fx_tilt_root"):
		return
	var tilt_root := button.get_meta("card_fx_tilt_root") as Control
	var glow := button.get_meta("card_fx_glow") as ColorRect
	var config: Dictionary = _config(button)
	var tween: Tween = button.get_meta("card_fx_tween") as Tween if button.has_meta("card_fx_tween") else null
	if tween != null:
		tween.kill()
	tween = button.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if tilt_root != null:
		tween.tween_property(tilt_root, "scale", Vector2.ONE * (float(config["active_scale"]) if active else 1.0), 0.14)
	if glow != null:
		tween.parallel().tween_property(
			glow,
			"color",
			_with_alpha(config["glow_color"], float(config["glow_active_alpha"]) if active else 0.0),
			0.14
		)
	button.set_meta("card_fx_tween", tween)

static func update_tilt(button: Button, local_position: Vector2) -> void:
	if button == null or (not button.is_hovered() and not button.has_focus()):
		return
	if not button.has_meta("card_fx_tilt_root"):
		return
	var tilt_root := button.get_meta("card_fx_tilt_root") as Control
	var sheen := button.get_meta("card_fx_sheen") as ColorRect
	var config: Dictionary = _config(button)
	if tilt_root == null or button.size.x <= 0.0 or button.size.y <= 0.0:
		return
	var x_ratio := clampf(local_position.x / button.size.x, 0.0, 1.0) * 2.0 - 1.0
	var y_ratio := clampf(local_position.y / button.size.y, 0.0, 1.0) * 2.0 - 1.0
	var float_offset := config["float_offset"] as Vector2
	tilt_root.rotation_degrees = x_ratio * float(config["rotation_max"])
	tilt_root.position = Vector2(x_ratio * float_offset.x, y_ratio * float_offset.y)
	if sheen != null:
		var sheen_padding_y := float(config["sheen_padding_y"])
		sheen.color = Color(1.0, 1.0, 1.0, float(config["sheen_alpha"]))
		sheen.position = Vector2(
			button.size.x * float(config["sheen_padding_x_ratio"]) + x_ratio * float(config["sheen_shift_x"]),
			-sheen_padding_y + y_ratio * float(config["sheen_shift_y"])
		)

static func reset_tilt(button: Button) -> void:
	if button == null or not button.has_meta("card_fx_tilt_root"):
		return
	var tilt_root := button.get_meta("card_fx_tilt_root") as Control
	var sheen := button.get_meta("card_fx_sheen") as ColorRect
	var config: Dictionary = _config(button)
	var tween := button.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if tilt_root != null:
		tween.tween_property(tilt_root, "rotation_degrees", 0.0, 0.16)
		tween.parallel().tween_property(tilt_root, "position", Vector2.ZERO, 0.16)
	if sheen != null:
		var sheen_padding_y := float(config["sheen_padding_y"])
		tween.parallel().tween_property(sheen, "color", Color(1.0, 1.0, 1.0, 0.0), 0.16)
		tween.parallel().tween_property(
			sheen,
			"position",
			Vector2(button.size.x * float(config["sheen_padding_x_ratio"]), -sheen_padding_y),
			0.16
		)

static func pin(button: Button, pinned: bool) -> void:
	if button == null:
		return
	button.set_meta("card_fx_pinned", pinned)
	if pinned:
		set_active(button, true)
		if not button.is_hovered() and not button.has_focus():
			reset_tilt(button)
		return
	if not button.is_hovered() and not button.has_focus():
		set_active(button, false)
		reset_tilt(button)

static func is_pinned(button: Button) -> bool:
	if button == null:
		return false
	return bool(button.get_meta("card_fx_pinned", false))

static func _config(button: Button) -> Dictionary:
	return button.get_meta("card_fx_config", _config_from({})) as Dictionary

static func _config_from(options: Dictionary) -> Dictionary:
	return {
		"float_offset": options.get("float_offset", DEFAULT_FLOAT_OFFSET),
		"rotation_max": float(options.get("rotation_max", DEFAULT_ROTATION_MAX)),
		"active_scale": float(options.get("active_scale", DEFAULT_ACTIVE_SCALE)),
		"sheen_alpha": float(options.get("sheen_alpha", DEFAULT_SHEEN_ALPHA)),
		"glow_color": options.get("glow_color", DEFAULT_GLOW_COLOR),
		"glow_active_alpha": float(options.get("glow_active_alpha", DEFAULT_GLOW_ACTIVE_ALPHA)),
		"sheen_width": float(options.get("sheen_width", DEFAULT_SHEEN_WIDTH)),
		"sheen_padding_x_ratio": float(options.get("sheen_padding_x_ratio", DEFAULT_SHEEN_PADDING_X_RATIO)),
		"sheen_padding_y": float(options.get("sheen_padding_y", DEFAULT_SHEEN_PADDING_Y)),
		"sheen_shift_x": float(options.get("sheen_shift_x", DEFAULT_SHEEN_SHIFT_X)),
		"sheen_shift_y": float(options.get("sheen_shift_y", DEFAULT_SHEEN_SHIFT_Y)),
		"sheen_rotation_degrees": float(options.get("sheen_rotation_degrees", DEFAULT_SHEEN_ROTATION))
	}

static func _invoke(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()

static func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
