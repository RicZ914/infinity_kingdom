extends Node

@export var state_name: StringName = &"Dash"
@export var priority: int = 4
@export var interruptible: bool = false

var state_machine: Node
var actor: Node
var elapsed: float = 0.0

func setup(machine: Node, state_actor: Node) -> void:
	state_machine = machine
	actor = state_actor

func enter() -> void:
	elapsed = 0.0
	actor.consume_queued_skill()
	actor.start_roll()

func physics_update(delta: float) -> void:
	elapsed += delta
	actor.process_roll(delta)

func evaluate_transitions() -> void:
	if elapsed >= actor.dash_duration:
		state_machine.transition_to(&"Idle")

func exit() -> void:
	actor.finish_roll()
