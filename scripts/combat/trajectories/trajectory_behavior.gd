extends Resource
class_name TrajectoryBehavior
## [FUTURO/STUB] Clase base abstracta para comportamientos de trayectoria de pelotas elementales
##
## Arquitectura pluggable: cada BallBody tiene un TrajectoryBehavior que controla su movimiento.
##
## Ejemplos concretos:
## - RectilinearTrajectory: Movimiento rectilíneo uniforme (disparos básicos)
## - ChaseTargetTrajectory: Perseguir jugador rival (summons)
## - StationaryWallTrajectory: Inmóvil (muros defensivos)
##
## Este diseño permite agregar nuevos patrones de movimiento sin modificar BallBody.

## Override en subclases: actualizar velocidad/posición de la pelota cada frame
func update_movement(ball: Node2D, delta: float) -> void:
	push_warning("[TrajectoryBehavior] update_movement() no implementado en subclase")
	# TODO: Implementar en clases concretas
	pass


## Helper: obtener jugador rival más cercano (útil para trayectorias de persecución)
func _get_nearest_enemy_player(ball: Node2D) -> Node2D:
	# TODO: Buscar jugadores en la escena, filtrar por equipo rival, devolver el más cercano
	return null


## Helper: aplicar fuerza direccional a la pelota (respeta masa)
func _apply_directional_force(ball: Node2D, direction: Vector2, force_magnitude: float) -> void:
	if not ball.has_method("apply_force"):
		return
	
	var force = direction.normalized() * force_magnitude
	ball.apply_force(force)
