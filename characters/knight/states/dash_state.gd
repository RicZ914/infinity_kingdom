extends Node

@export var state_name: StringName = &"Dash"
@export var priority: int = 3
@export var interruptible: bool = false

var state_machine: Node
var actor: Node
var elapsed: float = 0.0

func setup(machine: Node, state_actor: Node) -> void:
	state_machine = machine
	actor = state_actor

func enter() -> void:
	elapsed = 0.0
	if actor.get_queued_skill() == &"skill1":
		actor.ensure_skill1_started()
		actor.consume_queued_skill()
	actor.start_dash_from_skill()

func physics_update(delta: float) -> void:
	elapsed += delta
	if actor.process_dash(delta):
		state_machine.transition_to(&"Idle")

func evaluate_transitions() -> void:
	if elapsed >= actor.dash_duration:
		state_machine.transition_to(&"Idle")

func exit() -> void:
	actor.finish_dash()
