extends TrajectoryBehavior
class_name ChaseTargetTrajectory
## [FUTURO/STUB] Trayectoria de persecución al jugador rival más cercano
##
## La pelota persigue continuamente al enemigo más cercano.
## Velocidad puede escalar con masa (más masa = más lenta).
##
## Usado por:
## - Invocaciones/summons elementales
## - Proyectiles teledirigidos
## - Minions de habilidades avanzadas
##
## Comportamiento:
## - Cada frame, recalcula dirección hacia enemigo más cercano
## - Aplica fuerza direccional (respeta inercia y masa)
## - Puede tener velocidad máxima

@export var chase_force: float = 500.0
@export var max_speed: float = 300.0
@export var mass_speed_factor: bool = true  # Si true, masa afecta velocidad


func update_movement(ball: Node2D, delta: float) -> void:
	# TODO: Buscar jugador enemigo más cercano
	var target = _get_nearest_enemy_player(ball)
	if not target:
		# No hay enemigos, quedarse quieto o vagar
		return
	
	# TODO: Calcular dirección hacia el target
	var direction_to_target = (target.global_position - ball.global_position).normalized()
	
	# TODO: Aplicar fuerza de persecución (respeta masa)
	_apply_directional_force(ball, direction_to_target, chase_force)
	
	# TODO: Limitar velocidad máxima si es necesario
	if ball.has("velocity") and max_speed > 0.0:
		if ball.velocity.length() > max_speed:
			ball.velocity = ball.velocity.normalized() * max_speed


## Configurar parámetros de persecución
func initialize(force: float = 500.0, max_vel: float = 300.0, use_mass_factor: bool = true) -> void:
	chase_force = force
	max_speed = max_vel
	mass_speed_factor = use_mass_factor
