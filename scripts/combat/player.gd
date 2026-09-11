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
@export var ataque: int = 10
@export var defensa: int = 5
@export var velocidad: float = 1.0
@export var masa: float = 1.0

@export_group("Movement Tuning")
@export var aceleracion: float = 0.0  # Will be calculated as vmax/4 dynamically
@export var friccion: float = 0.0
@export var rebote_jugador: float = 1.15
@export var rebote_min_impulse: float = 50.0

## Constante de escala de arena (metros virtuales → píxeles)
const PIXELS_PER_METER: float = 200.0

## Velocidad normalizada en metros/segundo (calculada al iniciar match)
var speed_m_s: float = 1.0

var current_health: int = 100
var pelotita_id: String = ""
var loadout = null  # Loadout type - untyped to avoid circular dependency

# Physics collision tracking
var last_wall_collision_speed: float = 0.0
const WALL_DAMAGE_THRESHOLD: float = 100.0  # Mínima velocidad para causar daño
const WALL_DAMAGE_MULTIPLIER: float = 0.02  # Daño por unidad de velocidad


func _ready() -> void:
	current_health = max_health
	
	# Conectar señales de TouchInput (press-hold-drag-release)
	TouchInput.ability_fired.connect(_on_ability_fired)
	
	# TODO: Configurar sincronización de red (MultiplayerSynchronizer)
	# TODO: Aplicar autoridad de red según peer_id


func _physics_process(delta: float) -> void:
	# Dummies no procesan input pero sí física (pueden ser empujados, colisionar con paredes)
	var is_dummy = has_meta("is_dummy") and get_meta("is_dummy")
	
	# Offline mode: allow control without authority if no multiplayer peer
	var offline_mode = multiplayer.multiplayer_peer == null
	
	if not is_dummy and not offline_mode and not Net.has_authority(self):
		return  # Solo el owner controla movimiento (excepto dummies y offline)
	
	# Process input or AI
	if not is_dummy:
		_handle_input(delta)
	else:
		_handle_dummy_ai(delta)
	
	var previous_velocity = velocity
	var collision = move_and_slide()
	
	# Detectar colisiones con paredes (StaticBody2D)
	_handle_wall_collisions(previous_velocity)
	
	# Detectar colisiones con otros jugadores (CharacterBody2D)
	_handle_player_collisions()


func _handle_input(delta: float) -> void:
	# Movimiento: prioritizar touch input, fallback a teclado para testing en desktop
	var input_dir = TouchInput.get_move_direction()
	
	if input_dir == Vector2.ZERO:
		# Fallback para testing en desktop
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# PC controls: WASD/arrows, hold LMB to steer to mouse
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_dir = (get_global_mouse_position() - global_position).normalized()
		if mouse_dir.length() > 0.1:
			input_dir = mouse_dir
	
	# Velocidad máxima: velocidad relativa (m/s) × escala de píxeles
	# speed_m_s ya está normalizado por media geométrica de participantes
	var max_speed = speed_m_s * PIXELS_PER_METER
	
	# Calculate acceleration as vmax/4 (if not set manually)
	var effective_accel = aceleracion if aceleracion > 0.0 else (max_speed / 4.0)
	
	# Inertia-based movement: apply acceleration toward input direction
	if input_dir.length() > 0.01:
		# Apply acceleration toward desired direction
		var desired_velocity = input_dir.normalized() * max_speed
		velocity = velocity.move_toward(desired_velocity, effective_accel * delta)
	else:
		# Apply friction when no input (friction=0 means no deceleration when idle)
		if friccion > 0.0:
			var speed = velocity.length()
			if speed > 0:
				var friction_amount = friccion * delta
				if speed <= friction_amount:
					velocity = Vector2.ZERO
				else:
					velocity -= velocity.normalized() * friction_amount
	
	# Clamp velocity magnitude to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	# Habilidades: manejadas por señales de TouchInput o teclas de debug
	# RMB or keys 1-2-3 fire toward mouse
	var fire_dir = (get_global_mouse_position() - global_position).normalized()
	
	if (Input.is_action_just_pressed("ability_1") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) and loadout:
		loadout.use_ability(0, fire_dir)
	if Input.is_action_just_pressed("ability_2") and loadout:
		loadout.use_ability(1, fire_dir)
	if Input.is_action_just_pressed("ability_3") and loadout:
		loadout.use_ability(2, fire_dir)


func _handle_dummy_ai(delta: float) -> void:
	# Arena center for 1920x1080
	const ARENA_CENTER = Vector2(960, 540)
	const CENTER_RADIUS = 80.0  # Distance threshold to consider "at center"
	
	# Calculate direction to center
	var to_center = ARENA_CENTER - global_position
	var distance_to_center = to_center.length()
	
	# Velocidad máxima: same as player
	var max_speed = speed_m_s * PIXELS_PER_METER
	
	# Calculate acceleration as vmax/4 (if not set manually)
	var effective_accel = aceleracion if aceleracion > 0.0 else (max_speed / 4.0)
	
	if distance_to_center > CENTER_RADIUS:
		# Seek toward center with acceleration
		var seek_dir = to_center.normalized()
		var desired_velocity = seek_dir * max_speed
		velocity = velocity.move_toward(desired_velocity, effective_accel * delta)
	else:
		# Close to center: damp velocity
		if friccion > 0.0:
			var speed = velocity.length()
			if speed > 0:
				var damping_amount = friccion * delta * 1.5  # Slightly stronger damping at center
				if speed <= damping_amount:
					velocity = Vector2.ZERO
				else:
					velocity -= velocity.normalized() * damping_amount
	
	# Clamp velocity magnitude to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed


