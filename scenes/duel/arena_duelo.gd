extends Node2D
## Escena principal de duelo: gestiona jugadores, proyectiles y modo activo

@onready var players_node = $Players
@onready var projectiles_node = $Projectiles
@onready var spawn_point_1 = $SpawnPoint1
@onready var spawn_point_2 = $SpawnPoint2

var player_scene = preload("res://scenes/duel/player_prefab.tscn")


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
	Game.active_mode.register_player(player1)
	
	# Jugador 2 (dummy para pruebas)
	if spawn_positions.size() > 1:
		var player2 = player_scene.instantiate()
		player2.position = spawn_positions[1]
		player2.pelotita_id = "player_2"
		players_node.add_child(player2)
		Game.active_mode.register_player(player2)


func _process(delta: float) -> void:
	if Game.active_mode:
		Game.active_mode.process(delta)


## Helper: spawns un proyectil en el mundo
func spawn_projectile(projectile: Projectile) -> void:
	projectiles_node.add_child(projectile)
