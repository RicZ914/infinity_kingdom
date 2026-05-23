Drop generated `wav` or `ogg` files in this folder using the exact event id as the filename.

Examples:
- `knight_attack.wav`
- `mage_skill2_burst.wav`
- `enemy_arcanist_cast.ogg`
- `boss_twin_barrage.wav`

The runtime loader checks this folder first, then falls back to `res://audio/sfx`.

Prototype placeholders can be generated with:

```bash
python audio/tools/generate_placeholder_sfx.py --force --clean
python audio/tools/generate_placeholder_bgm.py --force --clean
python audio/tools/generate_placeholder_ambience.py --force --clean
```

These placeholder files are meant for playable feedback only. Replace them one-for-one with higher quality assets later without changing any game logic.

Current music cue filenames:
- `music_title_loop.wav`
- `music_town_battle_loop.wav`
- `music_town_boss_loop.wav`
- `music_victory_stinger.wav`
- `music_defeat_stinger.wav`

Current ambience cue filenames:
- `ambience_town_title_loop.wav`
- `ambience_town_battle_loop.wav`
- `ambience_town_boss_loop.wav`
