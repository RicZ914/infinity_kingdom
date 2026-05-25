extends Node2D

signal defeated

const SWORDSMAN_SCENE := preload("res://actors/enemy/swordsman_enemy.tscn")
const SHIELD_SCENE := preload("res://actors/enemy/shield_enemy.tscn")
const ARCHER_SCENE := preload("res://actors/enemy/archer_enemy.tscn")
const HUNTER_SCENE := preload("res://actors/enemy/hunter_enemy.tscn")
const APPRENTICE_SCENE := preload("res://actors/enemy/apprentice_mage_enemy.tscn")
const ARCANIST_SCENE := preload("res://actors/enemy/arcanist_enemy.tscn")
const TownEnemy := preload("res://actors/enemy/town_enemy.gd")

@onready var enemy_layer: Node2D = $EnemyLayer
@onready var spawn_layer: Node2D = $SpawnLayer

var target: Node2D = null
var active_enemies: Array[Node] = []
var wave_index: int = -1
var waiting_for_next_wave: bool = false
var active_waves: Array[Dictionary] = []
var active_modifier: Dictionary = {}
var rng := RandomNumberGenerator.new()

var wave_pool := [
	{
		"title": "Frontline Probe",
		"tags": ["frontline", "shield"],
		"units": [
			{"scene": SWORDSMAN_SCENE, "spawn": 0},
			{"scene": SWORDSMAN_SCENE, "spawn": 1},
			{"scene": SHIELD_SCENE, "spawn": 2},
			{"scene": SHIELD_SCENE, "spawn": 3}
		]
	},
	{
		"title": "Crossfire Patrol",
		"tags": ["ranged", "hunters"],
		"units": [
			{"scene": SWORDSMAN_SCENE, "spawn": 0},
			{"scene": SWORDSMAN_SCENE, "spawn": 1},
			{"scene": ARCHER_SCENE, "spawn": 4},
			{"scene": ARCHER_SCENE, "spawn": 5},
			{"scene": HUNTER_SCENE, "spawn": 6}
		]
	},
	{
		"title": "Shielded Volley",
		"tags": ["ranged", "shield", "arcane"],
		"units": [
			{"scene": SHIELD_SCENE, "spawn": 2},
			{"scene": SHIELD_SCENE, "spawn": 3},
			{"scene": ARCHER_SCENE, "spawn": 4},
			{"scene": ARCHER_SCENE, "spawn": 5},
			{"scene": APPRENTICE_SCENE, "spawn": 8}
		]
	},
	{
		"title": "Hunter Pincer",
		"tags": ["hunters", "ranged"],
		"units": [
			{"scene": SWORDSMAN_SCENE, "spawn": 0},
			{"scene": HUNTER_SCENE, "spawn": 6},
			{"scene": HUNTER_SCENE, "spawn": 7},
			{"scene": ARCHER_SCENE, "spawn": 4},
			{"scene": ARCHER_SCENE, "spawn": 5}
		]
	},
	{
		"title": "Shadow and Spell",
		"tags": ["hunters", "arcane"],
		"units": [
			{"scene": SHIELD_SCENE, "spawn": 2},
			{"scene": HUNTER_SCENE, "spawn": 6},
			{"scene": HUNTER_SCENE, "spawn": 7},
			{"scene": APPRENTICE_SCENE, "spawn": 4},
			{"scene": APPRENTICE_SCENE, "spawn": 5}
		]
	}
]

var final_wave := {
	"title": "Arcane Command",
	"tags": ["final", "ranged", "arcane", "shield"],
	"units": [
		{"scene": SWORDSMAN_SCENE, "spawn": 0, "elite": true},
		{"scene": SHIELD_SCENE, "spawn": 2, "elite": true},
		{"scene": ARCHER_SCENE, "spawn": 4, "elite": true},
		{"scene": HUNTER_SCENE, "spawn": 6, "elite": true},
		{"scene": APPRENTICE_SCENE, "spawn": 5},
		{"scene": ARCANIST_SCENE, "spawn": 8}
	]
}

