---
name: add-ability
description: Adds a Pelotitas usable or passive ability using Ability/UsableAbility/PassiveAbility and a .tres in resources/abilities. Use when creating a new shot, skill, passive, loadout slot, or elemental ability.
---

# Add ability

Tree rules (locked): `docs/GDD.md` §5.5. Rank 1–3 on the same skill (not extra loadout slots). T2 usables unlock at basic-shot rank 2; each T2 rank 2 unlocks **its** passive. 12 passives to learn, 1 equipped.

1. Read `scripts/abilities/ability.gd`, `usable_ability.gd` or `passive_ability.gd`, and `implementations/elemental_shot.gd`.
2. Reuse `ElementalShot` + a new `.tres` if it is only color/element/speed/rank numbers. New class only if `execute()` differs (spread, recoil, wall). Do **not** use `BallBody` / `TrajectoryBehavior` stubs.
3. Put data in `resources/abilities/`. Equip in `arena_duelo.gd` loadout setup only if the duel should start with it.
4. Formulas (damage, spawn offset, rank numbers) go through `GameRules`, not magic numbers in the ability.
5. Networked spawn: follow `ElementalShot.execute` (`arena._spawn_projectile_networked.rpc`). New projectile behavior (stop, bounce, expire) must simulate on all peers.
6. Add one check in `tests/logic_tests.gd` if the ability introduces a formula. Skip for a duplicate `.tres`.
