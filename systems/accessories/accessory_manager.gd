extends Node

signal accessory_equipped(accessory: Dictionary)
signal choices_generated(choices: Array[Dictionary])

const ACCESSORY_DATA_PATH := "res://systems/accessories/accessories.json"
const TAG_LABELS := {
	"attack": "Attack",
	"crit": "Crit",
	"damage": "Damage",
	"defense": "Defense",
	"power": "Power",
	"resource": "Resource",
	"risk": "Risk",
	"skill": "Skill",
	"speed": "Speed",
	"survival": "Survival",
	"tempo": "Tempo"
}

const TAG_LABELS_LOCALIZED := {
	"zh_Hans": {
		"attack": "攻击",
		"crit": "暴击",
		"damage": "伤害",
		"defense": "防御",
		"power": "强能",
		"resource": "资源",
		"risk": "风险",
		"skill": "技能",
		"speed": "速度",
		"survival": "生存",
		"tempo": "节奏"
	},
	"zh_Hant": {
		"attack": "攻擊",
		"crit": "暴擊",
		"damage": "傷害",
		"defense": "防禦",
		"power": "強能",
		"resource": "資源",
		"risk": "風險",
		"skill": "技能",
		"speed": "速度",
		"survival": "生存",
		"tempo": "節奏"
	}
}

const TAG_PLAYSTYLE_HINTS := {
	"attack": "Improves repeated basic pressure and rewards staying on target.",
	"crit": "Raises burst variance and scales best with fast hit volume.",
	"damage": "Pushes direct kill speed and helps finish elite checks sooner.",
	"defense": "Restores armor value and buys room for mistakes in long fights.",
	"power": "Favors skill-centered burst windows over attrition.",
	"resource": "Feeds inspiration economy so your strongest tools come back sooner.",
	"risk": "Pays off hardest when you stay aggressive on low health.",
	"skill": "Supports cooldown, control, and direct skill conversion.",
	"speed": "Makes dodges, flanks, and reposition checks easier to pass cleanly.",
	"survival": "Stabilizes rough runs and softens recovery mistakes.",
	"tempo": "Keeps momentum rolling once you start landing skills or kills."
}

const TAG_PLAYSTYLE_HINTS_LOCALIZED := {
	"zh_Hans": {
		"attack": "强化普攻压制力，适合持续贴身输出。",
		"crit": "提高爆发上限，命中频率越高收益越明显。",
		"damage": "直接提升斩杀速度，更容易通过精英与 Boss 检定。",
		"defense": "补足护甲价值，让长线战斗容错更高。",
		"power": "偏向技能爆发窗口，而不是拖长消耗。",
		"resource": "改善灵感循环，让强技能更快转回来。",
		"risk": "血线越低越敢打时，收益才会真正放大。",
		"skill": "强化冷却、控制与技能本体转化。",
		"speed": "更容易通过闪避、绕背和走位检查。",
		"survival": "让逆风局更稳，也更容易修正失误。",
		"tempo": "一旦打出节奏，就能把优势继续滚下去。"
	},
	"zh_Hant": {
		"attack": "強化普攻壓制力，適合持續貼身輸出。",
		"crit": "提高爆發上限，命中頻率越高收益越明顯。",
		"damage": "直接提升斬殺速度，更容易通過精英與 Boss 檢定。",
		"defense": "補足護甲價值，讓長線戰鬥容錯更高。",
		"power": "偏向技能爆發窗口，而不是拖長消耗。",
		"resource": "改善靈感循環，讓強技能更快轉回來。",
		"risk": "血線越低越敢打時，收益才會真正放大。",
		"skill": "強化冷卻、控制與技能本體轉化。",
		"speed": "更容易通過閃避、繞背和走位檢查。",
		"survival": "讓逆風局更穩，也更容易修正失誤。",
		"tempo": "一旦打出節奏，就能把優勢繼續滾下去。"
	}
}

const RARITY_LABELS_LOCALIZED := {
	"zh_Hans": {
		"Common": "普通",
		"Uncommon": "精良",
		"Rare": "稀有",
		"Epic": "史诗",
		"Legendary": "传说"
	},
	"zh_Hant": {
		"Common": "普通",
		"Uncommon": "精良",
		"Rare": "稀有",
		"Epic": "史詩",
		"Legendary": "傳說"
	}
}