var modifier_pool := [
	{
		"id": "fortified",
		"title": "Fortified Line",
		"summary": "Shield carriers reinforce every wave with heavier front-loaded pressure.",
		"hint": "Break shield carriers first or kite until the frontline opens.",
		"preferred_tags": ["shield", "frontline"],
		"global_hp_scale": 1.18,
		"shield_defense_scale": 1.35,
		"shield_elite": true
	},
	{
		"id": "relentless",
		"title": "Relentless March",
		"summary": "All enemies rotate back in faster and give you shorter recovery windows.",
		"hint": "Do not spend movement too early. The next engage comes back faster than normal.",
		"preferred_tags": ["frontline", "hunters"],
		"global_move_speed_scale": 1.12,
		"global_attack_interval_scale": 0.86,
		"global_detection_scale": 1.08
	},
	{
		"id": "crossfire",
		"title": "Crossfire Lanes",
		"summary": "Archers and casters hold lanes longer and punish loose positioning.",
		"hint": "The backline is the timer. Collapse on ranged units before flankers arrive.",
		"preferred_tags": ["ranged", "arcane"],
		"ranged_attack_damage_scale": 1.15,
		"ranged_attack_interval_scale": 0.78,
		"ranged_attack_range_scale": 1.12,
		"ranged_detection_scale": 1.18
	},
	{
		"id": "hunt_pack",
		"title": "Hunt Pack",
		"summary": "Hunters and skirmishers surge forward to punish stalled footwork.",
		"hint": "Expect harder flanks. Reposition early so hunters cannot pin you into volleys.",
		"preferred_tags": ["hunters", "ranged"],
		"swordsman_move_speed_scale": 1.18,
		"swordsman_attack_damage_scale": 1.10,
		"hunter_move_speed_scale": 1.30,
		"hunter_attack_interval_scale": 0.78,
		"hunter_attack_damage_scale": 1.14
	}
]

func _ready() -> void:
	rng.randomize()
	_build_spawn_markers()

func bind_player(player: Node2D) -> void:
	target = player
	active_modifier = _roll_modifier()
	active_waves = _build_active_waves()
	_start_next_wave()

func get_status_title() -> String:
	return "Town Enemy Sweep"

func get_status_text() -> String:
	if active_waves.is_empty():
		return "Scouts are forming up."
	if wave_index >= active_waves.size():
		return "All enemy waves cleared."
	var wave_name: String = String(active_waves[wave_index]["title"]) if wave_index >= 0 and wave_index < active_waves.size() else "Preparing"
	var modifier_title := get_modifier_title()
	return "Wave %d / %d\n%s\nModifier: %s\nEnemies remaining %d" % [
		max(wave_index + 1, 1),
		active_waves.size(),
		String(wave_name),
		modifier_title if not modifier_title.is_empty() else "Standard Patrol",
		active_enemies.size()
	]

func get_modifier_title() -> String:
	return String(active_modifier.get("title", ""))

func get_modifier_hint() -> String:
	return String(active_modifier.get("hint", ""))

func get_modifier_summary() -> String:
	return String(active_modifier.get("summary", ""))

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
	if wave_index >= active_waves.size():
		defeated.emit()
		queue_free()
		return
	active_enemies.clear()
	var wave: Dictionary = active_waves[wave_index]
	var final_wave_active := wave_index >= active_waves.size() - 1
	for unit_def in wave["units"]:
		var scene: PackedScene = unit_def["scene"] as PackedScene
		var enemy: Node = scene.instantiate()
		enemy.set("elite", bool(unit_def.get("elite", false)))
		_apply_modifier_to_enemy(enemy, final_wave_active)
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

func _build_active_waves() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for wave in wave_pool:
		pool.append((wave as Dictionary).duplicate(true))
	var selection: Array[Dictionary] = []
	var preferred_tags: Array = active_modifier.get("preferred_tags", [])
	while selection.size() < 2 and not pool.is_empty() and not preferred_tags.is_empty():
		var matching_indices: Array[int] = []
		for wave_index_value in range(pool.size()):
			if _wave_matches_modifier(pool[wave_index_value], preferred_tags):
				matching_indices.append(wave_index_value)
		if matching_indices.is_empty():
			break
		var preferred_index := matching_indices[rng.randi_range(0, matching_indices.size() - 1)]
		selection.append(pool[preferred_index])
		pool.remove_at(preferred_index)
	while selection.size() < 3 and not pool.is_empty():
		var next_index := rng.randi_range(0, pool.size() - 1)
		selection.append(pool[next_index])
		pool.remove_at(next_index)
	selection.append((final_wave as Dictionary).duplicate(true))
	return selection

