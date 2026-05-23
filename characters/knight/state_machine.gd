extends Node

var owner_actor: Node
var current_state: Node
var states: Dictionary = {}

func initialize(actor: Node) -> void:
	owner_actor = actor
	states.clear()
	for child in get_children():
		if child.has_method("setup") and child.get("state_name") != null:
			var state: Node = child
			state.setup(self, actor)
			states[state.state_name] = state
	transition_to(&"Idle")

func physics_update(delta: float) -> void:
	if current_state == null:
		return
	current_state.physics_update(delta)
	current_state.evaluate_transitions()

func change_state(next_state_name: StringName, bypass_priority: bool = false) -> bool:
	if not states.has(next_state_name):
		return false
	var next_state: Node = states[next_state_name]
	if current_state == next_state:
		return false
	if current_state != null and not bypass_priority and not can_enter(next_state):
		return false
	if current_state != null:
		current_state.exit()
	current_state = next_state
	current_state.enter()
	return true

func transition_to(next_state_name: StringName) -> bool:
	return change_state(next_state_name, true)

func force_change(next_state_name: StringName) -> void:
	change_state(next_state_name, true)

func can_enter(new_state: Node) -> bool:
	if current_state == null:
		return true
	return new_state.priority >= current_state.priority

func request_hit() -> void:
	if current_state == null:
		return
	if current_state.interruptible:
		transition_to(&"Hit")

func is_current_state_interruptible() -> bool:
	return current_state == null or current_state.interruptible

func get_state_name() -> StringName:
	if current_state == null:
		return &""
	return current_state.state_name
