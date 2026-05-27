extends CanvasLayer

signal character_selected(character_id: StringName)
signal audio_requested
signal settings_requested
signal quit_requested

const UISkin := preload("res://ui/ui_skin.gd")

const HEROES := [
	{
		"id": &"knight",
		"portrait": "res://assets/heroes/knight.png",
		"name": {
			"en": "Knight",
			"zh_Hans": "骑士",
			"zh_Hant": "騎士"
		},
		"role": {
			"en": "Frontline",
			"zh_Hans": "前线",
			"zh_Hant": "前線"
		},
		"stats": {
			"en": ["HP", "Armor", "Melee"],
			"zh_Hans": ["生命", "护甲", "近战"],
			"zh_Hant": ["生命", "護甲", "近戰"]
		},
		"summary": {
			"en": "Stable opener, heavy sustain, slower reposition.",
			"zh_Hans": "开局最稳，续航厚实，但转位节奏偏慢。",
			"zh_Hant": "開局最穩，續航厚實，但轉位節奏偏慢。"
		}
	},
	{
		"id": &"ranger",
		"portrait": "res://assets/heroes/ranger.png",
		"name": {
			"en": "Ranger",
			"zh_Hans": "游侠",
			"zh_Hant": "遊俠"
		},
		"role": {
			"en": "Agile",
			"zh_Hans": "灵巧",
			"zh_Hant": "靈巧"
		},
		"stats": {
			"en": ["Crit", "Speed", "Burst"],
			"zh_Hans": ["暴击", "速度", "爆发"],
			"zh_Hant": ["暴擊", "速度", "爆發"]
		},
		"summary": {
			"en": "Fast target picks, high tempo, lower fault tolerance.",
			"zh_Hans": "点杀速度最快，节奏很高，但失误空间最小。",
			"zh_Hant": "點殺速度最快，節奏很高，但失誤空間最小。"
		}
	},
	{
		"id": &"mage",
		"portrait": "res://assets/heroes/mage.png",
		"name": {
			"en": "Mage",
			"zh_Hans": "法师",
			"zh_Hant": "法師"
		},
		"role": {
			"en": "Control",
			"zh_Hans": "控场",
			"zh_Hant": "控場"
		},
		"stats": {
			"en": ["Range", "Skill", "Control"],
			"zh_Hans": ["射程", "技能", "控制"],
			"zh_Hant": ["射程", "技能", "控制"]
		},
		"summary": {
			"en": "Safest spacing, strong area control, lightest body.",
			"zh_Hans": "最安全的拉扯距离，范围控制强，但身板最薄。",
			"zh_Hant": "最安全的拉扯距離，範圍控制強，但身板最薄。"
		}
	}
]

var panel: PanelContainer
var panel_margin: MarginContainer
var title_label: Label
var subtitle_label: Label
var background_rect: TextureRect
var hero_portrait: TextureRect
var hero_detail_title: Label
var hero_detail_role: Label
var hero_detail_desc: Label
var cards_panel: PanelContainer
var cards_grid: GridContainer
var hero_buttons: Array[Button] = []
var primary_start_button: Button
var settings_button: Button
var audio_button: Button
var gallery_button: Button
var about_button: Button
var quit_button: Button
var left_hint_label: Label
var left_blurb_label: Label
var layout_size_override: Vector2 = Vector2.ZERO
var selected_hero_index: int = 0
var detail_mode: String = "hero"
var screen_mode: String = "menu"

func _ready() -> void:
	_build_ui()
	if UISettings != null and UISettings.has_signal("locale_changed") and not UISettings.locale_changed.is_connected(_refresh_copy):
		UISettings.locale_changed.connect(_refresh_copy)
	_set_selected_hero(0)
	_show_menu()
	_refresh_copy()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_queue_layout_refresh):
		get_viewport().size_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()

