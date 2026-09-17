extends Node
## Unique source of locked combat/progression formulas.
## Keep numbers here so modes, players and tests cannot drift.

const PIXELS_PER_METER: float = 200.0
const PLAYER_COLLISION_RADIUS: float = 20.0
const PROJECTILE_SPAWN_OFFSET: float = 32.0
## Seconds from 0 to vmax with stick/WASD held (accel = vmax / this).
const ACCEL_TIME_TO_MAX: float = 1.5
## Seconds to lose one vmax of extra speed after collision/ability (not stick).
const OVERSPEED_SLOWDOWN_TIME: float = 1.5

const WALL_DAMAGE_THRESHOLD: float = 100.0
## Was 0.02; +50% so wall hits hurt enough to matter at duel speeds.
const WALL_DAMAGE_MULTIPLIER: float = 0.03

const SHOT_LIFETIME: float = 3.0
const SHOT_DAMAGE_BASE: int = 20
const SHOT_DAMAGE_FUEGO: int = 30
const SHOT_MASA_BASE: float = 1.0
const SHOT_MASA_TIERRA: float = 1.5
const SHOT_SPEED_MULT: float = 1.5
const SHOT_SPEED_MULT_VIENTO: float = 2.25
const SHOT_STEER_FRAC_AGUA: float = 0.1
## Agua>Fuego>Tierra>Aire>Agua: masa × esto solo para la cuenta, después se revierte.
const ELEMENT_ADVANTAGE_MULT: float = 2.0
const HP_BASE: int = 100
const HP_PER_LEVEL: int = 10
const ELASTIC_RESTITUTION: float = 1.0
const ELASTIC_MIN_IMPULSE: float = 50.0

const LEVEL_CAP_TIER_1: int = 10
const XP_LOSS: int = 0
const BASE_WIN_XP: int = 25
const WIN_XP_PER_LEVEL_DIFF: int = 5
const WIN_XP_MAX: int = 65
const WIN_XP_MIN: int = 5

const CREATE_STAT_BASE: int = 50
const CREATE_STAT_BONUS: int = 10
const LEVELUP_STAT_POINTS: int = 10
const LEVELUP_HP: int = 10
const LEVELUP_MASA: float = 0.2
const DEFAULT_MASA: float = 1.0

const SHRINK_INTERVAL: float = 30.0
const SHRINK_AREA_STEP: float = 0.10
const SHRINK_MAX_STEPS: int = 5
const WALL_DAMAGE_STEP: float = 0.20

const VIEWPORT_SIZE := Vector2(1920, 1080)
## Playable field vs 1920x1080 viewport (0.75 = 25% smaller, centered).
const ARENA_SCALE: float = 0.75
const WALL_THICKNESS: float = 20.0
const DEFAULT_LAN_PORT: int = 7777


static func acceleration_for(max_speed: float) -> float:
	return max_speed / ACCEL_TIME_TO_MAX


static func overspeed_decel(max_speed: float) -> float:
	return max_speed / OVERSPEED_SLOWDOWN_TIME


## |a_friction| = 2 * a_pad * max(0, (v - vmax) / vmax), opposite current velocity.
static func speed_friction(speed: float, max_speed: float, pad_accel: float) -> float:
	if max_speed <= 0.001:
		return 0.0
	return 2.0 * pad_accel * maxf(0.0, (speed - max_speed) / max_speed)


## a = a_pad (fixed mag, pad dir) + a_friction.
## Split a into parallel/perp to v. If |v| > vmax and a_parallel > 0, a_parallel *= 0.
static func compose_drive_accel(current_velocity: Vector2, pad_dir: Vector2, max_speed: float, pad_accel: float) -> Vector2:
	var a_pad := Vector2.ZERO
	if pad_dir.length_squared() > 0.0001 and pad_accel > 0.0:
		a_pad = pad_dir.normalized() * pad_accel
	var speed := current_velocity.length()
	var a_friction := Vector2.ZERO
	if speed > 0.001:
		a_friction = -(current_velocity / speed) * speed_friction(speed, max_speed, pad_accel)
	var a_total := a_pad + a_friction
	if speed <= 0.001:
		return a_total
	return clamp_accel_for_speed(a_total, current_velocity, max_speed)


