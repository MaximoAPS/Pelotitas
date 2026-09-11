extends Control
## Menú principal: opciones para crear/unirse a partida o prueba local

@onready var join_dialog = $JoinDialog
@onready var input_nickname = $JoinDialog/VBoxContainer/InputNickname
@onready var input_ip = $JoinDialog/VBoxContainer/InputIP
@onready var input_port = $JoinDialog/VBoxContainer/InputPort

@onready var host_dialog = $HostDialog
@onready var label_host_ip = $HostDialog/VBoxContainer/LabelIP
@onready var label_host_port = $HostDialog/VBoxContainer/LabelPort
@onready var label_waiting = $HostDialog/VBoxContainer/LabelWaiting
@onready var btn_start_duel = $HostDialog/VBoxContainer/BtnStartDuel

var waiting_for_players: bool = false


func _ready() -> void:
	# Cargar nickname guardado
	input_nickname.text = UserPrefs.nickname
	
	# Conectar señales de red
	Net.peer_connected.connect(_on_peer_connected)
	Net.connection_succeeded.connect(_on_connection_succeeded)
	Net.connection_failed.connect(_on_connection_failed)
	
	# Deshabilitar botón de iniciar duelo hasta que haya jugadores
	btn_start_duel.disabled = true


func _ready() -> void:
	print("[MainMenu] Inicializando menú principal...")
	
	# Conectar señales en código como respaldo (por si las conexiones del .tscn fallan)
	var btn_host = $VBoxContainer/BtnHostGame
	var btn_join = $VBoxContainer/BtnJoinGame
	var btn_local = $VBoxContainer/BtnLocalTest
	var btn_exit = $VBoxContainer/BtnExit
	
	if not btn_host.pressed.is_connected(_on_host_game_pressed):
		btn_host.pressed.connect(_on_host_game_pressed)
		print("[MainMenu] Conectado señal Host Game")
	
	if not btn_join.pressed.is_connected(_on_join_game_pressed):
		btn_join.pressed.connect(_on_join_game_pressed)
		print("[MainMenu] Conectado señal Join Game")
	
	if not btn_local.pressed.is_connected(_on_local_test_pressed):
		btn_local.pressed.connect(_on_local_test_pressed)
		print("[MainMenu] Conectado señal Local Test")
	
	if not btn_exit.pressed.is_connected(_on_exit_pressed):
		btn_exit.pressed.connect(_on_exit_pressed)
		print("[MainMenu] Conectado señal Exit")
	
	print("[MainMenu] Menú listo - esperando input del usuario")


func _on_host_game_pressed() -> void:
	print("[MainMenu] Creando servidor...")
	
	var error = Net.create_server()
	if error == OK:
		# Mostrar diálogo con IP del servidor
		label_host_ip.text = "IP Local: %s" % Net.server_ip
		label_host_port.text = "Puerto: 7777"
		label_waiting.text = "Esperando jugadores... (0/2)"
		btn_start_duel.disabled = true
		waiting_for_players = true
		host_dialog.popup_centered()


func _on_join_game_pressed() -> void:
	print("[MainMenu] Mostrando diálogo de conexión...")
	join_dialog.popup_centered()


func _on_join_dialog_confirmed() -> void:
	# Actualizar nickname si cambió
	var new_nickname = input_nickname.text.strip_edges()
	if new_nickname != UserPrefs.nickname and not new_nickname.is_empty():
		UserPrefs.set_nickname(new_nickname)
	
	# Intentar conectar
	var ip = input_ip.text.strip_edges()
	var port = int(input_port.text)
	
	if ip.is_empty():
		ip = "127.0.0.1"
	if port <= 0:
		port = 7777
	
	print("[MainMenu] Conectando a %s:%d..." % [ip, port])
	var error = Net.join_server(ip, port)
	if error != OK:
		print("[MainMenu] Error al conectar: %d" % error)


func _on_local_test_pressed() -> void:
	print("[MainMenu] Iniciando prueba local...")
	_start_test_duel()


func _on_exit_pressed() -> void:
	print("[MainMenu] Botón Exit presionado - cerrando juego...")
	get_tree().quit()


func _on_start_duel_pressed() -> void:
	print("[MainMenu] Iniciando duelo multiplayer...")
	waiting_for_players = false
	host_dialog.hide()
	_start_test_duel()


func _on_peer_connected(peer_id: int) -> void:
	if waiting_for_players and Net.is_server:
		var connected_count = Net.connected_peers.size() - 1  # -1 porque el servidor se cuenta
		label_waiting.text = "Esperando jugadores... (%d/2)" % connected_count
		
		# Habilitar botón de iniciar cuando haya al menos 1 cliente
		if connected_count >= 1:
			btn_start_duel.disabled = false


func _on_connection_succeeded() -> void:
	print("[MainMenu] Conexión exitosa, iniciando duelo...")
	# Cliente conectado exitosamente, iniciar duelo
	await get_tree().create_timer(0.5).timeout  # Pequeña espera para sincronización
	_start_test_duel()


func _on_connection_failed() -> void:
	print("[MainMenu] Conexión fallida")
	# TODO: Mostrar mensaje de error al usuario


## Helper: inicia duelo
func _start_test_duel() -> void:
	print("[MainMenu] Iniciando duelo de prueba...")
	var mode = DueloPorVida.new()
	Game.start_duel(mode)
	
	var error = get_tree().change_scene_to_file("res://scenes/duel/arena_duelo.tscn")
	if error != OK:
		push_error("[MainMenu] Error al cambiar escena: %d" % error)
	else:
		print("[MainMenu] Cambiando a escena de duelo...")
