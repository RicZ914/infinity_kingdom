extends CanvasLayer

const RunEffects := preload("res://systems/run/run_effects.gd")
const UISkin := preload("res://ui/ui_skin.gd")

var player_character: Node = null
var root_margin: MarginContainer
var root_panel: PanelContainer
var inner_margin: MarginContainer
var content: VBoxContainer
var title_label: Label
var hp_bar: TextureProgressBar
var hp_label: Label
var defense_bar: TextureProgressBar
var defense_label: Label
var inspiration_bar: TextureProgressBar
var inspiration_label: Label
var shield_label: Label
var state_label: Label
var status_grid: GridContainer
var control_label: Label
var combat_feed_label: Label
var run_state_label: Label
var accessory_icon: TextureRect
var accessory_name_label: Label
var accessory_tags_label: Label
var accessory_summary_label: Label
var accessory_grid: GridContainer
var skill_grid: GridContainer
var skill_slots: Dictionary = {}
var meter_bars: Array[TextureProgressBar] = []
var combat_feed_tween: Tween = null
var last_control_summary: String = ""
var layout_size_override: Vector2 = Vector2.ZERO
var skill_icon_paths := {
	"Knight": [
		"res://assets/ui/skill/knight_charge_slash.png",
		"res://assets/ui/skill/knight_counter_shock.png",
		"res://assets/ui/skill/knight_holy_field.png"
	],
	"Ranger": [
		"res://assets/ui/skill/ranger_wind_arrow.png",
		"res://assets/ui/skill/ranger_shadow_step.png",
		"res://assets/ui/skill/ranger_hunt_rush.png"
	],
	"Mage": [
		"res://assets/ui/skill/mage_blade_whirl.png",
		"res://assets/ui/skill/mage_arcane_burst.png",
		"res://assets/ui/skill/mage_silence_decree.png"
	]
}

func _ready() -> void:
	_build_ui()
	if AccessoryManager != null and not AccessoryManager.accessory_equipped.is_connected(_on_accessory_equipped):
		AccessoryManager.accessory_equipped.connect(_on_accessory_equipped)
	if RunDirector != null and not RunDirector.state_changed.is_connected(_on_run_state_changed):
		RunDirector.state_changed.connect(_on_run_state_changed)
	if UISettings != null and UISettings.has_signal("locale_changed") and not UISettings.locale_changed.is_connected(_on_locale_changed):
		UISettings.locale_changed.connect(_on_locale_changed)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_queue_layout_refresh):
		get_viewport().size_changed.connect(_queue_layout_refresh)
	_on_accessory_equipped(AccessoryManager.get_equipped_accessory())
	_on_run_state_changed(RunDirector.get_state())
	_queue_layout_refresh()

func bind_character(target: Node) -> void:
	player_character = target
	if player_character == null:
		return
	last_control_summary = ""
	title_label.text = "%s %s" % [_hero_display_name(String(player_character.get_character_name())), _locale_text("Combat Frame", "战斗面板", "戰鬥面板")]
	_refresh_skill_icons()
	_connect_character_signal("hp_changed", _on_hp_changed)
	_connect_character_signal("defense_changed", _on_defense_changed)
	_connect_character_signal("inspiration_changed", _on_inspiration_changed)
	_connect_character_signal("shield_changed", _on_shield_changed)
	_connect_character_signal("took_damage", _on_took_damage)
	_connect_character_signal("control_status_changed", _on_control_status_changed)
	_connect_character_signal("attack_started", _on_attack_started)
	_connect_character_signal("attack_hit", _on_attack_hit)
	_on_hp_changed(player_character.hp, player_character.max_hp)
	_on_defense_changed(player_character.defense, player_character.max_defense)
	_on_inspiration_changed(player_character.inspiration, player_character.max_inspiration)
	_on_shield_changed(player_character.shield)
	if player_character.has_method("get_control_status_text"):
		_on_control_status_changed(player_character.get_control_status_text())
	_on_accessory_equipped(AccessoryManager.get_equipped_accessory())
	_queue_layout_refresh()

func bind_knight(target: Node) -> void:
	bind_character(target)