const ACCESSORY_LOCALIZATION := {
	"zh_Hans": {
		"none": {"name": "无饰品", "summary": "选择一件饰品来决定这一局的构筑方向。"},
		"ember_talisman": {"name": "余烬护符", "summary": "最大灵感 +20，每次命中额外恢复 1 点灵感。"},
		"wind_knot": {"name": "风结", "summary": "移动速度 +18%，普通攻击节奏略微加快。"},
		"wolf_pendant": {"name": "狼坠", "summary": "攻击伤害 +15%，暴击率 +6%。"},
		"echo_silver_ring": {"name": "回响银戒", "summary": "技能冷却更快，普攻回灵更多。"},
		"iron_branch_pendant": {"name": "铁枝坠饰", "summary": "最大生命 +18，最大护甲 +18。"},
		"shadow_charm": {"name": "影咒", "summary": "移动速度 +12%，暴击率 +10%。"},
		"fate_reversal_ring": {"name": "逆命之环", "summary": "最大生命 +30，攻击伤害 +12%，但技能消耗更高。"},
		"old_king_crest": {"name": "旧王纹章", "summary": "最大护甲 +25，技能伤害 +18%。"},
		"hunter_bone_charm": {"name": "猎骨符", "summary": "攻击伤害 +10%，移动速度 +14%。"},
		"nameless_astrolabe": {"name": "无名星盘", "summary": "最大灵感 +25，技能冷却 -15%。"},
		"throne_remnant": {"name": "王座残片", "summary": "攻击与技能伤害 +20%，最大护甲 +20。"},
		"field_band": {"name": "绑缚绷带", "summary": "最大生命 +12，最大护甲 +6。"},
		"sparring_token": {"name": "试锋令牌", "summary": "攻击伤害 +8%，普通攻击略微提速。"},
		"gleam_feather": {"name": "曦羽", "summary": "移动速度 +16%，最大灵感 +12。"},
		"pilgrim_censer": {"name": "朝圣香炉", "summary": "最大灵感 +18，技能伤害 +10%。"},
		"oathwire_loop": {"name": "誓丝环", "summary": "技能冷却 -10%，暴击率 +8%。"},
		"crimson_locket": {"name": "绯焰坠饰", "summary": "攻击伤害 +12%，普通攻击节奏更快。"},
		"warden_vambrace": {"name": "卫城臂甲", "summary": "最大生命 +24，最大护甲 +12，移动速度 +8%。"},
		"moonlit_quill": {"name": "月魄羽笔", "summary": "暴击率 +14%，攻击伤害 +10%，但最大护甲 -10。"},
		"starvein_compass": {"name": "星脉罗盘", "summary": "最大灵感 +20，技能消耗 -8%，暴击率 +6%。"},
		"crownwatch_sigil": {"name": "王卫印记", "summary": "攻击与技能伤害各 +15%，最大护甲 +15。"}
	},
	"zh_Hant": {
		"none": {"name": "無飾品", "summary": "選擇一件飾品來決定這一局的構築方向。"},
		"ember_talisman": {"name": "餘燼護符", "summary": "最大靈感 +20，每次命中額外恢復 1 點靈感。"},
		"wind_knot": {"name": "風結", "summary": "移動速度 +18%，普通攻擊節奏略微加快。"},
		"wolf_pendant": {"name": "狼墜", "summary": "攻擊傷害 +15%，暴擊率 +6%。"},
		"echo_silver_ring": {"name": "回響銀戒", "summary": "技能冷卻更快，普攻回靈更多。"},
		"iron_branch_pendant": {"name": "鐵枝墜飾", "summary": "最大生命 +18，最大護甲 +18。"},
		"shadow_charm": {"name": "影咒", "summary": "移動速度 +12%，暴擊率 +10%。"},
		"fate_reversal_ring": {"name": "逆命之環", "summary": "最大生命 +30，攻擊傷害 +12%，但技能消耗更高。"},
		"old_king_crest": {"name": "舊王紋章", "summary": "最大護甲 +25，技能傷害 +18%。"},
		"hunter_bone_charm": {"name": "獵骨符", "summary": "攻擊傷害 +10%，移動速度 +14%。"},
		"nameless_astrolabe": {"name": "無名星盤", "summary": "最大靈感 +25，技能冷卻 -15%。"},
		"throne_remnant": {"name": "王座殘片", "summary": "攻擊與技能傷害 +20%，最大護甲 +20。"},
		"field_band": {"name": "綁縛繃帶", "summary": "最大生命 +12，最大護甲 +6。"},
		"sparring_token": {"name": "試鋒令牌", "summary": "攻擊傷害 +8%，普通攻擊略微提速。"},
		"gleam_feather": {"name": "曦羽", "summary": "移動速度 +16%，最大靈感 +12。"},
		"pilgrim_censer": {"name": "朝聖香爐", "summary": "最大靈感 +18，技能傷害 +10%。"},
		"oathwire_loop": {"name": "誓絲環", "summary": "技能冷卻 -10%，暴擊率 +8%。"},
		"crimson_locket": {"name": "緋焰墜飾", "summary": "攻擊傷害 +12%，普通攻擊節奏更快。"},
		"warden_vambrace": {"name": "衛城臂甲", "summary": "最大生命 +24，最大護甲 +12，移動速度 +8%。"},
		"moonlit_quill": {"name": "月魄羽筆", "summary": "暴擊率 +14%，攻擊傷害 +10%，但最大護甲 -10。"},
		"starvein_compass": {"name": "星脈羅盤", "summary": "最大靈感 +20，技能消耗 -8%，暴擊率 +6%。"},
		"crownwatch_sigil": {"name": "王衛印記", "summary": "攻擊與技能傷害各 +15%，最大護甲 +15。"}
	}
}

const EFFECT_LABELS_LOCALIZED := {
	"zh_Hans": {
		"max_hp": "最大生命",
		"max_inspiration": "最大灵感",
		"max_defense": "最大护甲",
		"defense": "护甲",
		"move_speed": "移动速度",
		"attack_damage": "攻击伤害",
		"attack_interval": "攻击间隔",
		"crit_rate": "暴击率",
		"inspiration_gain_on_attack_hit": "命中回灵",
		"skill_cost": "技能消耗",
		"skill_damage": "技能伤害",
		"skill1_cooldown": "技能1冷却",
		"skill2_cooldown": "技能2冷却",
		"skill3_cooldown": "技能3冷却"
	},
	"zh_Hant": {
		"max_hp": "最大生命",
		"max_inspiration": "最大靈感",
		"max_defense": "最大護甲",
		"defense": "護甲",
		"move_speed": "移動速度",
		"attack_damage": "攻擊傷害",
		"attack_interval": "攻擊間隔",
		"crit_rate": "暴擊率",
		"inspiration_gain_on_attack_hit": "命中回靈",
		"skill_cost": "技能消耗",
		"skill_damage": "技能傷害",
		"skill1_cooldown": "技能1冷卻",
		"skill2_cooldown": "技能2冷卻",
		"skill3_cooldown": "技能3冷卻"
	}
}

const EMPTY_ACCESSORY := {
	"id": "none",
	"name": "No Accessory",
	"rarity": "Common",
	"icon": "res://assets/ui/icon/ui_unknown.png",
	"summary": "Choose a relic to shape this run.",
	"effects": {},
	"tags": []
}

