extends CanvasLayer
## Pantalla de resultados: muestra victoria/derrota y permite reiniciar o volver al menú

@onready var result_title = $CenterContainer/Panel/VBoxContainer/ResultTitle
@onready var winner_label = $CenterContainer/Panel/VBoxContainer/WinnerLabel


func _ready() -> void:
	hide()


## Muestra los resultados del duelo
func show_results(winner_id: int, local_player_id: int = 1) -> void:
	var winner_name = ""
	
	if winner_id == -1:
		result_title.text = "¡EMPATE!"
		winner_label.text = "Nadie ganó"
	elif winner_id == local_player_id:
		result_title.text = "¡GANASTE!"
		winner_label.text = "Victoria"
	else:
		result_title.text = "PERDISTE"
		winner_label.text = "Derrota"
	
	show()
	print("[ResultsScreen] Mostrando resultados: winner_id=%d" % winner_id)


func _on_restart_pressed() -> void:
	print("[ResultsScreen] Reiniciando duelo...")
	
	var mode = DueloPorVida.new()
	Game.start_duel(mode)
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	print("[ResultsScreen] Volviendo al menú principal...")
	
	Game.change_state(Game.GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
