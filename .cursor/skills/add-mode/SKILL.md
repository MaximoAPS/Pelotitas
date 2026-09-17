---
name: add-mode
description: Adds a Pelotitas game mode by subclassing Mode and registering it in ModeRegistry. Use when creating a new match type, victory condition, or game mode.
---

# Add mode

1. Read `scripts/modes/mode.gd` and `duelo_por_vida.gd`.
2. New script inheriting `Mode`. Set `mode_id`, `mode_name`, `max_players`, `map_scene_path`.
3. Override `get_spawn_positions`, `on_match_start`, `check_victory_conditions` only.
4. Register with `ModeRegistry.register_mode(...)` inside `_register_default_modes()`.
5. Start it via `ModeRegistry.create_mode("id")` then `Game.start_duel(mode)`. Do not `new()` the mode from random scenes.
6. Spawn positions from `GameRules` if the map is the same arena.
7. One logic_tests assertion if the mode adds a formula. Skip if it only reuses DueloPorVida rules.