const FALLBACK_ACCESSORIES := [
	{
		"id": "ember_talisman",
		"name": "Ember Talisman",
		"rarity": "Uncommon",
		"icon": "res://assets/ui/accessory/ember_talisman.png",
		"summary": "+20 max inspiration, +1 inspiration on every hit.",
		"effects": {"max_inspiration": 20.0, "inspiration_gain_on_attack_hit": 1.0},
		"tags": ["resource", "tempo"]
	},
	{
		"id": "wind_knot",
		"name": "Wind Knot",
		"rarity": "Uncommon",
		"icon": "res://assets/ui/accessory/wind_knot.png",
		"summary": "+18% move speed and slightly faster normal attacks.",
		"effects": {"move_speed_pct": 0.18, "attack_interval_pct": -0.08},
		"tags": ["speed", "attack"]
	},
	{
		"id": "wolf_pendant",
		"name": "Wolf Pendant",
		"rarity": "Rare",
		"icon": "res://assets/ui/accessory/wolf_pendant.png",
		"summary": "+15% attack damage and +6% critical chance.",
		"effects": {"attack_damage_pct": 0.15, "crit_rate": 0.06},
		"tags": ["damage", "crit"]
	},
	{
		"id": "echo_silver_ring",
		"name": "Echo Silver Ring",
		"rarity": "Rare",
		"icon": "res://assets/ui/accessory/echo_silver_ring.png",
		"summary": "Skills recover faster and basic hits restore more inspiration.",
		"effects": {"skill_cooldown_pct": -0.12, "inspiration_gain_on_attack_hit": 1.5},
		"tags": ["skill", "resource"]
	},
	{
		"id": "iron_branch_pendant",
		"name": "Iron Branch Pendant",
		"rarity": "Uncommon",
		"icon": "res://assets/ui/accessory/iron_branch_pendant.png",
		"summary": "+18 max hp, +18 max defense.",
		"effects": {"max_hp": 18.0, "max_defense": 18.0},
		"tags": ["survival", "defense"]
	},
	{
		"id": "shadow_charm",
		"name": "Shadow Charm",
		"rarity": "Rare",
		"icon": "res://assets/ui/accessory/shadow_charm.png",
		"summary": "+12% move speed, +10% critical chance.",
		"effects": {"move_speed_pct": 0.12, "crit_rate": 0.10},
		"tags": ["speed", "crit"]
	},
	{
		"id": "fate_reversal_ring",
		"name": "Fate Reversal Ring",
		"rarity": "Epic",
		"icon": "res://assets/ui/accessory/fate_reversal_ring.png",
		"summary": "+30 max hp, +12% attack damage, but skills cost more inspiration.",
		"effects": {"max_hp": 30.0, "attack_damage_pct": 0.12, "skill_cost_pct": 0.10},
		"tags": ["power", "risk"]
	},
	{
		"id": "old_king_crest",
		"name": "Old King Crest",
		"rarity": "Epic",
		"icon": "res://assets/ui/accessory/old_king_crest.png",
		"summary": "+25 max defense, +18% skill damage.",
		"effects": {"max_defense": 25.0, "skill_damage_pct": 0.18},
		"tags": ["skill", "defense"]
	},
	{
		"id": "hunter_bone_charm",
		"name": "Hunter Bone Charm",
		"rarity": "Rare",
		"icon": "res://assets/ui/accessory/hunter_bone_charm.png",
		"summary": "+10% attack damage, +14% move speed.",
		"effects": {"attack_damage_pct": 0.10, "move_speed_pct": 0.14},
		"tags": ["damage", "speed"]
	},
	{
		"id": "nameless_astrolabe",
		"name": "Nameless Astrolabe",
		"rarity": "Epic",
		"icon": "res://assets/ui/accessory/nameless_astrolabe.png",
		"summary": "+25 max inspiration, -15% skill cooldowns.",
		"effects": {"max_inspiration": 25.0, "skill_cooldown_pct": -0.15},
		"tags": ["skill", "resource"]
	},
	{
		"id": "throne_remnant",
		"name": "Throne Remnant",
		"rarity": "Legendary",
		"icon": "res://assets/ui/accessory/throne_remnant.png",
		"summary": "+20% attack and skill damage, +20 max defense.",
		"effects": {"attack_damage_pct": 0.20, "skill_damage_pct": 0.20, "max_defense": 20.0},
		"tags": ["damage", "skill", "defense"]
	}
]

const STAT_FIELDS := [
	"max_hp",
	"max_inspiration",
	"max_defense",
	"defense",
	"move_speed",
	"attack_damage",
	"attack_interval",
	"crit_rate",
	"inspiration_gain_on_attack_hit",
	"skill1_cost",
	"skill2_cost",
	"skill3_cost",
	"skill1_cooldown",
	"skill2_cooldown",
	"skill3_cooldown",
	"skill1_damage",
	"skill2_damage",
	"skill3_damage"
]

const DIRECT_SKILL_ATTACKS := {
	&"skill1": true,
	&"skill2": true,
	&"skill3": true
}

const RARITY_STAGE_WEIGHTS := [
	{"Common": 0.78, "Uncommon": 1.0, "Rare": 0.62, "Epic": 0.16, "Legendary": 0.02},
	{"Common": 0.28, "Uncommon": 0.92, "Rare": 1.0, "Epic": 0.34, "Legendary": 0.06},
	{"Common": 0.08, "Uncommon": 0.62, "Rare": 0.98, "Epic": 0.62, "Legendary": 0.14},
	{"Common": 0.0, "Uncommon": 0.34, "Rare": 0.88, "Epic": 0.82, "Legendary": 0.24}
]

const HERO_TAG_PROFILES := {
	"Knight": ["survival", "defense", "power", "attack"],
	"Ranger": ["crit", "speed", "damage", "attack"],
	"Mage": ["skill", "resource", "tempo", "power"]
}

const FIT_LABELS_LOCALIZED := {
	"zh_Hans": {
		"Best Now": "当前最优",
		"Strong Fit": "高度契合",
		"Flexible": "灵活可拿",
		"Pivot": "可作转向",
		"Niche": "偏功能位"
	},
	"zh_Hant": {
		"Best Now": "當前最優",
		"Strong Fit": "高度契合",
		"Flexible": "靈活可拿",
		"Pivot": "可作轉向",
		"Niche": "偏功能位"
	}
}

const DROP_SOURCE_LABELS_LOCALIZED := {
	"zh_Hans": {
		"opening": "开局宝匣",
		"victory": "战后战利品",
		"shop": "黑市补货",
		"reroll": "重抽补货",
		"route": "路线奖励",
		"boss": "高阶战利品"
	},
	"zh_Hant": {
		"opening": "開局寶匣",
		"victory": "戰後戰利品",
		"shop": "黑市補貨",
		"reroll": "重抽補貨",
		"route": "路線獎勵",
		"boss": "高階戰利品"
	}
}

var equipped_accessory: Dictionary = EMPTY_ACCESSORY.duplicate(true)
var current_choices: Array[Dictionary] = []
var base_stats_by_actor: Dictionary = {}
var combat_proc_ready_at: Dictionary = {}
var choice_cursor: int = 0
var accessory_catalog: Array[Dictionary] = []
var recent_offer_ids: Array[String] = []
var rare_pity: int = 0
var legendary_pity: int = 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	reload_catalog()

func reload_catalog() -> void:
	accessory_catalog = _load_catalog_from_json()
	if accessory_catalog.is_empty():
		accessory_catalog = FALLBACK_ACCESSORIES.duplicate(true)

func get_catalog() -> Array[Dictionary]:
	if accessory_catalog.is_empty():
		reload_catalog()
	var localized_catalog: Array[Dictionary] = []
	for accessory in accessory_catalog:
		localized_catalog.append(_localize_accessory(accessory))
	return localized_catalog

func reset_run() -> void:
	equipped_accessory = EMPTY_ACCESSORY.duplicate(true)
	current_choices.clear()
	base_stats_by_actor.clear()
	combat_proc_ready_at.clear()
	choice_cursor = 0
	recent_offer_ids.clear()
	rare_pity = 0
	legendary_pity = 0
	accessory_equipped.emit(_localize_accessory(equipped_accessory))

func get_equipped_accessory() -> Dictionary:
	return _localize_accessory(equipped_accessory)

func get_equipped_tags() -> Array[String]:
	var tags: Array[String] = []
	for tag in equipped_accessory.get("tags", []):
		var next_tag := String(tag)
		if next_tag.is_empty() or tags.has(next_tag):
			continue
		tags.append(next_tag)
	return tags

func describe_tags(tags: Array = []) -> String:
	var source_tags := tags
	if source_tags.is_empty():
		source_tags = get_equipped_tags()
	var parts: Array[String] = []
	var locale_tags := TAG_LABELS_LOCALIZED.get(_current_locale(), {}) as Dictionary
	for tag in source_tags:
		var next_tag := String(tag)
		if next_tag.is_empty():
			continue
		parts.append(String(locale_tags.get(next_tag, TAG_LABELS.get(next_tag, next_tag.capitalize()))))
	return ", ".join(parts)

