extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
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

	var start_button := world.character_select.get("primary_start_button") as Button
	var settings_button := world.character_select.get("settings_button") as Button
	var quit_button := world.character_select.get("quit_button") as Button
	if start_button == null or start_button.text != "开始":
		push_error("Title start button did not switch to Simplified Chinese")
		quit(1)
		return
	if settings_button == null or settings_button.text != "设置":
		push_error("Title settings button did not switch to Simplified Chinese")
		quit(1)
		return
	if quit_button == null or quit_button.text != "退出游戏":
		push_error("Title quit button did not switch to Simplified Chinese")
		quit(1)
		return

	var cards_panel := world.character_select.get("cards_panel") as PanelContainer
	if cards_panel == null or cards_panel.visible:
		push_error("Title screen did not stay on the start menu in Simplified Chinese")
		quit(1)
		return

	world._on_character_selected(&"knight")
	await process_frame
	var run_effects := load("res://systems/run/run_effects.gd")
	var run_director := root.get_node_or_null("/root/RunDirector")
	if run_effects == null:
		push_error("RunEffects script did not load")
		quit(1)
		return
	if run_director == null:
		push_error("RunDirector autoload missing")
		quit(1)
		return
	run_effects.apply_choice("scout_assault", world.player_character)
	var pending_prep := run_director.call("peek_pending_encounter_prep") as Dictionary
	if run_effects.prep_title(pending_prep) != "强袭路线":
		push_error("Scout prep title did not localize to Simplified Chinese")
		quit(1)
		return

	world.run_event_panel.open("scout", 100)
	await process_frame
	var detail_label := world.run_event_panel.get_node("Backdrop/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Detail") as Label
	if detail_label == null or detail_label.text.is_empty() or detail_label.text.find("Scout routes") != -1:
		push_error("Scout event detail text did not switch to Simplified Chinese")
		quit(1)
		return

	quit(0)
