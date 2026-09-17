extends Node
## Headless logic tests. Run:
## Godot --headless --path C:\dev\Pelotitas res://tests/logic_tests.tscn

const DueloPorVidaScript = preload("res://scripts/modes/duelo_por_vida.gd")
const PelotitaDataScript = preload("res://scripts/progression/pelotita_data.gd")
const LoadoutScript = preload("res://scripts/abilities/loadout.gd")
const BallBodyScript = preload("res://scripts/combat/ball_body.gd")


func _ready() -> void:
	print("[LogicTests] Starting...")
	var failures: Array[String] = []
	_test_damage_formula(failures)
	_test_xp_formula(failures)
	_test_win_xp(failures)
	_test_spawn_positions(failures)
	_test_affinity_and_create(failures)
	_test_pelotita_data_shape(failures)
	_test_loadout_slots(failures)
	_test_geometric_mean(failures)
	_test_mode_registry_autoload(failures)
	_test_element_enums(failures)
	_test_level_up_xp(failures)
	_test_accel_time(failures)
	_test_speed_friction(failures)
	_test_lan_address(failures)
	_test_wall_and_shots(failures)
	print("[LogicTests] Done. Failures: %d" % failures.size())
	for f in failures:
		print("  FAIL: %s" % f)
	get_tree().quit(1 if failures.size() > 0 else 0)


func _test_damage_formula(failures: Array[String]) -> void:
	var cases := [
		{"atk": 10, "def": 5, "expected": 8},
		{"atk": 15, "def": 8, "expected": 11},
		{"atk": 1, "def": 100, "expected": 1},
		{"atk": 60, "def": 40, "expected": 40},
	]
	for c in cases:
		var got = GameRules.compute_combat_damage(c.atk, c.def)
		if got != c.expected:
			failures.append("damage atk=%s def=%s got=%s expected=%s" % [c.atk, c.def, got, c.expected])


func _test_xp_formula(failures: Array[String]) -> void:
	for level in range(1, 11):
		var implemented = Progression._calculate_exp_for_level(level)
		var expected = GameRules.xp_required_for_level(level)
		if implemented != expected:
			failures.append("xp level %s implemented=%s expected=%s" % [level, implemented, expected])


func _test_win_xp(failures: Array[String]) -> void:
	if not Progression.has_method("calculate_win_xp"):
		failures.append("Progression.calculate_win_xp missing")
		return
	if Progression.calculate_win_xp(5, 5) != 25:
		failures.append("win xp same level")
	if Progression.calculate_win_xp(5, 6) != 30:
		failures.append("win xp +1 level")
	if Progression.calculate_win_xp(5, 13) != 65:
		failures.append("win xp cap")
	if Progression.calculate_win_xp(5, 1) != 5:
		failures.append("win xp min")


func _test_spawn_positions(failures: Array[String]) -> void:
	var mode = DueloPorVidaScript.new()
	var spawns = mode.get_spawn_positions()
	var expected = GameRules.duel_spawn_positions()
	if spawns[0] != expected[0] or spawns[1] != expected[1]:
		failures.append("spawn positions mode=%s,%s expected=%s,%s" % [spawns[0], spawns[1], expected[0], expected[1]])
	var rect := GameRules.arena_rect()
	if not rect.has_point(spawns[0]) or not rect.has_point(spawns[1]):
		failures.append("spawn outside arena rect")
	if not is_equal_approx(GameRules.ARENA_SCALE, 0.75):
		failures.append("ARENA_SCALE should be 0.75 (25 percent smaller)")
	if not is_equal_approx(GameRules.arena_size().x, 1440.0):
		failures.append("arena width should be 1440")


func _test_affinity_and_create(failures: Array[String]) -> void:
	seed(1)
	var bad_sum := 0
	var missing_stats := false
	for i in range(40):
		var data = Progression.create_pelotita("t_%d" % i)
		var total := 0
		for w in data.affinity_weights.values():
			total += int(w)
		if total != 100:
			bad_sum += 1
		if not data.has("ataque") or not data.has("defensa") or not data.has("velocidad"):
			missing_stats = true
		var hp_hit := int(data.get("bonus_hp", 0)) == GameRules.LEVELUP_HP
		var masa_hit := is_equal_approx(float(data.masa), GameRules.DEFAULT_MASA + GameRules.LEVELUP_MASA)
		if hp_hit == masa_hit:
			failures.append("create vitality should pick HP xor masa")
			break
		for key in ["ataque", "defensa", "velocidad"]:
			var v := float(data.get(key, 0))
			if v < 50.0 or v > 60.0:
				failures.append("create_pelotita %s out of 50-60: %s" % [key, v])
				break
	if missing_stats:
		failures.append("create_pelotita missing combate stats (ataque/defensa/velocidad)")
	if bad_sum > 0:
		failures.append("affinity sum != 100 in %d/40 rolls" % bad_sum)


