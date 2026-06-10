extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cheat_mode := root.get_node_or_null("/root/CheatMode")
	if cheat_mode == null:
		push_error("CheatMode autoload missing")
		quit(1)
		return
	cheat_mode.reset_session()

	var app_scene := load("res://app_entry.tscn") as PackedScene
	if app_scene == null:
		push_error("app_entry.tscn did not load")
		quit(1)
		return
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame

	var sequence := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_LEFT, KEY_RIGHT, KEY_RIGHT, KEY_A, KEY_A, KEY_B, KEY_B]
	for keycode in sequence:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = true
		app._input(event)

	if not bool(cheat_mode.enabled) or not bool(cheat_mode.infinite_hp):
		push_error("App entry cheat sequence did not enable CheatMode")
		quit(1)
		return
	var notice_panel := app.get("cheat_notice_panel") as PanelContainer
	if notice_panel == null or not notice_panel.visible:
		push_error("Cheat notice did not become visible")
		quit(1)
		return

	app.queue_free()
	await process_frame
	quit(0)
