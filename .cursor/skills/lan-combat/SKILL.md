---
name: lan-combat
description: Pelotitas LAN/ENet combat rules (authority, projectiles, damage, knockback). Use when touching net.gd, player collision, take_damage, projectiles, MultiplayerSpawner, or host/join.
---

# LAN combat

Movement is per-player authority + `MultiplayerSynchronizer` (position, velocity, health). Combat is not "server simulates everything".

## Do

- **Projectiles**: spawn on every peer (`rpc` + `call_local`). Simulate flight/lifetime on **all** peers. Do not `return` in `_physics_process` for lack of authority (that freezes shots on the other machine).
- **Damage / knockback**: the **projectile owner** registers the hit. `take_damage` runs on the **victim's** authority (`rpc_take_damage` if the owner is not the victim). Replicas must not write health or apply damage. Health replicates; UI/death follow `current_health`.
- **Ball vs ball**: the peer that detects the slide applies its own impulse and `rpc_apply_impulse` to the other peer. Do not write `other.velocity` if you do not own `other`.
- **Spawner**: `PlayerSpawner.spawn_path` must resolve to the `Players` node (`../Players` or `get_path_to(players_node)`). Sibling name `"Players"` is wrong.
- **Join on phone**: on-screen IP keypad in `main_menu.gd`, not system `LineEdit` IME.

## Don't

- Don't add a new net layer or mirror service.
- Don't `push_error` for expected join/host failures (debug APK pops a dialog). Use `Net.last_error_text` + the menu label.
- Don't change scene inside an RPC without `call_deferred`.

Port: `GameRules.DEFAULT_LAN_PORT` (7777).