func _build_ui() -> void:
	layer = 10

	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.texture = load("res://assets/ui/background/title_screen_bg.png") as Texture2D
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.modulate = Color(1.0, 1.0, 1.0, 0.96)
	add_child(background_rect)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.04, 0.05, 0.44)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	panel = PanelContainer.new()
	panel.name = "CharacterSelectPanel"
	panel.custom_minimum_size = Vector2(1180, 690)
	panel.add_theme_stylebox_override("panel", UISkin.menu_panel_style())
	center.add_child(panel)

	panel_margin = MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 28)
	panel_margin.add_theme_constant_override("margin_top", 24)
	panel_margin.add_theme_constant_override("margin_right", 28)
	panel_margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(panel_margin)

	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 18)
	panel_margin.add_child(root_column)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(title_label, 34, UISkin.COLOR_ACCENT)
	root_column.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(subtitle_label, 14, UISkin.COLOR_MUTED)
	root_column.add_child(subtitle_label)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 18)
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(main_row)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(286, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	main_row.add_child(left_panel)

	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 16)
	left_margin.add_theme_constant_override("margin_top", 16)
	left_margin.add_theme_constant_override("margin_right", 16)
	left_margin.add_theme_constant_override("margin_bottom", 16)
	left_panel.add_child(left_margin)

	var left_column := VBoxContainer.new()
	left_column.add_theme_constant_override("separation", 12)
	left_margin.add_child(left_column)

	left_blurb_label = Label.new()
	left_blurb_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(left_blurb_label, 13, Color(0.90, 0.92, 0.98))
	left_column.add_child(left_blurb_label)

	primary_start_button = _menu_button("", _on_primary_pressed, true)
	settings_button = _menu_button("", func() -> void: settings_requested.emit())
	audio_button = _menu_button("", func() -> void: audio_requested.emit())
	gallery_button = _menu_button("", func() -> void: _show_gallery_placeholder())
	about_button = _menu_button("", func() -> void: _show_about_placeholder())
	quit_button = _menu_button("", func() -> void: quit_requested.emit())
	for button in [primary_start_button, settings_button, audio_button, gallery_button, about_button, quit_button]:
		left_column.add_child(button)

	left_hint_label = Label.new()
	left_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(left_hint_label, 11, UISkin.COLOR_MUTED)
	left_column.add_child(left_hint_label)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", UISkin.content_panel_style())
	main_row.add_child(right_panel)

	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 18)
	right_margin.add_theme_constant_override("margin_top", 18)
	right_margin.add_theme_constant_override("margin_right", 18)
	right_margin.add_theme_constant_override("margin_bottom", 18)
	right_panel.add_child(right_margin)

	var right_column := VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 16)
	right_margin.add_child(right_column)

	var hero_top_row := HBoxContainer.new()
	hero_top_row.add_theme_constant_override("separation", 16)
	right_column.add_child(hero_top_row)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(220, 260)
	portrait_frame.add_theme_stylebox_override("panel", UISkin.icon_slot_style())
	hero_top_row.add_child(portrait_frame)

	hero_portrait = TextureRect.new()
	hero_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.add_child(hero_portrait)

	var hero_info_panel := PanelContainer.new()
	hero_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_info_panel.add_theme_stylebox_override("panel", UISkin.choice_panel_style())
	hero_top_row.add_child(hero_info_panel)

	var hero_info_margin := MarginContainer.new()
	hero_info_margin.add_theme_constant_override("margin_left", 14)
	hero_info_margin.add_theme_constant_override("margin_top", 14)
	hero_info_margin.add_theme_constant_override("margin_right", 14)
	hero_info_margin.add_theme_constant_override("margin_bottom", 14)
	hero_info_panel.add_child(hero_info_margin)

	var hero_info_column := VBoxContainer.new()
	hero_info_column.add_theme_constant_override("separation", 8)
	hero_info_margin.add_child(hero_info_column)

	hero_detail_title = Label.new()
	UISkin.label(hero_detail_title, 24, Color.WHITE)
	hero_info_column.add_child(hero_detail_title)

	hero_detail_role = Label.new()
	UISkin.label(hero_detail_role, 14, UISkin.COLOR_ACCENT)
	hero_info_column.add_child(hero_detail_role)

	hero_detail_desc = Label.new()
	hero_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(hero_detail_desc, 12, UISkin.COLOR_MUTED)
	hero_info_column.add_child(hero_detail_desc)

	cards_panel = PanelContainer.new()
	cards_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_panel.add_theme_stylebox_override("panel", UISkin.choice_panel_style())
	right_column.add_child(cards_panel)

	var cards_margin := MarginContainer.new()
	cards_margin.add_theme_constant_override("margin_left", 12)
	cards_margin.add_theme_constant_override("margin_top", 12)
	cards_margin.add_theme_constant_override("margin_right", 12)
	cards_margin.add_theme_constant_override("margin_bottom", 12)
	cards_panel.add_child(cards_margin)

	cards_grid = GridContainer.new()
	cards_grid.columns = 3
	cards_grid.add_theme_constant_override("h_separation", 12)
	cards_grid.add_theme_constant_override("v_separation", 12)
	cards_margin.add_child(cards_grid)

	for hero_index in range(HEROES.size()):
		var hero_button := _hero_card(HEROES[hero_index], hero_index)
		hero_buttons.append(hero_button)
		cards_grid.add_child(hero_button)