## If already faster than vmax, drop the parallel component when it would speed you up.
static func clamp_accel_for_speed(a_net: Vector2, current_velocity: Vector2, max_speed: float) -> Vector2:
	var speed := current_velocity.length()
	if speed <= max_speed or speed <= 0.001:
		return a_net
	var v_hat := current_velocity / speed
	var along := a_net.dot(v_hat)
	if along > 0.0:
		return a_net - v_hat * along
	return a_net


static func combat_stats_from(data: Dictionary) -> Dictionary:
	var level := int(data.get("level", 1))
	return {
		"ataque": int(data.get("ataque", CREATE_STAT_BASE)),
		"defensa": int(data.get("defensa", CREATE_STAT_BASE)),
		"velocidad": float(data.get("velocidad", CREATE_STAT_BASE)),
		"masa": float(data.get("masa", DEFAULT_MASA)),
		"bonus_hp": int(data.get("bonus_hp", HP_PER_LEVEL * maxi(level, 1))),
		"level": level,
	}


static func speed_m_s_from_stat(velocidad: float, geometric_mean: float) -> float:
	return maxf(velocidad, 0.01) / maxf(geometric_mean, 0.01)


static func compute_combat_damage(ataque: int, defensa: int) -> int:
	return maxi(1, int(round(float(ataque) - float(defensa) * 0.5)))


## Daño al pegarle a un jugador: max(1, round(D * ATK / DEF * m / M)).
## Sin debilidad elemental: eso solo aplica cuando dos pelotitas de habilidad chocan.
static func compute_shot_damage(d: int, ataque: int, defensa: int, masa: float, masa_inicial: float) -> int:
	var def := maxi(defensa, 1)
	var M := maxf(masa_inicial, 0.01)
	return maxi(1, int(round(float(d) * float(ataque) / float(def) * masa / M)))


static func shot_mass_advantage(attacker_el: int, defender_el: int) -> float:
	if attacker_el == 1 and defender_el == 0:
		return ELEMENT_ADVANTAGE_MULT
	if attacker_el == 0 and defender_el == 2:
		return ELEMENT_ADVANTAGE_MULT
	if attacker_el == 2 and defender_el == 3:
		return ELEMENT_ADVANTAGE_MULT
	if attacker_el == 3 and defender_el == 1:
		return ELEMENT_ADVANTAGE_MULT
	return 1.0


static func effective_shot_mass(masa: float, attacker_el: int, defender_el: int) -> float:
	return masa * shot_mass_advantage(attacker_el, defender_el)


static func revert_shot_mass(effective_masa: float, attacker_el: int, defender_el: int) -> float:
	return effective_masa / shot_mass_advantage(attacker_el, defender_el)


## Resta masas (con ventaja elemental momentánea). 0 = esa pelotita desaparece.
static func resolve_shot_masses(masa_a: float, el_a: int, masa_b: float, el_b: int) -> Dictionary:
	var ea := effective_shot_mass(masa_a, el_a, el_b)
	var eb := effective_shot_mass(masa_b, el_b, el_a)
	if absf(ea - eb) <= 0.0001:
		return {"a": 0.0, "b": 0.0}
	if ea > eb:
		return {"a": revert_shot_mass(ea - eb, el_a, el_b), "b": 0.0}
	return {"a": 0.0, "b": revert_shot_mass(eb - ea, el_b, el_a)}


static func max_health_for_level(level: int) -> int:
	return HP_BASE + HP_PER_LEVEL * maxi(level, 1)


static func max_health_from_bonus(bonus_hp: int) -> int:
	return HP_BASE + maxi(bonus_hp, 0)


## +10 HP o +0.2 masa. 10 rolls (create + 9 levels) → doble HP o triple masa.
static func apply_vitality_roll(data: Dictionary) -> String:
	if randi() % 2 == 0:
		data["bonus_hp"] = int(data.get("bonus_hp", 0)) + LEVELUP_HP
		return "hp"
	data["masa"] = float(data.get("masa", DEFAULT_MASA)) + LEVELUP_MASA
	return "masa"


