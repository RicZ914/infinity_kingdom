class_name RunEffects
extends RefCounted

const ATTUNEMENT_TAG_MAP := {
	"attack": "attune_offense",
	"crit": "attune_gambit",
	"damage": "attune_offense",
	"defense": "attune_guard",
	"power": "attune_offense",
	"resource": "attune_focus",
	"risk": "attune_gambit",
	"skill": "attune_focus",
	"speed": "attune_flow",
	"survival": "attune_guard",
	"tempo": "attune_flow"
}

const ATTUNEMENT_FILL_ORDER := [
	"attune_offense",
	"attune_focus",
	"attune_guard",
	"attune_flow",
	"attune_gambit"
]

const ATTUNEMENT_CHOICE_DATA := {
	"attune_offense": {
		"title": "Battle Temper",
		"summary": "+12% attack damage and +4% crit chance.",
		"icon": "res://assets/ui/trait/trait_damage.png"
	},
	"attune_focus": {
		"title": "Echo Circuit",
		"summary": "+10 max inspiration and faster skill recovery.",
		"icon": "res://assets/ui/trait/trait_echo.png"
	},
	"attune_guard": {
		"title": "Warden Seal",
		"summary": "+16 max defense, +6 max hp, and restore armor.",
		"icon": "res://assets/ui/icon/ui_shield.png"
	},
	"attune_flow": {
		"title": "Wind Rhythm",
		"summary": "+10% move speed, faster attacks, and more inspiration on hit.",
		"icon": "res://assets/ui/icon/stat_speed_pixel.png"
	},
	"attune_gambit": {
		"title": "Last Nerve",
		"summary": "+8% crit chance and +10% skill damage, but skills cost more inspiration.",
		"icon": "res://assets/ui/trait/trait_execute.png"
	}
}

const SCOUT_CHOICE_DATA := {
	"scout_assault": {
		"title": "Assault Route",
		"summary": "Next encounter: +14% attack damage, +6% crit chance, and +14 gold on clear.",
		"icon": "res://assets/ui/trait/trait_damage.png",
		"prep": {
			"title": "Assault Route",
			"summary": "Opening assault: +14% attack damage, +6% crit chance, and +14 gold on clear.",
			"temporary_effects": {
				"attack_damage_pct": 0.14,
				"crit_rate": 0.06
			},
			"reward_bonus": 14
		}
	},
	"scout_bulwark": {
		"title": "Bulwark Route",
		"summary": "Next encounter: full defense, +45 shield, and +10% move speed.",
		"icon": "res://assets/ui/icon/ui_shield.png",
		"prep": {
			"title": "Bulwark Route",
			"summary": "Defensive opener: restore defense, gain +45 shield, and +10% move speed.",
			"restore_defense": true,
			"shield": 45.0,
			"temporary_effects": {
				"move_speed_pct": 0.10
			},
			"clear_shield_on_end": true
		}
	},
	"scout_focus": {
		"title": "Focus Route",
		"summary": "Next encounter: full inspiration and 18% faster skill cooldowns.",
		"icon": "res://assets/ui/icon/ui_mana_flame.png",
		"prep": {
			"title": "Focus Route",
			"summary": "Prepared casting: restore inspiration and reduce skill cooldowns by 18%.",
			"restore_inspiration": true,
			"temporary_effects": {
				"skill_cooldown_pct": -0.18
			}
		}
	}
}

const FORGE_FILL_ORDER := [
	"forge_edge",
	"forge_focus",
	"forge_guard",
	"forge_flow",
	"forge_seal"
]

const FORGE_CHOICE_DATA := {
	"forge_edge": {
		"title": "Tempered Edge",
		"summary": "+8% attack damage, +3% crit chance, and 4% faster attacks.",
		"icon": "res://assets/ui/trait/trait_damage.png"
	},
	"forge_focus": {
		"title": "Spell Lattice",
		"summary": "+8 max inspiration, lower skill costs, and 6% faster skill recovery.",
		"icon": "res://assets/ui/trait/trait_echo.png"
	},
	"forge_guard": {
		"title": "Bastion Plate",
		"summary": "+10 max hp, +14 max defense, and restore armor.",
		"icon": "res://assets/ui/icon/ui_shield.png"
	},
	"forge_flow": {
		"title": "Quickstep Gears",
		"summary": "+10% move speed, faster attacks, and more inspiration on hit.",
		"icon": "res://assets/ui/icon/stat_speed_pixel.png"
	},
	"forge_seal": {
		"title": "King's Seal",
		"summary": "+8 max hp, +6 max inspiration, and +8% skill damage.",
		"icon": "res://assets/ui/trait/trait_execute.png"
	}
}

