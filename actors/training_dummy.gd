extends Node2D

signal damaged(amount: float, hp_value: float)
signal defeated

@export var max_hp: float = 400.0
@export var defense: float = 40.0
@export var knock_up_visual_height: float = 18.0

@onready var body: Polygon2D = $Body
@onready var health_component: Node = $HealthComponent
@onready var effects_layer: Node2D = $EffectsLayer

const DAMAGE_NUMBER_SCENE := preload("res://effects/damage_number.tscn")

var base_position: Vector2 = Vector2.ZERO
var knock_up_time_remaining: float = 0.0
var knock_up_total_duration: float = 0.0

func _ready() -> void:
	base_position = position
	add_to_group("damageable")
	health_component.setup(max_hp, defense)
	health_component.damaged.connect(_on_damaged)
	health_component.knocked_up.connect(_on_knocked_up)
	health_component.died.connect(_on_died)

func _process(delta: float) -> void:
	if knock_up_time_remaining > 0.0:
		knock_up_time_remaining = maxf(knock_up_time_remaining - delta, 0.0)
		var progress := 1.0 - knock_up_time_remaining / maxf(knock_up_total_duration, 0.001)
		var offset := sin(progress * PI) * knock_up_visual_height
		position.y = base_position.y - offset
	else:
		position = base_position

func receive_hit(payload: Dictionary) -> void:
	var result: Dictionary = health_component.receive_hit(payload)
	var damage := float(result.get("damage", 0.0))
	if damage > 0.0:
		_spawn_damage_number(damage, bool(result.get("is_critical", false)))

func _on_damaged(amount: float, remaining_hp: float, _source: Node) -> void:
	damaged.emit(amount, remaining_hp)
	body.color = Color(1.0, 0.55, 0.55, 1.0)
	var timer := get_tree().create_timer(0.12)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(body):
			body.color = Color(0.7, 0.2, 0.2, 1.0)
	)

func _on_knocked_up(duration: float) -> void:
	knock_up_total_duration = duration
	knock_up_time_remaining = duration

func _on_died() -> void:
	defeated.emit()
	queue_free()

func _spawn_damage_number(amount: float, is_critical: bool) -> void:
	var damage_number := DAMAGE_NUMBER_SCENE.instantiate()
	damage_number.position = Vector2(0.0, -36.0)
	damage_number.setup(amount, is_critical)
	effects_layer.add_child(damage_number)