static func shrink_steps_for_time(elapsed: float) -> int:
	if elapsed < SHRINK_INTERVAL:
		return 0
	return mini(int(elapsed / SHRINK_INTERVAL), SHRINK_MAX_STEPS)


static func arena_area_frac(steps: int) -> float:
	return 1.0 - SHRINK_AREA_STEP * float(clampi(steps, 0, SHRINK_MAX_STEPS))


static func arena_linear_scale(steps: int) -> float:
	return sqrt(arena_area_frac(steps))


static func wall_damage_scale(steps: int) -> float:
	return 1.0 + WALL_DAMAGE_STEP * float(clampi(steps, 0, SHRINK_MAX_STEPS))


static func shot_damage_for(element: int) -> int:
	return SHOT_DAMAGE_FUEGO if element == 0 else SHOT_DAMAGE_BASE


static func shot_masa_for(element: int) -> float:
	return SHOT_MASA_TIERRA if element == 2 else SHOT_MASA_BASE


static func shot_speed_mult(element: int) -> float:
	return SHOT_SPEED_MULT_VIENTO if element == 3 else SHOT_SPEED_MULT


static func shot_speed_px(player_vmax_px: float, element: int) -> float:
	return maxf(player_vmax_px, 0.01) * shot_speed_mult(element)


static func shot_steer_frac(element: int) -> float:
	return SHOT_STEER_FRAC_AGUA if element == 1 else 0.0


## Acelera solo en la perpendicular a v, módulo frac*|v|, hacia to_target. Conserva |v|.
static func steer_shot_velocity(velocity: Vector2, to_target: Vector2, delta: float, frac: float) -> Vector2:
	var speed := velocity.length()
	if speed <= 0.001 or frac <= 0.0 or to_target.length_squared() <= 0.0001:
		return velocity
	var v_hat := velocity / speed
	var perp := to_target - v_hat * to_target.dot(v_hat)
	if perp.length_squared() <= 0.0001:
		return velocity
	var steered := velocity + perp.normalized() * (frac * speed) * delta
	var new_speed := steered.length()
	if new_speed <= 0.001:
		return velocity
	return steered * (speed / new_speed)


## n_from_b_to_a apunta de B hacia A. Devuelve {a, b} deltas de velocidad (impulso elástico).
static func elastic_deltas(v_a: Vector2, m_a: float, v_b: Vector2, m_b: float, n_from_b_to_a: Vector2, restitution: float = ELASTIC_RESTITUTION, min_impulse: float = ELASTIC_MIN_IMPULSE) -> Dictionary:
	var n := n_from_b_to_a
	if n.length_squared() < 0.0001:
		return {"a": Vector2.ZERO, "b": Vector2.ZERO}
	n = n.normalized()
	var masa_a := maxf(m_a, 0.01)
	var masa_b := maxf(m_b, 0.01)
	var along := (v_a - v_b).dot(n)
	if along > 0.0:
		return {"a": Vector2.ZERO, "b": Vector2.ZERO}
	var j := -(1.0 + restitution) * along / ((1.0 / masa_a) + (1.0 / masa_b))
	if absf(j) < min_impulse:
		j = signf(j) * min_impulse
	return {"a": n * (j / masa_a), "b": -n * (j / masa_b)}


static func shot_color(element: int) -> Color:
	match element:
		0:
			return Color(1.0, 0.2, 0.0, 1.0)
		1:
			return Color(0.0, 0.4, 1.0, 1.0)
		2:
			return Color(0.6, 0.4, 0.2, 1.0)
		_:
			return Color(0.7, 1.0, 0.7, 1.0)


static func shot_name(element: int) -> String:
	return ["Disparo de Fuego", "Disparo de Agua", "Disparo de Tierra", "Disparo de Viento"][clampi(element, 0, 3)]


static func shot_blurb(element: int) -> String:
	return [
		"D 30. Masa ×2 vs Tierra.",
		"Curva suave hacia el rival. Masa ×2 vs Fuego.",
		"Masa 1.5. Masa ×2 vs Aire.",
		"2.25× vmax. Masa ×2 vs Agua.",
	][clampi(element, 0, 3)]


