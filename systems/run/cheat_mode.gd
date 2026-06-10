extends Node

signal cheat_enabled

const SEQUENCE := [
	KEY_UP,
	KEY_UP,
	KEY_DOWN,
	KEY_DOWN,
	KEY_LEFT,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_RIGHT,
	KEY_A,
	KEY_A,
	KEY_B,
	KEY_B
]

var enabled: bool = false
var infinite_hp: bool = false
var developer_room_unlocked: bool = false
var sequence_index: int = 0


func reset_session() -> void:
	enabled = false
	infinite_hp = false
	developer_room_unlocked = false
	sequence_index = 0


func input_key(keycode: int) -> bool:
	if enabled:
		return false
	if keycode == int(SEQUENCE[sequence_index]):
		sequence_index += 1
		if sequence_index >= SEQUENCE.size():
			_enable_cheats()
			return true
		return false
	sequence_index = 1 if keycode == int(SEQUENCE[0]) else 0
	return false


func unlock_developer_room() -> void:
	developer_room_unlocked = true


func _enable_cheats() -> void:
	enabled = true
	infinite_hp = true
	sequence_index = 0
	cheat_enabled.emit()
