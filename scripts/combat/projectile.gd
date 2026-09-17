extends Area2D
class_name Projectile
## Pelotita de habilidad: masa, daño D, cancelación vs tiros rivales.

@export var speed: float = 420.0
@export var lifetime: float = 5.0
@export var pierce: bool = false

var direction: Vector2 = Vector2.RIGHT
var owner_id: int = -1
var owner_ataque: int = 50
var traveled_time: float = 0.0
var shot_element: int = 0
var steer_frac: float = 0.0
var shot_damage: int = 20
var masa: float = 1.0
var masa_inicial: float = 1.0

var source_ability: UsableAbility = null
var source_player = null  # Player type - untyped to avoid circular dependency


func _ready() -> void:
	add_to_group("projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_sync_mass_visual()


func _physics_process(delta: float) -> void:
	if steer_frac > 0.0:
		_steer_toward_enemy(delta)
	position += direction * speed * delta
	traveled_time += delta
	if traveled_time >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is StaticBody2D:
		queue_free()
		return
	if body is Player and body != source_player:
		if Net.is_networked() and body.get_multiplayer_authority() == owner_id:
			return
		if Net.is_networked() and not Net.has_authority(self):
			if not pierce:
				queue_free()
			return
		var shot_v := direction * speed
		var n := body.global_position - global_position
		var deltas := GameRules.elastic_deltas(body.velocity, body.masa, shot_v, masa, n)
		var impact: Vector2 = deltas.a
		var final_damage = GameRules.compute_shot_damage(
			shot_damage, owner_ataque, body.defensa, masa, masa_inicial
		)
		body.take_damage(final_damage, owner_id, impact)
		if source_ability and source_player:
			source_ability.on_hit_enemy(source_player, body, self)
		if not pierce:
			queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Projectile:
		return
	var other: Projectile = area
	if _same_side(other):
		return
	if is_queued_for_deletion() or other.is_queued_for_deletion():
		return
	if get_instance_id() > other.get_instance_id():
		return
	var result := GameRules.resolve_shot_masses(masa, shot_element, other.masa, other.shot_element)
	masa = float(result.a)
	other.masa = float(result.b)
	_sync_mass_visual()
	other._sync_mass_visual()
	if masa <= 0.01:
		queue_free()
	if other.masa <= 0.01:
		other.queue_free()


func initialize(spawn_pos: Vector2, spawn_dir: Vector2, owner_peer_id: int, ataque_stat: int = 50, ability: UsableAbility = null, player = null, element: int = 0, d: int = 20, masa_stat: float = 1.0, speed_px: float = 0.0) -> void:
	position = spawn_pos
	direction = spawn_dir.normalized()
	owner_id = owner_peer_id
	owner_ataque = ataque_stat
	source_ability = ability
	source_player = player
	shot_element = element
	shot_damage = d
	masa = masa_stat
	masa_inicial = masa_stat
	steer_frac = GameRules.shot_steer_frac(element)
	speed = speed_px if speed_px > 0.0 else GameRules.shot_speed_px(GameRules.PIXELS_PER_METER, element)
	lifetime = GameRules.SHOT_LIFETIME
	_sync_mass_visual()


func _same_side(other: Projectile) -> bool:
	if source_player != null and other.source_player != null:
		return source_player == other.source_player
	return owner_id == other.owner_id


func _sync_mass_visual() -> void:
	var factor := sqrt(maxf(masa, 0.0) / maxf(masa_inicial, 0.01))
	scale = Vector2.ONE * maxf(factor, 0.15)


func _steer_toward_enemy(delta: float) -> void:
	var target := _nearest_enemy()
	if target == null:
		return
	var vel := direction * speed
	vel = GameRules.steer_shot_velocity(vel, target.global_position - global_position, delta, steer_frac)
	speed = vel.length()
	if speed > 0.001:
		direction = vel / speed


func _nearest_enemy() -> Player:
	var best: Player = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group("players"):
		if not node is Player:
			continue
		var p: Player = node
		if _is_owner_player(p):
			continue
		var d := global_position.distance_squared_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _is_owner_player(p: Player) -> bool:
	if source_player != null:
		return p == source_player
	return p.get_multiplayer_authority() == owner_id
