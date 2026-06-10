extends CanvasLayer

signal finished

const UISkin := preload("res://ui/ui_skin.gd")
const PANELS := [
	{
		"image": "res://assets/ui/background/prologue/prologue_01_falling_kingdom.png",
		"title": "The Kingdom Leans",
		"body": "The capital still wears its crown, but every bell rings like a warning. Walls crack, banners rot, and the old throne demands another heir."
	},
	{
		"image": "res://assets/ui/background/prologue/prologue_02_corrupt_throne.png",
		"title": "The Crown Remembers",
		"body": "Victory did not save the king. It taught the crown how to hunger. Each ruler who sits beneath it leaves less of themself behind."
	},
	{
		"image": "res://assets/ui/background/prologue/prologue_03_three_families.png",
		"title": "Three Bloodlines Answer",
		"body": "Steel, arrow, and arcane fire gather before the palace road. None are promised a second dawn, but all can leave something for the next hand."
	},
	{
		"image": "res://assets/ui/background/prologue/prologue_04_bloodline_embers.png",
		"title": "Five Embers",
		"body": "A new archive begins with five blood embers. Spend them poorly and the file dies. Spend them well and the next life starts stronger."
	}
]

var image_rect: TextureRect
var dimmer: ColorRect
var title_label: Label
var body_label: Label
var hint_label: Label
var current_index: int = 0
var layout_size_override: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_queue_layout_refresh):
		get_viewport().size_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()


func open() -> void:
	current_index = 0
	visible = true
	get_tree().paused = true
	_show_current_panel()


func close() -> void:
	visible = false
	get_tree().paused = false
	finished.emit()


func _build_ui() -> void:
	image_rect = TextureRect.new()
	image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(image_rect)

	dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.018, 0.018, 0.36)
	add_child(dimmer)

	var bottom_margin := MarginContainer.new()
	bottom_margin.anchor_left = 0.0
	bottom_margin.anchor_top = 1.0
	bottom_margin.anchor_right = 1.0
	bottom_margin.anchor_bottom = 1.0
	bottom_margin.offset_left = 72.0
	bottom_margin.offset_top = -270.0
	bottom_margin.offset_right = -72.0
	bottom_margin.offset_bottom = -54.0
	add_child(bottom_margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_margin.add_child(stack)

	title_label = Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UISkin.label(title_label, 38, Color(1.0, 0.88, 0.62))
	stack.add_child(title_label)

	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.max_lines_visible = 4
	UISkin.label(body_label, 18, Color(0.90, 0.92, 0.96))
	stack.add_child(body_label)

	hint_label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UISkin.label(hint_label, 13, Color(0.72, 0.78, 0.86))
	stack.add_child(hint_label)


func _show_current_panel() -> void:
	current_index = clampi(current_index, 0, PANELS.size() - 1)
	var panel := PANELS[current_index] as Dictionary
	image_rect.texture = load(String(panel.get("image", ""))) as Texture2D
	title_label.text = String(panel.get("title", ""))
	body_label.text = String(panel.get("body", ""))
	hint_label.text = "Enter / Space continue   Esc skip   %d / %d" % [current_index + 1, PANELS.size()]


func _advance() -> void:
	if current_index >= PANELS.size() - 1:
		close()
		return
	current_index += 1
	_show_current_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		_advance()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_advance()
			get_viewport().set_input_as_handled()


func _queue_layout_refresh() -> void:
	call_deferred("_refresh_layout")


func _refresh_layout() -> void:
	if title_label == null:
		return
	var viewport_size := layout_size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	var compact := viewport_size.x < 860.0 or viewport_size.y < 620.0
	UISkin.label(title_label, 28 if compact else 38, Color(1.0, 0.88, 0.62))
	UISkin.label(body_label, 14 if compact else 18, Color(0.90, 0.92, 0.96))
	UISkin.label(hint_label, 11 if compact else 13, Color(0.72, 0.78, 0.86))