func _hero_card(hero: Dictionary, hero_index: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0, 200)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", UISkin.choice_panel_style())
	button.add_theme_stylebox_override("hover", UISkin.flat_style(Color(0.22, 0.23, 0.27), UISkin.COLOR_ACCENT, 2, 3))
	button.add_theme_stylebox_override("pressed", UISkin.flat_style(Color(0.14, 0.15, 0.18), UISkin.COLOR_ACCENT.darkened(0.2), 2, 3))
	button.focus_entered.connect(func() -> void: _set_selected_hero(hero_index))
	button.mouse_entered.connect(func() -> void: _set_selected_hero(hero_index))
	button.pressed.connect(func() -> void: _activate_hero(hero_index))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 12
	margin.offset_top = 12
	margin.offset_right = -12
	margin.offset_bottom = -12
	button.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(0, 96)
	portrait_frame.add_theme_stylebox_override("panel", UISkin.icon_slot_style())
	column.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.texture = load(String(hero["portrait"])) as Texture2D
	portrait_frame.add_child(portrait)

	var name_label := Label.new()
	name_label.text = "%s  [%d]" % [_hero_name(hero), hero_index + 1]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(name_label, 16, Color.WHITE)
	column.add_child(name_label)

	var role_label := Label.new()
	role_label.text = _hero_role(hero)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(role_label, 12, UISkin.COLOR_ACCENT)
	column.add_child(role_label)

	var stats_label := Label.new()
	stats_label.text = " / ".join(_hero_stats(hero))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(stats_label, 11, UISkin.COLOR_MUTED)
	column.add_child(stats_label)

	UISkin.ignore_mouse_recursive(margin)
	return button

func _menu_button(text_value: String, callback: Callable, highlighted: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 46)
	UISkin.button_styles(button, "large" if highlighted else "medium")
	button.pressed.connect(callback)
	return button

func _on_primary_pressed() -> void:
	if screen_mode == "select":
		_activate_selected_hero()
		return
	_show_hero_select()

func _show_menu() -> void:
	screen_mode = "menu"
	detail_mode = "hero"
	cards_panel.visible = false
	_set_selected_hero(selected_hero_index)
	_refresh_copy()

func _show_hero_select() -> void:
	screen_mode = "select"
	detail_mode = "hero"
	cards_panel.visible = true
	_set_selected_hero(selected_hero_index)
	_refresh_copy()
	call_deferred("_focus_selected_card")

func _focus_selected_card() -> void:
	if selected_hero_index >= 0 and selected_hero_index < hero_buttons.size():
		hero_buttons[selected_hero_index].grab_focus()

func _set_selected_hero(hero_index: int) -> void:
	detail_mode = "hero"
	selected_hero_index = clampi(hero_index, 0, HEROES.size() - 1)
	var hero: Dictionary = HEROES[selected_hero_index]
	hero_portrait.texture = load(String(hero["portrait"])) as Texture2D
	hero_detail_title.text = _hero_name(hero)
	hero_detail_role.text = _hero_role(hero)
	var summary_text := _hero_summary(hero)
	var stats_text := " / ".join(_hero_stats(hero))
	var action_text := _locale_text(
		"Press Enter to start with this hero." if screen_mode == "select" else "Open hero select and lock this hero.",
		"按 Enter 用这名角色开始。" if screen_mode == "select" else "先打开选角，再锁定这名角色。",
		"按 Enter 用這名角色開始。" if screen_mode == "select" else "先打開選角，再鎖定這名角色。"
	)
	hero_detail_desc.text = "%s\n%s\n%s" % [summary_text, stats_text, action_text]

