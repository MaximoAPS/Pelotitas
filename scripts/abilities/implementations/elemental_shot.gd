extends UsableAbility
class_name ElementalShot
## Disparo elemental básico. Números por elemento: GameRules.shot_*.
##
## ⚠️ FUTURO: Migrará a spawnnear BallBody con RectilinearTrajectory
## en lugar de Projectile para aprovechar sistema de antimateria y masa

const PROJECTILE_SCENE = preload("res://scenes/combat/projectile_elemental.tscn")

@export var projectile_speed: float = 400.0
@export var projectile_lifetime: float = 3.0
@export var projectile_color: Color = Color.WHITE


func execute(caster, aim_direction: Vector2) -> void:  # caster is Player type
	if not caster:
		return
	if Net.is_networked() and not Net.has_authority(caster):
		return
	var arena = _find_arena(caster)
	if not arena:
		push_error("[ElementalShot] No se encontró ArenaDuelo en la escena")
		return
	var spawn_offset = aim_direction.normalized() * GameRules.PROJECTILE_SPAWN_OFFSET
	var spawn_pos = caster.global_position + spawn_offset
	var el := int(element)
	var d := GameRules.shot_damage_for(el)
	var masa := GameRules.shot_masa_for(el)
	var speed_px := GameRules.shot_speed_px(caster.speed_m_s * GameRules.PIXELS_PER_METER, el)
	if Net.is_networked():
		arena._spawn_projectile_networked.rpc(
			spawn_pos,
			aim_direction,
			caster.get_multiplayer_authority(),
			caster.ataque,
			el,
			d,
			masa,
			speed_px
		)
	else:
		_spawn_local_projectile(arena, spawn_pos, aim_direction, caster, el, d, masa, speed_px)


## Helper local para spawning sin red
func _spawn_local_projectile(arena: Node, spawn_pos: Vector2, aim_direction: Vector2, caster, el: int, d: int, masa: float, speed_px: float) -> void:
	var projectile = PROJECTILE_SCENE.instantiate()
	if projectile is Projectile:
		var sprite = projectile.get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = GameRules.shot_color(el)
		projectile.initialize(
			spawn_pos,
			aim_direction,
			caster.get_multiplayer_authority(),
			caster.ataque,
			self,
			caster,
			el,
			d,
			masa,
			speed_px
		)
		arena.spawn_projectile(projectile)
		print("[ElementalShot] %s disparó %s hacia %v" % [caster.pelotita_id, ability_name, aim_direction])


func _find_arena(caster: Node) -> Node:
	var tree := caster.get_tree()
	if tree == null:
		return null
	var direct = tree.root.get_node_or_null("ArenaDuelo")
	if direct:
		return direct
	return tree.root.find_child("ArenaDuelo", true, false)
