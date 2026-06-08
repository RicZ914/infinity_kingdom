extends Node

@onready var character_select: CanvasLayer = $CharacterSelect
@onready var play_mode_select: CanvasLayer = $PlayModeSelect
@onready var settings_panel: CanvasLayer = $SettingsPanel

var selected_character_id: StringName = &""


func _ready() -> void:
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


func _on_character_selected(character_id: StringName) -> void:
	selected_character_id = character_id
	if character_select != null:
		character_select.visible = false
	_on_normal_requested()


func _on_normal_requested() -> void:
	StartupContext.set_pending_start(&"normal", selected_character_id)
	get_tree().change_scene_to_file("res://world.tscn")


func _on_debug_requested() -> void:
	StartupContext.set_pending_start(&"debug", selected_character_id)
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