func describe_playstyle(tags: Array = []) -> String:
	var source_tags := tags
	if source_tags.is_empty():
		source_tags = get_equipped_tags()
	var hints: Array[String] = []
	var locale_hints := TAG_PLAYSTYLE_HINTS_LOCALIZED.get(_current_locale(), {}) as Dictionary
	for tag in source_tags:
		var next_tag := String(tag)
		if next_tag.is_empty():
			continue
		var hint := String(locale_hints.get(next_tag, TAG_PLAYSTYLE_HINTS.get(next_tag, "")))
		if hint.is_empty() or hints.has(hint):
			continue
		hints.append(hint)
		if hints.size() >= 2:
			break
	return " ".join(hints)

func generate_choices(count: int = 3, actor: Node = null, context: Dictionary = {}) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var pool := get_catalog()
	if pool.is_empty():
		return choices
	var equipped_id := String(equipped_accessory.get("id", "none"))
	var stage := _offer_stage(context)
	var source_key := _offer_source_key(context, stage)
	var candidate_entries: Array[Dictionary] = []
	for accessory in pool:
		var accessory_id := String(accessory.get("id", ""))
		if accessory_id.is_empty() or accessory_id == equipped_id:
			continue
		var annotated := accessory.duplicate(true)
		var offer_meta := _build_offer_meta(annotated, actor, stage, source_key)
		annotated["offer_meta"] = offer_meta
		candidate_entries.append({
			"id": accessory_id,
			"data": annotated,
			"base_weight": _base_offer_weight(annotated, offer_meta, stage, source_key)
		})
	var used_tags: Array[String] = []
	while choices.size() < count and not candidate_entries.is_empty():
		var pick_index := _pick_weighted_entry(candidate_entries, used_tags, choices)
		if pick_index < 0:
			pick_index = 0
		var chosen_entry: Dictionary = candidate_entries[pick_index]
		var chosen_accessory: Dictionary = (chosen_entry.get("data", {}) as Dictionary).duplicate(true)
		var meta := chosen_accessory.get("offer_meta", {}) as Dictionary
		meta["slot"] = choices.size() + 1
		chosen_accessory["offer_meta"] = meta
		choices.append(chosen_accessory)
		for tag in _normalized_tags(chosen_accessory.get("tags", [])):
			if not used_tags.has(tag):
				used_tags.append(tag)
		candidate_entries.remove_at(pick_index)
	choice_cursor = (choice_cursor + count + 1) % max(pool.size(), 1)
	_remember_offer_history(choices)
	current_choices = choices
	choices_generated.emit(current_choices)
	return choices

func evaluate_accessory_fit(accessory: Dictionary, actor: Node = null) -> Dictionary:
	var candidate_tags := _normalized_tags(accessory.get("tags", []))
	var current_tags := get_equipped_tags()
	var hero_tags := _preferred_tags_for_actor(actor)
	var build_overlap := _intersection_tags(candidate_tags, current_tags)
	var hero_overlap := _intersection_tags(candidate_tags, hero_tags)
	var score := float(build_overlap.size()) * 1.65 + float(hero_overlap.size()) * 1.15
	var reasons: Array[String] = []
	if not build_overlap.is_empty():
		reasons.append(_localized_phrase(
			"Matches your current %s route.",
			"延续当前的 %s 构筑方向。",
			"延續當前的 %s 構築方向。"
		) % describe_tags(build_overlap))
	if not hero_overlap.is_empty():
		var hero_name := _localized_hero_name(_actor_name(actor))
		if not hero_name.is_empty():
			reasons.append(_localized_phrase(
				"%s can cash in on these tags cleanly.",
				"%s 很容易把这些标签兑现成稳定收益。",
				"%s 很容易把這些標籤兌現成穩定收益。"
			) % hero_name)
	if actor != null and _ratio(actor, "hp", "max_hp") <= 0.58 and (candidate_tags.has("survival") or candidate_tags.has("defense")):
		score += 1.35
		reasons.append(_localized_phrase(
			"Stabilizes the run immediately while your health is under pressure.",
			"当前血线偏紧，这件能立刻稳住战局。",
			"當前血線偏緊，這件能立刻穩住戰局。"
		))
	if actor != null and _ratio(actor, "inspiration", "max_inspiration") <= 0.45 and (candidate_tags.has("resource") or candidate_tags.has("skill")):
		score += 1.05
		reasons.append(_localized_phrase(
			"Refills your rotation when inspiration is the real bottleneck.",
			"灵感偏紧时，它能把循环重新拉顺。",
			"靈感偏緊時，它能把循環重新拉順。"
		))
	if current_tags.is_empty():
		score += 0.55
		reasons.append(_localized_phrase(
			"Clean first pick for setting the opening route.",
			"很适合作为开局定方向的第一件。",
			"很適合作為開局定方向的第一件。"
		))
	elif build_overlap.is_empty() and hero_overlap.is_empty():
		score += 0.35
		reasons.append(_localized_phrase(
			"Useful as a pivot if your current route is running flat.",
			"如果当前路线开始发闷，它适合拿来转向。",
			"如果當前路線開始發悶，它適合拿來轉向。"
		))
	var fit_key := "Flexible"
	if score >= 4.2:
		fit_key = "Best Now"
	elif score >= 2.85:
		fit_key = "Strong Fit"
	elif build_overlap.is_empty() and hero_overlap.is_empty() and not current_tags.is_empty():
		fit_key = "Pivot"
	elif score <= 0.9:
		fit_key = "Niche"
	if reasons.is_empty():
		reasons.append(_localized_phrase(
			"Solid raw value even without a direct tag match.",
			"即使没有直接标签联动，它也有稳定的裸数值收益。",
			"即使沒有直接標籤聯動，它也有穩定的裸數值收益。"
		))
	return {
		"fit_key": fit_key,
		"label": _fit_label(fit_key),
		"reason": reasons[0],
		"score": score,
		"build_match": build_overlap.size(),
		"hero_match": hero_overlap.size(),
		"color": _fit_color(fit_key)
	}

