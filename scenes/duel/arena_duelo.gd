extends Node2D
## Escena principal de duelo: gestiona jugadores, proyectiles y modo activo

@onready var players_node = $Players
@onready var projectiles_node = $Projectiles
@onready var spawn_point_1 = $SpawnPoint1
@onready var spawn_point_2 = $SpawnPoint2
@onready var results_screen = $ResultsScreen
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner

var player_scene = preload("res://scenes/duel/player_prefab.tscn")
var _match_wired: bool = false
var _net_spawn_done: bool = false
var _peers_in_arena: Dictionary = {}
var _applied_shrink: int = 0

# Precarga de habilidades elementales para testing
var disparo_fuego = preload("res://resources/abilities/disparo_fuego.tres")
var disparo_agua = preload("res://resources/abilities/disparo_agua.tres")
var disparo_tierra = preload("res://resources/abilities/disparo_tierra.tres")
var disparo_viento = preload("res://resources/abilities/disparo_viento.tres")


func _ready() -> void:
	print("[ArenaDuelo] Iniciando duelo...")
	_apply_arena_layout()
	player_spawner.spawn_path = player_spawner.get_path_to(players_node)
	player_spawner.spawn_function = _spawn_player_from_data
	player_spawner.add_spawnable_scene("res://scenes/duel/player_prefab.tscn")
	
	if not Game.active_mode:
		push_warning("[ArenaDuelo] No hay modo activo, usando DueloPorVida por defecto")
		Game.active_mode = DueloPorVida.new()
	
	Game.duel_ended.connect(_on_duel_ended)
	if Net.is_networked():
		Net.peer_connected.connect(_on_peer_joined_arena)
		Net.peer_disconnected.connect(_on_peer_left_arena)
		if Net.is_server:
			Net.peer_reported_arena_ready.connect(_on_net_arena_ready)
	_spawn_players()
	if Net.is_offline():
		Game.active_mode.on_match_start()
	_bind_local_hud()


func _apply_arena_layout(steps: int = 0, move_spawns: bool = true) -> void:
	var rect := GameRules.arena_rect_at(steps)
	var origin := rect.position
	var size := rect.size
	var center := rect.get_center()
	var thick := GameRules.WALL_THICKNESS
	var bg := get_node_or_null("Background")
	if bg is ColorRect:
		bg.position = origin
		bg.size = size
	var line := get_node_or_null("CenterLine")
	if line is ColorRect:
		line.position = Vector2(center.x - 2.0, origin.y)
		line.size = Vector2(4.0, size.y)
	if move_spawns:
		if spawn_point_1:
			spawn_point_1.position = GameRules.duel_spawn_positions()[0]
		if spawn_point_2:
			spawn_point_2.position = GameRules.duel_spawn_positions()[1]
	var cam := get_node_or_null("Camera2D")
	if cam is Camera2D:
		cam.position = GameRules.arena_center()
	_place_wall($Walls/WallTop, Vector2(center.x, origin.y + thick * 0.5), Vector2(size.x, thick))
	_place_wall($Walls/WallBottom, Vector2(center.x, origin.y + size.y - thick * 0.5), Vector2(size.x, thick))
	_place_wall($Walls/WallLeft, Vector2(origin.x + thick * 0.5, center.y), Vector2(thick, size.y))
	_place_wall($Walls/WallRight, Vector2(origin.x + size.x - thick * 0.5, center.y), Vector2(thick, size.y))
	if get_node_or_null("Backdrop") == null:
		var backdrop := ColorRect.new()
		backdrop.name = "Backdrop"
		backdrop.color = Color(0.08, 0.1, 0.12, 1)
		backdrop.position = Vector2.ZERO
		backdrop.size = GameRules.VIEWPORT_SIZE
		backdrop.z_index = -2
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
		move_child(backdrop, 0)


func _place_wall(wall: Node2D, center: Vector2, extents: Vector2) -> void:
	if wall == null:
		return
	wall.position = center
	var col := wall.get_node_or_null("CollisionShape2D")
	if col and col.shape is RectangleShape2D:
		var shaped := RectangleShape2D.new()
		shaped.size = extents
		col.shape = shaped
	var vis := wall.get_node_or_null("Visual")
	if vis is ColorRect:
		vis.offset_left = -extents.x * 0.5
		vis.offset_top = -extents.y * 0.5
		vis.offset_right = extents.x * 0.5
		vis.offset_bottom = extents.y * 0.5


