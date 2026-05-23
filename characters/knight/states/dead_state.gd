extends Node

@export var state_name: StringName = &"Dead"
@export var priority: int = 6
@export var interruptible: bool = false

var state_machine: Node
var actor: Node

func setup(machine: Node, state_actor: Node) -> void:
	state_machine = machine
	actor = state_actor

func enter() -> void:
	actor.velocity = Vector2.ZERO
	actor.end_guard()
	actor.clear_sanctuary()
	actor.play_animation(&"dead")
	actor.set_physics_process(false)

func physics_update(_delta: float) -> void:
	pass

func evaluate_transitions() -> void:
	pass

func exit() -> void:
	pass
