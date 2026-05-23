# Infinity Kingdom SFX Prompt Pack

Use the exact event id as the output filename. Recommended export format: `wav` or `ogg`, 48 kHz, trimmed, with no long tail unless noted.

## UI

- `ui_confirm`: Clean, bright confirm click for character select and menu accept. Short, magical-metallic, 0.15 to 0.25 seconds.

## Knight

- `knight_attack`: Heavy sword swing, disciplined steel whoosh, 0.25 to 0.45 seconds.
- `knight_skill1_charge`: Charged dash slash with a short wind-up and a forceful cleave, 0.45 to 0.8 seconds.
- `knight_skill2_shockwave`: Ground shockwave counter with a dense slam and low-end impact, 0.35 to 0.7 seconds.
- `knight_skill3_sanctuary`: Holy field activation with bell-like sacred energy, 0.6 to 1.1 seconds.
- `knight_hit`: Armored hurt reaction, metal scrape plus body impact, 0.15 to 0.3 seconds.
- `knight_dead`: Heavy armored collapse with weapon and plate clatter, 0.8 to 1.4 seconds.

## Ranger

- `ranger_attack`: Fast close-range slash, sharp and agile, 0.12 to 0.25 seconds.
- `ranger_skill1_arrow`: Piercing bow release with a cutting wind trail, 0.2 to 0.4 seconds.
- `ranger_skill2_roll`: Short evasive roll with cloth and wind motion, 0.18 to 0.35 seconds.
- `ranger_skill3_assassinate`: Burst lunge into a lethal stab, 0.3 to 0.55 seconds.
- `ranger_hit`: Light hurt reaction, crisp and quick, 0.12 to 0.22 seconds.
- `ranger_dead`: Light collapse with gear slipping away, 0.45 to 0.8 seconds.

## Mage

- `mage_attack`: Arcane bolt cast with a blue-white magical release, 0.18 to 0.35 seconds.
- `mage_skill1_blades`: Arcane blades forming and orbiting into place, 0.45 to 0.8 seconds.
- `mage_skill2_burst`: Compressed magic detonating at a target point, 0.3 to 0.6 seconds.
- `mage_skill3_enchant`: Runic enchant activation, restrained but clear, 0.25 to 0.45 seconds.
- `mage_hit`: Hurt reaction with magical instability and rune scatter, 0.15 to 0.28 seconds.
- `mage_dead`: Magic extinguishing and energy dispersing, 0.7 to 1.2 seconds.

## Enemies

- `enemy_swordsman_attack`: Town swordsman slash, plain but trained military strike, 0.22 to 0.38 seconds.
- `enemy_shield_bash`: Dense shield impact with armor friction, 0.25 to 0.45 seconds.
- `enemy_archer_shot`: Enemy bow draw and release, readable and grounded, 0.22 to 0.38 seconds.
- `enemy_hunter_dash`: Predatory dash-in with short dangerous wind, 0.2 to 0.35 seconds.
- `enemy_apprentice_cast`: Unstable inexperienced spell release, 0.25 to 0.45 seconds.
- `enemy_arcanist_cast`: High-pressure arcane focus suitable for elite spell telegraphs, 0.35 to 0.7 seconds.
- `enemy_generic_hit`: Short generic enemy hurt reaction, 0.1 to 0.2 seconds.
- `enemy_generic_dead`: Quick enemy collapse or energy breakup, 0.35 to 0.7 seconds.

## Boss

- `boss_judicator_attack`: Two-handed heavy slash with strong pressure, 0.3 to 0.5 seconds.
- `boss_judicator_skill1`: Leap slam with stone debris and low-end impact, 0.55 to 0.95 seconds.
- `boss_judicator_skill2`: Straight line ground-rending smash, 0.5 to 0.9 seconds.
- `boss_guard_immune_break`: Barrier shatter and linked energy collapse, 0.45 to 0.8 seconds.
- `boss_twin_teleport`: Teleport slash with vanish, afterimage, and close strike, 0.28 to 0.5 seconds.
- `boss_twin_charge`: Spear rush with buildup and burst acceleration, 0.45 to 0.8 seconds.
- `boss_twin_barrage`: Repeated sacred projectile barrage, dense but readable, 0.45 to 0.85 seconds.
- `boss_generic_dead`: Large boss death with a dramatic final collapse, 0.9 to 1.6 seconds.

## Replacement Workflow

- Place rendered files in `audio/generated/` using the exact event id as the filename.
- `Sfx` checks `audio/generated/` first and falls back to `audio/sfx/`.
- The placeholder generator produces prototype assets only. Replace them one-for-one with higher quality files when ready.
