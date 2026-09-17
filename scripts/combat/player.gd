extends CharacterBody2D
class_name Player
## Controlador de jugador/pelotita en duelo
##
## Responsabilidades:
## - Movimiento top-down
## - Vida y daño
## - Usar habilidades del loadout
## - Sincronización de red

signal health_changed(new_health: int, max_health: int)
signal died()

@export var max_health: int = 100

@export_group("Stats")
@export var ataque: int = 50
@export var defensa: int = 50
@export var velocidad: float = 50.0
@export var masa: float = 1.0

@export_group("Movement Tuning")
@export var aceleracion: float = 0.0  # 0 = vmax / GameRules.ACCEL_TIME_TO_MAX
@export var friccion: float = 0.0
@export var rebote_jugador: float = 1.0
@export var rebote_min_impulse: float = 50.0

var speed_m_s: float = 1.0
var current_health: int = 100:
	set(value):
		if current_health == value:
			return
		var was_alive := current_health > 0
		current_health = value
		health_changed.emit(current_health, max_health)
		if was_alive and current_health <= 0:
			_die()
var pelotita_id: String = ""
var player_index: int = 0
var elemento: int = 0
var loadout = null  # Loadout type - untyped to avoid circular dependency
var last_wall_collision_speed: float = 0.0
var _rmb_held: bool = false
var pre_slide_velocity: Vector2 = Vector2.ZERO
var _pre_slide_frame: int = -1
var _aim_hint: Line2D


func _ready() -> void:
	add_to_group("players")
	current_health = max_health
	TouchInput.ability_fired.connect(_on_ability_fired)
	if has_node("HealthBar"):
		health_changed.connect(_on_own_health_bar)
	_aim_hint = Line2D.new()
	_aim_hint.width = 5.0
	_aim_hint.default_color = Color(1.0, 0.92, 0.35, 0.9)
	_aim_hint.z_index = 8
	_aim_hint.visible = false
	add_child(_aim_hint)


func _acceleration(max_speed: float) -> float:
	if aceleracion > 0.0:
		return aceleracion
	return GameRules.acceleration_for(max_speed)


func _max_speed_px() -> float:
	return speed_m_s * GameRules.PIXELS_PER_METER


## Pad + friction. Parallel accel cannot be positive while faster than vmax.
func _apply_drive(input_dir: Vector2, delta: float) -> void:
	var max_speed := _max_speed_px()
	var effective_accel := _acceleration(max_speed)
	var had_input := input_dir.length() > 0.01
	var dir := input_dir.normalized() if had_input else Vector2.ZERO
	var a_net := GameRules.compose_drive_accel(velocity, dir, max_speed, effective_accel)
	velocity += a_net * delta


func get_combat_id() -> int:
	if Net.is_networked():
		return get_multiplayer_authority()
	return player_index


func _is_dummy() -> bool:
	return has_meta("is_dummy") and get_meta("is_dummy")


func _on_own_health_bar(current: int, maximum: int) -> void:
	var bar = get_node_or_null("HealthBar")
	if bar:
		bar.max_value = maximum
		bar.value = current


func _process(_delta: float) -> void:
	if _aim_hint == null:
		return
	if _is_dummy() or (Net.is_networked() and not Net.has_authority(self)):
		_aim_hint.visible = false
		return
	if not TouchInput.is_aiming_ability():
		_aim_hint.visible = false
		return
	var offset := TouchInput.get_ability_aim_offset()
	if offset.length() < 8.0:
		_aim_hint.visible = false
		return
	var dir := offset.normalized()
	_aim_hint.visible = true
	_aim_hint.points = PackedVector2Array([dir * 28.0, dir * 78.0])


func _physics_process(delta: float) -> void:
	var is_dummy = _is_dummy()
	if not is_dummy and Net.is_networked() and not Net.has_authority(self):
		return
	if not is_dummy:
		_handle_input(delta)
	else:
		_handle_dummy_ai(delta)
	pre_slide_velocity = velocity
	_pre_slide_frame = Engine.get_physics_frames()
	move_and_slide()
	_handle_wall_collisions(pre_slide_velocity)
	_handle_player_collisions()


func _handle_input(delta: float) -> void:
	# Movimiento: prioritizar touch input, fallback a teclado para testing en desktop
	var input_dir = TouchInput.get_move_direction()
	
	if input_dir == Vector2.ZERO:
		# Fallback para testing en desktop
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not TouchInput.virtual_joystick_active and not TouchInput.ability_aiming:
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		if mouse_dir.length() > 0.1:
			input_dir = mouse_dir
	
	_apply_drive(input_dir, delta)
	# Habilidades: manejadas por señales de TouchInput o teclas de debug
	# RMB or keys 1-2-3 fire toward mouse
	var fire_dir = (get_global_mouse_position() - global_position).normalized()
	var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if loadout:
		if Input.is_action_just_pressed("ability_1") or (rmb and not _rmb_held):
			loadout.use_ability(0, fire_dir)
		if Input.is_action_just_pressed("ability_2"):
			loadout.use_ability(1, fire_dir)
		if Input.is_action_just_pressed("ability_3"):
			loadout.use_ability(2, fire_dir)
	_rmb_held = rmb


func _handle_dummy_ai(delta: float) -> void:
	var ARENA_CENTER = GameRules.arena_center()
	const CENTER_RADIUS = 80.0  # Distance threshold to consider "at center"
	
	# Calculate direction to center
	var to_center = ARENA_CENTER - global_position
	var distance_to_center = to_center.length()
	
	var seek_dir := Vector2.ZERO
	if distance_to_center > CENTER_RADIUS:
		seek_dir = to_center.normalized()
	_apply_drive(seek_dir, delta)


