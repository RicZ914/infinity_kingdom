extends SceneTree

const OUTPUT_DIR := "res://.tmp/ui_review"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var ui_settings := root.get_node_or_null("/root/UISettings")
	if ui_settings != null and ui_settings.has_method("set_locale"):
		ui_settings.call("set_locale", "zh_Hans", false)
	var world_scene := load("res://world.tscn") as PackedScene
	if world_scene == null:
		push_error("world.tscn did not load")
		quit(1)
		return
	var world := world_scene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	await _capture_world(world, Vector2i(1280, 720), "title_menu_zh_hans_1280x720.png")
	await _capture_world(world, Vector2i(720, 540), "title_menu_zh_hans_720x540.png")

	if world.character_select != null and world.character_select.has_method("_show_hero_select"):
		world.character_select._show_hero_select()
	await process_frame
	await process_frame
	await _capture_world(world, Vector2i(1280, 720), "title_select_zh_hans_1280x720.png")

	if world.has_method("_on_character_selected"):
		world._on_character_selected(&"knight")
	await process_frame
	await process_frame
	await _capture_world(world, Vector2i(1280, 720), "relic_offer_zh_hans_1280x720.png")
	await _capture_world(world, Vector2i(720, 540), "relic_offer_zh_hans_720x540.png")
	if world.accessory_choice != null and world.accessory_choice.has_method("close"):
		world.accessory_choice.close()
	if world.run_event_panel != null and world.run_event_panel.has_method("open"):
		world.run_event_panel.open("forge", 100)
	await process_frame
	await process_frame
	await _capture_world(world, Vector2i(1280, 720), "forge_event_zh_hans_1280x720.png")
	await _capture_world(world, Vector2i(720, 540), "forge_event_zh_hans_720x540.png")

	world.queue_free()
	await process_frame
	quit(0)

func _capture_world(world: Node, viewport_size: Vector2i, filename: String) -> void:
	root.size = viewport_size
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(viewport_size)
	_set_layout_override(world.character_select, viewport_size)
	_set_layout_override(world.pause_menu, viewport_size)
	_set_layout_override(world.audio_settings_panel, viewport_size)
	_set_layout_override(world.settings_panel, viewport_size)
	_set_layout_override(world.debug_panel, viewport_size)
	_set_layout_override(world.audio_shortcut_hint, viewport_size)
	_set_layout_override(world.accessory_choice, viewport_size)
	_set_layout_override(world.run_event_panel, viewport_size)
	_set_layout_override(world.result_screen, viewport_size)
	_set_layout_override(world.battle_status, viewport_size)
	_set_layout_override(world.character_hud, viewport_size)
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("Viewport capture failed for %s" % filename)
		return
	image.save_png(ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename]))

func _set_layout_override(target: Object, viewport_size: Vector2i) -> void:
	if target == null:
		return
	target.set("layout_size_override", Vector2(viewport_size))
	if target.has_method("_queue_layout_refresh"):
		target.call("_queue_layout_refresh")