func _test_pelotita_data_shape(failures: Array[String]) -> void:
	var typed = PelotitaDataScript.create_new("typed_1")
	var roundtrip = PelotitaDataScript.from_dict(typed.to_dict())
	if typed.pelotita_id != roundtrip.pelotita_id:
		failures.append("PelotitaData roundtrip id mismatch")


func _test_loadout_slots(failures: Array[String]) -> void:
	var loadout = LoadoutScript.new()
	if LoadoutScript.MAX_USABLE_ABILITIES != 3 or LoadoutScript.MAX_PASSIVE_ABILITIES != 1:
		failures.append("loadout slot constants drifted")
	if loadout.usable_abilities.size() != 3:
		failures.append("loadout usable array size %d" % loadout.usable_abilities.size())
	if loadout.equip_usable(null, 3):
		failures.append("loadout accepted invalid slot 3")


func _test_geometric_mean(failures: Array[String]) -> void:
	var g = pow(1.5 * 0.75, 0.5)
	if abs((1.5 / g) / (0.75 / g) - 2.0) > 0.001:
		failures.append("geometric mean ratio not 2.0")
	# GDD: SPD 60 vs 50 → ~1.095 / 0.913 m/s → ~219 / 183 px/s
	var gdd_g = GameRules.geometric_mean([60.0, 50.0])
	var a_ms = GameRules.speed_m_s_from_stat(60.0, gdd_g)
	var b_ms = GameRules.speed_m_s_from_stat(50.0, gdd_g)
	if abs(a_ms - 1.095445) > 0.001:
		failures.append("GDD SPD 60 m/s got=%s" % a_ms)
	if abs(b_ms - 0.912871) > 0.001:
		failures.append("GDD SPD 50 m/s got=%s" % b_ms)
	if abs(a_ms * GameRules.PIXELS_PER_METER - 219.089) > 0.5:
		failures.append("GDD SPD 60 px/s got=%s" % (a_ms * GameRules.PIXELS_PER_METER))
	if abs(b_ms * GameRules.PIXELS_PER_METER - 182.574) > 0.5:
		failures.append("GDD SPD 50 px/s got=%s" % (b_ms * GameRules.PIXELS_PER_METER))


func _test_mode_registry_autoload(failures: Array[String]) -> void:
	if get_tree().root.get_node_or_null("ModeRegistry") == null:
		failures.append("ModeRegistry is not an autoload")


func _test_element_enums(failures: Array[String]) -> void:
	var same := (
		int(Progression.Element.FUEGO) == 0
		and int(BallBodyScript.Elemento.FUEGO) == 0
		and int(PelotitaDataScript.Elemento.FUEGO) == 0
		and int(Progression.Element.AIRE) == int(BallBodyScript.Elemento.AIRE)
	)
	if not same:
		failures.append("Element enums drifted across types")


func _test_level_up_xp(failures: Array[String]) -> void:
	var id := "level_probe"
	var data = Progression.create_pelotita(id)
	var before_hp := int(data.get("bonus_hp", 0))
	var before_masa := float(data.masa)
	var need = Progression.xp_required_for_level(data.level + 1)
	Progression.grant_experience(id, need)
	var after = Progression.pelotitas_data[id]
	if after.level != 2:
		failures.append("grant_experience did not level 1->2")
	if after.experience != 0:
		failures.append("level-up did not consume XP threshold")
	var hp_up := int(after.get("bonus_hp", 0)) == before_hp + GameRules.LEVELUP_HP
	var masa_up := is_equal_approx(float(after.masa), before_masa + GameRules.LEVELUP_MASA)
	if hp_up == masa_up:
		failures.append("level-up vitality should pick HP xor masa")
	Progression.reset_pelotita(id)
	var reset = Progression.pelotitas_data[id]
	if int(reset.level) != 1:
		failures.append("reset_pelotita should return to level 1")
	if int(reset.get("experience", -1)) != 0:
		failures.append("reset_pelotita should clear XP")
	if reset.get("learned_skills", []).size() != 1:
		failures.append("reset_pelotita should leave 1 dominant shot")
	if Progression.pelotitas_data.size() != 1:
		failures.append("roster cap 1: reset should keep a single pelotita")


