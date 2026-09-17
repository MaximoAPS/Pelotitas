# Arquitectura actual

Fuente de verdad de diseño: `docs/DESIGN.md` y `docs/GDD.md`.  
Fuente de verdad de **números locked** en código: `scripts/core/game_rules.gd`.

## Autoloads

| Autoload | Script | Rol |
|---|---|---|
| GameRules | `scripts/core/game_rules.gd` | Fórmulas locked: daño, XP, spawn, afinidad, stats |
| Net | `scripts/core/net.gd` | ENet host/join. `is_networked()` / `is_offline()` (Godot 4.7 siempre tiene OfflineMultiplayerPeer) |
| Progression | `scripts/core/progression.gd` | XP, level-up, afinidad, stats de pelotita |
| TouchInput | `scripts/core/touch_input.gd` | Joystick + press-hold-drag-release |
| UserPrefs | `scripts/core/user_prefs.gd` | Nickname local |
| ModeRegistry | `scripts/modes/mode_registry.gd` | Factory de modos (`create_mode(id)`) |

## Cómo agregar contenido

- **Modo**: heredar `Mode`, registrar en `ModeRegistry._register_default_modes()`, crear con `ModeRegistry.create_mode("id")`.
- **Habilidad usable**: heredar `UsableAbility` (ver `ElementalShot`), crear `.tres` en `resources/abilities/`. Clase nueva solo si `execute()` hace otra cosa (chorro, recoil, muro). No usar `BallBody` / trajectories stub.
- **Pasiva**: heredar `PassiveAbility` e implementar `apply`/`remove`. 12 para aprender, 1 slot.
- **Fórmulas**: no hardcodear daño/XP/spawn; usar `GameRules`.

## Árbol (diseño locked, código no)

Ver `docs/GDD.md` §5.5. Resumen: disparo nv 2 abre 3 usables T2; cada T2 nv 2 abre su pasiva. Rangos 1–3 refuerzan el rasgo (fuego D, viento speed, tierra masa, agua steer+lifetime). 9 puntos al nivel 10. Primera pasiva = 4 puntos del mismo elemento (nivel 5 mínimo). Loadout 3 usables + 1 pasiva.

Hoy: 4 disparos básicos, slot 0 nada más, `learn_skill` existe, no hay UI de árbol ni rangos.

## Tests headless

```
"C:\godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "C:\dev\Pelotitas" "res://tests/logic_tests.tscn"
"C:\godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --headless --path "C:\dev\Pelotitas" "res://tests/duel_integration.tscn"
```

## Límites de módulo (no inflar)

- `arena_duelo.gd`: orquesta spawn, HUD y RPC de proyectil. No meter fórmulas de drive/daño ahí.
- `player.gd`: input, drive (`GameRules.compose_drive_accel`), choques, HP.
- `projectile.gd`: vuelo y hit. En LAN vuela en **todos** los peers; el dueño del tiro registra el hit y `rpc_take_damage` aplica en la víctima.
- `main_menu.gd`: host/join UI. Teclado IP en pantalla (el `LineEdit` nativo no escribe bien en el celu).

## LAN (estado del código)

- Spawn de jugadores: `MultiplayerSpawner` → `../Players`.
- Tiros: `_spawn_projectile_networked` (`any_peer`, `call_local`).
- Choque pelota-pelota: impulso propio + `rpc_apply_impulse` al otro peer.
- Join: keypad en `main_menu.gd`, no el diálogo de texto del sistema.

Cursor: `.cursor/rules/ponytail.mdc` + `pelotitas-architecture.mdc`. Skills: `add-ability`, `add-mode`, `lan-combat`.

No implementado aún (a propósito): pilares de arena, UI de skill tree / rangos / T2, matchmaking. Roster persiste en `user://` (cap 1 por ahora).
