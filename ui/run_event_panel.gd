extends CanvasLayer

signal event_choice_made(choice_id: String)

const RunEffects := preload("res://systems/run/run_effects.gd")
const UICardFx := preload("res://ui/ui_card_fx.gd")
const UISkin := preload("res://ui/ui_skin.gd")
const PANEL_MIN_SIZE := Vector2(340, 400)
const PANEL_MAX_SIZE := Vector2(1080, 640)
const CARD_MIN_WIDTH := 236.0
const CARD_GAP := 12.0

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Backdrop/CenterContainer/PanelContainer
@onready var panel_margin: MarginContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer
@onready var title_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var subtitle_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Subtitle
@onready var context_panel: PanelContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContextPanel
@onready var build_summary_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContextPanel/MarginContainer/VBoxContainer/BuildSummary
@onready var rule_summary_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContextPanel/MarginContainer/VBoxContainer/RuleSummary
@onready var choice_scroll: ScrollContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ChoiceScroll
@onready var choice_row: GridContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ChoiceScroll/ChoiceRow
@onready var detail_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Detail
@onready var footer_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer

var active_kind: String = ""
var active_gold: int = 0
var active_default_detail: String = ""
var choice_buttons: Array[Button] = []
var layout_size_override: Vector2 = Vector2.ZERO

func _ready() -> void:
	layer = 18
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	backdrop.color = Color(0.015, 0.018, 0.026, 0.72)
	panel.add_theme_stylebox_override("panel", UISkin.menu_panel_style())
	context_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(title_label, 28, Color(0.98, 0.90, 0.66))
	UISkin.label(subtitle_label, 15, Color(0.78, 0.84, 0.92))
	UISkin.label(build_summary_label, 12, Color(0.90, 0.92, 0.98))
	UISkin.label(rule_summary_label, 12, Color(0.78, 0.84, 0.92))
	UISkin.label(detail_label, 12, Color(0.92, 0.86, 0.72))
	UISkin.label(footer_label, 13, Color(0.74, 0.80, 0.88))
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_queue_layout_refresh):
		get_viewport().size_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()

