extends Node

var pending_mode: StringName = &""
var pending_character_id: StringName = &""
var pending_slot_index: int = -1


func set_pending_start(mode: StringName, character_id: StringName, slot_index: int = -1) -> void:
	pending_mode = mode
	pending_character_id = character_id
	pending_slot_index = slot_index


func consume_pending_start() -> Dictionary:
	var result := {
		"mode": pending_mode,
		"character_id": pending_character_id,
		"slot_index": pending_slot_index
	}
	pending_mode = &""
	pending_character_id = &""
	pending_slot_index = -1
	return result
