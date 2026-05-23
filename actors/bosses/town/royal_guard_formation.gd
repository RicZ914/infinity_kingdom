extends Node2D

signal defeated

const GUARD_SCENE := preload("res://actors/bosses/town/guard_unit.tscn")

@onready var line_layer: Node2D = $LineLayer
@onready var unit_layer: Node2D = $UnitLayer

var target: Node2D = null
var fixed_guards: Array[Node] = []
var mobile_guards: Array[Node] = []
var all_guards: Array[Node] = []
var link_lines: Array[Line2D] = []
var left_lane_line: Line2D
var right_lane_line: Line2D
var coverage_progress: float = 0.0
var encounter_finished: bool = false
var immune_phase_active: bool = true

func _ready() -> void:
	_build_lines()
	_spawn_guards()

func bind_player(player: Node2D) -> void:
	target = player
	for guard in all_guards:
		if is_instance_valid(guard):
			guard.bind_player(player)

func get_status_title() -> String:
	return "Royal Guard Formation"

func get_status_text() -> String:
	if encounter_finished:
		return "Formation collapsed."
	var immune_text := "Immune" if coverage_progress < 1.0 else "Vulnerable"
	return "%s\nCoverage %d%% | Guards remaining %d" % [
		immune_text,
		int(round(coverage_progress * 100.0)),
		all_guards.size()
	]

func _physics_process(delta: float) -> void:
	if encounter_finished:
		return
	coverage_progress = minf(coverage_progress + delta / 12.0, 1.0)
	var lane_extent := lerpf(50.0, 220.0, coverage_progress)
	for guard in mobile_guards:
		if is_instance_valid(guard):
			guard.set_lane_extent(lane_extent)
	var formation_immune := coverage_progress < 1.0
	if immune_phase_active and not formation_immune:
		immune_phase_active = false
		Sfx.play_event(&"boss_guard_immune_break", global_position)
	for guard in all_guards:
		if is_instance_valid(guard):
			guard.set_immune(formation_immune)
	_update_line_visuals(lane_extent, formation_immune)
	if all_guards.is_empty() and not encounter_finished:
		encounter_finished = true
		defeated.emit()
		queue_free()

func _spawn_guards() -> void:
	var positions := [
		Vector2(-220.0, -150.0),
		Vector2(220.0, -150.0),
		Vector2(-220.0, 150.0),
		Vector2(220.0, 150.0),
		Vector2(0.0, 0.0)
	]
	for guard_position in positions:
		var guard := GUARD_SCENE.instantiate()
		unit_layer.add_child(guard)
		guard.position = guard_position
		guard.bind_player(target)
		guard.defeated.connect(_on_guard_defeated.bind(guard))
		fixed_guards.append(guard)
		all_guards.append(guard)
	var left_mobile := GUARD_SCENE.instantiate()
	unit_layer.add_child(left_mobile)
	left_mobile.setup_lane(true, Vector2(-90.0, 0.0), Vector2.UP)
	left_mobile.position = Vector2(-90.0, 0.0)
	left_mobile.bind_player(target)
	left_mobile.defeated.connect(_on_guard_defeated.bind(left_mobile))
	mobile_guards.append(left_mobile)
	all_guards.append(left_mobile)
	var right_mobile := GUARD_SCENE.instantiate()
	unit_layer.add_child(right_mobile)
	right_mobile.setup_lane(true, Vector2(90.0, 0.0), Vector2.UP)
	right_mobile.position = Vector2(90.0, 0.0)
	right_mobile.bind_player(target)
	right_mobile.defeated.connect(_on_guard_defeated.bind(right_mobile))
	mobile_guards.append(right_mobile)
	all_guards.append(right_mobile)

func _build_lines() -> void:
	var square_points := [
		Vector2(-220.0, -150.0),
		Vector2(220.0, -150.0),
		Vector2(220.0, 150.0),
		Vector2(-220.0, 150.0)
	]
	for index in range(square_points.size()):
		var next_index := (index + 1) % square_points.size()
		link_lines.append(_add_line([square_points[index], square_points[next_index]], 2.0))
	for point in square_points:
		link_lines.append(_add_line([Vector2.ZERO, point], 2.0))
	left_lane_line = _add_line([Vector2(-90.0, -50.0), Vector2(-90.0, 50.0)], 3.0)
	right_lane_line = _add_line([Vector2(90.0, -50.0), Vector2(90.0, 50.0)], 3.0)

func _add_line(points: Array, width: float) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = Color(0.7, 0.88, 1.0, 0.52)
	var packed := PackedVector2Array()
	for point in points:
		packed.append(point)
	line.points = packed
	line_layer.add_child(line)
	return line

func _update_line_visuals(lane_extent: float, immune: bool) -> void:
	var alpha := 0.45 + 0.18 * sin(Time.get_ticks_msec() * 0.008)
	for line in link_lines:
		line.default_color = Color(0.7, 0.88, 1.0, alpha) if immune else Color(1.0, 0.82, 0.52, 0.55)
	left_lane_line.points = PackedVector2Array([
		Vector2(-90.0, -lane_extent),
		Vector2(-90.0, lane_extent)
	])
	right_lane_line.points = PackedVector2Array([
		Vector2(90.0, -lane_extent),
		Vector2(90.0, lane_extent)
	])
	left_lane_line.default_color = Color(0.74, 0.9, 1.0, 0.82)
	right_lane_line.default_color = Color(0.74, 0.9, 1.0, 0.82)

func _on_guard_defeated(guard: Node) -> void:
	all_guards.erase(guard)
	fixed_guards.erase(guard)
	mobile_guards.erase(guard)