func open(kind: String, gold: int) -> void:
	active_kind = kind
	active_gold = gold
	_rebuild(kind, gold)
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _rebuild(kind: String, gold: int) -> void:
	choice_buttons.clear()
	for child in choice_row.get_children():
		choice_row.remove_child(child)
		child.queue_free()
	_refresh_context(kind, gold)
	active_default_detail = _default_detail_for_kind(kind)
	match kind:
		"shop":
			title_label.text = UIText.text("event_shop_title")
			subtitle_label.text = UIText.text("event_shop_subtitle")
			choice_row.add_child(_choice_card("shop_attack", RunEffects.display_name("shop_attack"), RunEffects.card_summary("shop_attack"), "res://assets/ui/consumable/sharpening_oil.png", 45, gold))
			choice_row.add_child(_choice_card("shop_defense", RunEffects.display_name("shop_defense"), RunEffects.card_summary("shop_defense"), "res://assets/ui/consumable/light_armor_pack.png", 40, gold))
			choice_row.add_child(_choice_card("shop_relic", RunEffects.display_name("shop_relic"), RunEffects.card_summary("shop_relic"), "res://assets/ui/icon/ui_shop.png", 55, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Save Gold", "保留金币", "保留金幣"), _locale_text("Keep your gold for a later event.", "把金币留给后面的事件。", "把金幣留給後面的事件。"), "res://assets/ui/icon/currency_gold_pixel.png", 0, gold))
		"bounty":
			title_label.text = UIText.text("event_bounty_title")
			subtitle_label.text = UIText.text("event_bounty_subtitle")
			choice_row.add_child(_choice_card("bounty_cache", RunEffects.display_name("bounty_cache"), RunEffects.card_summary("bounty_cache"), "res://assets/ui/icon/currency_gold_pixel.png", 0, gold))
			choice_row.add_child(_choice_card("bounty_contract", RunEffects.display_name("bounty_contract"), RunEffects.card_summary("bounty_contract"), "res://assets/ui/icon/ui_shop.png", 0, gold))
			choice_row.add_child(_choice_card("bounty_tithe", RunEffects.display_name("bounty_tithe"), RunEffects.card_summary("bounty_tithe"), "res://assets/ui/trait/trait_execute.png", 0, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Walk Past", "直接离开", "直接離開"), _locale_text("Keep the build unchanged and move on.", "保持当前构筑，继续前进。", "保持當前構築，繼續前進。"), "res://assets/ui/icon/ui_back.png", 0, gold))
		"rest":
			title_label.text = UIText.text("event_rest_title")
			subtitle_label.text = UIText.text("event_rest_subtitle")
			choice_row.add_child(_choice_card("rest_heal", RunEffects.display_name("rest_heal"), RunEffects.card_summary("rest_heal"), "res://assets/ui/consumable/medkit.png", 0, gold))
			choice_row.add_child(_choice_card("rest_focus", RunEffects.display_name("rest_focus"), RunEffects.card_summary("rest_focus"), "res://assets/ui/consumable/protective_candle.png", 0, gold))
			choice_row.add_child(_choice_card("rest_repair", RunEffects.display_name("rest_repair"), RunEffects.card_summary("rest_repair"), "res://assets/ui/icon/ui_shield.png", 0, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Push Forward", "继续前进", "繼續前進"), _locale_text("Skip recovery and continue.", "跳过恢复，继续前进。", "跳過恢復，繼續前進。"), "res://assets/ui/icon/ui_check.png", 0, gold))
		"training":
			title_label.text = UIText.text("event_training_title")
			subtitle_label.text = UIText.text("event_training_subtitle")
			choice_row.add_child(_choice_card("train_crit", RunEffects.display_name("train_crit"), RunEffects.card_summary("train_crit"), "res://assets/ui/trait/trait_crit.png", 0, gold))
			choice_row.add_child(_choice_card("train_speed", RunEffects.display_name("train_speed"), RunEffects.card_summary("train_speed"), "res://assets/ui/icon/stat_speed_pixel.png", 0, gold))
			choice_row.add_child(_choice_card("train_cooldown", RunEffects.display_name("train_cooldown"), RunEffects.card_summary("train_cooldown"), "res://assets/ui/icon/stat_cooldown_pixel.png", 0, gold))
			choice_row.add_child(_choice_card("train_resource", RunEffects.display_name("train_resource"), RunEffects.card_summary("train_resource"), "res://assets/ui/icon/stat_mana_pixel.png", 0, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Leave the Yard", "离开训练场", "離開訓練場"), _locale_text("Skip training and keep the build unchanged.", "跳过训练，保持当前构筑。", "跳過訓練，保持當前構築。"), "res://assets/ui/icon/ui_back.png", 0, gold))
		"forge":
			title_label.text = UIText.text("event_forge_title")
			subtitle_label.text = UIText.text("event_forge_subtitle")
			for choice in RunEffects.forge_choices(_current_actor()):
				choice_row.add_child(_choice_card_from_data(choice, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Leave the Forge", "离开熔炉", "離開熔爐"), _locale_text("Keep the current build and move on.", "保持当前构筑不变，继续前进。", "保持當前構築不變，繼續前進。"), "res://assets/ui/icon/ui_back.png", 0, gold))
		"pact":
			title_label.text = UIText.text("event_pact_title")
			subtitle_label.text = UIText.text("event_pact_subtitle")
			choice_row.add_child(_choice_card("pact_power", RunEffects.display_name("pact_power"), RunEffects.card_summary("pact_power"), "res://assets/ui/trait/trait_damage.png", 0, gold))
			choice_row.add_child(_choice_card("pact_guard", RunEffects.display_name("pact_guard"), RunEffects.card_summary("pact_guard"), "res://assets/ui/icon/ui_shield.png", 0, gold))
			choice_row.add_child(_choice_card("pact_focus", RunEffects.display_name("pact_focus"), RunEffects.card_summary("pact_focus"), "res://assets/ui/icon/ui_mana_flame.png", 0, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Refuse", "拒绝", "拒絕"), _locale_text("Walk away without changing the build.", "不改变构筑，直接离开。", "不改變構築，直接離開。"), "res://assets/ui/icon/ui_back.png", 0, gold))
		"attunement":
			var tags_text := AccessoryManager.describe_tags()
			title_label.text = UIText.text("event_attunement_title")
			subtitle_label.text = UIText.text("event_attunement_subtitle", {
				"path": tags_text if not tags_text.is_empty() else _locale_text("an unknown path", "未知路线", "未知路線")
			})
			for choice in RunEffects.attunement_choices():
				choice_row.add_child(_choice_card_from_data(choice, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Leave It Still", "维持原样", "維持原樣"), _locale_text("Keep the relic unchanged and move on.", "保持当前饰品不变，继续前进。", "保持當前飾品不變，繼續前進。"), "res://assets/ui/icon/ui_back.png", 0, gold))
		"scout":
			title_label.text = UIText.text("event_scout_title")
			subtitle_label.text = UIText.text("event_scout_subtitle")
			for choice in RunEffects.scout_choices():
				choice_row.add_child(_choice_card_from_data(choice, gold))
			choice_row.add_child(_choice_card("skip", _locale_text("Ignore the Report", "忽略报告", "忽略報告"), _locale_text("Keep your current opener and fight without extra prep.", "保持当前开局方式，不做额外准备。", "保持當前開局方式，不做額外準備。"), "res://assets/ui/icon/ui_back.png", 0, gold))
		_:
			title_label.text = UIText.text("event_travel_title")
			subtitle_label.text = UIText.text("event_travel_subtitle")
			choice_row.add_child(_choice_card("skip", UIText.text("event_skip_continue"), _locale_text("Move to the next encounter.", "前往下一场遭遇。", "前往下一場遭遇。"), "res://assets/ui/icon/ui_check.png", 0, gold))
	detail_label.text = active_default_detail
	footer_label.text = _footer_text_for_kind(kind)
	_refresh_layout()
	call_deferred("_focus_first_choice")

func _choice_card_from_data(choice: Dictionary, gold: int) -> Button:
	return _choice_card(
		String(choice.get("id", "")),
		String(choice.get("title", "Choice")),
		String(choice.get("summary", "")),
		String(choice.get("icon", "res://assets/ui/icon/ui_unknown.png")),
		int(choice.get("cost", 0)),
		gold
	)

func _choice_card(choice_id: String, title: String, summary: String, icon_path: String, cost: int, gold: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(236, 274)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.disabled = cost > gold
	button.add_theme_stylebox_override("normal", UISkin.choice_panel_style())
	button.add_theme_stylebox_override("hover", UISkin.flat_style(Color(0.20, 0.22, 0.26, 0.98), UISkin.COLOR_ACCENT, 2, 4, Vector4(16, 14, 16, 14)))
	button.add_theme_stylebox_override("pressed", UISkin.flat_style(Color(0.12, 0.13, 0.16, 1.0), UISkin.COLOR_ACCENT.darkened(0.18), 2, 4, Vector4(16, 14, 16, 14)))
	button.add_theme_stylebox_override("disabled", UISkin.flat_style(Color(0.12, 0.13, 0.15, 0.72), Color(0.34, 0.36, 0.40, 0.8), 1, 4, Vector4(16, 14, 16, 14)))
	button.set_meta("choice_id", choice_id)
	choice_buttons.append(button)
	var tilt_root := UICardFx.install(button, {
		"active_scale": 1.024,
		"rotation_max": 2.4,
		"float_offset": Vector2(5.0, 3.0),
		"sheen_alpha": 0.10
	})

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 16
	margin.offset_top = 16
	margin.offset_right = -16
	margin.offset_bottom = -16
	tilt_root.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var meta := _choice_meta(choice_id, cost)
	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 6)
	box.add_child(badge_row)
	badge_row.add_child(_badge(String(meta.get("type", "Choice")), meta.get("color", Color(0.82, 0.86, 0.96))))
	var fit_data := RunEffects.evaluate_choice(choice_id, _current_actor())
	var fit_label := String(fit_data.get("label", meta.get("timing", "Now")))
	if _current_locale() != "en":
		fit_label = _localized_fit_label(fit_label)
	badge_row.add_child(_badge(fit_label, fit_data.get("color", meta.get("timing_color", Color(0.92, 0.84, 0.66)))))

	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(88, 88)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("panel", UISkin.icon_slot_style())
	box.add_child(slot)
	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(icon_path) as Texture2D
	slot.add_child(icon)

	var title_text := Label.new()
	title_text.text = title
	title_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(title_text, 18, Color.WHITE)
	box.add_child(title_text)

	var summary_label := Label.new()
	summary_label.text = summary
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.custom_minimum_size = Vector2(0, 70)
	UISkin.label(summary_label, 13, Color(0.78, 0.84, 0.92))
	box.add_child(summary_label)

	var cost_label := Label.new()
	cost_label.text = UIText.text("event_cost_gold", {"gold": cost}) if cost > 0 else UIText.text("event_cost_free")
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(cost_label, 13, Color(1.0, 0.86, 0.55) if not button.disabled else Color(0.72, 0.54, 0.48))
	box.add_child(cost_label)

	UISkin.ignore_mouse_recursive(margin)
	UICardFx.bind(button, func() -> void: _preview_choice(choice_id, title, summary, cost, button.disabled))
	button.pressed.connect(func() -> void:
		close()
		event_choice_made.emit(choice_id)
	)
	return button

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				_activate_choice_index(0)
				get_viewport().set_input_as_handled()
			KEY_2, KEY_KP_2:
				_activate_choice_index(1)
				get_viewport().set_input_as_handled()
			KEY_3, KEY_KP_3:
				_activate_choice_index(2)
				get_viewport().set_input_as_handled()
			KEY_4, KEY_KP_4:
				_activate_choice_index(3)
				get_viewport().set_input_as_handled()
			KEY_5, KEY_KP_5:
				_activate_choice_index(4)
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_activate_skip_choice()
				get_viewport().set_input_as_handled()

func _activate_choice_index(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= choice_buttons.size():
		return
	var button := choice_buttons[choice_index]
	if button == null or button.disabled:
		return
	button.grab_focus()
	button.emit_signal("pressed")

func _activate_skip_choice() -> void:
	for button in choice_buttons:
		if button != null and String(button.get_meta("choice_id", "")) == "skip" and not button.disabled:
			button.grab_focus()
			button.emit_signal("pressed")
			return

func _queue_layout_refresh() -> void:
	call_deferred("_refresh_layout")

func _refresh_context(kind: String, gold: int) -> void:
	var equipped_accessory := AccessoryManager.get_equipped_accessory()
	var accessory_name := String(equipped_accessory.get("name", _locale_text("No Accessory", "无饰品", "無飾品")))
	var tags_text := AccessoryManager.describe_tags(equipped_accessory.get("tags", []))
	var route_preview := RunDirector.describe_event_route(4)
	build_summary_label.text = "%s %d  |  %s %s%s" % [
		_locale_text("Gold", "金币", "金幣"),
		gold,
		_locale_text("Relic", "饰品", "飾品"),
		accessory_name,
		("  |  %s" % tags_text) if not tags_text.is_empty() else ""
	]
	rule_summary_label.text = "%s\n%s %s" % [_rule_summary_for_kind(kind), UIText.text("event_route_label"), route_preview]

func _rule_summary_for_kind(kind: String) -> String:
	match kind:
		"shop":
			return _locale_text("Buy one focused upgrade now. Economy spent here is gone immediately.", "先拿一项明确强化，这里花掉的金币会立刻结算。", "先拿一項明確強化，這裡花掉的金幣會立刻結算。")
		"bounty":
			return _locale_text("Bounties shape your economy. Immediate gold spikes now, contracts pay through later fights.", "悬赏会改变经济曲线：现在拿现钱，或把收益压到后续战斗。", "懸賞會改變經濟曲線：現在拿現錢，或把收益壓到後續戰鬥。")
		"rest":
			return _locale_text("Recovery is immediate and does not change your long-term route.", "恢复会立刻生效，不改变长期路线。", "恢復會立刻生效，不改變長期路線。")
		"training":
			return _locale_text("Training permanently boosts one lane for the rest of the run.", "训练会永久强化一条路线，持续到本局结束。", "訓練會永久強化一條路線，持續到本局結束。")
		"forge":
			return _locale_text("The forge offers hybrid permanent upgrades tuned to your current build.", "熔炉会给出更偏构筑成型的复合永久强化。", "熔爐會給出更偏構築成型的複合永久強化。")
		"pact":
			return _locale_text("Pacts are permanent. They raise power now and reshape future fights.", "契约是永久收益，也会永久改变后续战斗。", "契約是永久收益，也會永久改變後續戰鬥。")
		"attunement":
			return _locale_text("Attunement follows your relic tags and lasts for the rest of this run.", "共鸣会顺着当前饰品路线延伸，并持续到本局结束。", "共鳴會順著當前飾品路線延伸，並持續到本局結束。")
		"scout":
			return _locale_text("Scout routes are single-encounter spikes. Pick the opener that solves the very next fight.", "侦查路线只强化下一场战斗，优先解决眼前战局。", "偵查路線只強化下一場戰鬥，優先解決眼前戰局。")
		_:
			return _locale_text("Move on when you are ready.", "准备好后继续前进。", "準備好後繼續前進。")

func _default_detail_for_kind(kind: String) -> String:
	match kind:
		"shop":
			return _locale_text("Choose a purchase if it sharpens the next boss check. Saving gold keeps later options open.", "如果它能明显改善下一场 Boss 检定，就值得购买；不买则保留后手。", "如果它能明顯改善下一場 Boss 檢定，就值得購買；不買則保留後手。")
		"bounty":
			return _locale_text("Take cash now if a reroll or purchase is coming. Contracts are stronger when more encounters remain.", "如果后面准备重抽或购物，先拿现钱；剩余战斗越多，长期契约越值。", "如果後面準備重抽或購物，先拿現錢；剩餘戰鬥越多，長期契約越值。")
		"rest":
			return _locale_text("Take health if survival is shaky, or recover defense and inspiration if your build is already stable.", "生存压力大就补血，构筑稳定就回护甲和灵感。", "生存壓力大就補血，構築穩定就回護甲和靈感。")
		"training":
			return _locale_text("Training is permanent. Pick the lane your current relic and hero already reward.", "训练是永久收益，优先强化角色与饰品已经在奖励的方向。", "訓練是永久收益，優先強化角色與飾品已經在獎勵的方向。")
		"forge":
			return _locale_text("Forge options are mixed upgrades. Use them to round out a weakness or lock in a winning lane.", "熔炉给的是复合强化，既能补短板，也能把已经成型的路线彻底定住。", "熔爐給的是複合強化，既能補短板，也能把已經成型的路線徹底定住。")
		"pact":
			return _locale_text("Every pact is a commitment. Look for the tradeoff your current hero can absorb best.", "每个契约都是承诺，找你当前角色最扛得住的代价。", "每個契約都是承諾，找你當前角色最扛得住的代價。")
		"attunement":
			return _locale_text("Resonance is the cleanest way to reinforce your current relic identity.", "共鸣最适合继续放大当前饰品路线。", "共鳴最適合繼續放大當前飾品路線。")
		"scout":
			return _locale_text("Scout routes are short-term plans. Pick aggression, stability, or skill tempo for the next arena only.", "侦查是短期规划，只为下一张战场选择进攻、稳健或技能节奏。", "偵查是短期規劃，只為下一張戰場選擇進攻、穩健或技能節奏。")
		_:
			return _locale_text("Choose a path and continue.", "选好路线后继续前进。", "選好路線後繼續前進。")

func _footer_text_for_kind(kind: String) -> String:
	var shortcut_count := mini(maxi(choice_row.get_child_count(), 1), 5)
	var lead := UIText.text("event_footer_base", {"count": shortcut_count})
	if _has_skip_choice():
		lead += UIText.text("event_footer_skip")
	match kind:
		"shop":
			return UIText.text("event_footer_shop", {"lead": lead})
		"bounty":
			return UIText.text("event_footer_bounty", {"lead": lead})
		"rest":
			return UIText.text("event_footer_rest", {"lead": lead})
		"training":
			return UIText.text("event_footer_training", {"lead": lead})
		"forge":
			return UIText.text("event_footer_forge", {"lead": lead})
		"pact":
			return UIText.text("event_footer_pact", {"lead": lead})
		"attunement":
			return UIText.text("event_footer_attunement", {"lead": lead})
		"scout":
			return UIText.text("event_footer_scout", {"lead": lead})
		_:
			return UIText.text("event_footer_travel", {"lead": lead})

func _preview_choice(choice_id: String, title: String, summary: String, cost: int, disabled: bool) -> void:
	var meta := _choice_meta(choice_id, cost)
	var fit_data := RunEffects.evaluate_choice(choice_id, _current_actor())
	var cost_text := UIText.text("event_cost_gold", {"gold": cost}) + "." if cost > 0 else UIText.text("event_cost_free") + "."
	if disabled:
		cost_text = _locale_text("Not enough gold yet.", "当前金币不足。", "當前金幣不足。")
	var fit_label := String(fit_data.get("label", "Flexible"))
	if _current_locale() != "en":
		fit_label = _localized_fit_label(fit_label)
	detail_label.text = "%s: %s %s. %s %s %s" % [
		title,
		UIText.text("event_fit_label"),
		fit_label,
		String(fit_data.get("reason", meta.get("detail", ""))),
		summary,
		cost_text
	]

func _focus_first_choice() -> void:
	for child in choice_row.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return
	for child in choice_row.get_children():
		if child is Button:
			(child as Button).grab_focus()
			return

func _choice_meta(choice_id: String, cost: int) -> Dictionary:
	var meta := {
		"type": _locale_text("Choice", "选择", "選擇"),
		"timing": _locale_text("Now", "当前", "當前"),
		"detail": _locale_text("Updates the current run path.", "会影响当前本局路线。", "會影響當前本局路線。"),
		"color": Color(0.76, 0.84, 0.96),
		"timing_color": Color(0.92, 0.84, 0.66)
	}
	if choice_id == "skip":
		meta["type"] = _locale_text("Skip", "跳过", "跳過")
		meta["timing"] = _locale_text("No Cost", "无消耗", "無消耗")
		meta["detail"] = _locale_text("Keeps the current build unchanged and moves the run forward.", "保持当前构筑不变，继续推进流程。", "保持當前構築不變，繼續推進流程。")
		meta["color"] = Color(0.72, 0.78, 0.88)
		meta["timing_color"] = Color(0.76, 0.82, 0.90)
	elif choice_id.begins_with("shop_"):
		meta["type"] = _locale_text("Purchase", "购买", "購買")
		meta["timing"] = _locale_text("Run Bonus", "本局增益", "本局增益") if choice_id != "shop_relic" else _locale_text("Next Relic", "下一件饰品", "下一件飾品")
		meta["detail"] = _locale_text("Spends gold now for a lasting upgrade.", "现在花金币，换取持续到本局结束的强化。", "現在花金幣，換取持續到本局結束的強化。")
		meta["color"] = Color(1.0, 0.86, 0.56)
	elif choice_id.begins_with("bounty_"):
		meta["type"] = _locale_text("Bounty", "悬赏", "懸賞")
		meta["timing"] = _locale_text("Economy", "经济", "經濟")
		meta["detail"] = _locale_text("Turns the run toward immediate coin or stronger future payouts.", "把本局经济转向现钱收益，或转向更强的后续奖励。", "把本局經濟轉向現錢收益，或轉向更強的後續獎勵。")
		meta["color"] = Color(1.0, 0.82, 0.50)
	elif choice_id.begins_with("rest_"):
		meta["type"] = _locale_text("Recovery", "恢复", "恢復")
		meta["timing"] = _locale_text("Instant", "即时", "即時")
		meta["detail"] = _locale_text("Resolves immediately before the next encounter.", "会在下一场遭遇前立刻结算。", "會在下一場遭遇前立刻結算。")
		meta["color"] = Color(0.78, 0.96, 0.82)
	elif choice_id.begins_with("train_"):
		meta["type"] = _locale_text("Training", "训练", "訓練")
		meta["timing"] = _locale_text("Permanent", "永久", "永久")
		meta["detail"] = _locale_text("Adds a clean stat bonus for the rest of the run.", "会为本局剩余流程增加稳定属性收益。", "會為本局剩餘流程增加穩定屬性收益。")
		meta["color"] = Color(0.78, 0.90, 1.0)
	elif choice_id.begins_with("forge_"):
		meta["type"] = _locale_text("Forge", "锻造", "鍛造")
		meta["timing"] = _locale_text("Permanent", "永久", "永久")
		meta["detail"] = _locale_text("A mixed permanent upgrade that sharpens an established build lane.", "这是更贴着构筑走向的复合永久强化。", "這是更貼著構築走向的複合永久強化。")
		meta["color"] = Color(1.0, 0.78, 0.58)
	elif choice_id.begins_with("pact_"):
		meta["type"] = _locale_text("Pact", "契约", "契約")
		meta["timing"] = _locale_text("Tradeoff", "代价", "代價")
		meta["detail"] = _locale_text("Permanent power with a permanent drawback.", "永久强化伴随永久代价。", "永久強化伴隨永久代價。")
		meta["color"] = Color(1.0, 0.74, 0.66)
	elif choice_id.begins_with("scout_"):
		meta["type"] = _locale_text("Scout", "侦查", "偵查")
		meta["timing"] = _locale_text("Next Fight", "下一战", "下一戰")
		meta["detail"] = _locale_text("Queues a one-fight opener instead of a permanent run bonus.", "会排队一场战斗用的开局方案，而不是永久增益。", "會排隊一場戰鬥用的開局方案，而不是永久增益。")
		meta["color"] = Color(0.80, 0.96, 0.90)
	elif choice_id.begins_with("attune_"):
		meta["type"] = _locale_text("Attunement", "共鸣", "共鳴")
		meta["timing"] = _locale_text("Permanent", "永久", "永久")
		meta["detail"] = _locale_text("Deepens the current relic identity instead of changing direction.", "继续加深当前饰品路线，而不是临时改方向。", "繼續加深當前飾品路線，而不是臨時改方向。")
		meta["color"] = Color(0.88, 0.76, 1.0)
	if cost > 0:
		meta["timing"] = _locale_text("Cost %d", "花费 %d", "花費 %d") % cost
	return meta

func _current_actor() -> Node:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return null
	return scene_root.get("player_character") if scene_root.has_method("get") else null

func _has_skip_choice() -> bool:
	for button in choice_buttons:
		if button != null and String(button.get_meta("choice_id", "")) == "skip":
			return true
	return false

func _badge(text_value: String, color_value: Color) -> PanelContainer:
	var panel_value := PanelContainer.new()
	panel_value.add_theme_stylebox_override(
		"panel",
		UISkin.flat_style(color_value.darkened(0.76), color_value, 1, 5)
	)
	var label_value := Label.new()
	label_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_value.text = text_value
	UISkin.label(label_value, 10, color_value.lightened(0.12))
	panel_value.add_child(label_value)
	return panel_value

func _refresh_layout() -> void:
	if panel == null or choice_row == null:
		return
	var viewport_size: Vector2 = layout_size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO and get_window() != null:
		viewport_size = Vector2(get_window().size)
	var compact: bool = viewport_size.x < 980.0 or viewport_size.y < 700.0
	var very_compact: bool = viewport_size.x < 760.0 or viewport_size.y < 600.0
	panel.custom_minimum_size = Vector2(
		clampf(viewport_size.x - (48.0 if very_compact else 88.0), PANEL_MIN_SIZE.x, PANEL_MAX_SIZE.x),
		clampf(viewport_size.y - (48.0 if very_compact else 88.0), PANEL_MIN_SIZE.y, PANEL_MAX_SIZE.y)
	)
	panel_margin.add_theme_constant_override("margin_left", 18 if very_compact else (24 if compact else 34))
	panel_margin.add_theme_constant_override("margin_top", 18 if very_compact else (22 if compact else 30))
	panel_margin.add_theme_constant_override("margin_right", 18 if very_compact else (24 if compact else 34))
	panel_margin.add_theme_constant_override("margin_bottom", 18 if very_compact else (22 if compact else 30))
	choice_scroll.custom_minimum_size.y = clampf(panel.custom_minimum_size.y * (0.34 if very_compact else (0.40 if compact else 0.46)), 164.0, 330.0)
	UISkin.label(title_label, 22 if very_compact else (25 if compact else 28), Color(0.98, 0.90, 0.66))
	UISkin.label(subtitle_label, 13 if very_compact else (14 if compact else 15), Color(0.78, 0.84, 0.92))
	UISkin.label(build_summary_label, 11 if compact else 12, Color(0.90, 0.92, 0.98))
	UISkin.label(rule_summary_label, 11 if compact else 12, Color(0.78, 0.84, 0.92))
	UISkin.label(detail_label, 11 if compact else 12, Color(0.92, 0.86, 0.72))
	UISkin.label(footer_label, 11 if compact else 12, Color(0.74, 0.80, 0.88))
	if very_compact:
		footer_label.text = UIText.text("event_footer_base", {"count": mini(maxi(choice_row.get_child_count(), 1), 5)})
		if _has_skip_choice():
			footer_label.text += UIText.text("event_footer_skip")
	var card_width := 196.0 if very_compact else (224.0 if compact else 236.0)
	var card_height := 204.0 if very_compact else (252.0 if compact else 274.0)
	var available_width := maxf(choice_scroll.size.x, panel.custom_minimum_size.x - (56.0 if very_compact else 96.0))
	var max_columns := 3 if compact else 4
	var next_columns := clampi(int(floor((available_width + CARD_GAP) / (card_width + CARD_GAP))), 1, max_columns)
	choice_row.columns = max(1, min(next_columns, max(choice_row.get_child_count(), 1)))
	for child in choice_row.get_children():
		if child is Button:
			var card := child as Button
			card.custom_minimum_size = Vector2(card_width, card_height)

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

func _localized_fit_label(label_text: String) -> String:
	match label_text:
		"Best Now":
			return _locale_text("Best Now", "当前最佳", "當前最佳")
		"Strong Fit":
			return _locale_text("Strong Fit", "高度契合", "高度契合")
		"Flexible":
			return _locale_text("Flexible", "灵活可选", "靈活可選")
		"Risky":
			return _locale_text("Risky", "风险较高", "風險較高")
		"Hold":
			return _locale_text("Hold", "暂缓", "暫緩")
		_:
			return label_text