func _test_accel_time(failures: Array[String]) -> void:
	if not is_equal_approx(GameRules.ACCEL_TIME_TO_MAX, 1.5):
		failures.append("ACCEL_TIME_TO_MAX should be 1.5s")
	if not is_equal_approx(GameRules.acceleration_for(300.0), 200.0):
		failures.append("acceleration_for(300) should be 200 px/s^2")
	if not is_equal_approx(GameRules.OVERSPEED_SLOWDOWN_TIME, 1.5):
		failures.append("OVERSPEED_SLOWDOWN_TIME should be 1.5s")
	if not is_equal_approx(GameRules.overspeed_decel(300.0), 200.0):
		failures.append("overspeed_decel(300) should be 200 px/s^2")
	if not is_equal_approx(GameRules.ELASTIC_RESTITUTION, 1.0):
		failures.append("ELASTIC_RESTITUTION should be 1.0 (no energy gain)")


func _test_speed_friction(failures: Array[String]) -> void:
	var a_pad := 200.0
	var vmax := 300.0
	if not is_equal_approx(GameRules.speed_friction(150.0, vmax, a_pad), 0.0):
		failures.append("friction at 50% vmax should be 0")
	if not is_equal_approx(GameRules.speed_friction(vmax, vmax, a_pad), 0.0):
		failures.append("friction at vmax should be 0")
	if not is_equal_approx(GameRules.speed_friction(600.0, vmax, a_pad), 400.0):
		failures.append("friction at 2x vmax should be 2*pad_accel")
	var half := GameRules.compose_drive_accel(Vector2(150, 0), Vector2.RIGHT, vmax, a_pad)
	if not half.is_equal_approx(Vector2(a_pad, 0)):
		failures.append("below vmax: a should be pad only, got %s" % half)
	var over_forward := GameRules.compose_drive_accel(Vector2(400, 0), Vector2.RIGHT, vmax, a_pad)
	if over_forward.x > 0.001:
		failures.append("v>vmax pad along v: parallel must be 0, got %s" % over_forward)
	var double_forward := GameRules.compose_drive_accel(Vector2(600, 0), Vector2.RIGHT, vmax, a_pad)
	if not is_equal_approx(double_forward.x, -a_pad):
		failures.append("2x vmax pad along v: net should be -a_pad, got %s" % double_forward.x)
	var double_side := GameRules.compose_drive_accel(Vector2(600, 0), Vector2(0, 1), vmax, a_pad)
	if not is_equal_approx(double_side.x, -2.0 * a_pad) or not is_equal_approx(double_side.y, a_pad):
		failures.append("2x vmax pad perp: want (-2a, a), got %s" % double_side)


func _test_lan_address(failures: Array[String]) -> void:
	if Net.sanitize_address(" 192,168,0,10 ") != "192.168.0.10":
		failures.append("sanitize_address should fix spaces and commas")
	if not Net.is_probable_ipv4("192.168.0.10"):
		failures.append("192.168.0.10 should be valid ipv4")
	if Net.is_probable_ipv4("192.168"):
		failures.append("192.168 should be invalid ipv4")


