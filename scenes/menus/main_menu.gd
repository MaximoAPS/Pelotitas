extends Control
## Menú principal: opciones para crear/unirse a partida o prueba local

@onready var host_dialog = $HostDialog
@onready var label_host_ip = $HostDialog/VBoxContainer/LabelIP
@onready var label_host_port = $HostDialog/VBoxContainer/LabelPort
@onready var label_waiting = $HostDialog/VBoxContainer/LabelWaiting
@onready var btn_start_duel = $HostDialog/VBoxContainer/BtnStartDuel
@onready var label_lan_status = $VBoxContainer/LabelLanStatus

var waiting_for_players: bool = false
var _join_panel: Control
var _join_ip_label: Label
var _ip_buffer: String = ""


func _ready() -> void:
	print("[MainMenu] Inicializando menú principal...")
	Net.peer_connected.connect(_on_peer_connected)
	Net.connection_succeeded.connect(_on_connection_succeeded)
	Net.connection_failed.connect(_on_connection_failed)
	btn_start_duel.disabled = true
	_build_join_panel()
	_connect_menu_buttons()
	print("[MainMenu] Menú listo - esperando input del usuario")


func _connect_menu_buttons() -> void:
	var btn_host = $VBoxContainer/BtnHostGame
	var btn_join = $VBoxContainer/BtnJoinGame
	var btn_local = $VBoxContainer/BtnLocalTest
	var btn_exit = $VBoxContainer/BtnExit
	var btn_pelotitas = $VBoxContainer/BtnPelotitas
	var btn_abilities = $VBoxContainer/BtnHabilidades
	if not btn_host.pressed.is_connected(_on_host_game_pressed):
		btn_host.pressed.connect(_on_host_game_pressed)
	if not btn_join.pressed.is_connected(_on_join_game_pressed):
		btn_join.pressed.connect(_on_join_game_pressed)
	if not btn_local.pressed.is_connected(_on_local_test_pressed):
		btn_local.pressed.connect(_on_local_test_pressed)
	if not btn_exit.pressed.is_connected(_on_exit_pressed):
		btn_exit.pressed.connect(_on_exit_pressed)
	if btn_pelotitas and not btn_pelotitas.pressed.is_connected(_on_pelotitas_pressed):
		btn_pelotitas.pressed.connect(_on_pelotitas_pressed)
	if btn_abilities and not btn_abilities.pressed.is_connected(_on_habilidades_pressed):
		btn_abilities.pressed.connect(_on_habilidades_pressed)


func _on_host_game_pressed() -> void:
	print("[MainMenu] Creando servidor...")
	
	var error = Net.create_server()
	if error != OK:
		label_lan_status.text = Net.last_error_text
		return
	var ips := Net.get_lan_ips()
	if ips.is_empty():
		label_host_ip.text = "IP Local: %s (¿WiFi apagado?)" % Net.server_ip
	else:
		label_host_ip.text = "IP LAN:\n%s" % "\n".join(ips)
	label_host_port.text = "Puerto: %d" % GameRules.DEFAULT_LAN_PORT
	label_waiting.text = "Esperando jugadores... (0/1)"
	btn_start_duel.disabled = true
	waiting_for_players = true
	label_lan_status.text = "Hosteando en puerto %d. Pasá la IP al otro celular." % GameRules.DEFAULT_LAN_PORT
	host_dialog.popup_centered()


func _on_join_game_pressed() -> void:
	print("[MainMenu] Mostrando panel de conexión...")
	_refresh_join_ip_label()
	_join_panel.visible = true


func _on_join_cancel_pressed() -> void:
	_join_panel.visible = false


func _append_join_ip(chunk: String) -> void:
	if _ip_buffer.length() + chunk.length() > 15:
		return
	_ip_buffer += chunk
	_refresh_join_ip_label()


func _backspace_join_ip() -> void:
	if _ip_buffer.is_empty():
		return
	_ip_buffer = _ip_buffer.substr(0, _ip_buffer.length() - 1)
	_refresh_join_ip_label()


func _refresh_join_ip_label() -> void:
	if _join_ip_label == null:
		return
	_join_ip_label.text = _ip_buffer if not _ip_buffer.is_empty() else "192.168.x.x"