func describe_offer_comparison(accessory: Dictionary) -> Dictionary:
	var current_id := String(equipped_accessory.get("id", "none"))
	var current_tags := get_equipped_tags()
	var candidate_tags := _normalized_tags(accessory.get("tags", []))
	var route_line := ""
	if current_id == "none":
		route_line = _localized_phrase(
			"Opening route: %s.",
			"开局路线：%s。",
			"開局路線：%s。"
		) % describe_tags(candidate_tags)
	else:
		var overlap := _intersection_tags(candidate_tags, current_tags)
		if not overlap.is_empty():
			route_line = _localized_phrase(
				"Route stays on %s.",
				"路线继续押在 %s。",
				"路線繼續押在 %s。"
			) % describe_tags(overlap)
		else:
			route_line = _localized_phrase(
				"Route pivots from %s to %s.",
				"路线从 %s 转向 %s。",
				"路線從 %s 轉向 %s。"
			) % [describe_tags(current_tags), describe_tags(candidate_tags)]
	var delta_parts := _effect_delta_parts(equipped_accessory.get("effects", {}), accessory.get("effects", {}), 3)
	var compare_line := ""
	if delta_parts.is_empty():
		compare_line = _localized_phrase(
			"Swap keeps the same stat lane, but changes tag identity.",
			"替换后的主数值变化不大，但标签身份会改变。",
			"替換後的主數值變化不大，但標籤身份會改變。"
		)
	else:
		compare_line = _localized_phrase(
			"Swap: %s.",
			"替换后：%s。",
			"替換後：%s。"
		) % ", ".join(delta_parts)
	return {
		"route_line": route_line,
		"compare_line": compare_line,
		"summary": "%s %s" % [route_line, compare_line]
	}

func _build_offer_meta(accessory: Dictionary, actor: Node, stage: int, source_key: String) -> Dictionary:
	var fit_data := evaluate_accessory_fit(accessory, actor)
	var comparison := describe_offer_comparison(accessory)
	return {
		"source_key": source_key,
		"source_label": _source_label(source_key, stage),
		"source_line": _source_hint(source_key, stage),
		"fit_key": String(fit_data.get("fit_key", "Flexible")),
		"fit_label": String(fit_data.get("label", "Flexible")),
		"fit_reason": String(fit_data.get("reason", "")),
		"fit_score": float(fit_data.get("score", 0.0)),
		"fit_color": fit_data.get("color", Color(0.82, 0.88, 0.96)),
		"build_match": int(fit_data.get("build_match", 0)),
		"hero_match": int(fit_data.get("hero_match", 0)),
		"route_line": String(comparison.get("route_line", "")),
		"compare_line": String(comparison.get("compare_line", "")),
		"comparison_summary": String(comparison.get("summary", "")),
		"tag_summary": describe_tags(accessory.get("tags", [])),
		"rarity_key": String(accessory.get("rarity_key", accessory.get("rarity", "Common"))),
		"stage": stage
	}

func _offer_stage(context: Dictionary) -> int:
	if context.has("stage"):
		return maxi(int(context.get("stage", 0)), 0)
	if RunDirector != null and RunDirector.has_method("get_state"):
		var run_state := RunDirector.get_state()
		if run_state is Dictionary:
			return maxi(int((run_state as Dictionary).get("cleared_encounters", 0)), 0)
	return 0

func _offer_source_key(context: Dictionary, stage: int) -> String:
	if bool(context.get("reroll", false)):
		return "reroll"
	var source_key := String(context.get("source", ""))
	if not source_key.is_empty():
		return source_key
	if stage <= 0:
		return "opening"
	if stage >= 3:
		return "boss"
	return "route"

func _base_offer_weight(accessory: Dictionary, offer_meta: Dictionary, stage: int, source_key: String) -> float:
	var rarity_key := String(accessory.get("rarity_key", accessory.get("rarity", "Common")))
	var stage_index := mini(stage, RARITY_STAGE_WEIGHTS.size() - 1)
	var weight := float((RARITY_STAGE_WEIGHTS[stage_index] as Dictionary).get(rarity_key, 0.4))
	weight += float(offer_meta.get("fit_score", 0.0)) * 0.26
	weight += float(offer_meta.get("build_match", 0)) * 0.18
	weight += float(offer_meta.get("hero_match", 0)) * 0.14
	if recent_offer_ids.has(String(accessory.get("id", ""))):
		weight *= 0.22
	match source_key:
		"opening":
			if rarity_key == "Common" or rarity_key == "Uncommon":
				weight += 0.22
		"victory":
			if rarity_key == "Rare" or rarity_key == "Epic":
				weight += 0.14
		"shop":
			if rarity_key == "Rare":
				weight += 0.20
			elif rarity_key == "Epic":
				weight += 0.16
		"reroll":
			if rarity_key == "Rare" or rarity_key == "Epic":
				weight += 0.10
		"boss":
			if rarity_key == "Epic":
				weight += 0.22
			elif rarity_key == "Legendary":
				weight += 0.14 + float(legendary_pity) * 0.05
	if rarity_key == "Rare" or rarity_key == "Epic":
		weight += float(rare_pity) * 0.05
	if rarity_key == "Legendary":
		weight += float(legendary_pity) * 0.06
	return maxf(weight, 0.02)

func _pick_weighted_entry(candidate_entries: Array[Dictionary], used_tags: Array[String], choices: Array[Dictionary]) -> int:
	var total_weight := 0.0
	var weights: Array[float] = []
	for entry in candidate_entries:
		var accessory := entry.get("data", {}) as Dictionary
		var weight := float(entry.get("base_weight", 0.05))
		var shared_used_tags := _intersection_count(_normalized_tags(accessory.get("tags", [])), used_tags)
		if shared_used_tags > 0:
			weight *= pow(0.72, float(shared_used_tags))
		if _rarity_repeat_count(String(accessory.get("rarity_key", accessory.get("rarity", "Common"))), choices) > 0:
			weight *= 0.88
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0.0:
		return -1
	var roll := rng.randf_range(0.0, total_weight)
	for index in range(candidate_entries.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return index
	return candidate_entries.size() - 1

func _remember_offer_history(choices: Array[Dictionary]) -> void:
	var saw_rare_plus := false
	var saw_legendary := false
	for choice in choices:
		var choice_id := String(choice.get("id", ""))
		if not choice_id.is_empty():
			recent_offer_ids.append(choice_id)
		var rarity_key := String(choice.get("rarity_key", choice.get("rarity", "Common")))
		if rarity_key == "Rare" or rarity_key == "Epic" or rarity_key == "Legendary":
			saw_rare_plus = true
		if rarity_key == "Legendary":
			saw_legendary = true
	while recent_offer_ids.size() > 9:
		recent_offer_ids.remove_at(0)
	rare_pity = 0 if saw_rare_plus else mini(rare_pity + 1, 5)
	legendary_pity = 0 if saw_legendary else mini(legendary_pity + 1, 6)

func _preferred_tags_for_actor(actor: Node) -> Array[String]:
	var actor_name := _actor_name(actor)
	var tags_raw := HERO_TAG_PROFILES.get(actor_name, []) as Array
	var tags: Array[String] = []
	for tag in tags_raw:
		tags.append(String(tag))
	return tags

func _actor_name(actor: Node) -> String:
	if actor == null or not is_instance_valid(actor):
		return ""
	if actor.has_method("get_character_name"):
		return String(actor.get_character_name())
	return String(actor.name)

func _localized_hero_name(hero_name: String) -> String:
	match hero_name:
		"Knight":
			return _localized_phrase("Knight", "骑士", "騎士")
		"Ranger":
			return _localized_phrase("Ranger", "游侠", "遊俠")
		"Mage":
			return _localized_phrase("Mage", "法师", "法師")
		_:
			return hero_name

func _normalized_tags(raw_tags: Array) -> Array[String]:
	var tags: Array[String] = []
	for tag in raw_tags:
		var next_tag := String(tag)
		if next_tag.is_empty() or tags.has(next_tag):
			continue
		tags.append(next_tag)
	return tags

func _intersection_tags(left_tags: Array[String], right_tags: Array[String]) -> Array[String]:
	var output: Array[String] = []
	for tag in left_tags:
		if right_tags.has(tag) and not output.has(tag):
			output.append(tag)
	return output

func _intersection_count(left_tags: Array[String], right_tags: Array[String]) -> int:
	return _intersection_tags(left_tags, right_tags).size()

func _effect_delta_parts(current_effects: Dictionary, next_effects: Dictionary, limit: int = 3) -> Array[String]:
	var delta_entries: Array[Dictionary] = []
	var seen_keys := {}
	for key in current_effects.keys():
		seen_keys[String(key)] = true
	for key in next_effects.keys():
		seen_keys[String(key)] = true
	for raw_key in seen_keys.keys():
		var effect_key := String(raw_key)
		var delta := float(next_effects.get(effect_key, 0.0)) - float(current_effects.get(effect_key, 0.0))
		if is_zero_approx(delta):
			continue
		delta_entries.append({
			"key": effect_key,
			"value": delta,
			"sort": _effect_weight(effect_key, delta)
		})
	delta_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("sort", 0.0)) > float(b.get("sort", 0.0))
	)
	var parts: Array[String] = []
	for index in range(mini(limit, delta_entries.size())):
		var entry := delta_entries[index]
		parts.append(_format_effect(String(entry.get("key", "")), float(entry.get("value", 0.0))))
	return parts

