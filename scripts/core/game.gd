extends Node
## Autoload global para gestión de estado del juego
##
## Responsabilidades:
## - Gestionar el flujo entre menús, lobby y duelos
## - Mantener referencia al modo de juego activo
## - Coordinar transiciones de escenas
## - Proveer acceso global a datos de sesión

signal game_state_changed(new_state: GameState)
signal duel_ended(winner_id: int)

enum GameState {
	BOOT,
	MAIN_MENU,
	LOBBY,
	IN_DUEL,
	POST_DUEL
}

var current_state: GameState = GameState.BOOT
var active_mode: Mode = null


func _ready() -> void:
	print("[Game] Autoload inicializado")
	# TODO: Cargar configuración, datos persistentes


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	print("[Game] Cambiando estado: %s -> %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
	current_state = new_state
	game_state_changed.emit(new_state)


func start_duel(mode: Mode) -> void:
	active_mode = mode
	change_state(GameState.IN_DUEL)
	# TODO: Cargar escena de duelo, pasar modo activo


func end_duel(winner_id: int = -1) -> void:
	if active_mode:
		active_mode.on_duel_end(winner_id)
	
	change_state(GameState.POST_DUEL)
	duel_ended.emit(winner_id)
	print("[Game] Duelo finalizado, ganador: %d" % winner_id)
