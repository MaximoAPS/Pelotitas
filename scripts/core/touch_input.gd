extends Node
## Autoload para manejo de controles táctiles
##
## Responsabilidades:
## - Detectar gestos táctiles (toques, arrastres)
## - Proveer joystick virtual para movimiento
## - Gestionar habilidades con press-hold-drag-release para apuntar
## - Emitir señales para que el jugador responda
##
## Sistema de apuntado de habilidades:
## 1. Press y hold en botón de habilidad
## 2. Drag en la dirección deseada (genera aim_direction)
## 3. Release para disparar/activar en esa dirección

signal ability_aim_started(slot: int)
signal ability_aim_updated(slot: int, aim_direction: Vector2)
signal ability_fired(slot: int, aim_direction: Vector2)
signal ability_cancelled(slot: int)
signal move_direction_changed(direction: Vector2)

var virtual_joystick_active: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var joystick_current: Vector2 = Vector2.ZERO
var joystick_touch_index: int = -1

const JOYSTICK_DEADZONE: float = 0.2
const JOYSTICK_MAX_RADIUS: float = 120.0

## Dirección actual del joystick virtual (normalizada)
var move_direction: Vector2 = Vector2.ZERO

## Sistema de apuntado de habilidades
var ability_aiming: bool = false
var ability_slot_aiming: int = -1
var ability_aim_start_pos: Vector2 = Vector2.ZERO
var ability_aim_current_pos: Vector2 = Vector2.ZERO
var ability_touch_index: int = -1

const ABILITY_AIM_MIN_DISTANCE: float = 30.0  # Distancia mínima para considerar dirección válida


func _ready() -> void:
	print("[TouchInput] Autoload inicializado")


## Llamar desde el nodo de UI del joystick virtual
func start_virtual_joystick(touch_position: Vector2, touch_index: int) -> void:
	virtual_joystick_active = true
	joystick_center = touch_position
	joystick_current = touch_position
	joystick_touch_index = touch_index
	_update_move_direction()


## Actualiza la posición del joystick mientras se arrastra
func update_virtual_joystick(touch_position: Vector2) -> void:
	if not virtual_joystick_active:
		return
	
	joystick_current = touch_position
	_update_move_direction()


## Finaliza el joystick virtual
func end_virtual_joystick() -> void:
	virtual_joystick_active = false
	joystick_touch_index = -1
	move_direction = Vector2.ZERO
	move_direction_changed.emit(Vector2.ZERO)


func _update_move_direction() -> void:
	var offset = joystick_current - joystick_center
	var distance = offset.length()
	
	# Limitar distancia máxima
	if distance > JOYSTICK_MAX_RADIUS:
		offset = offset.normalized() * JOYSTICK_MAX_RADIUS
		distance = JOYSTICK_MAX_RADIUS
	
	# Aplicar deadzone
	if distance < JOYSTICK_DEADZONE * JOYSTICK_MAX_RADIUS:
		move_direction = Vector2.ZERO
	else:
		move_direction = offset.normalized()
	
	move_direction_changed.emit(move_direction)


## Inicia el proceso de apuntado de habilidad (press)
func start_ability_aim(slot: int, touch_position: Vector2, touch_index: int) -> void:
	if slot < 0 or slot > 2:
		return
	
	ability_aiming = true
	ability_slot_aiming = slot
	ability_aim_start_pos = touch_position
	ability_aim_current_pos = touch_position
	ability_touch_index = touch_index
	
	ability_aim_started.emit(slot)


## Actualiza la dirección de apuntado mientras se arrastra (drag)
func update_ability_aim(touch_position: Vector2) -> void:
	if not ability_aiming:
		return
	
	ability_aim_current_pos = touch_position
	var aim_vector = ability_aim_current_pos - ability_aim_start_pos
	
	# Solo emitir dirección si el arrastre es significativo
	if aim_vector.length() >= ABILITY_AIM_MIN_DISTANCE:
		var aim_direction = aim_vector.normalized()
		ability_aim_updated.emit(ability_slot_aiming, aim_direction)


## Dispara la habilidad en la dirección apuntada (release)
func fire_ability() -> void:
	if not ability_aiming:
		return
	
	var aim_vector = ability_aim_current_pos - ability_aim_start_pos
	var aim_direction = Vector2.RIGHT  # Dirección por defecto
	
	# Si hay arrastre significativo, usar esa dirección
	if aim_vector.length() >= ABILITY_AIM_MIN_DISTANCE:
		aim_direction = aim_vector.normalized()
	
	var slot = ability_slot_aiming
	_reset_ability_aim()
	
	ability_fired.emit(slot, aim_direction)


## Cancela el apuntado de habilidad (si el toque se pierde)
func cancel_ability_aim() -> void:
	if not ability_aiming:
		return
	
	var slot = ability_slot_aiming
	_reset_ability_aim()
	ability_cancelled.emit(slot)


func _reset_ability_aim() -> void:
	ability_aiming = false
	ability_slot_aiming = -1
	ability_touch_index = -1


## Helper: obtiene la dirección de movimiento actual
func get_move_direction() -> Vector2:
	return move_direction


## Helper: obtiene el offset del joystick para renderizar UI
func get_joystick_offset() -> Vector2:
	if not virtual_joystick_active:
		return Vector2.ZERO
	
	return joystick_current - joystick_center


## Helper: offset crudo del arrastre (para el hint visual)
func get_ability_aim_offset() -> Vector2:
	if not ability_aiming:
		return Vector2.ZERO
	return ability_aim_current_pos - ability_aim_start_pos


## Helper: obtiene la dirección de apuntado actual de habilidad
func get_ability_aim_direction() -> Vector2:
	if not ability_aiming:
		return Vector2.ZERO
	
	var aim_vector = ability_aim_current_pos - ability_aim_start_pos
	if aim_vector.length() >= ABILITY_AIM_MIN_DISTANCE:
		return aim_vector.normalized()
	
	return Vector2.ZERO


## Helper: verifica si está apuntando una habilidad
func is_aiming_ability() -> bool:
	return ability_aiming
