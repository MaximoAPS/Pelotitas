extends CanvasLayer
## HUD móvil con controles táctiles
##
## Incluye:
## - Joystick virtual (izquierda inferior)
## - 3 botones de habilidades usables (derecha inferior)
## - Indicador de habilidad pasiva
## - Barra de vida (superior)

@onready var joystick_base = $VirtualJoystick/Base
@onready var joystick_stick = $VirtualJoystick/Stick
@onready var health_bar = $TopBar/HealthBar
@onready var health_label = $TopBar/HealthBar/Label

var joystick_initial_pos: Vector2
var is_joystick_active: bool = false
var current_touch_index: int = -1


func _ready() -> void:
	joystick_initial_pos = joystick_stick.position
	
	# Conectar señales del autoload TouchInput
	TouchInput.move_direction_changed.connect(_on_move_direction_changed)


func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Inicio del toque
			is_joystick_active = true
			current_touch_index = event.index
			TouchInput.start_virtual_joystick(event.position, event.index)
		else:
			# Fin del toque
			if event.index == current_touch_index:
				is_joystick_active = false
				current_touch_index = -1
				TouchInput.end_virtual_joystick()
				joystick_stick.position = joystick_initial_pos
	
	elif event is InputEventScreenDrag:
		if is_joystick_active and event.index == current_touch_index:
			TouchInput.update_virtual_joystick(event.position)


func _on_move_direction_changed(direction: Vector2) -> void:
	# Actualizar visualmente el stick del joystick
	if is_joystick_active:
		var offset = TouchInput.get_joystick_offset()
		# Limitar el visual a un radio razonable
		if offset.length() > 60:
			offset = offset.normalized() * 60
		
		joystick_stick.position = joystick_initial_pos + offset


func _on_ability_1_pressed() -> void:
	TouchInput.press_ability(0)


func _on_ability_2_pressed() -> void:
	TouchInput.press_ability(1)


func _on_ability_3_pressed() -> void:
	TouchInput.press_ability(2)


## Actualiza la barra de vida (llamar desde el script del jugador)
func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


## Actualiza el cooldown visual de una habilidad (TODO)
func update_ability_cooldown(slot: int, remaining: float, total: float) -> void:
	# TODO: Mostrar progreso de cooldown en los botones
	pass