func _process(_delta: float) -> void:
	if player_character == null or not is_instance_valid(player_character):
		return
	state_label.text = "%s %s" % [_locale_text("State", "状态", "狀態"), String(player_character.state_machine.get_state_name())]
	_update_skill_slots()
	_update_danger_visuals()
	_refresh_run_state_label(RunDirector.get_state())

func _build_ui() -> void:
	layer = 5
	root_margin = MarginContainer.new()
	root_margin.anchor_top = 1.0
	root_margin.anchor_bottom = 1.0
	root_margin.offset_left = 18.0
	root_margin.offset_top = -428.0
	root_margin.offset_right = 470.0
	root_margin.offset_bottom = -18.0
	root_margin.add_theme_constant_override("margin_left", 10)
	root_margin.add_theme_constant_override("margin_top", 10)
	root_margin.add_theme_constant_override("margin_right", 10)
	root_margin.add_theme_constant_override("margin_bottom", 10)
	add_child(root_margin)

	root_panel = PanelContainer.new()
	root_panel.add_theme_stylebox_override("panel", UISkin.panel_style())
	root_margin.add_child(root_panel)

	inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 12)
	inner_margin.add_theme_constant_override("margin_top", 12)
	inner_margin.add_theme_constant_override("margin_right", 12)
	inner_margin.add_theme_constant_override("margin_bottom", 12)
	root_panel.add_child(inner_margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	inner_margin.add_child(content)

	title_label = Label.new()
	title_label.text = _locale_text("Character Combat Frame", "角色战斗面板", "角色戰鬥面板")
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(title_label, 20, Color(0.98, 0.90, 0.66))
	content.add_child(title_label)

	content.add_child(_meter("hp", _locale_text("HP", "生命", "生命"), Color(0.82, 0.22, 0.20)))
	content.add_child(_meter("defense", _locale_text("Defense", "护甲", "護甲"), Color(0.34, 0.68, 0.82)))
	content.add_child(_meter("inspiration", _locale_text("Inspiration", "灵感", "靈感"), Color(0.30, 0.52, 0.95)))

	status_grid = GridContainer.new()
	status_grid.columns = 2
	status_grid.add_theme_constant_override("h_separation", 10)
	status_grid.add_theme_constant_override("v_separation", 4)
	content.add_child(status_grid)
	shield_label = _make_label(_locale_text("Shield 0", "护盾 0", "護盾 0"), 13, Color(0.82, 0.90, 0.98))
	state_label = _make_label(_locale_text("State Idle", "状态 Idle", "狀態 Idle"), 13, Color(0.82, 0.90, 0.98))
	shield_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_grid.add_child(shield_label)
	status_grid.add_child(state_label)

	control_label = _make_label(_locale_text("Status Stable", "状态 稳定", "狀態 穩定"), 12, Color(0.72, 0.88, 1.0))
	control_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(control_label)

	combat_feed_label = _make_label(_locale_text("Combat feed ready.", "战斗播报已就绪。", "戰鬥播報已就緒。"), 12, Color(0.90, 0.94, 1.0))
	combat_feed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_feed_label.custom_minimum_size.y = 22.0
	content.add_child(combat_feed_label)

	var skills_panel := PanelContainer.new()
	skills_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	content.add_child(skills_panel)

	skill_grid = GridContainer.new()
	skill_grid.columns = 4
	skill_grid.add_theme_constant_override("h_separation", 8)
	skill_grid.add_theme_constant_override("v_separation", 8)
	skills_panel.add_child(skill_grid)
	for key in ["attack", "skill1", "skill2", "skill3"]:
		var label_text := "J" if key == "attack" else ("K" if key == "skill1" else ("L" if key == "skill2" else "I"))
		var icon_path := "res://assets/ui/icon/stat_attack_pixel.png"
		if key != "attack":
			icon_path = "res://assets/ui/icon/ui_unknown.png"
		var slot_data := _skill_slot(key, label_text, icon_path)
		skill_slots[key] = slot_data
		skill_grid.add_child(slot_data["root"])

	var accessory_panel := PanelContainer.new()
	accessory_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	content.add_child(accessory_panel)

	accessory_grid = GridContainer.new()
	accessory_grid.columns = 2
	accessory_grid.add_theme_constant_override("h_separation", 10)
	accessory_grid.add_theme_constant_override("v_separation", 8)
	accessory_panel.add_child(accessory_grid)

	var slot := PanelContainer.new()
	slot.name = "AccessorySlot"
	slot.custom_minimum_size = Vector2(64, 64)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("panel", UISkin.icon_slot_style())
	accessory_grid.add_child(slot)

	accessory_icon = TextureRect.new()
	accessory_icon.custom_minimum_size = Vector2(52, 52)
	accessory_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	accessory_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(accessory_icon)

	var accessory_text := VBoxContainer.new()
	accessory_text.name = "AccessoryText"
	accessory_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accessory_text.add_theme_constant_override("separation", 4)
	accessory_grid.add_child(accessory_text)
	accessory_name_label = _make_label(_locale_text("No Accessory", "无饰品", "無飾品"), 15, Color.WHITE)
	accessory_tags_label = _make_label(_locale_text("Tags: None", "标签：无", "標籤：無"), 11, Color(0.88, 0.84, 0.66))
	accessory_summary_label = _make_label(_locale_text("Win encounters to claim relics.", "通过战斗来获取饰品。", "通過戰鬥來獲取飾品。"), 12, Color(0.72, 0.78, 0.86))
	accessory_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	accessory_text.add_child(accessory_name_label)
	accessory_text.add_child(accessory_tags_label)
	accessory_text.add_child(accessory_summary_label)

	var run_panel := PanelContainer.new()
	run_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	content.add_child(run_panel)

	run_state_label = _make_label(_locale_text("Gold 0 | Next Black Market", "金币 0 | 下一步 黑市", "金幣 0 | 下一步 黑市"), 12, Color(0.84, 0.90, 0.98))
	run_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run_panel.add_child(run_state_label)

func _meter(meter_id: String, label_text: String, _fill_color: Color) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var label := _make_label("%s 0 / 0" % label_text, 13, Color(0.86, 0.88, 0.92))
	box.add_child(label)
	var bar := TextureProgressBar.new()
	bar.custom_minimum_size = Vector2(386, 22)
	UISkin.texture_bar(bar, meter_id)
	meter_bars.append(bar)
	box.add_child(bar)
	match meter_id:
		"hp":
			hp_bar = bar
			hp_label = label
		"defense":
			defense_bar = bar
			defense_label = label
		"inspiration":
			inspiration_bar = bar
			inspiration_label = label
	return box

func _skill_slot(key: String, hotkey: String, icon_path: String) -> Dictionary:
	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(84, 76)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_stylebox_override("panel", UISkin.choice_panel_style())

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	root.add_child(stack)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.texture = load(icon_path) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stack.add_child(icon)

	var label := Label.new()
	label.text = _skill_ready_text(hotkey)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(label, 11, Color(0.86, 0.88, 0.92))
	stack.add_child(label)

	return {"root": root, "icon": icon, "label": label, "hotkey": hotkey, "key": key}

func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	UISkin.label(label, size, color)
	return label

func _connect_character_signal(signal_name: String, callable: Callable) -> void:
	if not player_character.has_signal(signal_name):
		return
	if not player_character.is_connected(StringName(signal_name), callable):
		player_character.connect(StringName(signal_name), callable)

func _on_hp_changed(current_hp: float, max_hp_value: float) -> void:
	hp_bar.value = 0.0 if max_hp_value <= 0.0 else clampf(current_hp / max_hp_value, 0.0, 1.0)
	hp_label.text = "%s %d / %d" % [_locale_text("HP", "生命", "生命"), int(round(current_hp)), int(round(max_hp_value))]

func _on_inspiration_changed(current_inspiration: float, max_inspiration_value: float) -> void:
	inspiration_bar.value = 0.0 if max_inspiration_value <= 0.0 else clampf(current_inspiration / max_inspiration_value, 0.0, 1.0)
	inspiration_label.text = "%s %d / %d" % [_locale_text("Inspiration", "灵感", "靈感"), int(round(current_inspiration)), int(round(max_inspiration_value))]

func _on_defense_changed(current_defense: float, max_defense_value: float) -> void:
	defense_bar.value = 0.0 if max_defense_value <= 0.0 else clampf(current_defense / max_defense_value, 0.0, 1.0)
	defense_label.text = "%s %d / %d" % [_locale_text("Defense", "护甲", "護甲"), int(round(current_defense)), int(round(max_defense_value))]

func _on_shield_changed(current_shield: float) -> void:
	shield_label.text = "%s %d" % [_locale_text("Shield", "护盾", "護盾"), int(round(current_shield))]

func _on_took_damage(amount: float, remaining_hp: float) -> void:
	if player_character != null and is_instance_valid(player_character):
		_on_shield_changed(player_character.shield)
	var max_hp_value := float(player_character.max_hp) if player_character != null and is_instance_valid(player_character) else 0.0
	var hp_ratio := 0.0 if max_hp_value <= 0.0 else clampf(remaining_hp / max_hp_value, 0.0, 1.0)
	if amount > 0.0:
		if hp_ratio <= 0.25:
			_set_combat_feed(_locale_text("Danger %.0f HP", "危险血量 %.0f", "危險血量 %.0f") % remaining_hp, Color(1.0, 0.72, 0.68), 1.06)
		else:
			_set_combat_feed(_locale_text("Took %.0f damage", "受到 %.0f 伤害", "受到 %.0f 傷害") % amount, Color(1.0, 0.84, 0.76), 1.04)

func _on_control_status_changed(summary: String) -> void:
	if control_label == null:
		return
	if summary.is_empty():
		control_label.text = "%s %s" % [_locale_text("Status", "状态", "狀態"), _locale_text("Stable", "稳定", "穩定")]
		control_label.modulate = Color(0.72, 0.88, 1.0)
		if not last_control_summary.is_empty():
			_set_combat_feed(_locale_text("Steady", "已稳定", "已穩定"), Color(0.98, 0.90, 0.68), 1.05)
		last_control_summary = ""
		return
	control_label.text = "%s %s" % [_locale_text("Status", "状态", "狀態"), summary]
	control_label.modulate = Color(1.0, 0.84, 0.64)
	if summary != last_control_summary:
		_set_combat_feed(summary, Color(0.90, 0.82, 1.0), 1.04)
	last_control_summary = summary

func _on_attack_started(attack_name: StringName) -> void:
	if attack_name == &"attack":
		return
	_set_combat_feed(_locale_text("%s ready", "%s 就绪", "%s 就緒") % _attack_display_name(attack_name), Color(0.84, 0.90, 1.0), 1.04)

func _on_attack_hit(attack_name: StringName, target: Node) -> void:
	var action_label := _attack_display_name(attack_name)
	var target_defeated := _is_target_defeated(target)
	if target_defeated:
		_set_combat_feed(_locale_text("%s finished the target", "%s 完成击杀", "%s 完成擊殺") % action_label, Color(1.0, 0.86, 0.66), 1.08)
	elif attack_name == &"attack":
		_set_combat_feed(_locale_text("Hit confirmed", "命中确认", "命中確認"), Color(0.86, 0.96, 1.0), 1.03)
	else:
		_set_combat_feed(_locale_text("%s landed", "%s 命中", "%s 命中") % action_label, Color(0.88, 1.0, 0.82), 1.05)

func _on_accessory_equipped(accessory: Dictionary) -> void:
	if accessory_icon == null:
		return
	accessory_icon.texture = load(String(accessory.get("icon", "res://assets/ui/icon/ui_unknown.png"))) as Texture2D
	accessory_name_label.text = String(accessory.get("name", _locale_text("No Accessory", "无饰品", "無飾品")))
	var tags := AccessoryManager.describe_tags(accessory.get("tags", []))
	accessory_tags_label.text = "%s %s" % [_locale_text("Tags:", "标签：", "標籤："), tags if not tags.is_empty() else _locale_text("None", "无", "無")]
	var playstyle_text := AccessoryManager.describe_playstyle(accessory.get("tags", []))
	var summary_parts: Array[String] = []
	var summary_text := String(accessory.get("summary", ""))
	if not summary_text.is_empty():
		summary_parts.append(summary_text)
	if not playstyle_text.is_empty():
		summary_parts.append(playstyle_text)
	accessory_summary_label.text = "\n".join(summary_parts)

func _on_run_state_changed(state: Dictionary) -> void:
	if run_state_label == null:
		return
	_refresh_run_state_label(state)

func _refresh_run_state_label(state: Dictionary) -> void:
	if run_state_label == null:
		return
	var next_kind := String(state.get("next_event_kind", ""))
	var next_label := RunDirector.describe_event_kind(next_kind) if not next_kind.is_empty() else _locale_text("Victory", "胜利", "勝利")
	var reward_flat_bonus := int(state.get("reward_flat_bonus", 0))
	var reward_multiplier := float(state.get("reward_multiplier", 1.0))
	var pending_prep := state.get("pending_encounter_prep", {}) as Dictionary
	var reward_bonus_text := ""
	if reward_flat_bonus > 0 or reward_multiplier > 1.001:
		var parts: Array[String] = []
		if reward_flat_bonus > 0:
			parts.append(_locale_text("+%d gold", "+%d 金币", "+%d 金幣") % reward_flat_bonus)
		if reward_multiplier > 1.001:
			parts.append(_locale_text("x%.2f reward", "x%.2f 奖励", "x%.2f 獎勵") % reward_multiplier)
		reward_bonus_text = "  |  %s" % " ".join(parts)
	var prep_text := ""
	var current_scene := get_tree().current_scene
	if current_scene != null:
		var active_prep := current_scene.get("active_encounter_prep") as Dictionary
		if not active_prep.is_empty():
			prep_text = _locale_text("  |  Prep %s", "  |  准备 %s", "  |  準備 %s") % String(active_prep.get("title", _locale_text("Active", "生效中", "生效中")))
	if prep_text.is_empty() and not pending_prep.is_empty():
		prep_text = _locale_text("  |  Prep %s", "  |  准备 %s", "  |  準備 %s") % String(pending_prep.get("title", _locale_text("Queued", "已排队", "已排隊")))
	prep_text = _prep_run_text(current_scene, pending_prep)
	run_state_label.text = "%s %d  |  %s +%d  |  %s %s%s%s" % [
		_locale_text("Gold", "金币", "金幣"),
		int(state.get("gold", 0)),
		_locale_text("Last", "上次", "上次"),
		int(state.get("last_reward_gold", 0)),
		_locale_text("Next", "下一步", "下一步"),
		next_label,
		prep_text,
		reward_bonus_text
	]

func _on_locale_changed(_locale: String) -> void:
	if player_character != null and is_instance_valid(player_character):
		title_label.text = "%s %s" % [_hero_display_name(String(player_character.get_character_name())), _locale_text("Combat Frame", "战斗面板", "戰鬥面板")]
		_on_hp_changed(player_character.hp, player_character.max_hp)
		_on_defense_changed(player_character.defense, player_character.max_defense)
		_on_inspiration_changed(player_character.inspiration, player_character.max_inspiration)
		_on_shield_changed(player_character.shield)
	_on_accessory_equipped(AccessoryManager.get_equipped_accessory())
	_refresh_run_state_label(RunDirector.get_state())

func _refresh_skill_icons() -> void:
	if player_character == null or not is_instance_valid(player_character):
		return
	var character_name := String(player_character.get_character_name())
	var icons: Array = skill_icon_paths.get(character_name, [])
	for index in range(icons.size()):
		var slot_key := "skill%d" % (index + 1)
		if not skill_slots.has(slot_key):
			continue
		var slot: Dictionary = skill_slots[slot_key]
		var icon: TextureRect = slot["icon"]
		icon.texture = load(String(icons[index])) as Texture2D

func _update_skill_slots() -> void:
	if player_character == null or not is_instance_valid(player_character):
		return
	for key in skill_slots.keys():
		var slot: Dictionary = skill_slots[key]
		var label: Label = slot["label"]
		var cooldown := float(player_character.cooldowns.get(key, 0.0))
		if cooldown <= 0.05:
			label.text = _skill_ready_text(String(slot["hotkey"]))
			label.modulate = Color(0.78, 1.0, 0.78)
		else:
			label.text = "%s %.1f" % [String(slot["hotkey"]), cooldown]
			label.modulate = Color(1.0, 0.80, 0.62)

func _prep_run_text(current_scene: Node, pending_prep: Dictionary) -> String:
	var active_prep: Dictionary = {}
	if current_scene != null:
		active_prep = current_scene.get("active_encounter_prep") as Dictionary
	if not active_prep.is_empty():
		return _locale_text("  |  Prep %s", "  |  准备 %s", "  |  準備 %s") % RunEffects.prep_title(active_prep)
	if not pending_prep.is_empty():
		return _locale_text("  |  Prep %s", "  |  准备 %s", "  |  準備 %s") % RunEffects.prep_title(pending_prep)
	return ""

func _update_danger_visuals() -> void:
	if player_character == null or not is_instance_valid(player_character):
		return
	var max_hp_value := float(player_character.max_hp)
	var hp_ratio := 0.0 if max_hp_value <= 0.0 else clampf(float(player_character.hp) / max_hp_value, 0.0, 1.0)
	if hp_ratio <= 0.30:
		var pulse := 0.78 + 0.22 * sin(Time.get_ticks_msec() * 0.01)
		hp_label.modulate = Color(1.0, 0.70 + 0.12 * pulse, 0.70 + 0.10 * pulse, 1.0)
		hp_bar.modulate = Color(1.0, 0.92, 0.92, 0.92 + 0.08 * pulse)
	else:
		hp_label.modulate = Color.WHITE
		hp_bar.modulate = Color.WHITE

func _set_combat_feed(text: String, color_value: Color, scale_value: float = 1.0) -> void:
	if combat_feed_label == null:
		return
	combat_feed_label.text = text
	combat_feed_label.modulate = color_value
	combat_feed_label.scale = Vector2.ONE * scale_value
	if combat_feed_tween != null:
		combat_feed_tween.kill()
	combat_feed_tween = create_tween()
	combat_feed_tween.tween_property(combat_feed_label, "scale", Vector2.ONE, 0.16)

func _attack_display_name(attack_name: StringName) -> String:
	var character_name := String(player_character.get_character_name()) if player_character != null and is_instance_valid(player_character) and player_character.has_method("get_character_name") else ""
	match character_name:
		"Knight":
			match attack_name:
				&"skill1":
					return _locale_text("Charge Slash", "冲锋斩", "衝鋒斬")
				&"skill2":
					return _locale_text("Counter Shock", "反震冲击", "反震衝擊")
				&"skill3":
					return _locale_text("Holy Field", "圣域", "聖域")
		"Ranger":
			match attack_name:
				&"skill1":
					return _locale_text("Piercing Arrow", "穿刺箭", "穿刺箭")
				&"skill2":
					return _locale_text("Shadow Step", "影步", "影步")
				&"skill3":
					return _locale_text("Hunt Rush", "猎袭", "獵襲")
		"Mage":
			match attack_name:
				&"skill1":
					return _locale_text("Arcane Blades", "奥术刃群", "奧術刃群")
				&"skill2":
					return _locale_text("Arcane Burst", "奥术爆裂", "奧術爆裂")
				&"skill3":
					return _locale_text("Silence Decree", "沉默敕令", "沉默敕令")
	match attack_name:
		&"attack":
			return _locale_text("Attack", "普攻", "普攻")
		&"skill1_bonus":
			return _locale_text("Blade Echo", "刃响回声", "刃響回聲")
		_:
			return String(attack_name).capitalize()

func _skill_ready_text(hotkey: String) -> String:
	return _locale_text("%s Ready", "%s 就绪", "%s 就緒") % hotkey

func _is_target_defeated(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	for property in target.get_property_list():
		if String(property.get("name", "")) == "hp":
			return float(target.get("hp")) <= 0.0
	return false

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

func _hero_display_name(hero_name: String) -> String:
	match hero_name:
		"Knight":
			return _locale_text("Knight", "骑士", "騎士")
		"Ranger":
			return _locale_text("Ranger", "游侠", "遊俠")
		"Mage":
			return _locale_text("Mage", "法师", "法師")
		_:
			return hero_name

func _queue_layout_refresh() -> void:
	call_deferred("_refresh_layout")

func _refresh_layout() -> void:
	if root_margin == null:
		return
	var viewport_size: Vector2 = layout_size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO and get_window() != null:
		viewport_size = Vector2(get_window().size)
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 720.0
	var very_compact: bool = viewport_size.x < 780.0 or viewport_size.y < 620.0
	var panel_width := clampf(viewport_size.x * (0.34 if very_compact else 0.28), 292.0, 470.0)
	root_margin.offset_right = panel_width
	root_margin.offset_top = -clampf(viewport_size.y * (0.46 if very_compact else 0.40), 300.0, 428.0)
	root_margin.offset_left = 10.0 if very_compact else 18.0
	root_margin.offset_bottom = -10.0 if very_compact else -18.0
	root_margin.add_theme_constant_override("margin_left", 8 if very_compact else 10)
	root_margin.add_theme_constant_override("margin_top", 8 if very_compact else 10)
	root_margin.add_theme_constant_override("margin_right", 8 if very_compact else 10)
	root_margin.add_theme_constant_override("margin_bottom", 8 if very_compact else 10)
	inner_margin.add_theme_constant_override("margin_left", 10 if very_compact else 12)
	inner_margin.add_theme_constant_override("margin_top", 10 if very_compact else 12)
	inner_margin.add_theme_constant_override("margin_right", 10 if very_compact else 12)
	inner_margin.add_theme_constant_override("margin_bottom", 10 if very_compact else 12)
	content.add_theme_constant_override("separation", 6 if compact else 8)
	status_grid.columns = 1 if very_compact else 2
	skill_grid.columns = 2 if very_compact else 4
	skill_grid.add_theme_constant_override("h_separation", 6 if compact else 8)
	skill_grid.add_theme_constant_override("v_separation", 6 if compact else 8)
	accessory_grid.columns = 1 if very_compact else 2
	accessory_grid.add_theme_constant_override("h_separation", 8 if compact else 10)
	accessory_grid.add_theme_constant_override("v_separation", 6 if compact else 8)
	UISkin.label(title_label, 16 if very_compact else (18 if compact else 20), Color(0.98, 0.90, 0.66))
	UISkin.label(hp_label, 11 if compact else 13, Color(0.86, 0.88, 0.92))
	UISkin.label(defense_label, 11 if compact else 13, Color(0.86, 0.88, 0.92))
	UISkin.label(inspiration_label, 11 if compact else 13, Color(0.86, 0.88, 0.92))
	UISkin.label(shield_label, 11 if compact else 13, Color(0.82, 0.90, 0.98))
	UISkin.label(state_label, 11 if compact else 13, Color(0.82, 0.90, 0.98))
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if very_compact else HORIZONTAL_ALIGNMENT_RIGHT
	UISkin.label(control_label, 10 if compact else 12, Color(0.72, 0.88, 1.0))
	UISkin.label(combat_feed_label, 10 if compact else 12, Color(0.90, 0.94, 1.0))
	UISkin.label(accessory_name_label, 13 if compact else 15, Color.WHITE)
	UISkin.label(accessory_tags_label, 10 if compact else 11, Color(0.88, 0.84, 0.66))
	UISkin.label(accessory_summary_label, 10 if compact else 12, Color(0.72, 0.78, 0.86))
	UISkin.label(run_state_label, 10 if compact else 12, Color(0.84, 0.90, 0.98))
	for bar in meter_bars:
		bar.custom_minimum_size = Vector2(panel_width - (52.0 if very_compact else 72.0), 18.0 if compact else 22.0)
	var slot_width := 60.0 if very_compact else (72.0 if compact else 84.0)
	var slot_height := 64.0 if very_compact else (70.0 if compact else 76.0)
	for slot_data in skill_slots.values():
		var root: PanelContainer = slot_data["root"]
		var icon: TextureRect = slot_data["icon"]
		var label: Label = slot_data["label"]
		root.custom_minimum_size = Vector2(slot_width, slot_height)
		icon.custom_minimum_size = Vector2(34.0 if very_compact else 40.0, 34.0 if very_compact else 40.0)
		UISkin.label(label, 9 if very_compact else 11, Color(0.86, 0.88, 0.92))
	var accessory_slot := accessory_grid.get_node("AccessorySlot") as PanelContainer
	if accessory_slot != null:
		accessory_slot.custom_minimum_size = Vector2(56.0 if compact else 64.0, 56.0 if compact else 64.0)
	accessory_icon.custom_minimum_size = Vector2(44.0 if compact else 52.0, 44.0 if compact else 52.0)
