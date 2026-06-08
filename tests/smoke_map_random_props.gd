extends SceneTree

const MapRuntime := preload("res://systems/map/map_runtime.gd")
const MapBrowserDemo := preload("res://tools/map_browser_demo.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world_root := Node2D.new()
	root.add_child(world_root)

	var spawn_marker := Marker2D.new()
	var encounter_marker := Marker2D.new()
	world_root.add_child(spawn_marker)
	world_root.add_child(encounter_marker)

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260608

	var map_runtime := MapRuntime.new()
	root.add_child(map_runtime)
	map_runtime.setup(world_root, spawn_marker, encounter_marker, rng)
	map_runtime.build()
	await process_frame

	var prop_root := world_root.find_child("RuntimeRoomProps", true, false)
	if prop_root == null:
		push_error("Runtime map did not create random prop root")
		quit(1)
		return

	var prop_bodies := prop_root.find_children("*Prop", "StaticBody2D", true, false)
	if prop_bodies.size() < 8:
		push_error("Runtime map created too few random props: %d" % prop_bodies.size())
		quit(1)
		return

	var alpha_collision_count := 0
	var room_rects: Array = map_runtime.get("map_room_rects")
	var walkable_rects: Array = map_runtime.get("map_walkable_rects")
	var props_by_room := {}
	for body in prop_bodies:
		if body is StaticBody2D and not (body as StaticBody2D).is_in_group("projectile_blocker"):
			push_error("Random prop is not a projectile blocker: %s" % body.name)
			quit(1)
			return
		alpha_collision_count += body.find_children("AlphaCollision*", "CollisionPolygon2D", true, false).size()
		var sprite := body.get_node_or_null("Sprite") as Sprite2D
		if sprite == null or sprite.texture == null:
			push_error("Random prop is missing sprite texture: %s" % body.name)
			quit(1)
			return
		var room_index := int((body as StaticBody2D).get_meta("room_index", -1))
		if room_index < 0:
			push_error("Random prop is missing room metadata: %s" % body.name)
			quit(1)
			return
		props_by_room[room_index] = int(props_by_room.get(room_index, 0)) + 1
		var prop_size := (body as StaticBody2D).get_meta("prop_size", Vector2(sprite.texture.get_width(), sprite.texture.get_height()) * sprite.scale) as Vector2
		if not MapBrowserDemo.is_generated_prop_size_usable(prop_size, (room_rects[room_index] as Rect2).size):
			push_error("Random prop size filter failed for %s with size %s" % [body.name, prop_size])
			quit(1)
			return
		var prop_rect := Rect2((body as StaticBody2D).global_position - prop_size * 0.5, prop_size)
		var walk_rect := walkable_rects[room_index] as Rect2
		var player_spawn := map_runtime.player_spawn_for_room(room_index)
		var encounter_spawn := map_runtime.encounter_spawn_for_room(room_index)
		if not MapBrowserDemo.is_cover_position_valid(prop_rect, walk_rect, [], player_spawn, encounter_spawn):
			push_error("Random prop blocks reserved walking lanes: %s" % body.name)
			quit(1)
			return

	if alpha_collision_count < prop_bodies.size():
		push_error("Random props did not create alpha collision polygons")
		quit(1)
		return

	for room_index in props_by_room.keys():
		var count := int(props_by_room[room_index])
		if count > MapBrowserDemo.RANDOM_PROP_MAX_PER_ROOM:
			push_error("Room %d has too many random props: %d" % [int(room_index) + 1, count])
			quit(1)
			return

	quit(0)