const CHOICE_LOCALIZATION := {
	"zh_Hans": {
		"shop_attack": {"title": "磨锋油", "card": "本局攻击伤害 +10%。", "result": "已涂抹磨锋油。"},
		"shop_defense": {"title": "轻甲包", "card": "恢复护甲，并提升 12 点最大护甲。", "result": "护甲已经加固。"},
		"shop_relic": {"title": "饰品地图", "card": "在下一场战斗前额外获得一次饰品选择。", "result": "已标记隐藏饰品点。"},
		"bounty_cache": {"title": "打开钱袋", "card": "立刻获得 40 金币。", "result": "已领取即时金币。"},
		"bounty_contract": {"title": "稳定契约", "card": "之后的战斗额外奖励 18 金币。", "result": "后续悬赏收益提高。"},
		"bounty_tithe": {"title": "高风险契约", "card": "之后的战斗金币 +28%，但失去 10 点最大生命。", "result": "已签下高风险契约。"},
		"rest_heal": {"title": "医疗包", "card": "恢复 45% 生命。", "result": "生命已恢复。"},
		"rest_focus": {"title": "守护蜡烛", "card": "恢复灵感与护甲。", "result": "灵感与护甲已恢复。"},
		"rest_repair": {"title": "野战修整", "card": "恢复护甲，并提升 8 点最大生命。", "result": "护甲已修复，体力上限提升。"},
		"train_crit": {"title": "精准训练", "card": "暴击率 +5%。", "result": "精准训练完成。"},
		"train_speed": {"title": "步法训练", "card": "移动速度 +8%。", "result": "步法训练完成。"},
		"train_cooldown": {"title": "节奏训练", "card": "技能冷却 -6%。", "result": "技能节奏得到优化。"},
		"train_resource": {"title": "专注演练", "card": "最大灵感 +12。", "result": "灵感容量已经扩大。"},
		"pact_power": {"title": "血价", "card": "攻击 +18%，技能伤害 +10%，但技能消耗更高。", "result": "已接受血价。"},
		"pact_guard": {"title": "铁誓", "card": "获得大量护甲并恢复防御，但移动速度下降。", "result": "已接受铁誓。"},
		"pact_focus": {"title": "星债", "card": "提升灵感与冷却效率，但失去最大生命。", "result": "已接受星债。"},
		"skip": {"title": "跳过", "card": "保持当前构筑，继续前进。", "result": "你选择了继续前进。"},
		"attune_offense": {"title": "战意锻火", "card": "攻击伤害 +12%，暴击率 +4%。", "result": "已共鸣战意锻火。"},
		"attune_focus": {"title": "回声回路", "card": "最大灵感 +10，技能恢复更快。", "result": "已共鸣回声回路。"},
		"attune_guard": {"title": "守望封印", "card": "最大护甲 +16，最大生命 +6，并恢复护甲。", "result": "已共鸣守望封印。"},
		"attune_flow": {"title": "风律", "card": "移动速度 +10%，攻速更快，命中回灵更多。", "result": "已共鸣风律。"},
		"attune_gambit": {"title": "末线神经", "card": "暴击率 +8%，技能伤害 +10%，但技能消耗更高。", "result": "已共鸣末线神经。"},
		"scout_assault": {"title": "强袭路线", "card": "下一战：攻击伤害 +14%，暴击率 +6%，胜利后额外 +30 金币。", "result": "已准备强袭路线。"},
		"scout_bulwark": {"title": "壁垒路线", "card": "下一战：护甲回满，获得 45 点护盾，移动速度 +10%。", "result": "已准备壁垒路线。"},
		"scout_focus": {"title": "专注路线", "card": "下一战：灵感回满，技能冷却额外缩短 18%。", "result": "已准备专注路线。"},
		"forge_edge": {"title": "淬锋", "card": "攻击伤害 +8%，暴击率 +3%，攻击更快。", "result": "已完成淬锋。"},
		"forge_focus": {"title": "术式晶格", "card": "最大灵感 +8，技能消耗降低，冷却额外缩短 6%。", "result": "已完成术式晶格。"},
		"forge_guard": {"title": "壁垒甲片", "card": "最大生命 +10，最大护甲 +14，并恢复护甲。", "result": "已完成壁垒甲片。"},
		"forge_flow": {"title": "迅步齿轮", "card": "移动速度 +10%，攻击更快，命中回灵更多。", "result": "已完成迅步齿轮。"},
		"forge_seal": {"title": "王印", "card": "最大生命 +8，最大灵感 +6，技能伤害 +8%。", "result": "已完成王印锻造。"}
	},
	"zh_Hant": {
		"shop_attack": {"title": "磨鋒油", "card": "本局攻擊傷害 +10%。", "result": "已塗抹磨鋒油。"},
		"shop_defense": {"title": "輕甲包", "card": "恢復護甲，並提升 12 點最大護甲。", "result": "護甲已經加固。"},
		"shop_relic": {"title": "飾品地圖", "card": "在下一場戰鬥前額外獲得一次飾品選擇。", "result": "已標記隱藏飾品點。"},
		"bounty_cache": {"title": "打開錢袋", "card": "立刻獲得 40 金幣。", "result": "已領取即時金幣。"},
		"bounty_contract": {"title": "穩定契約", "card": "之後的戰鬥額外獎勵 18 金幣。", "result": "後續懸賞收益提高。"},
		"bounty_tithe": {"title": "高風險契約", "card": "之後的戰鬥金幣 +28%，但失去 10 點最大生命。", "result": "已簽下高風險契約。"},
		"rest_heal": {"title": "醫療包", "card": "恢復 45% 生命。", "result": "生命已恢復。"},
		"rest_focus": {"title": "守護蠟燭", "card": "恢復靈感與護甲。", "result": "靈感與護甲已恢復。"},
		"rest_repair": {"title": "野戰修整", "card": "恢復護甲，並提升 8 點最大生命。", "result": "護甲已修復，體力上限提升。"},
		"train_crit": {"title": "精準訓練", "card": "暴擊率 +5%。", "result": "精準訓練完成。"},
		"train_speed": {"title": "步法訓練", "card": "移動速度 +8%。", "result": "步法訓練完成。"},
		"train_cooldown": {"title": "節奏訓練", "card": "技能冷卻 -6%。", "result": "技能節奏得到優化。"},
		"train_resource": {"title": "專注演練", "card": "最大靈感 +12。", "result": "靈感容量已經擴大。"},
		"pact_power": {"title": "血價", "card": "攻擊 +18%，技能傷害 +10%，但技能消耗更高。", "result": "已接受血價。"},
		"pact_guard": {"title": "鐵誓", "card": "獲得大量護甲並恢復防禦，但移動速度下降。", "result": "已接受鐵誓。"},
		"pact_focus": {"title": "星債", "card": "提升靈感與冷卻效率，但失去最大生命。", "result": "已接受星債。"},
		"skip": {"title": "跳過", "card": "保持當前構築，繼續前進。", "result": "你選擇了繼續前進。"},
		"attune_offense": {"title": "戰意鍛火", "card": "攻擊傷害 +12%，暴擊率 +4%。", "result": "已共鳴戰意鍛火。"},
		"attune_focus": {"title": "回聲迴路", "card": "最大靈感 +10，技能恢復更快。", "result": "已共鳴回聲迴路。"},
		"attune_guard": {"title": "守望封印", "card": "最大護甲 +16，最大生命 +6，並恢復護甲。", "result": "已共鳴守望封印。"},
		"attune_flow": {"title": "風律", "card": "移動速度 +10%，攻速更快，命中回靈更多。", "result": "已共鳴風律。"},
		"attune_gambit": {"title": "末線神經", "card": "暴擊率 +8%，技能傷害 +10%，但技能消耗更高。", "result": "已共鳴末線神經。"},
		"scout_assault": {"title": "強襲路線", "card": "下一戰：攻擊傷害 +14%，暴擊率 +6%，勝利後額外 +30 金幣。", "result": "已準備強襲路線。"},
		"scout_bulwark": {"title": "壁壘路線", "card": "下一戰：護甲回滿，獲得 45 點護盾，移動速度 +10%。", "result": "已準備壁壘路線。"},
		"scout_focus": {"title": "專注路線", "card": "下一戰：靈感回滿，技能冷卻額外縮短 18%。", "result": "已準備專注路線。"},
		"forge_edge": {"title": "淬鋒", "card": "攻擊傷害 +8%，暴擊率 +3%，攻擊更快。", "result": "已完成淬鋒。"},
		"forge_focus": {"title": "術式晶格", "card": "最大靈感 +8，技能消耗降低，冷卻額外縮短 6%。", "result": "已完成術式晶格。"},
		"forge_guard": {"title": "壁壘甲片", "card": "最大生命 +10，最大護甲 +14，並恢復護甲。", "result": "已完成壁壘甲片。"},
		"forge_flow": {"title": "迅步齒輪", "card": "移動速度 +10%，攻擊更快，命中回靈更多。", "result": "已完成迅步齒輪。"},
		"forge_seal": {"title": "王印", "card": "最大生命 +8，最大靈感 +6，技能傷害 +8%。", "result": "已完成王印鍛造。"}
	}
}

