extends Area2D
class_name BallBody
## [FUTURO/STUB] Pelota elemental con masa para sistema de antimateria
##
## Esta clase es un STUB que define la arquitectura futura del sistema
## de combate basado en pelotas elementales con colisiones de antimateria.
##
## NO REEMPLAZA a Projectile en el MVP actual.
##
## Propiedades clave:
## - masa: Determina el resultado de colisiones antimateria
## - elemento: Fuego, Agua, Tierra, Aire (para modificadores de masa)
## - trajectory_behavior: Script pluggable que controla movimiento
## - owner_team: Equipo rival = antimateria, mismo equipo = potencial fusión

enum Elemento {
	FUEGO,
	AGUA,
	TIERRA,
	AIRE
}

@export var masa: float = 1.0
@export var elemento: Elemento = Elemento.FUEGO
@export var owner_team: int = -1
@export var owner_peer_id: int = -1

var velocity: Vector2 = Vector2.ZERO
var trajectory_behavior: TrajectoryBehavior = null


func _ready() -> void:
	# TODO: Conectar señales de colisión
	# TODO: Configurar visual según masa (tamaño) y elemento (color)
	pass


func _physics_process(delta: float) -> void:
	# TODO: Delegar movimiento al trajectory_behavior si existe
	if trajectory_behavior:
		trajectory_behavior.update_movement(self, delta)
	
	# TODO: Aplicar velocidad y manejar colisiones con física Godot
	position += velocity * delta


## TODO: Resolver colisión antimateria con otra BallBody rival
func resolve_antimatter_collision(other: BallBody) -> void:
	if other.owner_team == owner_team:
		return  # Mismo equipo, no es antimateria
	
	# 1. Calcular masas efectivas (aplicar modificadores elementales)
	var masa_efectiva_self = _calculate_effective_mass(elemento, other.elemento, masa)
	var masa_efectiva_other = _calculate_effective_mass(other.elemento, elemento, other.masa)
	
	# 2. Cancelar masas
	var masa_restante = abs(masa_efectiva_self - masa_efectiva_other)
	
	# 3. Determinar superviviente
	if masa_efectiva_self > masa_efectiva_other:
		# Self sobrevive
		masa = _revert_effective_mass(elemento, other.elemento, masa_restante)
		other.queue_free()
	elif masa_efectiva_other > masa_efectiva_self:
		# Other sobrevive
		other.masa = other._revert_effective_mass(other.elemento, elemento, masa_restante)
		queue_free()
	else:
		# Aniquilación total
		queue_free()
		other.queue_free()


## TODO: Calcular masa efectiva con modificadores elementales
func _calculate_effective_mass(attacker_element: Elemento, defender_element: Elemento, base_mass: float) -> float:
	return GameRules.effective_shot_mass(base_mass, int(attacker_element), int(defender_element))


## TODO: Revertir masa efectiva al factor normal después de cancelación
func _revert_effective_mass(attacker_element: Elemento, defender_element: Elemento, effective_mass: float) -> float:
	return GameRules.revert_shot_mass(effective_mass, int(attacker_element), int(defender_element))


## TODO: Matriz de ventajas elementales
func _get_element_advantage(attacker: Elemento, defender: Elemento) -> float:
	return GameRules.shot_mass_advantage(int(attacker), int(defender))


## TODO: Configurar comportamiento de trayectoria
func set_trajectory_behavior(behavior: TrajectoryBehavior) -> void:
	trajectory_behavior = behavior


## TODO: Aplicar fuerza (filosofía de fuerzas sobre masas)
func apply_force(force: Vector2) -> void:
	# Futuro: integrar con sistema de física de Godot (RigidBody2D)
	# Por ahora, aplicar fuerza dividida por masa como aceleración
	var acceleration = force / masa
	velocity += acceleration * get_physics_process_delta_time()


## TODO: Escalar tamaño visual según masa
func update_visual_scale() -> void:
	# Tamaño visual proporcional a raíz cuadrada de la masa
	# radio ∝ sqrt(masa)
	var base_radius = 16.0
	var scale_factor = sqrt(masa)
	scale = Vector2.ONE * scale_factor
