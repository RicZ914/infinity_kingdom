extends CanvasLayer

signal accessory_choice_made(accessory_id: String, kept_current: bool)

const UISkin := preload("res://ui/ui_skin.gd")

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var subtitle_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Subtitle
@onready var current_icon: TextureRect = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CurrentRow/IconSlot/Icon
@onready var current_name_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CurrentRow/Text/Name
@onready var current_summary_label: Label = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CurrentRow/Text/Summary
@onready var choices_row: HBoxContainer = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ChoicesRow
@onready var keep_button: Button = $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonRow/KeepButton

var active_choices: Array[Dictionary] = []
var active_actor: Node = null

func _ready() -> void:
	visible = false
	_apply_skin()
	keep_button.pressed.connect(_on_keep_pressed)

func open(choices: Array[Dictionary], actor: Node, reason: String = "Relic Offering") -> void:
	active_choices = choices
	active_actor = actor
	title_label.text = reason
	subtitle_label.text = "Equip one accessory. The current relic is replaced immediately."
	_refresh_current()
	_rebuild_choices()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _apply_skin() -> void:
	backdrop.color = Color(0.015, 0.018, 0.026, 0.76)
	var panel := $Backdrop/CenterContainer/PanelContainer as PanelContainer
	panel.add_theme_stylebox_override("panel", UISkin.red_panel_style())
	var current_panel := $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CurrentRow as PanelContainer
	current_panel.add_theme_stylebox_override("panel", UISkin.texture_style(UISkin.asset("menu/menu_content_panel.png"), 34, 10))
	var icon_slot := $Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CurrentRow/IconSlot as PanelContainer
	icon_slot.add_theme_stylebox_override("panel", UISkin.icon_slot_style())
	UISkin.label(title_label, 28, Color(0.98, 0.90, 0.67))
	UISkin.label(subtitle_label, 15, Color(0.76, 0.80, 0.88))
	UISkin.label(current_name_label, 18, Color.WHITE)
	UISkin.label(current_summary_label, 14, Color(0.76, 0.82, 0.90))
	UISkin.button_styles(keep_button, "thin")

func _refresh_current() -> void:
	var current := AccessoryManager.get_equipped_accessory()
	current_icon.texture = load(String(current.get("icon", "res://assets/ui/icon/ui_unknown.png"))) as Texture2D
	current_name_label.text = "Current: %s" % String(current.get("name", "No Accessory"))
	current_summary_label.text = "%s\n%s" % [
		String(current.get("summary", "")),
		AccessoryManager.describe_effects(current)
	]

func _rebuild_choices() -> void:
	for child in choices_row.get_children():
		choices_row.remove_child(child)
		child.queue_free()
	for accessory in active_choices:
		choices_row.add_child(_choice_card(accessory))

func _choice_card(accessory: Dictionary) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(292, 320)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", UISkin.texture_style(UISkin.asset("choice/choice_card_normal.png"), 30, 12))
	button.add_theme_stylebox_override("hover", UISkin.texture_style(UISkin.asset("choice/choice_card_hover.png"), 30, 12))
	button.add_theme_stylebox_override("pressed", UISkin.texture_style(UISkin.asset("choice/choice_card_selected.png"), 30, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	button.add_child(box)
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(86, 86)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("panel", UISkin.texture_style(UISkin.asset("choice/choice_icon_slot.png"), 22, 4))
	box.add_child(slot)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(String(accessory.get("icon", "res://assets/ui/icon/ui_unknown.png"))) as Texture2D
	slot.add_child(icon)
	var name_label := Label.new()
	name_label.text = String(accessory.get("name", "Accessory"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(name_label, 20, Color.WHITE)
	box.add_child(name_label)
	var rarity_label := Label.new()
	rarity_label.text = String(accessory.get("rarity", "Common"))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UISkin.label(rarity_label, 14, _rarity_color(String(accessory.get("rarity", "Common"))))
	box.add_child(rarity_label)
	var summary_label := Label.new()
	summary_label.text = String(accessory.get("summary", ""))
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(summary_label, 14, Color(0.78, 0.84, 0.92))
	box.add_child(summary_label)
	var effects_label := Label.new()
	effects_label.text = AccessoryManager.describe_effects(accessory)
	effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UISkin.label(effects_label, 13, Color(0.72, 0.92, 0.78))
	box.add_child(effects_label)
	button.pressed.connect(func() -> void:
		var accessory_id := String(accessory.get("id", ""))
		AccessoryManager.equip(accessory_id, active_actor)
		close()
		accessory_choice_made.emit(accessory_id, false)
	)
	return button

func _on_keep_pressed() -> void:
	AccessoryManager.keep_current(active_actor)
	close()
	accessory_choice_made.emit(String(AccessoryManager.get_equipped_accessory().get("id", "none")), true)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Uncommon":
			return Color(0.62, 0.90, 0.62)
		"Rare":
			return Color(0.54, 0.75, 1.0)
		"Epic":
			return Color(0.78, 0.58, 1.0)
		"Legendary":
			return Color(1.0, 0.72, 0.35)
		_:
			return Color(0.78, 0.80, 0.84)
