extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := root.get_node_or_null("/root/AccessoryManager")
	if manager == null:
		push_error("AccessoryManager missing")
		quit(1)
		return
	manager.reload_catalog()
	var catalog: Array = manager.get_catalog()
	if catalog.size() < 18:
		push_error("Accessory catalog is unexpectedly small")
		quit(1)
		return
	var seen := {}
	for accessory in catalog:
		var id := String(accessory.get("id", ""))
		if id.is_empty():
			push_error("Accessory has empty id")
			quit(1)
			return
		if seen.has(id):
			push_error("Duplicate accessory id: %s" % id)
			quit(1)
			return
		seen[id] = true
		if not ResourceLoader.exists(String(accessory.get("icon", ""))):
			push_error("Missing accessory icon: %s" % id)
			quit(1)
			return
	var choices: Array = manager.generate_choices(3)
	if choices.size() != 3:
		push_error("Accessory choice generation failed")
		quit(1)
		return
	var seen_choice_ids := {}
	for choice in choices:
		var choice_id := String(choice.get("id", ""))
		if choice_id.is_empty():
			push_error("Generated accessory choice has empty id")
			quit(1)
			return
		if seen_choice_ids.has(choice_id):
			push_error("Accessory choice generation repeated the same item: %s" % choice_id)
			quit(1)
			return
		seen_choice_ids[choice_id] = true
		var offer_meta := choice.get("offer_meta", {}) as Dictionary
		if offer_meta.is_empty():
			push_error("Accessory choice is missing offer metadata: %s" % choice_id)
			quit(1)
			return
		if String(offer_meta.get("fit_label", "")).is_empty():
			push_error("Accessory choice is missing fit label: %s" % choice_id)
			quit(1)
			return
		if String(offer_meta.get("compare_line", "")).is_empty():
			push_error("Accessory choice is missing comparison line: %s" % choice_id)
			quit(1)
			return
		if String(offer_meta.get("source_label", "")).is_empty():
			push_error("Accessory choice is missing source label: %s" % choice_id)
			quit(1)
			return
	quit(0)