const HERO_TAG_PROFILES := {
	"Knight": ["defense", "survival", "power"],
	"Ranger": ["crit", "speed", "tempo", "damage"],
	"Mage": ["skill", "resource", "power"]
}

const CHOICE_TAGS := {
	"shop_attack": ["attack", "damage"],
	"shop_defense": ["defense", "survival"],
	"shop_relic": ["resource", "tempo"],
	"bounty_cache": ["resource"],
	"bounty_contract": ["resource", "tempo"],
	"bounty_tithe": ["risk", "damage"],
	"rest_heal": ["survival"],
	"rest_focus": ["defense", "resource", "skill"],
	"rest_repair": ["defense", "survival"],
	"train_crit": ["crit", "damage"],
	"train_speed": ["speed", "tempo"],
	"train_cooldown": ["skill", "tempo", "resource"],
	"train_resource": ["resource", "skill"],
	"forge_edge": ["attack", "damage", "crit", "tempo"],
	"forge_focus": ["skill", "resource", "tempo"],
	"forge_guard": ["defense", "survival"],
	"forge_flow": ["speed", "tempo", "resource"],
	"forge_seal": ["power", "skill", "resource", "survival"],
	"pact_power": ["power", "damage", "risk"],
	"pact_guard": ["defense", "survival"],
	"pact_focus": ["skill", "resource", "power"],
	"scout_assault": ["damage", "crit", "tempo"],
	"scout_bulwark": ["defense", "survival", "speed"],
	"scout_focus": ["skill", "resource", "tempo"],
	"attune_offense": ["damage", "crit"],
	"attune_focus": ["skill", "resource"],
	"attune_guard": ["defense", "survival"],
	"attune_flow": ["speed", "tempo"],
	"attune_gambit": ["crit", "risk", "damage"]
}