func _spawn_player_from_data(data: Variant) -> Node:
	var d: Dictionary = data
	var peer_id := int(d["peer_id"])
	var player_index := int(d["player_index"])
	var player: Player = player_scene.instantiate()
	player.position = d["spawn_pos"]
	player.pelotita_id = str(d.get("nickname", "Jugador%d" % peer_id))
	player.name = "Player_%d" % peer_id
	player.player_index = player_index
	player.set_multiplayer_authority(peer_id)
	var el := int(d.get("element", 0))
	_setup_loadout(player, el, d)
	var sprite = player.get_node_or_null("Sprite")
	if sprite and sprite is Polygon2D:
		sprite.color = GameRules.shot_color(el)
	call_deferred("_after_networked_player_spawned", player)
	return player


func _after_networked_player_spawned(player: Player) -> void:
	if player == null or not is_instance_valid(player):
		return
	if Game.active_mode:
		Game.active_mode.register_player(player)
	_check_all_players_ready()
	_bind_local_hud()


func _spawn_players() -> void:
	var spawn_positions = Game.active_mode.get_spawn_positions()
	if Net.is_networked():
		if Net.is_server:
			_peers_in_arena[Net.local_peer_id] = true
			for peer_id in Net.arena_ready_peers.keys():
				_peers_in_arena[peer_id] = true
			print("[ArenaDuelo] Servidor: esperando que el cliente cargue la arena")
			_try_network_spawn()
		else:
			print("[ArenaDuelo] Cliente: reportando arena lista")
			Net.rpc_arena_ready.rpc_id(1)
	else:
		_spawn_local_players(spawn_positions)


func _on_net_arena_ready(peer_id: int) -> void:
	_peers_in_arena[peer_id] = true
	_try_network_spawn()


func _try_network_spawn() -> void:
	if _net_spawn_done or not Net.is_server:
		return
	if _peers_in_arena.size() < 2:
		return
	_net_spawn_done = true
	var spawn_positions = Game.active_mode.get_spawn_positions()
	print("[ArenaDuelo] Servidor: spawneando jugador local")
	_spawn_networked_player(Net.local_peer_id, spawn_positions[0], 0)
	for peer_id in Net.connected_peers.keys():
		if peer_id != Net.local_peer_id:
			print("[ArenaDuelo] Servidor: spawneando cliente %d" % peer_id)
			_spawn_networked_player(peer_id, spawn_positions[1], 1)
			break


## Calcula la media geométrica de velocidades y normaliza speeds de todos los jugadores
func _normalize_player_speeds(players: Array) -> void:
	if players.is_empty():
		return
	
	# Recolectar stats de velocidad
	var velocidades: Array[float] = []
	for player in players:
		if player is Player:
			velocidades.append(maxf(player.velocidad, 0.01))
	if velocidades.is_empty():
		return
	var geometric_mean = GameRules.geometric_mean(velocidades)
	
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
	player1.player_index = 0
	players_node.add_child(player1)
	_setup_loadout(player1, Progression.selected_element(), Progression.selected_pelotita())
	players.append(player1)
	
	# Jugador 2 (dummy estacionario para testing)
	if spawn_positions.size() > 1:
		var player2 = player_scene.instantiate()
		player2.position = spawn_positions[1]
		player2.pelotita_id = "player_2_dummy"
		player2.name = "Player2Dummy"
		player2.player_index = 1
		player2.set_meta("is_dummy", true)
		players_node.add_child(player2)
		var dummy_el := (Progression.selected_element() + 2) % 4
		_setup_loadout(player2, dummy_el, {})
		var sprite = player2.get_node_or_null("Sprite")
		if sprite and sprite is Polygon2D:
			sprite.color = GameRules.shot_color(dummy_el)
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


## Spawn de jugador en modo multiplayer (solo servidor; se replica con MultiplayerSpawner)
func _spawn_networked_player(peer_id: int, spawn_pos: Vector2, player_index: int) -> void:
	if not Net.is_server:
		return
	for child in players_node.get_children():
		if child is Player and child.get_multiplayer_authority() == peer_id:
			return
	var info: Dictionary = Net.connected_peers.get(peer_id, {})
	if peer_id == Net.local_peer_id:
		info = Progression.combat_payload()
	var data := GameRules.combat_stats_from(info)
	data["peer_id"] = peer_id
	data["player_index"] = player_index
	data["spawn_pos"] = spawn_pos
	data["nickname"] = str(info.get("nickname", "Jugador%d" % peer_id))
	data["element"] = int(info.get("element", Progression.selected_element() if peer_id == Net.local_peer_id else 0))
	player_spawner.spawn(data)


## Verifica si todos los jugadores están listos y activa el match
func _check_all_players_ready() -> void:
	if _match_wired:
		return
	var players = []
	for child in players_node.get_children():
		if child is Player:
			players.append(child)
	if players.size() < 2:
		return
	_match_wired = true
	Game.active_mode.on_match_start()
	_normalize_player_speeds(players)
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


