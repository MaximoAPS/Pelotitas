extends Node
## Registro global de modos de juego
##
## Permite agregar nuevos modos sin modificar código existente.
## Cada modo se registra con un ID único.

var registered_modes: Dictionary = {}


func _ready() -> void:
	_register_default_modes()


func _register_default_modes() -> void:
	register_mode(DueloPorVida.new())
	# TODO: Agregar más modos aquí:
	# register_mode(CapturaLaBandera.new())
	# register_mode(DestruyeEstructura.new())
	# register_mode(EquipoDeathmatch.new())


func register_mode(mode) -> void:  # Mode type
	if mode.mode_id.is_empty():
		push_error("[ModeRegistry] Modo sin ID válido")
		return
	
	registered_modes[mode.mode_id] = mode
	print("[ModeRegistry] Modo registrado: %s (%s)" % [mode.mode_name, mode.mode_id])


func get_mode(mode_id: String) -> Mode:
	if not registered_modes.has(mode_id):
		push_error("[ModeRegistry] Modo no encontrado: %s" % mode_id)
		return null
	
	return registered_modes[mode_id]


func get_all_modes() -> Array[Mode]:
	var modes: Array[Mode] = []
	for mode in registered_modes.values():
		modes.append(mode)
	return modes
