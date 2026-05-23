# Infinity Kingdom Ambience Prompt Pack

Use the exact cue id as the output filename. Recommended export format: `wav` or `ogg`, 48 kHz, loopable, trimmed. These files should behave like atmospheric layers, not foreground sound effects.

## Cue List

- `ambience_town_title_loop`: Quiet but uneasy town-hall atmosphere before the boss rush. Cold air, distant banner cloth, low stone-space resonance, restrained fire crackle.
- `ambience_town_battle_loop`: Same town atmosphere under pressure. Add distant boots, scattered metal movement, slightly stronger wind and tension.
- `ambience_town_boss_loop`: Throne-hall confrontation ambience. Heavy low rumble, colder reverb, sparse chain or armor resonance, more oppressive air movement.

## Direction

- All three cues should feel like the same town chapter location at different threat levels.
- Keep them supportive and low-contrast so they sit under music and combat SFX.
- Avoid obvious melodic content. Use texture, rumble, distant impacts, and air.
- Differentiate them by spatial identity, not only loudness:
  - title: cold hall plus cloth and torch life
  - battle: movement, boots, armor bustle, and rising pressure
  - boss: low pressure, chain resonance, and a heavier throne-room void

## Runtime Notes

- `Music.play_profile(...)` switches both BGM and ambience layers together.
- Ambience routes through the dedicated `Ambience` bus.
- The in-game audio panel can adjust `Music / Ambience / SFX / UI` independently and mute each lane without losing the stored slider level.
