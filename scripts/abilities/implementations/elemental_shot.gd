extends UsableAbility
class_name ElementalShot
## Disparo elemental básico
##
## Mecánica unificada para los 4 elementos (fuego, agua, tierra, viento)
## Diferenciados solo por elemento y color
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
	
	# Solo el authority spawnea proyectiles
	if not Net.has_authority(caster):
		return
	
	# Obtener la arena para spawning
	var arena = caster.get_tree().root.get_node_or_null("ArenaDuelo")
	if not arena:
		push_error("[ElementalShot] No se encontró ArenaDuelo en la escena")
		return
	
	# Calcular datos del proyectil
	var spawn_offset = aim_direction.normalized() * 32.0
	var spawn_pos = caster.global_position + spawn_offset
	
	# Si somos el servidor o hay conexión de red, usar RPC para replicar
	if multiplayer.has_multiplayer_peer():
		arena._spawn_projectile_networked.rpc(
			spawn_pos,
			aim_direction,
			caster.get_multiplayer_authority(),
			caster.ataque,
			projectile_speed,
			projectile_lifetime,
			projectile_color,
			caster.pelotita_id
		)
	else:
		# Modo local sin red
		_spawn_local_projectile(arena, spawn_pos, aim_direction, caster)


func _apply_element_color(projectile: Node2D) -> void:
	# Aplicar color visual según elemento
	var sprite = projectile.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = projectile_color


## Helper local para spawning sin red
func _spawn_local_projectile(arena: Node, spawn_pos: Vector2, aim_direction: Vector2, caster) -> void:  # caster is Player type
	var projectile = PROJECTILE_SCENE.instantiate()
	
	if projectile is Projectile:
		projectile.speed = projectile_speed
		projectile.lifetime = projectile_lifetime
		
		_apply_element_color(projectile)
		
		projectile.initialize(
			spawn_pos,
			aim_direction,
			caster.get_multiplayer_authority(),
			caster.ataque,
			self,
			caster
		)
		
		arena.spawn_projectile(projectile)
		
		print("[ElementalShot] %s disparó %s hacia %v" % [caster.pelotita_id, ability_name, aim_direction])