func _effect_weight(effect_key: String, value: float) -> float:
	if effect_key.ends_with("_pct") or effect_key == "crit_rate":
		return absf(value) * 100.0
	return absf(value)

func _rarity_repeat_count(rarity_key: String, choices: Array[Dictionary]) -> int:
	var repeat_count := 0
	for choice in choices:
		if String(choice.get("rarity_key", choice.get("rarity", "Common"))) == rarity_key:
			repeat_count += 1
	return repeat_count

func _fit_label(fit_key: String) -> String:
	var locale_map := FIT_LABELS_LOCALIZED.get(_current_locale(), {}) as Dictionary
	return String(locale_map.get(fit_key, fit_key))

func _fit_color(fit_key: String) -> Color:
	match fit_key:
		"Best Now":
			return Color(0.98, 0.84, 0.58)
		"Strong Fit":
			return Color(0.66, 0.92, 0.70)
		"Pivot":
			return Color(0.86, 0.78, 1.0)
		"Niche":
			return Color(0.72, 0.78, 0.88)
		_:
			return Color(0.74, 0.88, 1.0)

func _source_label(source_key: String, stage: int) -> String:
	var locale_map := DROP_SOURCE_LABELS_LOCALIZED.get(_current_locale(), {}) as Dictionary
	if locale_map.has(source_key):
		return String(locale_map[source_key])
	match source_key:
		"opening":
			return "Opening"
		"victory":
			return "Victory"
		"shop":
			return "Market"
		"reroll":
			return "Reroll"
		"boss":
			return "Boss Grade"
		_:
			return "Route" if stage > 0 else "Opening"

func _source_hint(source_key: String, stage: int) -> String:
	match source_key:
		"opening":
			return _localized_phrase(
				"Opening offers lean stable and flexible so the route can form cleanly.",
				"开局掉落更偏稳定和泛用，方便先把路线立起来。",
				"開局掉落更偏穩定和泛用，方便先把路線立起來。"
			)
		"victory":
			return _localized_phrase(
				"Victory drops start leaning toward rare pieces and stronger route reinforcement.",
				"战后掉落会更偏向稀有件和更明确的路线加深。",
				"戰後掉落會更偏向稀有件和更明確的路線加深。"
			)
		"shop":
			return _localized_phrase(
				"Purchased relics bias sharper pivots and more expensive build spikes.",
				"黑市补货更偏向有转向价值、也更舍得给高强度件。",
				"黑市補貨更偏向有轉向價值，也更捨得給高強度件。"
			)
		"reroll":
			return _localized_phrase(
				"Rerolls avoid recent repeats and widen the current route before repeating tags.",
				"重抽会先避开最近见过的饰品，再考虑重复同类标签。",
				"重抽會先避開最近見過的飾品，再考慮重複同類標籤。"
			)
		"boss":
			return _localized_phrase(
				"Late drops lean rare, epic, and finisher pieces for the final checks.",
				"后段掉落会更偏向稀有、史诗和收尾型部件。",
				"後段掉落會更偏向稀有、史詩和收尾型部件。"
			)
		_:
			if stage >= 2:
				return _localized_phrase(
					"Mid-run rewards bias sharper identity and higher rarity ceilings.",
					"中后段奖励会更偏向明确构筑身份和更高稀有度上限。",
					"中後段獎勵會更偏向明確構築身份和更高稀有度上限。"
				)
			return _localized_phrase(
				"Route rewards still keep some flexibility while your build is taking shape.",
				"路线奖励仍会保留一些弹性，让构筑还能继续调整。",
				"路線獎勵仍會保留一些彈性，讓構築還能繼續調整。"
			)

func equip(accessory_id: String, actor: Node = null) -> Dictionary:
	var accessory := get_accessory(accessory_id)
	if accessory.is_empty():
		return equipped_accessory
	equipped_accessory = accessory.duplicate(true)
	if actor != null:
		apply_to_actor(actor)
	accessory_equipped.emit(equipped_accessory)
	return equipped_accessory

func keep_current(actor: Node = null) -> Dictionary:
	if actor != null:
		apply_to_actor(actor)
	accessory_equipped.emit(equipped_accessory)
	return equipped_accessory

func build_hit_payload(actor: Node, attack_name: StringName, base_damage: float, base_crit_rate: float, extra_payload: Dictionary = {}) -> Dictionary:
	var payload := {
		"source": actor,
		"damage": base_damage,
		"crit_rate": base_crit_rate
	}
	for key in extra_payload.keys():
		payload[key] = extra_payload[key]
	return enhance_hit_payload(actor, attack_name, payload)

