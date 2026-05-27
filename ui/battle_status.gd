extends CanvasLayer

const RunEffects := preload("res://systems/run/run_effects.gd")
const UISkin := preload("res://ui/ui_skin.gd")

var root_margin: MarginContainer
var panel_margin: MarginContainer
var title_label: Label
var subtitle_label: Label
var detail_label: Label
var info_grid: GridContainer
var objective_value_label: Label
var threat_value_label: Label
var hero_value_label: Label
var relic_value_label: Label
var run_label: Label
var context_caption_labels: Array[Label] = []
var layout_size_override: Vector2 = Vector2.ZERO
var context_state := {
	"objective": "Select a champion to begin the run.",
	"threat": "Knight is safest, Ranger spikes tempo, Mage controls space.",
	"hero": "No champion selected.",
	"relic": "No Accessory\nChoose a relic to shape this run."
}

func _ready() -> void:
	_build_ui()
	if RunDirector != null and not RunDirector.state_changed.is_connected(_on_run_state_changed):
		RunDirector.state_changed.connect(_on_run_state_changed)
	if UISettings != null and UISettings.has_signal("locale_changed") and not UISettings.locale_changed.is_connected(_refresh_copy):
		UISettings.locale_changed.connect(_refresh_copy)
	_on_run_state_changed(RunDirector.get_state())
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_queue_layout_refresh):
		get_viewport().size_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()

func set_message(title: String, subtitle: String = "", detail: String = "") -> void:
	if title_label == null:
		return
	title_label.text = title
	subtitle_label.text = subtitle
	detail_label.text = detail

func set_context(context: Dictionary) -> void:
	if context.is_empty():
		return
	for key in ["objective", "threat", "hero", "relic"]:
		if context.has(key):
			context_state[key] = String(context.get(key, context_state[key]))
	_refresh_context()

