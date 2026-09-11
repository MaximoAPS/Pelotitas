extends Mode
class_name DueloPorVida
## Modo: Duelo por Vida (1v1)
##
## Condición de victoria: Reducir la vida del rival a 0
## Jugadores: 2
## Mapa: Arena simple con obstáculos opcionales


func _init() -> void:
	mode_id = "duelo_por_vida"
	mode_name = "Duelo por Vida"
	description = "Combate 1 contra 1. Gana el primero en reducir la vida del rival a 0."
	max_players = 2
	map_scene_path = "res://scenes/duel/arena_duelo.tscn"


func on_match_start() -> void:
	super.on_match_start()
	
	if active_players.size() != 2:
		push_warning("[DueloPorVida] Se esperaban 2 jugadores, hay %d" % active_players.size())


func check_victory_conditions() -> void:
	# Contar jugadores vivos
	var alive_players: Array = []  # Array of Player instances
	
	for player in active_players:
		if player.current_health > 0:
			alive_players.append(player)
	
	# Victoria si solo queda 1 vivo (o 0 en caso de empate/simultáneo)
	if alive_players.size() <= 1:
		var winner_id = -1
		if alive_players.size() == 1:
			winner_id = alive_players[0].get_multiplayer_authority()
		
		_declare_victory(winner_id)


func _declare_victory(winner_id: int) -> void:
	print("[DueloPorVida] ¡Victoria! Ganador: %d" % winner_id)
	Game.end_duel(winner_id)
	# TODO: Mostrar pantalla de victoria/derrota


func get_spawn_positions() -> Array[Vector2]:
	# Posiciones fijas para 2 jugadores (provisional)
	return [
		Vector2(200, 360),   # Jugador 1 (izquierda)
		Vector2(1080, 360)   # Jugador 2 (derecha)
	]


func on_player_death(player: Player) -> void:
	super.on_player_death(player)
	# En este modo, cualquier muerte puede significar victoria
	check_victory_conditions()
