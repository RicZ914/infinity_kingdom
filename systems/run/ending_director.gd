extends Node

signal state_changed(state: Dictionary)

var no_damage_run: bool = true
var church_baptized: bool = false
var damaged_after_baptism: bool = false
var final_boss_defeated: bool = false
var developer_skill_marks := {}


func reset_run() -> void:
	no_damage_run = true
	church_baptized = false
	damaged_after_baptism = false
	final_boss_defeated = false
	developer_skill_marks.clear()
	_emit_state_changed()


func record_player_damage() -> void:
	no_damage_run = false
	if church_baptized:
		damaged_after_baptism = true
	_emit_state_changed()


func record_church_baptism() -> void:
	church_baptized = true
	damaged_after_baptism = false
	_emit_state_changed()


func record_final_boss_defeated() -> void:
	final_boss_defeated = true
	_emit_state_changed()


func can_break_crown() -> bool:
	return final_boss_defeated and (no_damage_run or (church_baptized and not damaged_after_baptism))


func record_developer_skill(skill_name: StringName) -> void:
	if not final_boss_defeated:
		developer_skill_marks[String(skill_name)] = true
	_emit_state_changed()


func developer_room_ready() -> bool:
	return developer_skill_marks.has("skill1") and developer_skill_marks.has("skill2") and developer_skill_marks.has("skill3")


func get_state() -> Dictionary:
	return {
		"no_damage_run": no_damage_run,
		"church_baptized": church_baptized,
		"damaged_after_baptism": damaged_after_baptism,
		"final_boss_defeated": final_boss_defeated,
		"developer_skill_count": developer_skill_marks.size()
	}


func _emit_state_changed() -> void:
	state_changed.emit(get_state())
