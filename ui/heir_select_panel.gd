extends CanvasLayer

signal confirmed(attribute_id: String)

const UISkin := preload("res://ui/ui_skin.gd")

var selected_attribute := "strength"
var title_label: Label
var score_label: Label
var aptitude_labels: Dictionary = {}
var confirm_button: Button

func _ready() -> void:
	layer = 24
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func open(payload: Dictionary) -> void:
	var lineage := payload.get("lineage", {}) as Dictionary
	var score := payload.get("score", {}) as Dictionary
	var aptitude := lineage.get("aptitude", {}) as Dictionary
	title_label.text = "%s %d" % [
		_locale_text("Heir Generation", "继承者 第", "繼承者 第"),
		int(lineage.get("generation_index", 1))
	]
	score_label.text = "%s %s / %d  |  %s" % [
		_locale_text("Grade", "评分", "評分"),
		String(score.get("grade", "D")),
		int(score.get("score", 0)),
		_locale_text("Add 1 aptitude point before respawn.", "重生前选择一项资质 +1。", "重生前選擇一項資質 +1。")
	]
	for key in aptitude_labels.keys():
		var button := aptitude_labels[key] as Button
		button.text = "%s\n%d%s" % [
			_attribute_name(String(key)),
			int(aptitude.get(key, 3)),
			" +1" if String(key) == selected_attribute else ""
		]
	_refresh_selection()
	visible = true
	get_tree().paused = true
	confirm_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select("strength")
			KEY_2:
				_select("agility")
			KEY_3:
				_select("focus")
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_confirm()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.01, 0.012, 0.018, 0.62)
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 420)
	panel.add_theme_stylebox_override("panel", UISkin.menu_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	title_label = Label.new()
	UISkin.label(title_label, 28, UISkin.COLOR_ACCENT)
	column.add_child(title_label)

	score_label = Label.new()
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(score_label, 15, UISkin.COLOR_TEXT)
	column.add_child(score_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	for key in ["strength", "agility", "focus"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 92)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UISkin.button_styles(button, "large")
		button.pressed.connect(_select.bind(key))
		row.add_child(button)
		aptitude_labels[key] = button

	var hint := Label.new()
	hint.text = _locale_text(
		"1 Strength: HP/armor  |  2 Agility: speed/crit  |  3 Focus: inspiration/skills",
		"1 强壮：生命/护甲  |  2 迅捷：速度/暴击  |  3 专注：灵感/技能",
		"1 強壯：生命/護甲  |  2 迅捷：速度/暴擊  |  3 專注：靈感/技能"
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(hint, 13, UISkin.COLOR_MUTED)
	column.add_child(hint)

	confirm_button = Button.new()
	confirm_button.text = _locale_text("Confirm Heir", "确认继承", "確認繼承")
	UISkin.button_styles(confirm_button, "large")
	confirm_button.pressed.connect(_confirm)
	column.add_child(confirm_button)

func _select(attribute_id: String) -> void:
	selected_attribute = attribute_id
	_refresh_selection()

func _refresh_selection() -> void:
	for key in aptitude_labels.keys():
		var button := aptitude_labels[key] as Button
		if button == null:
			continue
		button.add_theme_stylebox_override(
			"normal",
			UISkin.flat_style(
				Color(0.18, 0.16, 0.12, 0.98) if String(key) == selected_attribute else UISkin.COLOR_PANEL,
				UISkin.COLOR_ACCENT if String(key) == selected_attribute else UISkin.COLOR_BORDER_ALT,
				2,
				4
			)
		)

func _confirm() -> void:
	visible = false
	get_tree().paused = false
	confirmed.emit(selected_attribute)

func _attribute_name(attribute_id: String) -> String:
	match attribute_id:
		"agility":
			return _locale_text("Agility", "迅捷", "迅捷")
		"focus":
			return _locale_text("Focus", "专注", "專注")
		_:
			return _locale_text("Strength", "强壮", "強壯")

func _locale_text(en_text: String, zh_hans_text: String, zh_hant_text: String) -> String:
	if UISettings != null and UISettings.has_method("get_locale"):
		match String(UISettings.get_locale()):
			"zh_Hant":
				return zh_hant_text
			"zh_Hans":
				return zh_hans_text
	return en_text
