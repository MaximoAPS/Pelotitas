extends Control
## Menú principal: opciones para crear/unirse a partida o prueba local


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
	get_tree().quit()


## Helper temporal: inicia duelo de prueba
func _start_test_duel() -> void:
	var mode = DueloPorVida.new()
	Game.start_duel(mode)
	get_tree().change_scene_to_file("res://scenes/duel/arena_duelo.tscn")