func _shot_for_element(element: int) -> Resource:
	match element:
		1:
			return disparo_agua
		2:
			return disparo_tierra
		3:
			return disparo_viento
		_:
			return disparo_fuego


func _setup_loadout(player: Player, element: int, raw: Dictionary = {}) -> void:
	var loadout = Loadout.new()
	var shot = _shot_for_element(element)
	if shot:
		loadout.equip_usable(shot.duplicate(), 0)
	player.set_loadout(loadout)
	var stats := GameRules.combat_stats_from(raw)
	player.ataque = int(stats.ataque)
	player.defensa = int(stats.defensa)
	player.velocidad = float(stats.velocidad)
	player.masa = float(stats.masa)
	player.elemento = element
	player.max_health = GameRules.max_health_from_bonus(int(stats.bonus_hp))
	player.current_health = player.max_health
	var sprite = player.get_node_or_null("Sprite")
	if sprite and sprite is Polygon2D:
		sprite.color = GameRules.shot_color(element)
	print("[ArenaDuelo] Loadout %s para %s ATK %s DEF %s SPD %s" % [
		GameRules.shot_name(element), player.pelotita_id, player.ataque, player.defensa, player.velocidad,
	])
	loadout.trigger_on_equip()


func _process(delta: float) -> void:
	if Game.active_mode:
		Game.active_mode.process(delta)
		if Game.active_mode.shrink_steps != _applied_shrink:
			_applied_shrink = Game.active_mode.shrink_steps
			_apply_arena_layout(_applied_shrink, false)
			_clamp_players_to_arena(_applied_shrink)


func _clamp_players_to_arena(steps: int) -> void:
	var rect := GameRules.arena_rect_at(steps)
	var pad := GameRules.PLAYER_COLLISION_RADIUS + GameRules.WALL_THICKNESS
	var inner := rect.grow(-pad)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	for child in players_node.get_children():
		if not child is Player:
			continue
		var p: Player = child
		p.global_position.x = clampf(p.global_position.x, inner.position.x, inner.end.x)
		p.global_position.y = clampf(p.global_position.y, inner.position.y, inner.end.y)


## Helper: spawns un proyectil en el mundo
func spawn_projectile(projectile: Projectile) -> void:
	projectiles_node.add_child(projectile)


## Maneja el fin del duelo y muestra la pantalla de resultados
func _bind_local_hud() -> void:
	var hud = get_node_or_null("MobileHUD")
	if hud == null:
		return
	var local_player: Player = null
	for child in players_node.get_children():
		if child is Player and not (child.has_meta("is_dummy") and child.get_meta("is_dummy")):
			if Net.is_offline() or Net.has_authority(child):
				local_player = child
				break
	if local_player and not local_player.health_changed.is_connected(hud.update_health):
		local_player.health_changed.connect(hud.update_health)
		hud.update_health(local_player.current_health, local_player.max_health)
		hud.sync_ability_buttons(local_player.loadout)


func _local_results_id() -> int:
	if Net.is_networked():
		return Net.local_peer_id
	return 0


func _on_duel_ended(winner_id: int) -> void:
	print("[ArenaDuelo] Duelo finalizado, mostrando resultados")
	var won := winner_id == _local_results_id()
	var result: Dictionary = Progression.award_xp_for_match(Progression.selected_id, won, 1)
	print("[ArenaDuelo] XP: +%s" % result.get("xp_gained", 0))
	results_screen.show_results(winner_id, _local_results_id())


## RPC: Spawn de proyectil replicado en red
@rpc("any_peer", "call_local", "reliable")
func _spawn_projectile_networked(
	spawn_pos: Vector2,
	direction: Vector2,
	owner_id: int,
	owner_ataque: int,
	element: int,
	d: int = 20,
	masa_stat: float = 1.0,
	speed_px: float = 0.0
) -> void:
	var projectile_scene = preload("res://scenes/combat/projectile_elemental.tscn")
	var projectile = projectile_scene.instantiate()
	if projectile is Projectile:
		var sprite = projectile.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = GameRules.shot_color(element)
		projectile.initialize(
			spawn_pos,
			direction,
			owner_id,
			owner_ataque,
			null,
			null,
			element,
			d,
			masa_stat,
			speed_px
		)
		projectile.set_multiplayer_authority(owner_id)
		spawn_projectile(projectile)
		print("[ArenaDuelo] Proyectil spawneado en red: owner=%d, pos=%v" % [owner_id, spawn_pos])
