extends Node2D
## Headless probe: player coasts into a box and bounces. Logs speed vs initial.


func _ready() -> void:
	var wall_thickness := 40.0
	var origin := Vector2(200, 200)
	var size := Vector2(400, 400)
	_add_wall("Top", Vector2(origin.x + size.x * 0.5, origin.y), Vector2(size.x, wall_thickness))
	_add_wall("Bottom", Vector2(origin.x + size.x * 0.5, origin.y + size.y), Vector2(size.x, wall_thickness))
	_add_wall("Left", Vector2(origin.x, origin.y + size.y * 0.5), Vector2(wall_thickness, size.y))
	_add_wall("Right", Vector2(origin.x + size.x, origin.y + size.y * 0.5), Vector2(wall_thickness, size.y))

	var player: Player = (load("res://scenes/duel/player_prefab.tscn") as PackedScene).instantiate()
	player.name = "ProbePlayer"
	player.position = origin + size * 0.5
	player.speed_m_s = 1.5
	player.velocity = Vector2(280, 160)
	add_child(player)

	var initial := player.velocity.length()
	var max_seen := initial
	for frame in range(180):
		await get_tree().physics_frame
		var speed := player.velocity.length()
		if speed > max_seen:
			max_seen = speed
	var grew := max_seen > initial + 1.0
	print("[WallBounceProbe] initial=%.1f max_seen=%.1f grew=%s" % [initial, max_seen, grew])
	get_tree().quit(1 if grew else 0)


func _add_wall(wall_name: String, center: Vector2, extents: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = wall_name
	body.position = center
	var shape := RectangleShape2D.new()
	shape.size = extents
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
