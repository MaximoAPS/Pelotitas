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
	
	# Conectar señales de red para manejo de peers
	if multiplayer.has_multiplayer_peer():
		Net.peer_connected.connect(_on_peer_joined_arena)
		Net.peer_disconnected.connect(_on_peer_left_arena)
	
	_spawn_players()
	Game.active_mode.on_match_start()


func _spawn_players() -> void:
	var spawn_positions = Game.active_mode.get_spawn_positions()
	
	if multiplayer.has_multiplayer_peer():
		# Modo multiplayer
		if Net.is_server:
			print("[ArenaDuelo] Servidor: spawneando jugador local")
			_spawn_networked_player(Net.local_peer_id, spawn_positions[0], 0)
			
			# Si ya hay un cliente conectado, spawnearlo también
			var client_peers = []
			for peer_id in Net.connected_peers.keys():
				if peer_id != Net.local_peer_id:
					client_peers.append(peer_id)
			
			if client_peers.size() > 0:
				var client_id = client_peers[0]
				print("[ArenaDuelo] Servidor: spawneando cliente %d" % client_id)
				_spawn_networked_player(client_id, spawn_positions[1], 1)
		else:
			# Cliente espera a que el servidor spawnee jugadores
			print("[ArenaDuelo] Cliente: esperando spawn desde servidor")
	else:
		# Modo local sin red
		_spawn_local_players(spawn_positions)


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


## Spawn de jugador en modo local (sin red)
func _spawn_local_players(spawn_positions: Array[Vector2]) -> void:
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


## Spawn de jugador en modo multiplayer
func _spawn_networked_player(peer_id: int, spawn_pos: Vector2, player_index: int) -> void:
	var player = player_scene.instantiate()
	player.position = spawn_pos
	player.pelotita_id = Net.connected_peers.get(peer_id, {}).get("nickname", "Jugador%d" % peer_id)
	player.name = "Player_%d" % peer_id
	
	# Establecer autoridad de red
	player.set_multiplayer_authority(peer_id)
	
	players_node.add_child(player)
	_setup_test_loadout(player, player_index)
	
	# Color distintivo según jugador
	var sprite = player.get_node_or_null("Sprite")
	if sprite and sprite is Polygon2D:
		if player_index == 0:
			sprite.color = Color(0.3, 0.6, 0.9, 1.0)  # Azul
		else:
			sprite.color = Color(1.0, 0.4, 0.3, 1.0)  # Rojo/naranja
	
	Game.active_mode.register_player(player)
	
	# Normalizar velocidades y triggers se harán cuando ambos jugadores estén spawneados
	_check_all_players_ready()


## Verifica si todos los jugadores están listos y activa el match
func _check_all_players_ready() -> void:
	var player_count = players_node.get_child_count()
	
	if player_count >= 2:
		# Normalizar velocidades de todos los jugadores
		var players = []
		for child in players_node.get_children():
			if child is Player:
				players.append(child)
		
		_normalize_player_speeds(players)
		
		# Trigger: on_match_start para todas las habilidades
		for player in players:
			if player.loadout:
				player.loadout.trigger_on_match_start()
		
		print("[ArenaDuelo] Todos los jugadores listos, iniciando match")


## Callback cuando un peer se une a la arena
func _on_peer_joined_arena(peer_id: int) -> void:
	if not Net.is_server:
		return
	
	# El servidor spawnea el nuevo jugador
	var spawn_positions = Game.active_mode.get_spawn_positions()
	var player_count = players_node.get_child_count()
	
	if player_count < spawn_positions.size():
		var spawn_pos = spawn_positions[player_count]
		print("[ArenaDuelo] Spawneando jugador para peer %d" % peer_id)
		_spawn_networked_player(peer_id, spawn_pos, player_count)


## Callback cuando un peer deja la arena
func _on_peer_left_arena(peer_id: int) -> void:
	# Buscar y eliminar el jugador que se desconectó
	for child in players_node.get_children():
		if child is Player and child.get_multiplayer_authority() == peer_id:
			print("[ArenaDuelo] Removiendo jugador desconectado: peer %d" % peer_id)
			child.queue_free()
			break


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


## RPC: Spawn de proyectil replicado en red
@rpc("any_peer", "call_local", "reliable")
func _spawn_projectile_networked(
	spawn_pos: Vector2,
	direction: Vector2,
	owner_id: int,
	owner_ataque: int,
	speed: float,
	lifetime: float,
	color: Color,
	caster_id: String
) -> void:
	# Instanciar proyectil
	var projectile_scene = preload("res://scenes/combat/projectile_elemental.tscn")
	var projectile = projectile_scene.instantiate()
	
	if projectile is Projectile:
		projectile.speed = speed
		projectile.lifetime = lifetime
		
		# Aplicar color
		var sprite = projectile.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = color
		
		# Inicializar (sin referencias a ability/player para evitar problemas de red)
		projectile.initialize(
			spawn_pos,
			direction,
			owner_id,
			owner_ataque,
			null,  # source_ability
			null   # source_player
		)
		
		# Establecer autoridad de red
		projectile.set_multiplayer_authority(owner_id)
		
		spawn_projectile(projectile)
		
		print("[ArenaDuelo] Proyectil spawneado en red: owner=%d, pos=%v" % [owner_id, spawn_pos])
