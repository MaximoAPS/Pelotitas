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

var is_server: bool = false
var local_peer_id: int = 1


func _ready() -> void:
	print("[Net] Autoload inicializado")
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)


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
	print("[Net] Servidor creado en puerto %d, peer_id: %d" % [port, local_peer_id])
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
	print("[Net] Desconectado")


## Helper: verifica si este nodo tiene autoridad de red
func has_authority(node: Node) -> bool:
	return node.is_multiplayer_authority()


func _on_peer_connected(id: int) -> void:
	print("[Net] Peer conectado: %d" % id)
	peer_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	print("[Net] Peer desconectado: %d" % id)
	peer_disconnected.emit(id)


func _on_server_disconnected() -> void:
	print("[Net] Desconectado del servidor")
	server_disconnected.emit()


func _on_connection_failed() -> void:
	print("[Net] Falló la conexión")
	connection_failed.emit()