func _on_join_dialog_confirmed() -> void:
	var ip = Net.sanitize_address(_ip_buffer)
	var port = GameRules.DEFAULT_LAN_PORT
	
	if ip.is_empty():
		label_lan_status.text = "Ingresá la IP LAN que muestra el host."
		_join_ip_label.text = "Falta la IP"
		return
	if not Net.is_probable_ipv4(ip):
		label_lan_status.text = "IP inválida: %s (ejemplo 192.168.0.10)" % ip
		_join_ip_label.text = "IP inválida"
		return
	if port <= 0:
		port = GameRules.DEFAULT_LAN_PORT
	
	label_lan_status.text = "Conectando a %s:%d..." % [ip, port]
	print("[MainMenu] Conectando a %s:%d..." % [ip, port])
	var error = Net.join_server(ip, port)
	if error != OK:
		label_lan_status.text = Net.last_error_text
		print("[MainMenu] Error al conectar: %s" % Net.last_error_text)
	else:
		_join_panel.visible = false


func _on_local_test_pressed() -> void:
	print("[MainMenu] Iniciando prueba local...")
	_start_test_duel()


func _on_exit_pressed() -> void:
	print("[MainMenu] Botón Exit presionado - cerrando juego...")
	get_tree().quit()


func _on_pelotitas_pressed() -> void:
	CollectionScreen.start_tab = 0
	get_tree().change_scene_to_file("res://scenes/menus/collection_screen.tscn")


func _on_habilidades_pressed() -> void:
	CollectionScreen.start_tab = 1
	get_tree().change_scene_to_file("res://scenes/menus/collection_screen.tscn")


func _on_start_duel_pressed() -> void:
	print("[MainMenu] Iniciando duelo multiplayer...")
	waiting_for_players = false
	host_dialog.hide()
	Game.rpc_load_arena.rpc()


func _on_peer_connected(peer_id: int) -> void:
	if waiting_for_players and Net.is_server:
		var connected_count = Net.connected_peers.size() - 1  # -1 porque el servidor se cuenta
		label_waiting.text = "Esperando jugadores... (%d/2)" % connected_count
		
		# Habilitar botón de iniciar cuando haya al menos 1 cliente
		if connected_count >= 1:
			btn_start_duel.disabled = false


func _on_connection_succeeded() -> void:
	print("[MainMenu] Conexión exitosa, esperando al host...")
	if _join_panel:
		_join_panel.visible = false
	label_lan_status.text = "Conectado. Esperá a que el host inicie el duelo."


func _on_connection_failed() -> void:
	print("[MainMenu] Conexión fallida")
	if Net.last_error_text.is_empty():
		label_lan_status.text = "No se pudo conectar. Misma WiFi, IP y puerto 7777."
	else:
		label_lan_status.text = Net.last_error_text


## Helper: inicia duelo
func _start_test_duel() -> void:
	print("[MainMenu] Iniciando duelo de prueba...")
	var mode = ModeRegistry.create_mode("duelo_por_vida")
	if mode == null:
		mode = DueloPorVida.new()
	Game.start_duel(mode)
	
	var error = get_tree().change_scene_to_file("res://scenes/duel/arena_duelo.tscn")
	if error != OK:
		push_error("[MainMenu] Error al cambiar escena: %d" % error)
	else:
		print("[MainMenu] Cambiando a escena de duelo...")


func _build_join_panel() -> void:
	_join_panel = ColorRect.new()
	_join_panel.name = "JoinPanel"
	_join_panel.visible = false
	_join_panel.color = Color(0.08, 0.1, 0.13, 0.96)
	_join_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_join_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_join_panel)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 48
	root.offset_top = 24
	root.offset_right = -48
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 12)
	_join_panel.add_child(root)

	var title := Label.new()
	title.text = "Unirse — escribí la IP del host"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	_join_ip_label = Label.new()
	_join_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_join_ip_label.add_theme_font_size_override("font_size", 48)
	_join_ip_label.custom_minimum_size = Vector2(0, 72)
	root.add_child(_join_ip_label)
	_refresh_join_ip_label()

	var shortcuts := HBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 12)
	root.add_child(shortcuts)
	shortcuts.add_child(_make_key_button("192.168.", _append_join_ip.bind("192.168."), Vector2(0, 64)))
	shortcuts.add_child(_make_key_button("10.", _append_join_ip.bind("10."), Vector2(0, 64)))
	shortcuts.add_child(_make_key_button("Borrar", _backspace_join_ip, Vector2(0, 64)))

	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0"]
	var row: HBoxContainer = null
	for i in keys.size():
		if i % 3 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			root.add_child(row)
		row.add_child(_make_key_button(keys[i], _append_join_ip.bind(keys[i]), Vector2(0, 72)))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 16)
	root.add_child(actions)
	actions.add_child(_make_key_button("Cancelar", _on_join_cancel_pressed, Vector2(0, 80)))
	actions.add_child(_make_key_button("Unirse", _on_join_dialog_confirmed, Vector2(0, 80)))


func _make_key_button(text: String, callback: Callable, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(callback)
	return btn
