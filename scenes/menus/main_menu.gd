extends Control
## Menú principal: opciones para crear/unirse a partida o prueba local


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
		# TODO: Ir a lobby o selección de modo
		_start_test_duel()


func _on_join_game_pressed() -> void:
	print("[MainMenu] Uniéndose a servidor...")
	
	# TODO: Mostrar input para IP/puerto
	var error = Net.join_server("127.0.0.1", 7777)
	if error == OK:
		# TODO: Esperar conexión, ir a lobby
		pass


func _on_local_test_pressed() -> void:
	print("[MainMenu] Iniciando prueba local...")
	
	# Crear servidor local sin red real
	_start_test_duel()


func _on_exit_pressed() -> void:
	print("[MainMenu] Botón Exit presionado - cerrando juego...")
	get_tree().quit()


## Helper temporal: inicia duelo de prueba
func _start_test_duel() -> void:
	print("[MainMenu] Iniciando duelo de prueba...")
	var mode = DueloPorVida.new()
	Game.start_duel(mode)
	
	var error = get_tree().change_scene_to_file("res://scenes/duel/arena_duelo.tscn")
	if error != OK:
		push_error("[MainMenu] Error al cambiar escena: %d" % error)
	else:
		print("[MainMenu] Cambiando a escena de duelo...")
