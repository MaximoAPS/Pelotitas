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

var is_server: bool = false
var local_peer_id: int = 1
var connected_peers: Dictionary = {}  # peer_id -> {nickname: String}
var server_ip: String = ""


func _ready() -> void:
	print("[Net] Autoload inicializado")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)


## Crea un servidor local para pruebas o host
func create_server(port: int = 7777, max_clients: int = 2) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_clients)
	
	if error != OK:
		push_error("[Net] Error al crear servidor: %d" % error)
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	local_peer_id = multiplayer.get_unique_id()
	server_ip = _get_local_ip()
	
	# Registrar el propio servidor como peer
	connected_peers[local_peer_id] = {"nickname": UserPrefs.nickname}
	
	print("[Net] Servidor creado en %s:%d, peer_id: %d" % [server_ip, port, local_peer_id])
	return OK


## Conecta como cliente a un servidor
func join_server(address: String = "127.0.0.1", port: int = 7777) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		push_error("[Net] Error al conectar: %d" % error)
		return error
	
	multiplayer.multiplayer_peer = peer
	is_server = false
	# El peer_id será asignado por el servidor
	print("[Net] Conectando a %s:%d..." % [address, port])
	return OK


## Cierra la conexión actual
func disconnect_peer() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_server = false
	connected_peers.clear()
	server_ip = ""
	print("[Net] Desconectado")


## Helper: verifica si este nodo tiene autoridad de red
func has_authority(node: Node) -> bool:
	return node.is_multiplayer_authority()


func _on_peer_connected(id: int) -> void:
	print("[Net] Peer conectado: %d" % id)
	
	# Si somos el servidor, solicitar nickname del nuevo peer
	if is_server:
		connected_peers[id] = {"nickname": "Jugador%d" % id}
	
	# Si somos cliente y nos conectamos, enviar nuestro nickname al servidor
	if not is_server and id == 1:
		_register_nickname.rpc_id(1, UserPrefs.nickname)
	
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
	print("[Net] Falló la conexión")
	connection_failed.emit()


func _on_connected_to_server() -> void:
	print("[Net] Conectado al servidor exitosamente")
	local_peer_id = multiplayer.get_unique_id()
	# Enviar nickname al servidor
	_register_nickname.rpc_id(1, UserPrefs.nickname)
	connection_succeeded.emit()


## Obtiene la IP local de la máquina
func _get_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	
	# Filtrar por direcciones IPv4 que no sean localhost
	for addr in addresses:
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	
	# Fallback a localhost si no se encuentra IP local
	if addresses.size() > 0:
		return addresses[0]
	
	return "127.0.0.1"


## RPC: Registra el nickname de un peer en el servidor
@rpc("any_peer", "reliable")
func _register_nickname(nickname: String) -> void:
	if not is_server:
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	connected_peers[sender_id] = {"nickname": nickname}
	print("[Net] Peer %d registrado como '%s'" % [sender_id, nickname])
