extends Control
## Escena de inicio: carga recursos y transiciona al menú principal


func _ready() -> void:
	print("[Boot] Iniciando juego...")
	
	# TODO: Cargar recursos globales, configuración
	# TODO: Inicializar sistemas
	
	# Transicionar al menú principal después de un breve delay
	await get_tree().create_timer(1.0).timeout
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	Game.change_state(Game.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
