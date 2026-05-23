# Infinity Kingdom

Godot 4 action prototype with three playable families, a town boss rush, custom UI art, audio mix controls, and an accessory relic system.

## Run

1. Open `project.godot` with Godot 4.6 or newer.
2. Run `world.tscn`.
3. Pick Knight, Ranger, or Mage.
4. Choose an accessory at the start and after each cleared encounter.

## Controls

- `WASD`: move
- `J` or left mouse: attack
- `K`, `L`, `I`: skills
- `F10`: audio mix panel
- `Esc`: close audio panel

## Structure

- `characters/`: playable character scenes and state machines
- `actors/`: enemies, encounters, and town bosses
- `combat/`: shared health and defense component
- `effects/`: damage numbers and projectiles
- `systems/accessories/`: accessory data, equip logic, and stat application
- `ui/`: HUD, character select, accessory choice, and UI skin helpers
- `assets/`: committed gameplay and UI art assets
- `audio/`: music, ambience, SFX managers, generated placeholder audio