static func basic_shot_id(element: int) -> String:
	return ["disparo_fuego_basico", "disparo_agua_basico", "disparo_tierra_basico", "disparo_viento_basico"][clampi(element, 0, 3)]


static func basic_shot_path(element: int) -> String:
	return [
		"res://resources/abilities/disparo_fuego.tres",
		"res://resources/abilities/disparo_agua.tres",
		"res://resources/abilities/disparo_tierra.tres",
		"res://resources/abilities/disparo_viento.tres",
	][clampi(element, 0, 3)]


static func element_label(element: int) -> String:
	return ["Fuego", "Agua", "Tierra", "Aire"][clampi(element, 0, 3)]


static func dominant_element(weights: Dictionary) -> int:
	var best_w := -1
	var tied: Array[int] = []
	for el in range(4):
		var w := int(weights.get(el, weights.get(str(el), 0)))
		if w > best_w:
			best_w = w
			tied = [el]
		elif w == best_w:
			tied.append(el)
	if tied.is_empty():
		return 0
	return tied[randi() % tied.size()]


static func compute_wall_damage(impact_speed: float, masa: float, shrink_steps: int = 0) -> int:
	if impact_speed <= WALL_DAMAGE_THRESHOLD:
		return 0
	var raw: float = (impact_speed - WALL_DAMAGE_THRESHOLD) * WALL_DAMAGE_MULTIPLIER * masa * wall_damage_scale(shrink_steps)
	return maxi(0, int(ceil(raw)))


static func xp_required_for_level(level: int) -> int:
	if level <= 1:
		return int(round(100.0 * pow(1.5, 0.0)))
	return int(round(100.0 * pow(1.5, float(level - 1))))


static func calculate_win_xp(your_level: int, opponent_level: int) -> int:
	var diff := opponent_level - your_level
	if diff >= 0:
		return mini(BASE_WIN_XP + WIN_XP_PER_LEVEL_DIFF * diff, WIN_XP_MAX)
	return maxi(WIN_XP_MIN, BASE_WIN_XP + WIN_XP_PER_LEVEL_DIFF * diff)


static func geometric_mean(values: Array[float]) -> float:
	if values.is_empty():
		return 1.0
	var product := 1.0
	for v in values:
		product *= maxf(v, 0.01)
	return pow(product, 1.0 / float(values.size()))


static func distribute_points(total: int, buckets: int = 3) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(buckets)
	var remaining := total
	for i in range(buckets - 1):
		var take := randi_range(0, remaining)
		result[i] = take
		remaining -= take
	result[buckets - 1] = remaining
	return result


static func roll_affinity_weights() -> Dictionary:
	var weights: Array[int] = [1, 1, 1, 1]
	var remaining := 96
	var order: Array[int] = [0, 1, 2, 3]
	order.shuffle()
	for i in range(3):
		var take := randi_range(0, remaining)
		weights[order[i]] += take
		remaining -= take
	weights[order[3]] += remaining
	return {
		0: weights[0],
		1: weights[1],
		2: weights[2],
		3: weights[3],
	}


static func arena_size() -> Vector2:
	return VIEWPORT_SIZE * ARENA_SCALE


static func arena_size_at(steps: int) -> Vector2:
	return arena_size() * arena_linear_scale(steps)


static func arena_origin() -> Vector2:
	return (VIEWPORT_SIZE - arena_size()) * 0.5


static func arena_origin_at(steps: int) -> Vector2:
	return (VIEWPORT_SIZE - arena_size_at(steps)) * 0.5


static func arena_center() -> Vector2:
	return arena_origin() + arena_size() * 0.5


static func arena_rect() -> Rect2:
	return Rect2(arena_origin(), arena_size())


static func arena_rect_at(steps: int) -> Rect2:
	return Rect2(arena_origin_at(steps), arena_size_at(steps))


static func duel_spawn_positions() -> Array[Vector2]:
	var origin := arena_origin()
	var size := arena_size()
	var inset_x := size.x * (300.0 / 1920.0)
	var center_y := origin.y + size.y * 0.5
	return [
		Vector2(origin.x + inset_x, center_y),
		Vector2(origin.x + size.x - inset_x, center_y),
	]