func _test_wall_and_shots(failures: Array[String]) -> void:
	if GameRules.compute_wall_damage(200.0, 1.0) != 3:
		failures.append("wall damage 200px/s masa1 should be 3 (+50% vs old 2)")
	if GameRules.compute_wall_damage(100.0, 1.0) != 0:
		failures.append("wall damage at threshold should be 0")
	if GameRules.compute_wall_damage(200.0, 1.0, 5) != 6:
		failures.append("wall damage after 5 shrinks should double")
	if GameRules.shrink_steps_for_time(0.0) != 0 or GameRules.shrink_steps_for_time(29.9) != 0:
		failures.append("no shrink before 30s")
	if GameRules.shrink_steps_for_time(30.0) != 1:
		failures.append("first shrink at 30s")
	if GameRules.shrink_steps_for_time(150.0) != 5 or GameRules.shrink_steps_for_time(180.0) != 5:
		failures.append("shrink should cap at 5 steps / 2:30")
	if not is_equal_approx(GameRules.arena_area_frac(5), 0.5):
		failures.append("5 shrinks should leave half area")
	if not is_equal_approx(GameRules.wall_damage_scale(5), 2.0):
		failures.append("5 shrinks should double wall damage scale")
	if GameRules.max_health_from_bonus(0) != 100:
		failures.append("base HP should be 100")
	if GameRules.max_health_from_bonus(GameRules.LEVELUP_HP * 10) != 200:
		failures.append("10 HP rolls should double life to 200")
	if not is_equal_approx(GameRules.DEFAULT_MASA + GameRules.LEVELUP_MASA * 10.0, 3.0):
		failures.append("10 masa rolls should triple mass to 3")
	if GameRules.shot_speed_mult(3) <= GameRules.shot_speed_mult(0):
		failures.append("viento should be faster than fuego")
	if not is_equal_approx(GameRules.shot_speed_mult(0), 1.5):
		failures.append("default shot speed should be 1.5 vmax")
	if not is_equal_approx(GameRules.shot_speed_mult(3), 2.25):
		failures.append("viento shot speed should be 2.25 vmax")
	if GameRules.shot_damage_for(0) != 30:
		failures.append("fuego D should be 30")
	if GameRules.shot_damage_for(1) != 20:
		failures.append("non-fuego D should be 20")
	if not is_equal_approx(GameRules.shot_masa_for(2), 1.5):
		failures.append("tierra masa should be 1.5")
	if not is_equal_approx(GameRules.shot_masa_for(0), 1.0):
		failures.append("non-tierra masa should be 1")
	if not is_equal_approx(GameRules.shot_steer_frac(1), 0.1):
		failures.append("agua steer frac should be 0.1")
	if GameRules.shot_steer_frac(0) != 0.0:
		failures.append("fuego should not steer")
	var steered := GameRules.steer_shot_velocity(Vector2(100, 0), Vector2(0, 50), 0.1, 0.1)
	if steered.y <= 0.0:
		failures.append("agua steer should add perpendicular toward target")
	if abs(steered.length() - 100.0) > 0.01:
		failures.append("steer must keep speed, got %s" % steered.length())
	if GameRules.shot_speed_px(200.0, 0) != 300.0:
		failures.append("1.5*200 vmax should be 300")
	if GameRules.shot_speed_px(200.0, 3) != 450.0:
		failures.append("2.25*200 vmax should be 450")
	var swap := GameRules.elastic_deltas(Vector2(-10, 0), 1.0, Vector2(10, 0), 1.0, Vector2.RIGHT, 1.0, 0.0)
	if not swap.a.is_equal_approx(Vector2(20, 0)) or not swap.b.is_equal_approx(Vector2(-20, 0)):
		failures.append("equal-mass elastic should swap, got %s %s" % [swap.a, swap.b])
	var still := Vector2.ZERO
	var fire_hit := GameRules.elastic_deltas(still, 1.0, Vector2(300, 0), 1.0, Vector2.RIGHT)
	var earth_hit := GameRules.elastic_deltas(still, 1.0, Vector2(300, 0), 1.5, Vector2.RIGHT)
	if earth_hit.a.length() <= fire_hit.a.length():
		failures.append("heavier shot should push player more")
	var wind_hit := GameRules.elastic_deltas(still, 1.0, Vector2(450, 0), 1.0, Vector2.RIGHT)
	if wind_hit.a.length() <= fire_hit.a.length():
		failures.append("faster viento should push more than fuego")
	# D=20, ATK=DEF=50, m=M → 20. El elemento del jugador no entra.
	if GameRules.compute_shot_damage(20, 50, 50, 1.0, 1.0) != 20:
		failures.append("neutral shot D20 atk=def should be 20")
	if GameRules.compute_shot_damage(20, 60, 40, 1.0, 1.0) != 30:
		failures.append("D*ATK/DEF 20*60/40 should be 30")
	if GameRules.compute_shot_damage(20, 50, 50, 0.5, 1.0) != 10:
		failures.append("half remaining mass should deal half damage")
	if GameRules.shot_mass_advantage(1, 0) != 2.0:
		failures.append("agua vs fuego shot-vs-shot should be ×2")
	if GameRules.shot_mass_advantage(1, 0) == 2.0 and GameRules.compute_shot_damage(20, 50, 50, 1.0, 1.0) != 20:
		failures.append("player hit must ignore elemental advantage")
	var even := GameRules.resolve_shot_masses(1.0, 0, 1.0, 0)
	if not is_equal_approx(float(even.a), 0.0) or not is_equal_approx(float(even.b), 0.0):
		failures.append("equal same-element shots should annihilate")
	var heavier := GameRules.resolve_shot_masses(5.0, 0, 3.0, 0)
	if not is_equal_approx(float(heavier.a), 2.0) or not is_equal_approx(float(heavier.b), 0.0):
		failures.append("5 vs 3 same element should leave 2")
	# Agua 3 vs Fuego 4: agua ×2 → 6-4=2, revert /2 → 1
	var wet := GameRules.resolve_shot_masses(3.0, 1, 4.0, 0)
	if not is_equal_approx(float(wet.a), 1.0) or not is_equal_approx(float(wet.b), 0.0):
		failures.append("agua 3 vs fuego 4 should leave agua 1, got %s/%s" % [wet.a, wet.b])
	if GameRules.dominant_element({0: 40, 1: 20, 2: 20, 3: 20}) != 0:
		failures.append("dominant element should be fuego")
	if GameRules.max_health_from_bonus(10) != 110:
		failures.append("hp with +10 bonus should be 110")
	var created = Progression.create_pelotita("shot_probe")
	if created.learned_skills.size() != 1:
		failures.append("new pelotita should auto-learn 1 dominant shot")
	if created.learned_skills[0] != GameRules.basic_shot_id(int(created.dominant_element)):
		failures.append("learned shot should match dominant element")