static func apply_choice(choice_id: String, actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var persistent_changed := false
	var restore_defense_after_refresh := false
	match choice_id:
		"shop_attack":
			RunDirector.add_run_modifier("attack_damage", 0.0, 1.10)
			persistent_changed = true
		"shop_defense":
			RunDirector.add_run_modifier("max_defense", 12.0)
			persistent_changed = true
			restore_defense_after_refresh = true
		"shop_relic":
			pass
		"bounty_cache":
			RunDirector.grant_gold(24)
		"bounty_contract":
			RunDirector.add_reward_flat_bonus(8)
		"bounty_tithe":
			RunDirector.add_reward_multiplier(1.15)
			RunDirector.add_run_modifier("max_hp", -10.0, 1.0, 28.0)
			persistent_changed = true
		"rest_heal":
			heal_percent(actor, 0.45)
		"rest_focus":
			restore_defense(actor)
			restore_inspiration(actor)
		"rest_repair":
			RunDirector.add_run_modifier("max_hp", 8.0)
			persistent_changed = true
			restore_defense_after_refresh = true
		"train_crit":
			RunDirector.add_run_modifier("crit_rate", 0.05)
			persistent_changed = true
		"train_speed":
			RunDirector.add_run_modifier("move_speed", 0.0, 1.08)
			persistent_changed = true
		"train_cooldown":
			for field in ["skill1_cooldown", "skill2_cooldown", "skill3_cooldown"]:
				RunDirector.add_run_modifier(field, 0.0, 0.94, 0.0)
			persistent_changed = true
		"train_resource":
			RunDirector.add_run_modifier("max_inspiration", 12.0)
			persistent_changed = true
		"forge_edge":
			RunDirector.add_run_modifier("attack_damage", 0.0, 1.08)
			RunDirector.add_run_modifier("crit_rate", 0.03)
			RunDirector.add_run_modifier("attack_interval", 0.0, 0.96, 0.18)
			persistent_changed = true
		"forge_focus":
			RunDirector.add_run_modifier("max_inspiration", 8.0)
			for field in ["skill1_cooldown", "skill2_cooldown", "skill3_cooldown"]:
				RunDirector.add_run_modifier(field, 0.0, 0.94, 0.0)
			for field in ["skill1_cost", "skill2_cost", "skill3_cost"]:
				RunDirector.add_run_modifier(field, 0.0, 0.94, 0.0)
			persistent_changed = true
		"forge_guard":
			RunDirector.add_run_modifier("max_hp", 10.0)
			RunDirector.add_run_modifier("max_defense", 14.0)
			persistent_changed = true
			restore_defense_after_refresh = true
		"forge_flow":
			RunDirector.add_run_modifier("move_speed", 0.0, 1.10)
			RunDirector.add_run_modifier("attack_interval", 0.0, 0.95, 0.15)
			RunDirector.add_run_modifier("inspiration_gain_on_attack_hit", 0.8)
			persistent_changed = true
		"forge_seal":
			RunDirector.add_run_modifier("max_hp", 8.0)
			RunDirector.add_run_modifier("max_inspiration", 6.0)
			for field in ["skill1_damage", "skill2_damage", "skill3_damage"]:
				RunDirector.add_run_modifier(field, 0.0, 1.08, 0.0)
			persistent_changed = true
		"pact_power":
			RunDirector.add_run_modifier("attack_damage", 0.0, 1.18)
			for field in ["skill1_damage", "skill2_damage", "skill3_damage"]:
				RunDirector.add_run_modifier(field, 0.0, 1.10, 0.0)
			for field in ["skill1_cost", "skill2_cost", "skill3_cost"]:
				RunDirector.add_run_modifier(field, 0.0, 1.12, 0.0)
			persistent_changed = true
		"pact_guard":
			RunDirector.add_run_modifier("max_defense", 28.0)
			RunDirector.add_run_modifier("move_speed", 0.0, 0.90, 0.0)
			persistent_changed = true
			restore_defense_after_refresh = true
		"pact_focus":
			RunDirector.add_run_modifier("max_inspiration", 20.0)
			RunDirector.add_run_modifier("max_hp", -12.0, 1.0, 30.0)
			for field in ["skill1_cooldown", "skill2_cooldown", "skill3_cooldown"]:
				RunDirector.add_run_modifier(field, 0.0, 0.92, 0.0)
			persistent_changed = true
		"scout_assault", "scout_bulwark", "scout_focus":
			RunDirector.set_pending_encounter_prep(_scout_prep_for_choice(choice_id))
		"attune_offense":
			RunDirector.add_run_modifier("attack_damage", 0.0, 1.12)
			RunDirector.add_run_modifier("crit_rate", 0.04)
			persistent_changed = true
		"attune_focus":
			RunDirector.add_run_modifier("max_inspiration", 10.0)
			for field in ["skill1_cooldown", "skill2_cooldown", "skill3_cooldown"]:
				RunDirector.add_run_modifier(field, 0.0, 0.92, 0.0)
			persistent_changed = true
		"attune_guard":
			RunDirector.add_run_modifier("max_defense", 16.0)
			RunDirector.add_run_modifier("max_hp", 6.0)
			persistent_changed = true
			restore_defense_after_refresh = true
		"attune_flow":
			RunDirector.add_run_modifier("move_speed", 0.0, 1.10)
			RunDirector.add_run_modifier("attack_interval", 0.0, 0.94, 0.15)
			RunDirector.add_run_modifier("inspiration_gain_on_attack_hit", 0.8)
			persistent_changed = true
		"attune_gambit":
			RunDirector.add_run_modifier("crit_rate", 0.08)
			for field in ["skill1_damage", "skill2_damage", "skill3_damage"]:
				RunDirector.add_run_modifier(field, 0.0, 1.10, 0.0)
			for field in ["skill1_cost", "skill2_cost", "skill3_cost"]:
				RunDirector.add_run_modifier(field, 0.0, 1.08, 0.0)
			persistent_changed = true
	if persistent_changed:
		refresh_persistent_modifiers(actor)
	if restore_defense_after_refresh:
		restore_defense(actor)
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

static func refresh_persistent_modifiers(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	AccessoryManager.apply_to_actor(actor)
	RunDirector.apply_run_modifiers(actor)

static func can_pay(choice_id: String, gold: int) -> bool:
	return gold >= cost_for(choice_id)

static func cost_for(choice_id: String) -> int:
	match choice_id:
		"shop_attack":
			return 28
		"shop_defense":
			return 26
		"shop_relic":
			return 36
		_:
			return 0

static func summary(choice_id: String) -> String:
	var localized := _localized_choice_value(choice_id, "result")
	if not localized.is_empty():
		return localized
	match choice_id:
		"shop_attack":
			return "Sharpening Oil applied."
		"shop_defense":
			return "Armor reinforced."
		"shop_relic":
			return "A hidden relic cache is marked."
		"bounty_cache":
			return "Immediate gold claimed."
		"bounty_contract":
			return "Future bounty payments improved."
		"bounty_tithe":
			return "High-risk contract signed."
		"rest_heal":
			return "Health restored."
		"rest_focus":
			return "Inspiration and defense restored."
		"rest_repair":
			return "Armor repaired and vitality improved."
		"train_crit":
			return "Precision training complete."
		"train_speed":
			return "Footwork training complete."
		"train_cooldown":
			return "Skill rhythm improved."
		"train_resource":
			return "Inspiration capacity expanded."
		"forge_edge":
			return "Tempered Edge is complete."
		"forge_focus":
			return "Spell Lattice is complete."
		"forge_guard":
			return "Bastion Plate is complete."
		"forge_flow":
			return "Quickstep Gears are complete."
		"forge_seal":
			return "King's Seal is complete."
		"pact_power":
			return "Blood Price accepted."
		"pact_guard":
			return "Iron Oath accepted."
		"pact_focus":
			return "Astral Debt accepted."
		"scout_assault":
			return "Assault route prepared."
		"scout_bulwark":
			return "Bulwark route prepared."
		"scout_focus":
			return "Focus route prepared."
		"attune_offense":
			return "Battle Temper attuned."
		"attune_focus":
			return "Echo Circuit attuned."
		"attune_guard":
			return "Warden Seal attuned."
		"attune_flow":
			return "Wind Rhythm attuned."
		"attune_gambit":
			return "Last Nerve attuned."
		_:
			return "You move on."

static func display_name(choice_id: String) -> String:
	var localized := _localized_choice_value(choice_id, "title")
	if not localized.is_empty():
		return localized
	match choice_id:
		"shop_attack":
			return "Sharpening Oil"
		"shop_defense":
			return "Light Armor Pack"
		"shop_relic":
			return "Relic Map"
		"bounty_cache":
			return "Open Purse"
		"bounty_contract":
			return "Steady Contract"
		"bounty_tithe":
			return "Risk Contract"
		"rest_heal":
			return "Medkit"
		"rest_focus":
			return "Protective Candle"
		"rest_repair":
			return "Field Repair"
		"train_crit":
			return "Precision"
		"train_speed":
			return "Footwork"
		"train_cooldown":
			return "Rhythm"
		"train_resource":
			return "Focus Drill"
		"forge_edge":
			return "Tempered Edge"
		"forge_focus":
			return "Spell Lattice"
		"forge_guard":
			return "Bastion Plate"
		"forge_flow":
			return "Quickstep Gears"
		"forge_seal":
			return "King's Seal"
		"pact_power":
			return "Blood Price"
		"pact_guard":
			return "Iron Oath"
		"pact_focus":
			return "Astral Debt"
		"skip":
			return "Skip"
	var choice_data := _choice_catalog_entry(choice_id)
	if not choice_data.is_empty():
		return String(choice_data.get("title", choice_id))
	return choice_id.capitalize()

static func card_summary(choice_id: String) -> String:
	match choice_id:
		"bounty_cache":
			return _localized_text("Gain 24 gold immediately.", "立刻获得 24 金币。", "立刻獲得 24 金幣。")
		"bounty_contract":
			return _localized_text("Future encounters grant +8 gold.", "之后的战斗额外奖励 8 金币。", "之後的戰鬥額外獎勵 8 金幣。")
		"bounty_tithe":
			return _localized_text("Future battle gold +15%, but lose 10 max hp.", "之后的战斗金币 +15%，但失去 10 点最大生命。", "之後的戰鬥金幣 +15%，但失去 10 點最大生命。")
		"scout_assault":
			return _localized_text("Next encounter: +14% attack damage, +6% crit chance, and +14 gold on clear.", "下一战：攻击伤害 +14%，暴击率 +6%，胜利后额外 +14 金币。", "下一戰：攻擊傷害 +14%，暴擊率 +6%，勝利後額外 +14 金幣。")
	var localized := _localized_choice_value(choice_id, "card")
	if not localized.is_empty():
		return localized
	var choice_data := _choice_catalog_entry(choice_id)
	if not choice_data.is_empty():
		return String(choice_data.get("summary", ""))
	return ""

static func attunement_choices() -> Array[Dictionary]:
	var categories: Array[String] = []
	for tag in AccessoryManager.get_equipped_tags():
		var choice_id := String(ATTUNEMENT_TAG_MAP.get(String(tag), ""))
		if choice_id.is_empty() or categories.has(choice_id):
			continue
		categories.append(choice_id)
	for fallback in ATTUNEMENT_FILL_ORDER:
		if categories.size() >= 3:
			break
		if categories.has(fallback):
			continue
		categories.append(fallback)
	var choices: Array[Dictionary] = []
	for choice_id in categories:
		if choices.size() >= 3:
			break
		_append_choice_from_catalog(choices, choice_id, ATTUNEMENT_CHOICE_DATA)
	return choices

static func scout_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for choice_id in ["scout_assault", "scout_bulwark", "scout_focus"]:
		_append_choice_from_catalog(choices, choice_id, SCOUT_CHOICE_DATA)
	return choices

static func forge_choices(actor: Node = null) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var remaining: Array = FORGE_FILL_ORDER.duplicate()
	while choices.size() < 3 and not remaining.is_empty():
		var best_index := 0
		var best_score := -9999
		for index in range(remaining.size()):
			var choice_id := String(remaining[index])
			var score := _forge_offer_score(choice_id, actor)
			if score > best_score:
				best_score = score
				best_index = index
		_append_choice_from_catalog(choices, String(remaining[best_index]), FORGE_CHOICE_DATA)
		remaining.remove_at(best_index)
	return choices

static func choice_tags(choice_id: String) -> Array[String]:
	var tags: Array[String] = []
	for tag in CHOICE_TAGS.get(choice_id, []):
		var next_tag := String(tag)
		if next_tag.is_empty() or tags.has(next_tag):
			continue
		tags.append(next_tag)
	return tags

static func evaluate_choice(choice_id: String, actor: Node = null) -> Dictionary:
	if choice_id == "skip":
		return {
			"label": "Hold",
			"color": Color(0.76, 0.82, 0.90),
			"reason": _localized_text(
				"Passing keeps the current route and build unchanged.",
				"跳过后会保持当前路线与构筑不变。",
				"跳過後會保持當前路線與構築不變。"
			)
		}
	var relic_tags := AccessoryManager.get_equipped_tags()
	var hero_name := _hero_name(actor)
	var hero_tags: Array[String] = []
	for tag in HERO_TAG_PROFILES.get(hero_name, []):
		var next_tag := String(tag)
		if next_tag.is_empty() or hero_tags.has(next_tag):
			continue
		hero_tags.append(next_tag)
	var effect_tags := choice_tags(choice_id)
	var relic_matches: Array[String] = []
	var hero_matches: Array[String] = []
	for tag in effect_tags:
		if relic_tags.has(tag) and not relic_matches.has(tag):
			relic_matches.append(tag)
		if hero_tags.has(tag) and not hero_matches.has(tag):
			hero_matches.append(tag)

	var hp_ratio := _ratio(actor, "hp", "max_hp")
	var defense_ratio := _ratio(actor, "defense", "max_defense")
	var inspiration_ratio := _ratio(actor, "inspiration", "max_inspiration")
	var score := relic_matches.size() * 2 + hero_matches.size()
	var reasons: Array[String] = []
	if not relic_matches.is_empty():
		reasons.append(_localized_text(
			"Matches relic tags: %s.",
			"契合当前饰品标签：%s。",
			"契合當前飾品標籤：%s。"
		) % AccessoryManager.describe_tags(relic_matches))
	if not hero_matches.is_empty() and not hero_name.is_empty():
		reasons.append(_localized_text(
			"Plays well with %s's preferred lane.",
			"很适合 %s 当前偏好的战斗路线。",
			"很適合 %s 當前偏好的戰鬥路線。"
		) % _localized_hero_name(hero_name))
	if choice_id == "rest_heal" and hp_ratio <= 0.55:
		score += 3
		reasons.append(_localized_text(
			"Your health margin is low enough that raw healing is premium.",
			"当前血量压力偏高，直接治疗的价值很高。",
			"當前血量壓力偏高，直接治療的價值很高。"
		))
	if choice_id == "rest_focus" and (defense_ratio <= 0.35 or inspiration_ratio <= 0.35):
		score += 2
		reasons.append(_localized_text(
			"You are short on armor or inspiration for the next check.",
			"你在下一场检定前已经缺护甲或灵感了。",
			"你在下一場檢定前已經缺護甲或靈感了。"
		))
	if choice_id == "scout_assault" and hp_ratio >= 0.70:
		score += 2
		reasons.append(_localized_text(
			"Your health buffer is healthy enough to cash in on a fast opener.",
			"你的血线足够健康，可以兑现强势开局收益。",
			"你的血線足夠健康，可以兌現強勢開局收益。"
		))
	if choice_id == "scout_bulwark" and (hp_ratio <= 0.55 or defense_ratio <= 0.35):
		score += 3
		reasons.append(_localized_text(
			"This covers a weak defensive start and buys room to stabilize.",
			"这能补足偏弱的防守开局，并争取稳定空间。",
			"這能補足偏弱的防守開局，並爭取穩定空間。"
		))
	if choice_id == "scout_focus" and inspiration_ratio <= 0.45:
		score += 2
		reasons.append(_localized_text(
			"Your inspiration economy is low enough that a reset is meaningful.",
			"你的灵感循环已经偏紧，这次重置会很有价值。",
			"你的靈感循環已經偏緊，這次重置會很有價值。"
		))
	if choice_id == "shop_defense" and defense_ratio <= 0.40:
		score += 2
		reasons.append(_localized_text(
			"Defense is already thin, so armor value is immediate.",
			"当前护甲已经偏薄，补防御能立刻见效。",
			"當前護甲已經偏薄，補防禦能立刻見效。"
		))
	if choice_id == "train_resource" and inspiration_ratio <= 0.40:
		score += 2
		reasons.append(_localized_text(
			"Your hero is running close to inspiration pressure.",
			"你当前角色已经接近灵感压力线。",
			"你當前角色已經接近靈感壓力線。"
		))
	if choice_id == "shop_relic" and AccessoryManager.get_equipped_tags().is_empty():
		score += 2
		reasons.append(_localized_text(
			"An extra relic is strongest when your build identity is still thin.",
			"当构筑方向还不够明确时，额外饰品最有价值。",
			"當構築方向還不夠明確時，額外飾品最有價值。"
		))
	if choice_id == "forge_guard" and (hp_ratio <= 0.65 or defense_ratio <= 0.45):
		score += 3
		reasons.append(_localized_text(
			"This shores up a fragile mid-run state before it snowballs against you.",
			"这能在中盘失稳前把生存面补回来。",
			"這能在中盤失穩前把生存面補回來。"
		))
	if choice_id == "forge_focus" and inspiration_ratio <= 0.55:
		score += 2
		reasons.append(_localized_text(
			"Your build is tight on inspiration, so better spell economy pays immediately.",
			"当前灵感周转偏紧，强化技能经济会立刻见效。",
			"當前靈感周轉偏緊，強化技能經濟會立刻見效。"
		))
	if choice_id == "forge_edge" and hp_ratio >= 0.70:
		score += 2
		reasons.append(_localized_text(
			"You have enough health to press the run harder with a sharper damage lane.",
			"你当前血线足够健康，适合把伤害路线再往前推一档。",
			"你當前血線足夠健康，適合把傷害路線再往前推一檔。"
		))
	if choice_id == "forge_flow" and (hero_name == "Ranger" or relic_matches.has("tempo")):
		score += 2
		reasons.append(_localized_text(
			"This compounds tempo cleanly, especially on speed-leaning setups.",
			"这会很顺地叠高节奏，尤其适合偏速度的构筑。",
			"這會很順地疊高節奏，尤其適合偏速度的構築。"
		))
	if choice_id == "forge_seal" and (hero_name == "Mage" or (hp_ratio <= 0.75 and inspiration_ratio <= 0.70)):
		score += 2
		reasons.append(_localized_text(
			"This is a balanced bridge when you need both body and casting headroom.",
			"当你同时需要身板和施法空间时，这条线最均衡。",
			"當你同時需要身板和施法空間時，這條線最均衡。"
		))
	if choice_id in ["bounty_tithe", "pact_power", "attune_gambit"] and hp_ratio <= 0.42:
		score -= 3
		reasons.append(_localized_text(
			"This stacks risk while your current health buffer is already narrow.",
			"你当前血量缓冲已经偏窄，再叠风险会很危险。",
			"你當前血量緩衝已經偏窄，再疊風險會很危險。"
		))
	if choice_id == "pact_guard" and hero_name == "Ranger":
		score -= 1
		reasons.append(_localized_text(
			"The move-speed tax cuts into Ranger's cleanest advantage.",
			"移速惩罚会削弱游侠最明显的优势。",
			"移速懲罰會削弱遊俠最明顯的優勢。"
		))

	var label := "Flexible"
	var color := Color(0.80, 0.88, 1.0)
	if score >= 5:
		label = "Best Now"
		color = Color(0.78, 0.96, 0.82)
	elif score >= 2:
		label = "Strong Fit"
		color = Color(0.92, 0.90, 0.66)
	elif score >= 0:
		label = "Flexible"
		color = Color(0.80, 0.88, 1.0)
	else:
		label = "Risky"
		color = Color(1.0, 0.76, 0.70)

	return {
		"label": label,
		"color": color,
		"reason": reasons[0] if not reasons.is_empty() else _localized_text(
			"Keeps the run moving without a special synergy hook.",
			"能稳定推进流程，但没有特别明显的联动。",
			"能穩定推進流程，但沒有特別明顯的聯動。"
		)
	}

static func activate_encounter_prep(actor: Node, prep: Dictionary) -> void:
	if actor == null or not is_instance_valid(actor) or prep.is_empty():
		return
	if bool(prep.get("restore_defense", false)):
		restore_defense(actor)
	if bool(prep.get("restore_inspiration", false)):
		restore_inspiration(actor)
	apply_shield(actor, float(prep.get("shield", 0.0)))
	apply_temporary_effects(actor, prep.get("temporary_effects", {}) as Dictionary)
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

static func apply_temporary_effects(actor: Node, effects: Dictionary) -> void:
	if actor == null or not is_instance_valid(actor) or effects.is_empty():
		return
	for key in effects.keys():
		var value := float(effects[key])
		match String(key):
			"max_hp", "max_inspiration", "max_defense", "defense", "move_speed", "attack_damage", "crit_rate", "inspiration_gain_on_attack_hit":
				_apply_actor_flat(actor, String(key), value)
			"move_speed_pct":
				_apply_actor_percent(actor, "move_speed", value)
			"attack_damage_pct":
				_apply_actor_percent(actor, "attack_damage", value)
			"attack_interval_pct":
				_scale_actor(actor, "attack_interval", 1.0 + value, 0.15)
			"skill_cooldown_pct":
				for field in ["skill1_cooldown", "skill2_cooldown", "skill3_cooldown"]:
					_scale_actor(actor, field, 1.0 + value, 0.0)
			"skill_cost_pct":
				for field in ["skill1_cost", "skill2_cost", "skill3_cost"]:
					_scale_actor(actor, field, 1.0 + value, 0.0)
			"skill_damage_pct":
				for field in ["skill1_damage", "skill2_damage", "skill3_damage"]:
					_scale_actor(actor, field, 1.0 + value, 0.0)

static func apply_shield(actor: Node, amount: float) -> void:
	if actor == null or not is_instance_valid(actor) or amount <= 0.0:
		return
	var health_component := _health_component(actor)
	if health_component != null and health_component.has_method("apply_shield"):
		health_component.apply_shield(amount)
	elif _has_property(actor, "shield"):
		actor.shield = float(actor.get("shield")) + amount
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

static func clear_shield(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var health_component := _health_component(actor)
	if health_component != null and health_component.has_method("clear_shield"):
		health_component.clear_shield()
	elif _has_property(actor, "shield"):
		actor.shield = 0.0
	if actor.has_method("emit_stat_signals"):
		actor.emit_stat_signals()

static func heal_percent(actor: Node, percent: float) -> void:
	if not _has_property(actor, "max_hp") or not actor.has_method("heal"):
		return
	actor.heal(float(actor.max_hp) * percent)

static func restore_defense(actor: Node) -> void:
	var health_component: Node = actor.get("health_component") if _has_property(actor, "health_component") else null
	if health_component != null and health_component.has_method("restore_defense_full"):
		health_component.restore_defense_full()
	if _has_property(actor, "defense") and _has_property(actor, "max_defense"):
		actor.defense = actor.max_defense

static func restore_inspiration(actor: Node) -> void:
	if _has_property(actor, "inspiration") and _has_property(actor, "max_inspiration"):
		actor.inspiration = actor.max_inspiration

static func _apply_actor_flat(actor: Node, field: String, amount: float) -> void:
	if not _has_property(actor, field):
		return
	actor.set(field, float(actor.get(field)) + amount)

static func _apply_actor_percent(actor: Node, field: String, percent: float) -> void:
	if not _has_property(actor, field):
		return
	actor.set(field, float(actor.get(field)) * (1.0 + percent))

static func _scale_actor(actor: Node, field: String, multiplier: float, floor_value: float = -INF) -> void:
	if not _has_property(actor, field):
		return
	var next_value := float(actor.get(field)) * multiplier
	if floor_value != -INF:
		next_value = maxf(next_value, floor_value)
	actor.set(field, next_value)

static func _has_property(actor: Node, field: String) -> bool:
	for property in actor.get_property_list():
		if String(property.get("name", "")) == field:
			return true
	return false

static func _ratio(actor: Node, current_field: String, max_field: String) -> float:
	if actor == null or not is_instance_valid(actor):
		return 1.0
	if not _has_property(actor, current_field) or not _has_property(actor, max_field):
		return 1.0
	var max_value := float(actor.get(max_field))
	if max_value <= 0.0:
		return 1.0
	return clampf(float(actor.get(current_field)) / max_value, 0.0, 1.0)

static func _hero_name(actor: Node) -> String:
	if actor == null or not is_instance_valid(actor) or not actor.has_method("get_character_name"):
		return ""
	return String(actor.get_character_name())

static func _current_locale() -> String:
	if UISettings != null and UISettings.has_method("get_locale"):
		return String(UISettings.get_locale())
	return "zh_Hans"

static func prep_title(prep: Dictionary) -> String:
	if prep.is_empty():
		return _localized_text("Battle Plan", "战斗方案", "戰鬥方案")
	var choice_id := String(prep.get("choice_id", ""))
	var localized := _localized_choice_value(choice_id, "title")
	if not localized.is_empty():
		return localized
	return String(prep.get("title", _localized_text("Battle Plan", "战斗方案", "戰鬥方案")))

static func prep_summary(prep: Dictionary) -> String:
	if prep.is_empty():
		return _localized_text("Temporary opener active.", "临时开局增益生效。", "臨時開局增益生效。")
	var choice_id := String(prep.get("choice_id", ""))
	var localized := _localized_choice_value(choice_id, "card")
	if not localized.is_empty():
		return localized
	return String(prep.get("summary", _localized_text("Temporary opener active.", "临时开局增益生效。", "臨時開局增益生效。")))

static func _localized_choice_value(choice_id: String, field: String) -> String:
	var locale_map := CHOICE_LOCALIZATION.get(_current_locale(), {}) as Dictionary
	var entry := locale_map.get(choice_id, {}) as Dictionary
	return String(entry.get(field, ""))

static func _localized_text(en_text: String, zh_hans_text: String, zh_hant_text: String) -> String:
	match _current_locale():
		"zh_Hant":
			return zh_hant_text
		"zh_Hans":
			return zh_hans_text
		_:
			return en_text

static func _localized_hero_name(hero_name: String) -> String:
	match hero_name:
		"Knight":
			return _localized_text("Knight", "骑士", "騎士")
		"Ranger":
			return _localized_text("Ranger", "游侠", "遊俠")
		"Mage":
			return _localized_text("Mage", "法师", "法師")
		_:
			return hero_name

static func _health_component(actor: Node) -> Node:
	if actor == null:
		return null
	return actor.get("health_component") if _has_property(actor, "health_component") else actor.get_node_or_null("HealthComponent")

static func _scout_prep_for_choice(choice_id: String) -> Dictionary:
	var data := SCOUT_CHOICE_DATA.get(choice_id, {}) as Dictionary
	if data.is_empty():
		return {}
	var prep := (data.get("prep", {}) as Dictionary).duplicate(true)
	if prep.is_empty():
		return prep
	prep["choice_id"] = choice_id
	return prep

static func _append_choice_from_catalog(choices: Array[Dictionary], choice_id: String, catalog: Dictionary) -> void:
	var data: Dictionary = (catalog.get(choice_id, {}) as Dictionary).duplicate(true)
	if data.is_empty():
		return
	data["id"] = choice_id
	data["cost"] = 0
	data["title"] = display_name(choice_id)
	data["summary"] = card_summary(choice_id)
	choices.append(data)

static func _choice_catalog_entry(choice_id: String) -> Dictionary:
	if ATTUNEMENT_CHOICE_DATA.has(choice_id):
		return ATTUNEMENT_CHOICE_DATA.get(choice_id, {}) as Dictionary
	if SCOUT_CHOICE_DATA.has(choice_id):
		return SCOUT_CHOICE_DATA.get(choice_id, {}) as Dictionary
	if FORGE_CHOICE_DATA.has(choice_id):
		return FORGE_CHOICE_DATA.get(choice_id, {}) as Dictionary
	return {}

static func _forge_offer_score(choice_id: String, actor: Node = null) -> int:
	var score := 0
	var effect_tags := choice_tags(choice_id)
	var relic_tags := AccessoryManager.get_equipped_tags()
	for tag in effect_tags:
		if relic_tags.has(tag):
			score += 2
	var hero_name := _hero_name(actor)
	for tag in HERO_TAG_PROFILES.get(hero_name, []):
		if effect_tags.has(String(tag)):
			score += 1
	var hp_ratio := _ratio(actor, "hp", "max_hp")
	var defense_ratio := _ratio(actor, "defense", "max_defense")
	var inspiration_ratio := _ratio(actor, "inspiration", "max_inspiration")
	match choice_id:
		"forge_guard":
			if hp_ratio <= 0.65:
				score += 3
			if defense_ratio <= 0.50:
				score += 2
		"forge_focus":
			if inspiration_ratio <= 0.55:
				score += 3
		"forge_edge":
			if hp_ratio >= 0.70:
				score += 2
		"forge_flow":
			if hero_name == "Ranger":
				score += 2
		"forge_seal":
			if hero_name == "Mage":
				score += 2
			if hp_ratio <= 0.75 and inspiration_ratio <= 0.70:
				score += 2
	return score