func _activate_selected_hero() -> void:
	_activate_hero(selected_hero_index)

func _activate_hero(hero_index: int) -> void:
	var safe_index := clampi(hero_index, 0, HEROES.size() - 1)
	visible = false
	character_selected.emit(HEROES[safe_index]["id"])

func _show_about_placeholder() -> void:
	screen_mode = "about"
	detail_mode = "about"
	cards_panel.visible = false
	hero_detail_title.text = UIText.text("about_title")
	hero_detail_role.text = UIText.text("placeholder_panel")
	hero_detail_desc.text = UIText.text("char_about_placeholder")
	_refresh_copy()

func _show_gallery_placeholder() -> void:
	screen_mode = "gallery"
	detail_mode = "gallery"
	cards_panel.visible = false
	hero_detail_title.text = UIText.text("gallery_title")
	hero_detail_role.text = UIText.text("placeholder_panel")
	hero_detail_desc.text = UIText.text("char_gallery_placeholder")
	_refresh_copy()

func _refresh_copy(_locale: String = "") -> void:
	title_label.text = UIText.text("menu_title")
	subtitle_label.text = _locale_text(
		"Choose a menu entry first, then lock in a hero for the town trial.",
		"先选择菜单项，再确定要进入城镇试炼的角色。",
		"先選擇選單項，再確定要進入城鎮試煉的角色。"
	)
	left_blurb_label.text = _locale_text(
		"Start here, adjust audio or settings if needed, then lock a hero and shape the run with relics.",
		"先从这里开始；要调音频或设置也能直接处理。选定角色后，再用饰品把路线做出来。",
		"先從這裡開始；要調音訊或設定也能直接處理。選定角色後，再用飾品把路線做出來。"
	)
	primary_start_button.text = _locale_text("Start", "开始", "開始") if screen_mode != "select" else _locale_text("Enter Trial", "进入试炼", "進入試煉")
	settings_button.text = UIText.text("menu_settings")
	audio_button.text = UIText.text("audio_mix")
	gallery_button.text = UIText.text("menu_gallery")
	about_button.text = UIText.text("menu_about")
	quit_button.text = UIText.text("menu_quit")
	left_hint_label.text = _hint_text()
	match detail_mode:
		"gallery":
			hero_detail_title.text = UIText.text("gallery_title")
			hero_detail_role.text = UIText.text("placeholder_panel")
			hero_detail_desc.text = UIText.text("char_gallery_placeholder")
		"about":
			hero_detail_title.text = UIText.text("about_title")
			hero_detail_role.text = UIText.text("placeholder_panel")
			hero_detail_desc.text = UIText.text("char_about_placeholder")
		_:
			_set_selected_hero(selected_hero_index)

func _hint_text() -> String:
	match screen_mode:
		"select":
			return _locale_text(
				"1 / 2 / 3 choose hero  |  Enter begin  |  Esc menu  |  S settings  |  F10 audio  |  Q quit",
				"1 / 2 / 3 选择角色  |  Enter 开始  |  Esc 返回菜单  |  S 设置  |  F10 音频  |  Q 退出",
				"1 / 2 / 3 選擇角色  |  Enter 開始  |  Esc 返回選單  |  S 設定  |  F10 音訊  |  Q 退出"
			)
		"gallery":
			return _locale_text(
				"G reopen gallery  |  Esc menu  |  S settings  |  F10 audio  |  Q quit",
				"G 重新打开图鉴  |  Esc 返回菜单  |  S 设置  |  F10 音频  |  Q 退出",
				"G 重新打開圖鑑  |  Esc 返回選單  |  S 設定  |  F10 音訊  |  Q 退出"
			)
		"about":
			return _locale_text(
				"A reopen about  |  Esc menu  |  S settings  |  F10 audio  |  Q quit",
				"A 重新打开关于  |  Esc 返回菜单  |  S 设置  |  F10 音频  |  Q 退出",
				"A 重新打開關於  |  Esc 返回選單  |  S 設定  |  F10 音訊  |  Q 退出"
			)
		_:
			return _locale_text(
				"Enter open hero select  |  S settings  |  F10 audio  |  G gallery  |  A about  |  Q quit",
				"Enter 打开选角菜单  |  S 设置  |  F10 音频  |  G 图鉴  |  A 关于  |  Q 退出",
				"Enter 打開選角選單  |  S 設定  |  F10 音訊  |  G 圖鑑  |  A 關於  |  Q 退出"
			)

