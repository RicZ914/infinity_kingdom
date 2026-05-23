extends Node2D

signal defeated

const SWORDSMAN_SCENE := preload("res://actors/enemy/swordsman_enemy.tscn")
const SHIELD_SCENE := preload("res://actors/enemy/shield_enemy.tscn")
const ARCHER_SCENE := preload("res://actors/enemy/archer_enemy.tscn")
const HUNTER_SCENE := preload("res://actors/enemy/hunter_enemy.tscn")
const APPRENTICE_SCENE := preload("res://actors/enemy/apprentice_mage_enemy.tscn")
const ARCANIST_SCENE := preload("res://actors/enemy/arcanist_enemy.tscn")

@onready var enemy_layer: Node2D = $EnemyLayer
@onready var spawn_layer: Node2D = $SpawnLayer

var target: Node2D = null
var active_enemies: Array[Node] = []
var wave_index: int = -1
var waiting_for_next_wave: bool = false

var wave_defs := [
	{
		"title": "Frontline Probe",
		"units": [
			{"scene": SWORDSMAN_SCENE, "spawn": 0},
			{"scene": SWORDSMAN_SCENE, "spawn": 1},
			{"scene": SHIELD_SCENE, "spawn": 2},
			{"scene": SHIELD_SCENE, "spawn": 3}
		]
	},
	{
		"title": "Crossfire Patrol",
		"units": [
			{"scene": SWORDSMAN_SCENE, "spawn": 0},
			{"scene": SWORDSMAN_SCENE, "spawn": 1},
			{"scene": ARCHER_SCENE, "spawn": 4},
			{"scene": ARCHER_SCENE, "spawn": 5},
			{"scene": HUNTER_SCENE, "spawn": 6}
		]
	},
	{
		"title": "Shadow and Spell",
		"units": [
			{"scene": SHIELD_SCENE, "spawn": 2},
			{"scene": HUNTER_SCENE, "spawn": 6},
			{"scene": HUNTER_SCENE, "spawn": 7},
			{"scene": APPRENTICE_SCENE, "spawn": 4},
			{"scene": APPRENTICE_SCENE, "spawn": 5}
		]
	},
	{
		"title": "Arcane Command",
		"units": [
			{"scene": SWORDSMAN_SCENE, "spawn": 0, "elite": true},
			{"scene": SHIELD_SCENE, "spawn": 2, "elite": true},
			{"scene": ARCHER_SCENE, "spawn": 4, "elite": true},
			{"scene": HUNTER_SCENE, "spawn": 6, "elite": true},
			{"scene": APPRENTICE_SCENE, "spawn": 5},
			{"scene": ARCANIST_SCENE, "spawn": 8}
		]
	}
]

func _ready() -> void:
	_build_spawn_markers()

func bind_player(player: Node2D) -> void:
	target = player
	_start_next_wave()

func get_status_title() -> String:
	return "Town Enemy Sweep"

func get_status_text() -> String:
	if wave_index >= wave_defs.size():
		return "All enemy waves cleared."
	var wave_name: String = String(wave_defs[wave_index]["title"]) if wave_index >= 0 else "Preparing"
	return "Wave %d / %d\n%s\nEnemies remaining %d" % [
		max(wave_index + 1, 1),
		wave_defs.size(),
		String(wave_name),
		active_enemies.size()
	]

func _physics_process(_delta: float) -> void:
	if active_enemies.is_empty() and not waiting_for_next_wave and wave_index >= 0:
		waiting_for_next_wave = true
		var timer := get_tree().create_timer(1.1)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(self):
				_start_next_wave()
		)

func _start_next_wave() -> void:
	waiting_for_next_wave = false
	wave_index += 1
	if wave_index >= wave_defs.size():
		defeated.emit()
		queue_free()
		return
	active_enemies.clear()
	var wave: Dictionary = wave_defs[wave_index]
	for unit_def in wave["units"]:
		var scene: PackedScene = unit_def["scene"] as PackedScene
		var enemy: Node = scene.instantiate()
		if unit_def.get("elite", false):
			enemy.elite = true
		var marker: Marker2D = spawn_layer.get_child(int(unit_def["spawn"]))
		enemy_layer.add_child(enemy)
		enemy.global_position = marker.global_position
		if enemy.has_method("bind_player"):
			enemy.bind_player(target)
		if enemy.has_signal("defeated"):
			enemy.defeated.connect(_on_enemy_defeated.bind(enemy))
		active_enemies.append(enemy)

func _on_enemy_defeated(enemy: Node) -> void:
	active_enemies.erase(enemy)

func _build_spawn_markers() -> void:
	var positions := [
		Vector2(-250.0, -110.0),
		Vector2(250.0, -110.0),
		Vector2(-200.0, -10.0),
		Vector2(200.0, -10.0),
		Vector2(-260.0, -210.0),
		Vector2(260.0, -210.0),
		Vector2(-320.0, 120.0),
		Vector2(320.0, 120.0),
		Vector2(0.0, -240.0)
	]
	for index in range(positions.size()):
		var marker := Marker2D.new()
		marker.name = "Spawn%d" % index
		marker.position = positions[index]
		spawn_layer.add_child(marker)
