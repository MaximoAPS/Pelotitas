extends Resource
class_name Mode
## Clase base abstracta para modos de juego
##
## Arquitectura modular: cada modo define sus propias:
## - Condiciones de victoria
## - Reglas de spawn
## - Configuración de mapa
## - Lógica específica de eventos
##
## El núcleo de combate es compartido; los modos solo "enchufan" su lógica.

@export var mode_id: String = ""
@export var mode_name: String = ""
@export var description: String = ""
@export var max_players: int = 2
@export var map_scene_path: String = ""

var active_players: Array = []  # Array of Player instances
var match_start_time: float = 0.0
var match_running: bool = false
var match_elapsed: float = 0.0
var shrink_steps: int = 0


## Inicializa el modo cuando comienza el duelo
func on_match_start() -> void:
	match_start_time = Time.get_ticks_msec() / 1000.0
	match_running = true
	match_elapsed = 0.0
	shrink_steps = 0
	print("[Mode] Iniciando modo: %s" % mode_name)


## Actualiza la lógica del modo cada frame
func process(delta: float) -> void:
	if not match_running:
		return
	match_elapsed += delta
	shrink_steps = GameRules.shrink_steps_for_time(match_elapsed)


## Verifica condiciones de victoria
func check_victory_conditions() -> void:
	push_warning("[Mode] check_victory_conditions() no implementado")


## Maneja la muerte de un jugador
func on_player_death(player) -> void:  # Player type
	print("[Mode] Jugador murió: %s" % player.pelotita_id)
	check_victory_conditions()


## Finaliza el duelo
func on_duel_end(winner_id: int) -> void:
	print("[Mode] Duelo finalizado, ganador: %d" % winner_id)


## Configura spawn points según el modo
func get_spawn_positions() -> Array[Vector2]:
	push_warning("[Mode] get_spawn_positions() no implementado")
	return []


## Registra un jugador en el modo
func register_player(player) -> void:  # Player type
	if player in active_players:
		return
	active_players.append(player)
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died.bind(player))


func _on_player_died(player) -> void:  # Player type
	on_player_death(player)
