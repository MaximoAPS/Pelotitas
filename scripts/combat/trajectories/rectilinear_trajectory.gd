extends TrajectoryBehavior
class_name RectilinearTrajectory
## [FUTURO/STUB] Trayectoria rectilínea uniforme (MRU)
##
## Movimiento en línea recta a velocidad constante.
## NO afectado por fuerzas externas (o mínimamente).
##
## Usado por:
## - Disparos elementales básicos (ElementalShot)
## - Proyectiles simples sin homing
##
## Propiedades:
## - Dirección fija establecida en spawn
## - Velocidad constante (puede basarse en masa: más masa = más lento, o ser fija)

@export var fixed_speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT


func update_movement(ball: Node2D, delta: float) -> void:
	# TODO: Mover pelota en línea recta
	# Opción A: velocidad fija (ignora masa)
	if ball.has("velocity"):
		ball.velocity = direction.normalized() * fixed_speed
	
	# Opción B futura: velocidad inversamente proporcional a masa
	# var adjusted_speed = fixed_speed / sqrt(ball.masa)
	# ball.velocity = direction.normalized() * adjusted_speed


## Configurar dirección y velocidad al spawn
func initialize(spawn_direction: Vector2, speed: float = 400.0) -> void:
	direction = spawn_direction.normalized()
	fixed_speed = speed
