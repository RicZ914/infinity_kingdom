extends Node

const SAVE_SLOT_SELECT_SCRIPT := preload("res://ui/save_slot_select.gd")
const OPENING_PROLOGUE_SCRIPT := preload("res://ui/opening_prologue.gd")

@onready var character_select: CanvasLayer = $CharacterSelect
@onready var play_mode_select: CanvasLayer = $PlayModeSelect
@onready var settings_panel: CanvasLayer = $SettingsPanel

var selected_character_id: StringName = &""
var selected_slot_index: int = -1
var save_slot_select: CanvasLayer = null
var opening_prologue: CanvasLayer = null


func _ready() -> void:
	_build_save_slot_select()
	_build_opening_prologue()
	if character_select != null:
		character_select.character_selected.connect(_on_character_selected)
		if character_select.has_signal("settings_requested"):
			character_select.settings_requested.connect(_on_settings_requested)
		if character_select.has_signal("quit_requested"):
			character_select.quit_requested.connect(_on_quit_requested)
	if play_mode_select != null:
		play_mode_select.normal_requested.connect(_on_normal_requested)
		play_mode_select.debug_requested.connect(_on_debug_requested)
		play_mode_select.back_requested.connect(_on_mode_back_requested)
	if Music != null:
		Music.play_profile(&"title", true)
	_show_save_slots()

func _build_save_slot_select() -> void:
	save_slot_select = SAVE_SLOT_SELECT_SCRIPT.new()
	save_slot_select.name = "SaveSlotSelect"
	add_child(save_slot_select)
	save_slot_select.slot_selected.connect(_on_save_slot_selected)
	save_slot_select.new_slot_requested.connect(_on_new_slot_requested)
	save_slot_select.quit_requested.connect(_on_quit_requested)

func _build_opening_prologue() -> void:
	opening_prologue = OPENING_PROLOGUE_SCRIPT.new()
	opening_prologue.name = "OpeningPrologue"
	add_child(opening_prologue)
	opening_prologue.finished.connect(_on_opening_prologue_finished)

func _show_save_slots() -> void:
	selected_slot_index = -1
	selected_character_id = &""
	if save_slot_select != null:
		save_slot_select.visible = true
	if character_select != null:
		character_select.visible = false
	if play_mode_select != null and play_mode_select.has_method("close"):
		play_mode_select.close()

func _on_save_slot_selected(slot_index: int) -> void:
	selected_slot_index = slot_index
	if SaveManager != null:
		SaveManager.select_slot(slot_index)
	if save_slot_select != null:
		save_slot_select.visible = false
	if character_select != null:
		character_select.visible = true

func _on_new_slot_requested(slot_index: int) -> void:
	selected_slot_index = slot_index
	if SaveManager != null:
		SaveManager.create_slot(slot_index, "Archive %d" % (slot_index + 1))
	if save_slot_select != null:
		save_slot_select.visible = false
	if opening_prologue != null and opening_prologue.has_method("open"):
		opening_prologue.open()
		return
	if character_select != null:
		character_select.visible = true

func _on_opening_prologue_finished() -> void:
	if character_select != null:
		character_select.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var title_visible := (save_slot_select != null and save_slot_select.visible) or (character_select != null and character_select.visible)
	if title_visible and CheatMode != null and CheatMode.input_key(event.keycode):
		get_viewport().set_input_as_handled()

func _on_character_selected(character_id: StringName) -> void:
	selected_character_id = character_id
	if character_select != null:
		character_select.visible = false
	_on_normal_requested()


func _on_normal_requested() -> void:
	StartupContext.set_pending_start(&"normal", selected_character_id, selected_slot_index)
	get_tree().change_scene_to_file("res://world.tscn")


func _on_debug_requested() -> void:
	StartupContext.set_pending_start(&"debug", selected_character_id, selected_slot_index)
	get_tree().change_scene_to_file("res://tools/character_debug_world.tscn")


func _on_mode_back_requested() -> void:
	selected_character_id = &""
	if play_mode_select != null and play_mode_select.has_method("close"):
		play_mode_select.close()
	if character_select != null:
		character_select.visible = true


func _on_settings_requested() -> void:
	if settings_panel != null and settings_panel.has_method("open"):
		settings_panel.open()


func _on_quit_requested() -> void:
	get_tree().quit()
