extends TrajectoryBehavior
class_name StationaryWallTrajectory
## [FUTURO/STUB] Trayectoria estacionaria (muro/barrera)
##
## La pelota permanece inmóvil en su posición de spawn.
## Actúa como muro defensivo que bloquea/aniquila proyectiles enemigos.
##
## Usado por:
## - Muros de tierra (habilidad defensiva)
## - Barreras elementales estáticas
## - Trampas estacionarias
##
## Comportamiento:
## - NO se mueve (velocity = Vector2.ZERO siempre)
## - Puede tener vida útil (lifetime) o ser permanente hasta destrucción
## - Interactúa con proyectiles enemigos mediante colisiones antimateria

@export var is_permanent: bool = false
@export var lifetime: float = 10.0

var elapsed_time: float = 0.0


func update_movement(ball: Node2D, delta: float) -> void:
	# TODO: Mantener pelota inmóvil
	if ball.has("velocity"):
		ball.velocity = Vector2.ZERO
	
	# TODO: Gestionar vida útil si no es permanente
	if not is_permanent:
		elapsed_time += delta
		if elapsed_time >= lifetime:
			if ball.has_method("queue_free"):
				ball.queue_free()


## Configurar como muro permanente o temporal
func initialize(permanent: bool = false, duration: float = 10.0) -> void:
	is_permanent = permanent
	lifetime = duration
	elapsed_time = 0.0
