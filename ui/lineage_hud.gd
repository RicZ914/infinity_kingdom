extends CanvasLayer

const UISkin := preload("res://ui/ui_skin.gd")

const LIT_FRAMES := [
	preload("res://assets/ui/emblem/ember_node_1.png"),
	preload("res://assets/ui/emblem/ember_node_2.png"),
	preload("res://assets/ui/emblem/ember_node_3.png"),
	preload("res://assets/ui/emblem/ember_node_4.png"),
	preload("res://assets/ui/emblem/ember_node_5.png"),
	preload("res://assets/ui/emblem/ember_node_6.png")
]
const EMPTY_FRAME := preload("res://assets/ui/emblem/ember_node_empty.png")

var ember_nodes: Array[TextureRect] = []
var title_label: Label
var aptitude_label: Label
var state: Dictionary = {}

func _ready() -> void:
	layer = 7
	_build_ui()
	if LineageDirector != null:
		if not LineageDirector.state_changed.is_connected(_on_lineage_state_changed):
			LineageDirector.state_changed.connect(_on_lineage_state_changed)
		_on_lineage_state_changed(LineageDirector.get_state())

func _process(_delta: float) -> void:
	var seeds_left := int(state.get("seeds_left", 5))
	var frame_index := int(Time.get_ticks_msec() / 120) % LIT_FRAMES.size()
	var bob := sin(float(Time.get_ticks_msec()) * 0.006)
	for index in range(ember_nodes.size()):
		var node := ember_nodes[index]
		if index < seeds_left:
			node.texture = LIT_FRAMES[frame_index]
			node.modulate = Color(1.0, 1.0, 1.0, 1.0)
			node.position.y = bob * 2.0
		else:
			node.texture = EMPTY_FRAME
			node.modulate = Color(0.56, 0.58, 0.64, 0.86)
			node.position.y = 0.0

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.anchor_left = 1.0
	margin.anchor_right = 1.0
	margin.anchor_top = 0.0
	margin.anchor_bottom = 0.0
	margin.offset_left = -412.0
	margin.offset_top = 18.0
	margin.offset_right = -18.0
	margin.offset_bottom = 138.0
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	margin.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 10)
	inner.add_theme_constant_override("margin_top", 8)
	inner.add_theme_constant_override("margin_right", 10)
	inner.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(inner)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	inner.add_child(column)

	title_label = Label.new()
	UISkin.label(title_label, 13, UISkin.COLOR_ACCENT)
	column.add_child(title_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	column.add_child(row)
	for index in range(5):
		var ember := TextureRect.new()
		ember.custom_minimum_size = Vector2(56, 56)
		ember.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ember.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(ember)
		ember_nodes.append(ember)

	aptitude_label = Label.new()
	UISkin.label(aptitude_label, 11, UISkin.COLOR_TEXT)
	column.add_child(aptitude_label)

func _on_lineage_state_changed(next_state: Dictionary) -> void:
	state = next_state.duplicate(true)
	var aptitude := state.get("aptitude", {}) as Dictionary
	title_label.text = "%s %d  |  %s %d" % [
		_locale_text("Reincarnation", "轮回", "輪迴"),
		int(state.get("reincarnation_index", 1)),
		_locale_text("Generation", "第几代", "第幾代"),
		int(state.get("generation_index", 1))
	]
	aptitude_label.text = "%s %d  %s %d  %s %d" % [
		_locale_text("STR", "强壮", "強壯"),
		int(aptitude.get("strength", 3)),
		_locale_text("AGI", "迅捷", "迅捷"),
		int(aptitude.get("agility", 3)),
		_locale_text("FOC", "专注", "專注"),
		int(aptitude.get("focus", 3))
	]

func _locale_text(en_text: String, zh_hans_text: String, zh_hant_text: String) -> String:
	if UISettings != null and UISettings.has_method("get_locale"):
		match String(UISettings.get_locale()):
			"zh_Hant":
				return zh_hant_text
			"zh_Hans":
				return zh_hans_text
	return en_text