func enhance_hit_payload(actor: Node, attack_name: StringName, payload: Dictionary) -> Dictionary:
	var enhanced := payload.duplicate(true)
	var tags := get_equipped_tags()
	if tags.is_empty():
		return enhanced
	var damage_value := float(enhanced.get("damage", 0.0))
	if tags.has("crit"):
		enhanced["crit_rate"] = float(enhanced.get("crit_rate", 0.0)) + 0.08
	if tags.has("attack") and attack_name == &"attack":
		damage_value += maxf(4.0, damage_value * 0.06)
		enhanced["damage"] = damage_value
	if tags.has("power") and _is_direct_skill_attack(attack_name):
		damage_value += maxf(8.0, damage_value * 0.08)
		enhanced["damage"] = damage_value
	if tags.has("risk") and _ratio(actor, "hp", "max_hp") <= 0.55:
		damage_value *= 1.12
		enhanced["damage"] = damage_value
	if tags.has("damage") and _is_direct_skill_attack(attack_name):
		_merge_payload_max(enhanced, "damage_multiplier", 1.12)
		_merge_payload_max(enhanced, "damage_multiplier_duration", 2.25)
	return enhanced

func apply_on_hit_effects(actor: Node, attack_name: StringName, target: Node) -> void:
	if actor == null:
		return
	var tags := get_equipped_tags()
	if tags.is_empty():
		return
	if tags.has("resource") and _consume_combat_proc(actor, "resource_flow", 0.18):
		_grant_inspiration(actor, 1.0 if _is_direct_skill_attack(attack_name) else 0.5)
	if tags.has("attack") and attack_name == &"attack":
		_refund_cooldown(actor, "attack", 0.08)
	if tags.has("tempo") and _is_direct_skill_attack(attack_name):
		_refund_cooldown(actor, String(attack_name), 0.32)
	if tags.has("skill") and _is_direct_skill_attack(attack_name) and _consume_combat_proc(actor, "skill_silence", 0.55):
		_try_apply_target_control(target, {"silence_duration": 1.0})
	if tags.has("speed") and (attack_name == &"attack" or attack_name == &"skill1") and _consume_combat_proc(actor, "speed_slow", 0.35):
		_try_apply_target_control(target, {"slow_duration": 1.15, "slow_multiplier": 0.82})
	if tags.has("defense") and _is_direct_skill_attack(attack_name) and _consume_combat_proc(actor, "defense_guard", 0.55):
		_restore_defense_or_shield(actor, 10.0, 10.0)
	if tags.has("survival") and _ratio(actor, "hp", "max_hp") <= 0.5 and _consume_combat_proc(actor, "survival_heal", 1.2):
		_heal_actor(actor, 4.0)

func get_accessory(accessory_id: String) -> Dictionary:
	if accessory_id == "none":
		return _localize_accessory(EMPTY_ACCESSORY)
	for accessory in get_catalog():
		if String(accessory.get("id", "")) == accessory_id:
			return _localize_accessory(accessory)
	return {}

func _load_catalog_from_json() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	if not FileAccess.file_exists(ACCESSORY_DATA_PATH):
		return catalog
	var raw := FileAccess.get_file_as_string(ACCESSORY_DATA_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Array):
		push_warning("Accessory data is not an array: %s" % ACCESSORY_DATA_PATH)
		return catalog
	for entry in parsed:
		if not (entry is Dictionary):
			continue
		var accessory: Dictionary = (entry as Dictionary).duplicate(true)
		if _is_valid_accessory(accessory):
			catalog.append(accessory)
	return catalog

func _is_valid_accessory(accessory: Dictionary) -> bool:
	for required in ["id", "name", "rarity", "icon", "summary", "effects", "tags"]:
		if not accessory.has(required):
			push_warning("Accessory missing field '%s': %s" % [required, accessory])
			return false
	return true

func apply_to_actor(actor: Node) -> void:
	if actor == null:
		return
	var hp_ratio := _ratio(actor, "hp", "max_hp")
	var defense_ratio := _ratio(actor, "defense", "max_defense")
	var current_inspiration := float(actor.get("inspiration")) if _has_property(actor, "inspiration") else 0.0
	_capture_base_stats(actor)
	_restore_base_stats(actor)
	_apply_effects(actor, equipped_accessory.get("effects", {}))
	_sync_actor_health(actor, hp_ratio, defense_ratio, current_inspiration)
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

func describe_effects(accessory: Dictionary) -> String:
	var effects: Dictionary = accessory.get("effects", {})
	if effects.is_empty():
		return _localized_phrase("No active stat change.", "当前没有数值变化。", "當前沒有數值變化。")
	var parts: Array[String] = []
	var sorted_keys := effects.keys()
	sorted_keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		return _effect_weight(String(a), float(effects.get(String(a), 0.0))) > _effect_weight(String(b), float(effects.get(String(b), 0.0)))
	)
	for key in sorted_keys:
		var value := float(effects[key])
		parts.append(_format_effect(String(key), value))
	return ", ".join(parts)

func _capture_base_stats(actor: Node) -> void:
	var actor_id := actor.get_instance_id()
	if base_stats_by_actor.has(actor_id):
		return
	var stats := {}
	for field in STAT_FIELDS:
		if _has_property(actor, field):
			stats[field] = actor.get(field)
	base_stats_by_actor[actor_id] = stats

func _restore_base_stats(actor: Node) -> void:
	var actor_id := actor.get_instance_id()
	if not base_stats_by_actor.has(actor_id):
		return
	var stats: Dictionary = base_stats_by_actor[actor_id]
	for field in stats.keys():
		if _has_property(actor, String(field)):
			actor.set(field, stats[field])

func _apply_effects(actor: Node, effects: Dictionary) -> void:
	for key in effects.keys():
		var value := float(effects[key])
		match String(key):
			"max_hp", "max_inspiration", "max_defense", "defense", "move_speed", "attack_damage", "crit_rate", "inspiration_gain_on_attack_hit":
				_add(actor, String(key), value)
			"move_speed_pct":
				_scale(actor, "move_speed", 1.0 + value)
			"attack_damage_pct":
				_scale(actor, "attack_damage", 1.0 + value)
			"attack_interval_pct":
				_scale(actor, "attack_interval", 1.0 + value, 0.15)
			"skill_cooldown_pct":
				for field in ["skill1_cooldown", "skill2_cooldown", "skill3_cooldown"]:
					_scale(actor, field, 1.0 + value, 0.0)
			"skill_cost_pct":
				for field in ["skill1_cost", "skill2_cost", "skill3_cost"]:
					_scale(actor, field, 1.0 + value, 0.0)
			"skill_damage_pct":
				for field in ["skill1_damage", "skill2_damage", "skill3_damage"]:
					_scale(actor, field, 1.0 + value, 0.0)