func _build_ui() -> void:
	layer = 4
	root_margin = MarginContainer.new()
	root_margin.offset_left = 18.0
	root_margin.offset_top = 16.0
	root_margin.offset_right = 600.0
	root_margin.offset_bottom = 320.0
	root_margin.add_theme_constant_override("margin_left", 10)
	root_margin.add_theme_constant_override("margin_top", 10)
	root_margin.add_theme_constant_override("margin_right", 10)
	root_margin.add_theme_constant_override("margin_bottom", 10)
	add_child(root_margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UISkin.panel_style())
	root_margin.add_child(panel)

	panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 14)
	panel_margin.add_theme_constant_override("margin_top", 14)
	panel_margin.add_theme_constant_override("margin_right", 14)
	panel_margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(panel_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel_margin.add_child(content)

	title_label = Label.new()
	title_label.text = _locale_text("Town Boss Trial", "城镇王战试炼", "城鎮王戰試煉")
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(title_label, 24, Color(0.98, 0.90, 0.66))
	content.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = _locale_text("Pick a champion to begin.", "选择一名角色开始试炼。", "選擇一名角色開始試煉。")
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(subtitle_label, 15, Color(0.86, 0.88, 0.92))
	content.add_child(subtitle_label)

	detail_label = Label.new()
	detail_label.text = _locale_text("Controls: WASD move, J attack, K/L/I skills.", "操作：WASD 移动，J 普攻，K/L/I 技能。", "操作：WASD 移動，J 普攻，K/L/I 技能。")
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(detail_label, 13, Color(0.70, 0.76, 0.84))
	content.add_child(detail_label)

	info_grid = GridContainer.new()
	info_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_grid.add_theme_constant_override("h_separation", 8)
	info_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(info_grid)

	var objective_card := _context_card(UIText.text("status_objective"), Color(0.98, 0.90, 0.66))
	objective_value_label = objective_card["value"]
	info_grid.add_child(objective_card["panel"])

	var threat_card := _context_card(UIText.text("status_threat"), Color(1.0, 0.78, 0.66))
	threat_value_label = threat_card["value"]
	info_grid.add_child(threat_card["panel"])

	var hero_card := _context_card(UIText.text("status_hero"), Color(0.78, 0.88, 1.0))
	hero_value_label = hero_card["value"]
	info_grid.add_child(hero_card["panel"])

	var relic_card := _context_card(UIText.text("status_relic"), Color(0.82, 0.92, 0.76))
	relic_value_label = relic_card["value"]
	info_grid.add_child(relic_card["panel"])

	var run_panel := PanelContainer.new()
	run_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	content.add_child(run_panel)

	var run_margin := MarginContainer.new()
	run_margin.add_theme_constant_override("margin_left", 10)
	run_margin.add_theme_constant_override("margin_top", 8)
	run_margin.add_theme_constant_override("margin_right", 10)
	run_margin.add_theme_constant_override("margin_bottom", 8)
	run_panel.add_child(run_margin)

	run_label = Label.new()
	run_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(run_label, 12, Color(0.82, 0.88, 0.96))
	run_margin.add_child(run_label)
	_refresh_context()

func _context_card(caption: String, accent: Color) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var caption_label := Label.new()
	caption_label.text = caption
	UISkin.label(caption_label, 11, accent)
	column.add_child(caption_label)
	context_caption_labels.append(caption_label)

	var value_label := Label.new()
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(value_label, 12, Color(0.88, 0.92, 0.98))
	column.add_child(value_label)

	return {
		"panel": panel,
		"value": value_label
	}

func _on_run_state_changed(state: Dictionary) -> void:
	if run_label == null:
		return
	var next_event := String(state.get("next_event_kind", ""))
	var next_text := RunDirector.describe_event_kind(next_event) if RunDirector != null and not next_event.is_empty() else _locale_text("Victory", "胜利", "勝利")
	var modifier_count := (state.get("run_modifiers", {}) as Dictionary).size()
	var reward_flat_bonus := int(state.get("reward_flat_bonus", 0))
	var reward_multiplier := float(state.get("reward_multiplier", 1.0))
	var pending_prep := state.get("pending_encounter_prep", {}) as Dictionary
	var reward_bonus_text := _locale_text("None", "无", "無")
	if reward_flat_bonus > 0 or reward_multiplier > 1.001:
		var parts: Array[String] = []
		if reward_flat_bonus > 0:
			parts.append(_locale_text("+%d gold", "+%d 金币", "+%d 金幣") % reward_flat_bonus)
		if reward_multiplier > 1.001:
			parts.append(_locale_text("x%.2f reward", "x%.2f 奖励", "x%.2f 獎勵") % reward_multiplier)
		reward_bonus_text = " ".join(parts)
	var route_preview := RunDirector.describe_event_route(3)
	var prep_text := (_locale_text("  |  Prep %s", "  |  准备 %s", "  |  準備 %s") % RunEffects.prep_title(pending_prep)) if not pending_prep.is_empty() else ""
	run_label.text = "%s %d  |  %s +%d  |  %s %d\n%s %s%s  |  %s %d  |  %s %s\n%s %s" % [
		_locale_text("Gold", "金币", "金幣"),
		int(state.get("gold", 0)),
		_locale_text("Last", "上次", "上次"),
		int(state.get("last_reward_gold", 0)),
		_locale_text("Cleared", "完成", "完成"),
		int(state.get("cleared_encounters", 0)),
		_locale_text("Next", "下一步", "下一步"),
		next_text,
		prep_text,
		_locale_text("Run effects", "本局加成", "本局加成"),
		modifier_count,
		_locale_text("Bounty", "悬赏", "懸賞"),
		reward_bonus_text,
		UIText.text("event_route_label"),
		route_preview
	]

func _refresh_copy(_locale: String = "") -> void:
	if context_caption_labels.size() >= 4:
		context_caption_labels[0].text = UIText.text("status_objective")
		context_caption_labels[1].text = UIText.text("status_threat")
		context_caption_labels[2].text = UIText.text("status_hero")
		context_caption_labels[3].text = UIText.text("status_relic")

func _current_locale() -> String:
	if UISettings != null and UISettings.has_method("get_locale"):
		return String(UISettings.get_locale())
	return "zh_Hans"

func _locale_text(en_text: String, zh_hans_text: String, zh_hant_text: String) -> String:
	match _current_locale():
		"zh_Hant":
			return zh_hant_text
		"zh_Hans":
			return zh_hans_text
		_:
			return en_text

func _queue_layout_refresh() -> void:
	call_deferred("_refresh_layout")

func _refresh_context() -> void:
	if objective_value_label == null:
		return
	objective_value_label.text = String(context_state.get("objective", ""))
	threat_value_label.text = String(context_state.get("threat", ""))
	hero_value_label.text = String(context_state.get("hero", ""))
	relic_value_label.text = String(context_state.get("relic", ""))

func _refresh_layout() -> void:
	if root_margin == null:
		return
	var viewport_size: Vector2 = layout_size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO and get_window() != null:
		viewport_size = Vector2(get_window().size)
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 680.0
	var very_compact: bool = viewport_size.x < 760.0 or viewport_size.y < 560.0
	root_margin.offset_right = clampf(viewport_size.x * (0.44 if very_compact else 0.39), 420.0, 680.0)
	root_margin.offset_bottom = clampf(viewport_size.y * (0.48 if very_compact else 0.40), 264.0, 420.0)
	panel_margin.add_theme_constant_override("margin_left", 10 if very_compact else (12 if compact else 14))
	panel_margin.add_theme_constant_override("margin_top", 10 if very_compact else (12 if compact else 14))
	panel_margin.add_theme_constant_override("margin_right", 10 if very_compact else (12 if compact else 14))
	panel_margin.add_theme_constant_override("margin_bottom", 10 if very_compact else (12 if compact else 14))
	info_grid.columns = 1 if very_compact else 2
	UISkin.label(title_label, 18 if very_compact else (21 if compact else 24), Color(0.98, 0.90, 0.66))
	UISkin.label(subtitle_label, 12 if very_compact else (13 if compact else 15), Color(0.86, 0.88, 0.92))
	UISkin.label(detail_label, 10 if very_compact else (11 if compact else 13), Color(0.70, 0.76, 0.84))
	for value_label in [objective_value_label, threat_value_label, hero_value_label, relic_value_label]:
		if value_label != null:
			UISkin.label(value_label, 11 if very_compact else 12, Color(0.88, 0.92, 0.98))
	UISkin.label(run_label, 10 if very_compact else 12, Color(0.82, 0.88, 0.96))
