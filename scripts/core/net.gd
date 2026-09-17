extends Node
## Autoload para manejo de red y multiplayer
##
## Responsabilidades:
## - Configurar ENetMultiplayerPeer (servidor/cliente)
## - Gestionar autoridad de red (network authority)
## - Sincronizar estado entre jugadores
## - Proveer helpers para RPCs y replicación

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal server_disconnected()
signal connection_failed()
signal connection_succeeded()
signal peer_reported_arena_ready(peer_id: int)

var is_server: bool = false
var local_peer_id: int = 1
var connected_peers: Dictionary = {}  # peer_id -> {nickname: String}
var server_ip: String = ""
var arena_ready_peers: Dictionary = {}
var last_error_text: String = ""


func _ready() -> void:
	print("[Net] Autoload inicializado")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


## Godot 4.6+ always has OfflineMultiplayerPeer, so peer == null is never true.
func is_networked() -> bool:
	return multiplayer.multiplayer_peer is ENetMultiplayerPeer


func is_offline() -> bool:
	return not is_networked()


func error_text(error: Error) -> String:
	match error:
		ERR_CANT_CREATE:
			return "no se pudo abrir el puerto"
		ERR_ALREADY_IN_USE:
			return "puerto ocupado"
		ERR_CANT_CONNECT:
			return "no se pudo conectar"
		ERR_TIMEOUT:
			return "tiempo agotado"
		ERR_BUSY:
			return "conexión ocupada"
		_:
			return "código %d" % error


func sanitize_address(raw: String) -> String:
	var address := raw.strip_edges().replace(" ", "").replace(",", ".")
	address = address.replace("。", ".")
	return address


func is_probable_ipv4(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
		var n := int(part)
		if n < 0 or n > 255:
			return false
	return true


## Crea un servidor local para pruebas o host
func create_server(port: int = GameRules.DEFAULT_LAN_PORT, max_clients: int = 2) -> Error:
	disconnect_peer()
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_clients)
	
	if error != OK:
		last_error_text = "No se pudo crear servidor: %s" % error_text(error)
		print("[Net] %s" % last_error_text)
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	local_peer_id = multiplayer.get_unique_id()
	server_ip = _get_local_ip()
	
	# Registrar el propio servidor como peer
	connected_peers[local_peer_id] = Progression.combat_payload()
	arena_ready_peers.clear()
	
	print("[Net] Servidor creado en %s:%d, peer_id: %d" % [server_ip, port, local_peer_id])
	return OK


## Conecta como cliente a un servidor
func join_server(address: String = "127.0.0.1", port: int = GameRules.DEFAULT_LAN_PORT) -> Error:
	address = sanitize_address(address)
	disconnect_peer()
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		last_error_text = "No se pudo unir a %s:%d (%s)" % [address, port, error_text(error)]
		print("[Net] %s" % last_error_text)
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	print("[Net] Conectando a %s:%d..." % [address, port])
	return OK


## Cierra la conexión actual
func disconnect_peer() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_server = false
	connected_peers.clear()
	arena_ready_peers.clear()
	server_ip = ""
	print("[Net] Desconectado")


## Helper: verifica si este nodo tiene autoridad de red
func has_authority(node: Node) -> bool:
	return node.is_multiplayer_authority()


func _on_peer_connected(id: int) -> void:
	print("[Net] Peer conectado: %d" % id)
	
	# Si somos el servidor, solicitar nickname del nuevo peer
	if is_server:
		connected_peers[id] = {"nickname": "Jugador%d" % id, "element": 0, "ataque": GameRules.CREATE_STAT_BASE, "defensa": GameRules.CREATE_STAT_BASE, "velocidad": float(GameRules.CREATE_STAT_BASE), "masa": GameRules.DEFAULT_MASA, "level": 1}
	
	# Si somos cliente y nos conectamos, enviar nuestro nickname al servidor
	if not is_server and id == 1:
		_register_nickname.rpc_id(1, Progression.combat_payload())
	
	peer_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	print("[Net] Peer desconectado: %d" % id)
	connected_peers.erase(id)
	peer_disconnected.emit(id)


func _on_server_disconnected() -> void:
	print("[Net] Desconectado del servidor")
	connected_peers.clear()
	server_disconnected.emit()


func _on_connection_failed() -> void:
	last_error_text = "No se pudo conectar. Misma WiFi, IP y puerto %d." % GameRules.DEFAULT_LAN_PORT
	print("[Net] Falló la conexión")
	disconnect_peer()
	connection_failed.emit()


func _on_connected_to_server() -> void:
	print("[Net] Conectado al servidor exitosamente")
	local_peer_id = multiplayer.get_unique_id()
	# Enviar nickname al servidor
	_register_nickname.rpc_id(1, Progression.combat_payload())
	connection_succeeded.emit()


## IPv4 locales útiles para LAN (WiFi / hotspot).
func get_lan_ips() -> PackedStringArray:
	var result: PackedStringArray = []
	for addr in IP.get_local_addresses():
		if _is_lan_ipv4(addr) and addr not in result:
			result.append(addr)
	return result


func _is_lan_ipv4(addr: String) -> bool:
	if addr.contains(":"):
		return false
	if addr.begins_with("127.") or addr.begins_with("169.254."):
		return false
	if addr.begins_with("192.168.") or addr.begins_with("10."):
		return true
	if addr.begins_with("172."):
		var parts := addr.split(".")
		if parts.size() != 4:
			return false
		var second := int(parts[1])
		return second >= 16 and second <= 31
	return false


## Obtiene la IP local de la máquina
func _get_local_ip() -> String:
	var lan := get_lan_ips()
	if lan.size() > 0:
		return lan[0]
	var addresses = IP.get_local_addresses()
	for addr in addresses:
		if not addr.contains(":") and not addr.begins_with("127."):
			return addr
	return "127.0.0.1"


## RPC: Registra nickname + ATK/DEF/SPD del peer en el servidor
@rpc("any_peer", "reliable")
func _register_nickname(payload: Dictionary) -> void:
	if not is_server:
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var info := GameRules.combat_stats_from(payload)
	info["nickname"] = str(payload.get("nickname", "Jugador%d" % sender_id))
	info["element"] = int(payload.get("element", 0))
	connected_peers[sender_id] = info
	print("[Net] Peer %d registrado como '%s' (%s) ATK %s DEF %s SPD %s" % [
		sender_id, info.nickname, GameRules.element_label(int(info.element)),
		info.ataque, info.defensa, info.velocidad,
	])


@rpc("any_peer", "reliable")
func rpc_arena_ready() -> void:
	if not is_server:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = local_peer_id
	arena_ready_peers[sender_id] = true
	peer_reported_arena_ready.emit(sender_id)