func _sync_actor_health(actor: Node, hp_ratio: float, defense_ratio: float, current_inspiration: float) -> void:
	if _has_property(actor, "max_hp") and _has_property(actor, "hp"):
		actor.hp = clampf(float(actor.max_hp) * hp_ratio, 0.0, float(actor.max_hp))
		if actor.hp <= 0.0:
			actor.hp = float(actor.max_hp)
	if _has_property(actor, "max_inspiration") and _has_property(actor, "inspiration"):
		actor.inspiration = minf(current_inspiration, float(actor.max_inspiration))
	if _has_property(actor, "max_defense"):
		if _has_property(actor, "defense"):
			actor.defense = clampf(float(actor.max_defense) * defense_ratio, 0.0, float(actor.max_defense))
		var health_component: Node = actor.get("health_component") if _has_property(actor, "health_component") else null
		if health_component != null and health_component.has_method("setup"):
			health_component.setup(float(actor.max_hp), float(actor.max_defense))
			if _has_property(actor, "hp"):
				health_component.hp = float(actor.hp)
			if _has_property(actor, "defense"):
				health_component.defense = float(actor.defense)

func _add(actor: Node, field: String, value: float) -> void:
	if not _has_property(actor, field):
		return
	actor.set(field, float(actor.get(field)) + value)

func _scale(actor: Node, field: String, multiplier: float, floor_value: float = -INF) -> void:
	if not _has_property(actor, field):
		return
	var next_value := float(actor.get(field)) * multiplier
	if floor_value != -INF:
		next_value = maxf(next_value, floor_value)
	actor.set(field, next_value)

func _has_property(actor: Node, field: String) -> bool:
	if actor == null:
		return false
	for property in actor.get_property_list():
		if String(property.get("name", "")) == field:
			return true
	return false

func _ratio(actor: Node, current_field: String, max_field: String) -> float:
	if not _has_property(actor, current_field) or not _has_property(actor, max_field):
		return 1.0
	var max_value := float(actor.get(max_field))
	if max_value <= 0.0:
		return 1.0
	return clampf(float(actor.get(current_field)) / max_value, 0.0, 1.0)

func _format_effect(key: String, value: float) -> String:
	var normalized_key := key.replace("_pct", "")
	var locale_labels := EFFECT_LABELS_LOCALIZED.get(_current_locale(), {}) as Dictionary
	var label := String(locale_labels.get(normalized_key, normalized_key.replace("_", " ").capitalize()))
	if key.ends_with("_pct"):
		return "%s %+d%%" % [label, int(round(value * 100.0))]
	if key == "crit_rate":
		return "%s %+d%%" % [label, int(round(value * 100.0))]
	var sign := "+" if value >= 0.0 else ""
	return "%s %s%.1f" % [label, sign, value]

func _is_direct_skill_attack(attack_name: StringName) -> bool:
	return DIRECT_SKILL_ATTACKS.has(attack_name)

func _merge_payload_max(payload: Dictionary, key: String, value: float) -> void:
	payload[key] = maxf(float(payload.get(key, 0.0)), value)

func _consume_combat_proc(actor: Node, proc_name: String, cooldown: float) -> bool:
	if actor == null:
		return false
	var proc_key := "%s:%s" % [actor.get_instance_id(), proc_name]
	var now := Time.get_ticks_msec() * 0.001
	if now < float(combat_proc_ready_at.get(proc_key, 0.0)):
		return false
	combat_proc_ready_at[proc_key] = now + cooldown
	return true

func _localize_accessory(source: Dictionary) -> Dictionary:
	var accessory := source.duplicate(true)
	var locale := _current_locale()
	var id := String(accessory.get("id", ""))
	var raw_rarity := String(accessory.get("rarity_key", accessory.get("rarity", "Common")))
	accessory["rarity_key"] = raw_rarity
	var locale_map := ACCESSORY_LOCALIZATION.get(locale, {}) as Dictionary
	var localized := locale_map.get(id, {}) as Dictionary
	if not localized.is_empty():
		accessory["name"] = String(localized.get("name", accessory.get("name", "")))
		accessory["summary"] = String(localized.get("summary", accessory.get("summary", "")))
	var rarity_map := RARITY_LABELS_LOCALIZED.get(locale, {}) as Dictionary
	accessory["rarity"] = String(rarity_map.get(raw_rarity, raw_rarity))
	return accessory

func _current_locale() -> String:
	if UISettings != null and UISettings.has_method("get_locale"):
		return String(UISettings.get_locale())
	return "zh_Hans"

func _localized_phrase(en_text: String, zh_hans_text: String, zh_hant_text: String) -> String:
	match _current_locale():
		"zh_Hant":
			return zh_hant_text
		"zh_Hans":
			return zh_hans_text
		_:
			return en_text

func _grant_inspiration(actor: Node, amount: float) -> void:
	if amount <= 0.0:
		return
	if actor.has_method("gain_inspiration"):
		actor.gain_inspiration(amount)
		return
	if not _has_property(actor, "inspiration") or not _has_property(actor, "max_inspiration"):
		return
	actor.inspiration = clampf(float(actor.inspiration) + amount, 0.0, float(actor.max_inspiration))
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

func _refund_cooldown(actor: Node, cooldown_key: String, amount: float) -> void:
	if amount <= 0.0 or not _has_property(actor, "cooldowns"):
		return
	var cooldowns_value: Variant = actor.get("cooldowns")
	if not (cooldowns_value is Dictionary):
		return
	var cooldowns: Dictionary = cooldowns_value
	if not cooldowns.has(cooldown_key):
		return
	cooldowns[cooldown_key] = maxf(float(cooldowns[cooldown_key]) - amount, 0.0)
	actor.set("cooldowns", cooldowns)

func _restore_defense_or_shield(actor: Node, defense_amount: float, shield_amount: float) -> void:
	var health_component := _get_health_component(actor)
	if health_component != null:
		var current_defense := float(health_component.get("defense"))
		var max_defense_value := float(health_component.get("max_defense"))
		if max_defense_value > 0.0 and current_defense < max_defense_value:
			health_component.defense = minf(current_defense + defense_amount, max_defense_value)
			health_component.defense_changed.emit(float(health_component.defense), max_defense_value)
			return
		if health_component.has_method("apply_shield"):
			health_component.apply_shield(shield_amount)
			return
	if _has_property(actor, "defense") and _has_property(actor, "max_defense"):
		if float(actor.defense) < float(actor.max_defense):
			actor.defense = minf(float(actor.defense) + defense_amount, float(actor.max_defense))
		elif _has_property(actor, "shield"):
			actor.shield = float(actor.get("shield")) + shield_amount
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

func _heal_actor(actor: Node, amount: float) -> void:
	if amount <= 0.0:
		return
	if actor.has_method("heal"):
		actor.heal(amount)
		return
	if not _has_property(actor, "hp") or not _has_property(actor, "max_hp"):
		return
	actor.hp = clampf(float(actor.hp) + amount, 0.0, float(actor.max_hp))
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

func _try_apply_target_control(target: Node, payload: Dictionary) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("apply_control_effects"):
		target.apply_control_effects(payload)

func _get_health_component(actor: Node) -> Node:
	if actor == null:
		return null
	return actor.get_node_or_null("HealthComponent")
