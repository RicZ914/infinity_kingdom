extends CanvasLayer

signal character_selected(character_id: StringName)

const UISkin := preload("res://ui/ui_skin.gd")

const HEROES := [
	{
		"id": &"knight",
		"name": "Knight",
		"role": "Frontline Vanguard",
		"desc": "High health and defense. Charge slash, shockwave, sanctuary.",
		"texture": "res://assets/heroes/knight.png",
		"color": Color(0.82, 0.58, 0.34)
	},
	{
		"id": &"ranger",
		"name": "Ranger",
		"role": "Mobile Hunter",
		"desc": "Fast attacks and burst. Piercing arrow, shadow roll, assassination.",
		"texture": "res://assets/heroes/ranger.png",
		"color": Color(0.38, 0.78, 0.56)
	},
	{
		"id": &"mage",
		"name": "Mage",
		"role": "Arcane Controller",
		"desc": "Ranged burst and control. Arcane blades, burst, silence decree.",
		"texture": "res://assets/heroes/mage.png",
		"color": Color(0.56, 0.62, 0.95)
	}
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	layer = 10
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.018, 0.022, 0.034, 0.88)
	add_child(backdrop)

	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = load("res://assets/ui/background/title_screen_bg.png") as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.55, 0.55, 0.60, 0.58)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1180, 560)
	panel.add_theme_stylebox_override("panel", UISkin.red_panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Choose Your Champion"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(title, 32, Color(0.98, 0.90, 0.66))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Pick a family style, then claim relics between encounters to bend the run."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(subtitle, 16, Color(0.76, 0.80, 0.88))
	column.add_child(subtitle)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(cards)

	for hero in HEROES:
		cards.add_child(_hero_card(hero))

func _hero_card(hero: Dictionary) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(350, 395)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", UISkin.texture_style(UISkin.asset("choice/choice_card_normal.png"), 30, 12))
	button.add_theme_stylebox_override("hover", UISkin.texture_style(UISkin.asset("choice/choice_card_hover.png"), 30, 12))
	button.add_theme_stylebox_override("pressed", UISkin.texture_style(UISkin.asset("choice/choice_card_selected.png"), 30, 12))
	button.pressed.connect(func() -> void:
		visible = false
		character_selected.emit(hero["id"])
	)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	button.add_child(box)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(300, 170)
	portrait.texture = load(String(hero["texture"])) as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(portrait)

	var name_label := Label.new()
	name_label.text = String(hero["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(name_label, 25, Color.WHITE)
	box.add_child(name_label)

	var role_label := Label.new()
	role_label.text = String(hero["role"])
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(role_label, 15, hero["color"])
	box.add_child(role_label)

	var desc_label := Label.new()
	desc_label.text = String(hero["desc"])
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(desc_label, 15, Color(0.78, 0.84, 0.92))
	box.add_child(desc_label)

	return button