func take_damage(amount: int, attacker_id: int = -1, knockback_direction: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	# Permitir daño a dummies (para testing local)
	var is_dummy = has_meta("is_dummy") and get_meta("is_dummy")
	
	if not is_dummy and not Net.has_authority(self):
		return  # Solo el servidor/authority aplica daño (excepto dummies)
	
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	print("[Player] %s recibió %d de daño, vida: %d/%d" % [pelotita_id, amount, current_health, max_health])
	
	# Aplicar knockback
	if knockback_direction != Vector2.ZERO and knockback_strength > 0:
		velocity = knockback_direction.normalized() * knockback_strength
	
	if current_health <= 0:
		_die()


func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


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
	if loadout:
		# TODO: Pasar aim_direction a la habilidad para spawning direccional
		loadout.use_ability(slot, aim_direction)


## Calcula y asigna la velocidad normalizada basada en media geométrica
## G = media geométrica de velocidades de todos los participantes
## speed_m_s = velocidad_stat / G
func set_normalized_speed(geometric_mean: float) -> void:
	if geometric_mean <= 0.0:
		push_error("[Player] Media geométrica inválida: %f" % geometric_mean)
		geometric_mean = 1.0
	
	speed_m_s = velocidad / geometric_mean
	
	var move_speed_px_s = speed_m_s * PIXELS_PER_METER
	print("[Player] %s: velocidad_stat=%.2f, G=%.2f → speed=%.2f m/s (%.1f px/s)" % [
		pelotita_id, velocidad, geometric_mean, speed_m_s, move_speed_px_s
	])


## Maneja colisiones con paredes (StaticBody2D)
## Aplica daño basado en velocidad de impacto y rebote
func _handle_wall_collisions(previous_velocity: Vector2) -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Solo procesar colisiones con paredes (StaticBody2D)
		if collider is StaticBody2D:
			# Calcular velocidad de impacto (componente normal a la pared)
			var normal = collision.get_normal()
			var impact_speed = abs(previous_velocity.dot(-normal))
			
			# Bounce velocity with normal
			var velocity_normal = velocity.dot(normal) * normal
			var velocity_tangent = velocity - velocity_normal
			velocity = velocity_tangent - velocity_normal * rebote_jugador
			
			if impact_speed > WALL_DAMAGE_THRESHOLD:
				# Calcular daño basado en velocidad e impacto × masa
				var wall_damage = (impact_speed - WALL_DAMAGE_THRESHOLD) * WALL_DAMAGE_MULTIPLIER * masa
				
				if wall_damage > 0:
					print("[Player] %s chocó contra pared a %.1f px/s → %.1f daño" % [pelotita_id, impact_speed, wall_damage])
					take_damage(int(ceil(wall_damage)))
					
					# Trigger de colisión con pared para habilidades
					if loadout:
						loadout.trigger_on_collide_wall(self, collision.get_position(), normal)


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
func _apply_elastic_collision(other: Player, collision: KinematicCollision2D) -> void:
	# Offline mode: allow collision handling without authority
	var offline_mode = multiplayer.multiplayer_peer == null
	if not offline_mode and not Net.has_authority(self):
		return
	
	# Vector de separación (de other hacia self)
	var separation = (global_position - other.global_position)
	var distance = separation.length()
	
	if distance < 0.001:
		# Evitar división por cero
		separation = Vector2.RIGHT
		distance = 1.0
	
	var normal = separation / distance
	
	# Velocidades relativas
	var v1 = velocity
	var v2 = other.velocity
	var relative_velocity = v1 - v2
	
	# Velocidad relativa a lo largo del normal
	var vel_along_normal = relative_velocity.dot(normal)
	
	# No resolver si ya se están separando
	if vel_along_normal > 0:
		return
	
	# Coeficiente de restitución con boost (rebote_jugador > 1.0)
	var restitution = rebote_jugador
	
	# Calcular impulso escalar
	var impulse_scalar = -(1.0 + restitution) * vel_along_normal
	impulse_scalar /= (1.0 / masa) + (1.0 / other.masa)
	
	# Only apply impulse if above minimum threshold
	if abs(impulse_scalar) < rebote_min_impulse:
		impulse_scalar = sign(impulse_scalar) * rebote_min_impulse
	
	# Aplicar impulso a velocidades
	var impulse = normal * impulse_scalar
	velocity += impulse / masa
	
	# Si tenemos autoridad sobre el otro jugador también, aplicar su impulso
	if offline_mode or Net.has_authority(other):
		other.velocity -= impulse / other.masa
	
	# Anti-overlap separation: push apart if overlapping
	var min_separation = 32.0  # Assumed collision shape radius × 2
	if distance < min_separation:
		var overlap = min_separation - distance
		var separation_offset = normal * overlap * 0.5
		global_position += separation_offset
		if offline_mode or Net.has_authority(other):
			other.global_position -= separation_offset
