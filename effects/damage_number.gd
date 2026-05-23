extends Label

@export var rise_distance: float = 44.0
@export var lifetime: float = 0.65

var _elapsed: float = 0.0
var _start_position: Vector2 = Vector2.ZERO

func setup(amount: float, is_critical: bool) -> void:
	text = str(int(round(amount)))
	modulate = Color(1.0, 0.95, 0.65, 1.0) if is_critical else Color.WHITE
	scale = Vector2.ONE * (1.4 if is_critical else 1.0)

func _ready() -> void:
	_start_position = position

func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / lifetime, 0.0, 1.0)
	position = _start_position + Vector2(0.0, -rise_distance * progress)
	modulate.a = 1.0 - progress
	if progress >= 1.0:
		queue_free()
