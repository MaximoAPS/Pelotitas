extends CanvasLayer
## HUD móvil con controles táctiles (layout twin-stick-ish)
##
## Layout bloqueado:
## - Joystick virtual / palanca (izquierda inferior): movimiento 360°
## - 3 botones de habilidades usables (derecha inferior): press-hold-drag-release para apuntar
## - Barra de vida (superior)
##
## Sistema de apuntado de habilidades:
## 1. Press y hold en botón de habilidad
## 2. Drag en la dirección deseada
## 3. Release para disparar en esa dirección
##
## Nota: La habilidad pasiva NO tiene botón (siempre activa)

@onready var joystick_base = $VirtualJoystick/Base
@onready var joystick_stick = $VirtualJoystick/Stick
@onready var health_bar = $TopBar/HealthBar
@onready var health_label = $TopBar/HealthBar/Label
@onready var ability_buttons = [$AbilityButtons/Ability1, $AbilityButtons/Ability2, $AbilityButtons/Ability3]
@onready var ability_aim_line: Line2D = $AbilityAimLine

var joystick_initial_pos: Vector2
var is_joystick_active: bool = false
var current_touch_index: int = -1

# Tracking de habilidades siendo apuntadas
var ability_touch_tracking: Dictionary = {}  # {touch_index: ability_slot}


func _ready() -> void:
	joystick_initial_pos = joystick_stick.position
	
	# Conectar señales del autoload TouchInput
	TouchInput.move_direction_changed.connect(_on_move_direction_changed)


func _on_joystick_input(event: InputEvent) -> void:
	# Soporte para touch (móvil)
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
	
	# Soporte para mouse (desktop testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_joystick_active = true
				current_touch_index = 0  # Usar índice 0 para mouse
				TouchInput.start_virtual_joystick(event.position, 0)
			else:
				if is_joystick_active:
					is_joystick_active = false
					current_touch_index = -1
					TouchInput.end_virtual_joystick()
					joystick_stick.position = joystick_initial_pos
	
	elif event is InputEventMouseMotion:
		if is_joystick_active and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			TouchInput.update_virtual_joystick(event.position)


func _on_move_direction_changed(direction: Vector2) -> void:
	# Actualizar visualmente el stick del joystick
	if is_joystick_active:
		var offset = TouchInput.get_joystick_offset()
		# Limitar el visual a un radio razonable
		if offset.length() > 110:
			offset = offset.normalized() * 110
		
		joystick_stick.position = joystick_initial_pos + offset


## Manejo de habilidades con press-hold-drag-release
func _on_ability_button_gui_input(event: InputEvent, slot: int) -> void:
	# Soporte para touch (móvil)
	if event is InputEventScreenTouch:
		if event.pressed:
			# Press: Iniciar apuntado
			TouchInput.start_ability_aim(slot, event.position, event.index)
			ability_touch_tracking[event.index] = slot
		else:
			# Release: Disparar habilidad
			if ability_touch_tracking.has(event.index) and ability_touch_tracking[event.index] == slot:
				TouchInput.fire_ability()
				ability_touch_tracking.erase(event.index)
	
	elif event is InputEventScreenDrag:
		# Drag: Actualizar dirección de apuntado
		if ability_touch_tracking.has(event.index) and ability_touch_tracking[event.index] == slot:
			TouchInput.update_ability_aim(event.position)
	
	# Soporte para mouse (desktop testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Press: Iniciar apuntado
				TouchInput.start_ability_aim(slot, event.position, 0)
				ability_touch_tracking[0] = slot
			else:
				# Release: Disparar habilidad
				if ability_touch_tracking.has(0) and ability_touch_tracking[0] == slot:
					TouchInput.fire_ability()
					ability_touch_tracking.erase(0)
	
	elif event is InputEventMouseMotion:
		# Drag con mouse: Actualizar dirección de apuntado
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if ability_touch_tracking.has(0) and ability_touch_tracking[0] == slot:
				TouchInput.update_ability_aim(event.position)


# Conectar eventos de botones a la función común
func _on_ability_1_pressed() -> void:
	pass  # Manejado por gui_input


func _on_ability_2_pressed() -> void:
	pass  # Manejado por gui_input


func _on_ability_3_pressed() -> void:
	pass  # Manejado por gui_input


## Muestra solo botones de slots con habilidad equipada (nivel 1 = 1 botón).
func sync_ability_buttons(loadout) -> void:
	for i in range(ability_buttons.size()):
		var equipped = loadout != null and loadout.usable_abilities[i] != null
		ability_buttons[i].visible = equipped


func _process(_delta: float) -> void:
	_update_ability_aim_hint()


func _update_ability_aim_hint() -> void:
	if not TouchInput.is_aiming_ability():
		ability_aim_line.visible = false
		return
	var offset: Vector2 = TouchInput.get_ability_aim_offset()
	if offset.length() < 8.0:
		ability_aim_line.visible = false
		return
	var slot: int = TouchInput.ability_slot_aiming
	if slot < 0 or slot >= ability_buttons.size():
		ability_aim_line.visible = false
		return
	var btn: Control = ability_buttons[slot]
	var origin: Vector2 = btn.get_global_rect().get_center()
	var dir: Vector2 = offset.normalized()
	ability_aim_line.visible = true
	ability_aim_line.points = PackedVector2Array([origin, origin + dir * 110.0])


## Actualiza la barra de vida (llamar desde el script del jugador)
func update_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]


## Actualiza el cooldown visual de una habilidad (TODO)
func update_ability_cooldown(slot: int, remaining: float, total: float) -> void:
	# TODO: Mostrar progreso de cooldown en los botones
	pass
