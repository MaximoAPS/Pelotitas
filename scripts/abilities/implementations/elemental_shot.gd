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


func execute(caster: Player, aim_direction: Vector2) -> void:
	if not caster:
		return
	
	# Spawn del proyectil elemental
	var projectile = PROJECTILE_SCENE.instantiate()
	
	# Configurar el proyectil
	if projectile is Projectile:
		projectile.speed = projectile_speed
		projectile.lifetime = projectile_lifetime
		
		# Color según elemento
		_apply_element_color(projectile)
		
		# Posición inicial: delante del caster
		var spawn_offset = aim_direction.normalized() * 32.0
		projectile.global_position = caster.global_position + spawn_offset
		
		# Inicializar con stats del caster y referencia a esta habilidad
		projectile.initialize(
			projectile.global_position,
			aim_direction,
			caster.get_multiplayer_authority(),
			caster.ataque,
			self,  # source_ability
			caster  # source_player
		)
		
		# Agregar a la escena
		caster.get_parent().add_child(projectile)
		
		print("[ElementalShot] %s disparó %s hacia %v" % [caster.pelotita_id, ability_name, aim_direction])


func _apply_element_color(projectile: Node2D) -> void:
	# Aplicar color visual según elemento
	var sprite = projectile.get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = projectile_color
