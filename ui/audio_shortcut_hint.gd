extends CanvasLayer

@onready var container: MarginContainer = $MarginContainer
@onready var panel: PanelContainer = $MarginContainer/PanelContainer
@onready var title_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var subtitle_label: Label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Subtitle

var tween: Tween = null
var panel_open: bool = false
var rest_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	title_label.text = "F10 Audio Mix"
	subtitle_label.text = "Master / Music / Ambience / SFX"
	rest_position = container.position
	container.modulate = Color(1.0, 1.0, 1.0, 0.0)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.position = rest_position + Vector2(18.0, -10.0)
	show_hint(true)

func show_hint(emphasize: bool = false) -> void:
	if panel_open:
		return
	if tween != null:
		tween.kill()
	visible = true
	var pulse_scale := 1.0
	if emphasize:
		pulse_scale = 1.03
		container.modulate = Color(1.0, 1.0, 1.0, 0.0)
		container.position = rest_position + Vector2(18.0, -10.0)
		panel.scale = Vector2.ONE * 0.98
		tween = create_tween()
		tween.tween_property(container, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)
		tween.parallel().tween_property(container, "position", rest_position, 0.28)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE * pulse_scale, 0.28)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.18)
		tween.parallel().tween_property(container, "modulate", Color(1.0, 1.0, 1.0, 0.82), 0.18)
	else:
		container.modulate = Color(1.0, 1.0, 1.0, 0.82)
		container.position = rest_position
		panel.scale = Vector2.ONE
		tween = create_tween()
		tween.tween_property(panel, "scale", Vector2.ONE * 1.02, 0.16)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.16)

func set_panel_open(is_open: bool) -> void:
	panel_open = is_open
	if tween != null:
		tween.kill()
	if is_open:
		visible = true
		tween = create_tween()
		tween.tween_property(container, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.16)
		tween.finished.connect(func() -> void:
			if is_instance_valid(self) and panel_open:
				visible = false
		)
	else:
		show_hint(false)
