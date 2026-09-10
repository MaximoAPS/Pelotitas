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

const BASE_MOVE_SPEED: float = 200.0

var current_health: int = 100
var pelotita_id: String = ""
var loadout: Loadout = null


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
	move_and_slide()


func _handle_input() -> void:
	# Movimiento: prioritizar touch input, fallback a teclado para testing en desktop
	var input_dir = TouchInput.get_move_direction()
	
	if input_dir == Vector2.ZERO:
		# Fallback para testing en desktop
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Velocidad de movimiento: BASE_MOVE_SPEED × stat de velocidad
	# velocidad = 1.0 → 200 px/s (baseline)
	# velocidad = 2.0 → 400 px/s (doble)
	# velocidad = 0.5 → 100 px/s (mitad)
	var move_speed = BASE_MOVE_SPEED * velocidad
	velocity = input_dir * move_speed
	
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