func _roll_modifier() -> Dictionary:
	if modifier_pool.is_empty():
		return {}
	var modifier_index := rng.randi_range(0, modifier_pool.size() - 1)
	return (modifier_pool[modifier_index] as Dictionary).duplicate(true)

func _apply_modifier_to_enemy(enemy: Object, final_wave_active: bool) -> void:
	if enemy == null or active_modifier.is_empty():
		return
	_scale_property(enemy, "max_hp", float(active_modifier.get("global_hp_scale", 1.0)))
	_scale_property(enemy, "move_speed", float(active_modifier.get("global_move_speed_scale", 1.0)))
	_scale_property(enemy, "attack_interval", float(active_modifier.get("global_attack_interval_scale", 1.0)))
	_scale_property(enemy, "detection_range", float(active_modifier.get("global_detection_scale", 1.0)))

	if _unit_is_type(enemy, TownEnemy.EnemyType.SHIELD):
		_scale_property(enemy, "defense_value", float(active_modifier.get("shield_defense_scale", 1.0)))
		if bool(active_modifier.get("shield_elite", false)):
			enemy.set("elite", true)

	if _unit_is_type(enemy, TownEnemy.EnemyType.ARCHER) or _unit_is_type(enemy, TownEnemy.EnemyType.APPRENTICE_MAGE) or _unit_is_type(enemy, TownEnemy.EnemyType.ARCANIST):
		_scale_property(enemy, "attack_damage", float(active_modifier.get("ranged_attack_damage_scale", 1.0)))
		_scale_property(enemy, "attack_interval", float(active_modifier.get("ranged_attack_interval_scale", 1.0)))
		_scale_property(enemy, "attack_range", float(active_modifier.get("ranged_attack_range_scale", 1.0)))
		_scale_property(enemy, "detection_range", float(active_modifier.get("ranged_detection_scale", 1.0)))
		if final_wave_active and bool(active_modifier.get("ranged_elite_final_wave", false)):
			enemy.set("elite", true)

	if _unit_is_type(enemy, TownEnemy.EnemyType.SWORDSMAN):
		_scale_property(enemy, "move_speed", float(active_modifier.get("swordsman_move_speed_scale", 1.0)))
		_scale_property(enemy, "attack_damage", float(active_modifier.get("swordsman_attack_damage_scale", 1.0)))

	if _unit_is_type(enemy, TownEnemy.EnemyType.HUNTER):
		_scale_property(enemy, "move_speed", float(active_modifier.get("hunter_move_speed_scale", 1.0)))
		_scale_property(enemy, "attack_interval", float(active_modifier.get("hunter_attack_interval_scale", 1.0)))
		_scale_property(enemy, "attack_damage", float(active_modifier.get("hunter_attack_damage_scale", 1.0)))

func _wave_matches_modifier(wave: Dictionary, preferred_tags: Array) -> bool:
	var tags_value: Variant = wave.get("tags", [])
	if not (tags_value is Array):
		return false
	for tag in preferred_tags:
		if (tags_value as Array).has(tag):
			return true
	return false

func _unit_is_type(enemy: Object, enemy_type: int) -> bool:
	return _has_property(enemy, "enemy_type") and int(enemy.get("enemy_type")) == enemy_type

func _scale_property(target: Object, field: String, scale: float) -> void:
	if target == null or is_equal_approx(scale, 1.0) or not _has_property(target, field):
		return
	target.set(field, float(target.get(field)) * scale)

func _has_property(target: Object, field: String) -> bool:
	if target == null:
		return false
	for property in target.get_property_list():
		if String(property.get("name", "")) == field:
			return true
	return false
