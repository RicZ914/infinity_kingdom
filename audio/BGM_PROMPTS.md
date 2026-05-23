# Infinity Kingdom BGM Prompt Pack

Use the exact cue id as the output filename. Recommended export format: `wav` or `ogg`, 48 kHz, trimmed. Loop tracks should begin cleanly and re-enter smoothly when replayed.

All five cues should feel like the same town chapter soundtrack family:
- shared harmonic language
- shared lead timbre family
- a recognizable leitmotif that appears in calmer, combat, boss, victory, and defeat variants

## Cue List

- `music_title_loop`: Town selection / chapter preparation music. Reflect a tense frontier town before the boss rush, restrained fantasy pulse, 24 to 36 seconds. This is the base statement of the chapter motif.
- `music_town_battle_loop`: Small-enemy wave combat loop. Brisk rhythm, military pressure, readable midrange, 20 to 30 seconds. Reuse the title motif in a more rhythmic and percussive arrangement.
- `music_town_boss_loop`: Town finale boss loop. Heavier percussion, darker harmonic weight, higher urgency, 20 to 28 seconds. Same motif, but lower, more forceful, and more oppressive.
- `music_victory_stinger`: Clear chapter-clear reward cue. Bright resolution, compact, 2.5 to 4.5 seconds. Resolve the chapter motif upward.
- `music_defeat_stinger`: Short defeat cue. Weighty and final without being overly long, 2.5 to 4.5 seconds. Collapse the same motif downward.

## Runtime Notes

- `Music` routes all BGM through the `Music` bus.
- `world.gd` switches cues automatically for title, mob waves, bosses, victory, and defeat.
- `Sfx` can temporarily duck the `Music` bus during heavy hits and major skills.
