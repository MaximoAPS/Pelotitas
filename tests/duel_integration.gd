extends Node
## Integration probes for duel wiring.

const DueloPorVidaScript = preload("res://scripts/modes/duelo_por_vida.gd")


func _ready() -> void:
	var mode = DueloPorVidaScript.new()
	Game.start_duel(mode)
	var arena = load("res://scenes/duel/arena_duelo.tscn").instantiate()
	add_child(arena)
	await get_tree().process_frame
	await get_tree().physics_frame

	var players_node: Node = arena.get_node("Players")
	var p1: Player = players_node.get_node("Player1")
	var dummy: Player = players_node.get_node("Player2Dummy")

	TouchInput.start_ability_aim(0, Vector2.ZERO, 0)
	TouchInput.update_ability_aim(Vector2(80, 0))
	TouchInput.fire_ability()
	await get_tree().process_frame

	p1.global_position = Vector2(960, 540)
	dummy.global_position = Vector2(980, 540)
	p1.velocity = Vector2(200, 0)
	dummy.velocity = Vector2(-200, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	dummy.take_damage(999, 1)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
