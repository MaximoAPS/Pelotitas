extends Node2D
## Isolated collision probe: coasting player rams a stationary one.

const PLAYER_SCENE = preload("res://scenes/duel/player_prefab.tscn")


func _ready() -> void:
	var p1: Player = PLAYER_SCENE.instantiate()
	var p2: Player = PLAYER_SCENE.instantiate()
	p1.name = "P1"
	p2.name = "P2"
	p1.position = Vector2(400, 400)
	p2.position = Vector2(430, 400)
	p1.speed_m_s = 2.0
	p2.speed_m_s = 2.0
	p1.velocity = Vector2(300, 0)
	p2.velocity = Vector2.ZERO
	add_child(p1)
	add_child(p2)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("[CollisionProbe] p1_speed=%.1f p2_speed=%.1f" % [p1.velocity.length(), p2.velocity.length()])
	get_tree().quit()
