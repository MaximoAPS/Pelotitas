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

## Constante de escala de arena (metros virtuales → píxeles)
const PIXELS_PER_METER: float = 200.0

## Velocidad normalizada en metros/segundo (calculada al iniciar match)
var speed_m_s: float = 1.0

var current_health: int = 100
var pelotita_id: String = ""
var loadout: Loadout = null

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
	if not Net.has_authority(self):
		return  # Solo el owner controla movimiento
	
	_handle_input()
	
	var previous_velocity = velocity
	var collision = move_and_slide()
	
	# Detectar colisiones con paredes (StaticBody2D)
	_handle_wall_collisions(previous_velocity)
	
	# Detectar colisiones con otros jugadores (CharacterBody2D)
	_handle_player_collisions()


func _handle_input() -> void:
	# Movimiento: prioritizar touch input, fallback a teclado para testing en desktop
	var input_dir = TouchInput.get_move_direction()
	
	if input_dir == Vector2.ZERO:
		# Fallback para testing en desktop
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Velocidad de movimiento: velocidad relativa (m/s) × escala de píxeles
	# speed_m_s ya está normalizado por media geométrica de participantes
	var move_speed_px_s = speed_m_s * PIXELS_PER_METER
	velocity = input_dir * move_speed_px_s
	
	# Habilidades: manejadas por señales de TouchInput o teclas de debug
	if Input.is_action_just_pressed("ability_1") and loadout:
		loadout.use_ability(0)
	if Input.is_action_just_pressed("ability_2") and loadout:
		loadout.use_ability(1)
	if Input.is_action_just_pressed("ability_3") and loadout:
		loadout.use_ability(2)


func take_damage(amount: int, attacker_id: int = -1, knockback_direction: Vector2 = Vector2.ZERO, knockback_strength: float = 0.0) -> void:
	if not Net.has_authority(self):
		return  # Solo el servidor/authority aplica daño
	
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
	# TODO: Notificar al modo de juego
	# TODO: Desactivar controles, reproducir animación de muerte


func set_loadout(new_loadout: Loadout) -> void:
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
## Aplica daño basado en velocidad de impacto
func _handle_wall_collisions(previous_velocity: Vector2) -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Solo procesar colisiones con paredes (StaticBody2D)
		if collider is StaticBody2D:
			# Calcular velocidad de impacto (componente normal a la pared)
			var normal = collision.get_normal()
			var impact_speed = abs(previous_velocity.dot(-normal))
			
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
## Usa conservación de momento y energía (colisión perfectamente elástica)
func _apply_elastic_collision(other: Player, collision: KinematicCollision2D) -> void:
	if not Net.has_authority(self):
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
	
	# Coeficiente de restitución (1.0 = perfectamente elástico)
	var restitution = 1.0
	
	# Calcular impulso escalar
	var impulse_scalar = -(1.0 + restitution) * vel_along_normal
	impulse_scalar /= (1.0 / masa) + (1.0 / other.masa)
	
	# Aplicar impulso a velocidades
	var impulse = normal * impulse_scalar
	velocity += impulse / masa
	
	# Si tenemos autoridad sobre el otro jugador también, aplicar su impulso
	if Net.has_authority(other):
		other.velocity -= impulse / other.masa