func _queue_layout_refresh() -> void:
	call_deferred("_refresh_layout")

func _refresh_layout() -> void:
	if panel == null or cards_grid == null:
		return
	var viewport_size: Vector2 = layout_size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO and get_window() != null:
		viewport_size = Vector2(get_window().size)
	var compact := viewport_size.x < 1100.0 or viewport_size.y < 760.0
	var very_compact := viewport_size.x < 860.0 or viewport_size.y < 640.0
	panel.custom_minimum_size = Vector2(
		clampf(viewport_size.x - (48.0 if compact else 96.0), 720.0, 1360.0),
		clampf(viewport_size.y - (48.0 if compact else 96.0), 540.0, 820.0)
	)
	panel_margin.add_theme_constant_override("margin_left", 18 if compact else 28)
	panel_margin.add_theme_constant_override("margin_top", 16 if compact else 24)
	panel_margin.add_theme_constant_override("margin_right", 18 if compact else 28)
	panel_margin.add_theme_constant_override("margin_bottom", 16 if compact else 24)
	UISkin.label(title_label, 28 if compact else 34, UISkin.COLOR_ACCENT)
	UISkin.label(subtitle_label, 13 if compact else 14, UISkin.COLOR_MUTED)
	UISkin.label(left_blurb_label, 12 if compact else 13, Color(0.90, 0.92, 0.98))
	UISkin.label(hero_detail_title, 21 if compact else 24, Color.WHITE)
	UISkin.label(hero_detail_role, 13 if compact else 14, UISkin.COLOR_ACCENT)
	UISkin.label(hero_detail_desc, 12 if compact else 13, UISkin.COLOR_MUTED)
	UISkin.label(left_hint_label, 11 if compact else 12, UISkin.COLOR_MUTED)
	cards_grid.columns = 1 if very_compact else (2 if compact else 3)
	hero_portrait.custom_minimum_size = Vector2(200.0 if compact else 220.0, 240.0 if compact else 260.0)
	for hero_button in hero_buttons:
		hero_button.custom_minimum_size.y = 172.0 if compact else 200.0

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				_show_hero_select()
				_set_selected_hero(0)
			KEY_2, KEY_KP_2:
				_show_hero_select()
				_set_selected_hero(1)
			KEY_3, KEY_KP_3:
				_show_hero_select()
				_set_selected_hero(2)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if screen_mode == "select":
					_activate_selected_hero()
				else:
					_show_hero_select()
			KEY_ESCAPE:
				if screen_mode != "menu":
					_show_menu()
				else:
					return
			KEY_S:
				settings_requested.emit()
			KEY_G:
				_show_gallery_placeholder()
			KEY_A:
				_show_about_placeholder()
			KEY_Q:
				quit_requested.emit()
			_:
				return
		get_viewport().set_input_as_handled()

func _hero_name(hero: Dictionary) -> String:
	return _localized_hero_field(hero, "name")

func _hero_role(hero: Dictionary) -> String:
	return _localized_hero_field(hero, "role")

func _hero_summary(hero: Dictionary) -> String:
	return _localized_hero_field(hero, "summary")

func _hero_stats(hero: Dictionary) -> Array[String]:
	var locale := _current_locale()
	var localized := hero.get("stats", {}) as Dictionary
	var raw: Variant = localized.get(locale, localized.get("en", []))
	var output: Array[String] = []
	if raw is Array:
		for entry in raw:
			output.append(String(entry))
	return output

func _localized_hero_field(hero: Dictionary, field: String) -> String:
	var locale := _current_locale()
	var localized := hero.get(field, {}) as Dictionary
	return String(localized.get(locale, localized.get("en", "")))

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
