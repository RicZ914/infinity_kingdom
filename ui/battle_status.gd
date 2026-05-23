extends CanvasLayer

const UISkin := preload("res://ui/ui_skin.gd")

var title_label: Label
var subtitle_label: Label
var detail_label: Label

func _ready() -> void:
	_build_ui()

func set_message(title: String, subtitle: String = "", detail: String = "") -> void:
	if title_label == null:
		return
	title_label.text = title
	subtitle_label.text = subtitle
	detail_label.text = detail

func _build_ui() -> void:
	layer = 4
	var margin := MarginContainer.new()
	margin.offset_left = 18.0
	margin.offset_top = 16.0
	margin.offset_right = 600.0
	margin.offset_bottom = 210.0
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UISkin.panel_style())
	margin.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)

	title_label = Label.new()
	title_label.text = "Town Boss Trial"
	UISkin.label(title_label, 24, Color(0.98, 0.90, 0.66))
	content.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Pick a champion to begin."
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(subtitle_label, 15, Color(0.86, 0.88, 0.92))
	content.add_child(subtitle_label)

	detail_label = Label.new()
	detail_label.text = "Controls: WASD move, J attack, K/L/I skills."
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(detail_label, 13, Color(0.70, 0.76, 0.84))
	content.add_child(detail_label)