func take_damage(amount: int, attacker_id: int = -1, impact: Vector2 = Vector2.ZERO) -> void:
	var is_dummy = _is_dummy()
	if not is_dummy and Net.is_networked() and not Net.has_authority(self):
		rpc_take_damage.rpc_id(get_multiplayer_authority(), amount, attacker_id, impact)
		return
	current_health = max(0, current_health - amount)
	print("[Player] %s recibió %d de daño, vida: %d/%d" % [pelotita_id, amount, current_health, max_health])
	if impact.length_squared() > 0.0001:
		velocity += impact


@rpc("any_peer", "reliable")
func rpc_take_damage(amount: int, attacker_id: int, impact: Vector2) -> void:
	take_damage(amount, attacker_id, impact)


func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)


func _die() -> void:
	print("[Player] %s murió" % pelotita_id)
	died.emit()
	# Modo de juego maneja la muerte via signal conectado en register_player
	# TODO: Desactivar controles, reproducir animación de muerte


func set_loadout(new_loadout) -> void:  # Loadout type
	loadout = new_loadout
	if loadout:
		loadout.owner_player = self


func _on_ability_fired(slot: int, aim_direction: Vector2) -> void:
	if _is_dummy():
		return
	if Net.is_networked() and not Net.has_authority(self):
		return
	if loadout:
		loadout.use_ability(slot, aim_direction)


## Calcula y asigna la velocidad normalizada basada en media geométrica
## G = media geométrica de velocidades de todos los participantes
## speed_m_s = velocidad_stat / G
func set_normalized_speed(geometric_mean: float) -> void:
	if geometric_mean <= 0.0:
		push_error("[Player] Media geométrica inválida: %f" % geometric_mean)
		geometric_mean = 1.0
	
	speed_m_s = GameRules.speed_m_s_from_stat(velocidad, geometric_mean)
	
	var move_speed_px_s = speed_m_s * GameRules.PIXELS_PER_METER
	print("[Player] %s: velocidad_stat=%.2f, G=%.2f → speed=%.2f m/s (%.1f px/s)" % [
		pelotita_id, velocidad, geometric_mean, speed_m_s, move_speed_px_s
	])


## Maneja colisiones con paredes (StaticBody2D)
## Aplica daño basado en velocidad de impacto y rebote
func _handle_wall_collisions(previous_velocity: Vector2) -> void:
	var incoming := previous_velocity
	var did_bounce := false
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Solo procesar colisiones con paredes (StaticBody2D)
		if collider is StaticBody2D:
			# Calcular velocidad de impacto (componente normal a la pared)
			var normal = collision.get_normal()
			var along := incoming.dot(normal)
			var approaching := along < -0.01
			var impact_speed := absf(along)
			if approaching:
				var restitution := minf(rebote_jugador, 1.0)
				incoming = incoming - (1.0 + restitution) * along * normal
				did_bounce = true
			if approaching and impact_speed > GameRules.WALL_DAMAGE_THRESHOLD:
				var wall_damage = GameRules.compute_wall_damage(impact_speed, masa, _wall_shrink_steps())
				if wall_damage > 0:
					print("[Player] %s chocó contra pared a %.1f px/s → %d daño" % [pelotita_id, impact_speed, wall_damage])
					take_damage(wall_damage)
			if approaching and loadout:
				loadout.trigger_on_collide_wall(self, collision.get_position(), normal)
	if did_bounce:
		var conserved := previous_velocity.length()
		if incoming.length() > conserved:
			incoming = incoming.normalized() * conserved
		velocity = incoming


func _wall_shrink_steps() -> int:
	if Game.active_mode:
		return Game.active_mode.shrink_steps
	return 0


## Maneja colisiones elásticas con otros jugadores (CharacterBody2D)
## Usa física de esferas rígidas sin deformación
func _handle_player_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Solo procesar colisiones con otros jugadores
		if collider is Player and collider != self:
			_apply_elastic_collision(collider, collision)
			
			# Trigger de colisión con jugador para habilidades
			if loadout:
				loadout.trigger_on_collide_player(self, collider)


## Aplica respuesta de colisión elástica entre dos pelotitas
## Usa conservación de momento y energía con restitución aumentada
@rpc("any_peer", "reliable")
func rpc_apply_impulse(delta_v: Vector2) -> void:
	if Net.is_networked() and not Net.has_authority(self):
		return
	velocity += delta_v


func _apply_elastic_collision(other: Player, collision: KinematicCollision2D) -> void:
	if Net.is_networked() and not Net.has_authority(self):
		return
	if Net.is_offline() and get_instance_id() > other.get_instance_id():
		return
	var separation = (global_position - other.global_position)
	var distance = separation.length()
	if distance < 0.001:
		separation = Vector2.RIGHT
		distance = 1.0
	var normal = separation / distance
	var other_pre: Vector2 = other.pre_slide_velocity
	if other._pre_slide_frame != Engine.get_physics_frames():
		other_pre = other.velocity
	var deltas := GameRules.elastic_deltas(pre_slide_velocity, masa, other_pre, other.masa, normal, rebote_jugador, rebote_min_impulse)
	velocity += deltas.a
	var other_delta: Vector2 = deltas.b
	if Net.is_offline() or Net.has_authority(other):
		other.velocity += other_delta
	else:
		other.rpc_apply_impulse.rpc_id(other.get_multiplayer_authority(), other_delta)
	var min_separation = GameRules.PLAYER_COLLISION_RADIUS * 2.0
	if distance < min_separation:
		var overlap = min_separation - distance
		var separation_offset = normal * overlap * 0.5
		global_position += separation_offset
		if Net.is_offline() or Net.has_authority(other):
			other.global_position -= separation_offset
