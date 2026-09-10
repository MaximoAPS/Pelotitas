extends Node
## Autoload para manejo de controles táctiles
##
## Responsabilidades:
## - Detectar gestos táctiles (toques, arrastres)
## - Proveer joystick virtual para movimiento
## - Gestionar botones táctiles de habilidades
## - Emitir señales para que el jugador responda

signal ability_pressed(slot: int)
signal move_direction_changed(direction: Vector2)

var virtual_joystick_active: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var joystick_current: Vector2 = Vector2.ZERO
var joystick_touch_index: int = -1

const JOYSTICK_DEADZONE: float = 0.2
const JOYSTICK_MAX_RADIUS: float = 80.0

## Dirección actual del joystick virtual (normalizada)
var move_direction: Vector2 = Vector2.ZERO


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


## Llamar cuando se presiona un botón de habilidad
func press_ability(slot: int) -> void:
	if slot < 0 or slot > 2:
		return
	
	ability_pressed.emit(slot)


## Helper: obtiene la dirección de movimiento actual
func get_move_direction() -> Vector2:
	return move_direction


## Helper: obtiene el offset del joystick para renderizar UI
func get_joystick_offset() -> Vector2:
	if not virtual_joystick_active:
		return Vector2.ZERO
	
	return joystick_current - joystick_center
