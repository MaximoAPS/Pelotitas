extends Node2D
## Escena principal de duelo: gestiona jugadores, proyectiles y modo activo

@onready var players_node = $Players
@onready var projectiles_node = $Projectiles
@onready var spawn_point_1 = $SpawnPoint1
@onready var spawn_point_2 = $SpawnPoint2

var player_scene = preload("res://scenes/duel/player_prefab.tscn")

# Precarga de habilidades elementales para testing
var disparo_fuego = preload("res://resources/abilities/disparo_fuego.tres")
var disparo_agua = preload("res://resources/abilities/disparo_agua.tres")
var disparo_tierra = preload("res://resources/abilities/disparo_tierra.tres")
var disparo_viento = preload("res://resources/abilities/disparo_viento.tres")


func _ready() -> void:
	print("[ArenaDuelo] Iniciando duelo...")
	
	if not Game.active_mode:
		push_warning("[ArenaDuelo] No hay modo activo, usando DueloPorVida por defecto")
		Game.active_mode = DueloPorVida.new()
	
	_spawn_players()
	Game.active_mode.on_match_start()


func _spawn_players() -> void:
	var spawn_positions = Game.active_mode.get_spawn_positions()
	
	# Testing local: Jugador 1 controlable, Jugador 2 dummy estacionario
	
	var players = []
	
	# Jugador 1 (controlable)
	var player1 = player_scene.instantiate()
	player1.position = spawn_positions[0] if spawn_positions.size() > 0 else spawn_point_1.position
	player1.pelotita_id = "player_1"
	player1.name = "Player1"
	players_node.add_child(player1)
	_setup_test_loadout(player1, 0)
	players.append(player1)
	
	# Jugador 2 (dummy estacionario para testing)
	if spawn_positions.size() > 1:
		var player2 = player_scene.instantiate()
		player2.position = spawn_positions[1]
		player2.pelotita_id = "player_2_dummy"
		player2.name = "Player2Dummy"
		players_node.add_child(player2)
		_setup_test_loadout(player2, 1)
		
		# Marcar como dummy: no procesará input
		player2.set_meta("is_dummy", true)
		
		# Color distintivo para el dummy (rojo/naranja)
		var sprite = player2.get_node_or_null("Sprite")
		if sprite and sprite is Polygon2D:
			sprite.color = Color(1.0, 0.4, 0.3, 1.0)
		
		players.append(player2)
	
	# Calcular media geométrica y normalizar velocidades
	_normalize_player_speeds(players)
	
	# Registrar jugadores en el modo después de normalizar velocidades
	for player in players:
		Game.active_mode.register_player(player)
	
	# Trigger: on_match_start para todas las habilidades
	for player in players:
		if player.loadout:
			player.loadout.trigger_on_match_start()


## Calcula la media geométrica de velocidades y normaliza speeds de todos los jugadores
func _normalize_player_speeds(players: Array) -> void:
	if players.is_empty():
		return
	
	# Recolectar stats de velocidad
	var velocidades: Array[float] = []
	for player in players:
		if player is Player:
			# Clamp a epsilon mínimo para evitar división por cero
			var v = max(player.velocidad, 0.01)
			velocidades.append(v)
	
	if velocidades.is_empty():
		return
	
	# Calcular media geométrica: G = (∏ V_i)^(1/n)
	var product = 1.0
	for v in velocidades:
		product *= v
	
	var n = float(velocidades.size())
	var geometric_mean = pow(product, 1.0 / n)
	
	print("[ArenaDuelo] Media geométrica de velocidades: G = %.3f" % geometric_mean)
	
	# Asignar velocidad normalizada a cada jugador
	for player in players:
		if player is Player:
			player.set_normalized_speed(geometric_mean)


## Configura loadout de prueba con habilidades elementales
func _setup_test_loadout(player: Player, player_index: int) -> void:
	var loadout = Loadout.new()
	
	# Equipar 3 disparos elementales para testing
	# Player 1: Fuego, Agua, Tierra
	# Player 2: Agua, Viento, Fuego (para variar)
	if player_index == 0:
		loadout.equip_usable(disparo_fuego, 0)
		loadout.equip_usable(disparo_agua, 1)
		loadout.equip_usable(disparo_tierra, 2)
		# Stats de prueba: velocidad más alta
		player.velocidad = 1.5
	else:
		loadout.equip_usable(disparo_agua, 0)
		loadout.equip_usable(disparo_viento, 1)
		loadout.equip_usable(disparo_fuego, 2)
		# Stats de prueba: velocidad más baja
		player.velocidad = 0.75
	
	player.set_loadout(loadout)
	print("[ArenaDuelo] Loadout de prueba configurado para %s" % player.pelotita_id)
	
	# Llamar triggers de equip
	loadout.trigger_on_equip()


func _process(delta: float) -> void:
	if Game.active_mode:
		Game.active_mode.process(delta)


## Helper: spawns un proyectil en el mundo
func spawn_projectile(projectile: Projectile) -> void:
	projectiles_node.add_child(projectile)
