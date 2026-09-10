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
	
	# TODO: Crear jugadores según peers conectados
	# Por ahora, spawn de prueba local
	
	# Jugador 1
	var player1 = player_scene.instantiate()
	player1.position = spawn_positions[0] if spawn_positions.size() > 0 else spawn_point_1.position
	player1.pelotita_id = "player_1"
	players_node.add_child(player1)
	_setup_test_loadout(player1, 0)
	Game.active_mode.register_player(player1)
	
	# Jugador 2 (dummy para pruebas)
	if spawn_positions.size() > 1:
		var player2 = player_scene.instantiate()
		player2.position = spawn_positions[1]
		player2.pelotita_id = "player_2"
		players_node.add_child(player2)
		_setup_test_loadout(player2, 1)
		Game.active_mode.register_player(player2)


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
	else:
		loadout.equip_usable(disparo_agua, 0)
		loadout.equip_usable(disparo_viento, 1)
		loadout.equip_usable(disparo_fuego, 2)
	
	player.set_loadout(loadout)
	print("[ArenaDuelo] Loadout de prueba configurado para %s" % player.pelotita_id)


func _process(delta: float) -> void:
	if Game.active_mode:
		Game.active_mode.process(delta)


## Helper: spawns un proyectil en el mundo
func spawn_projectile(projectile: Projectile) -> void:
	projectiles_node.add_child(projectile)
