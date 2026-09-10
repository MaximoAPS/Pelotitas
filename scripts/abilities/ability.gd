extends Resource
class_name Ability
## Clase base abstracta para habilidades
##
## Jerarquía:
## - Ability (base)
##   - UsableAbility (activables: disparos, invocaciones, muros)
##   - PassiveAbility (pasivas: stats, efectos permanentes)

@export var ability_id: String = ""
@export var ability_name: String = ""
@export var element: Progression.Element = Progression.Element.FUEGO
@export var icon_path: String = ""
@export var description: String = ""

## Requisitos para aprender
@export var required_skills: Array[String] = []
@export var skill_point_cost: int = 1


## Verifica si el jugador puede aprender esta habilidad
func can_learn(pelotita_data: Dictionary) -> bool:
	# Verificar prerrequisitos
	for req_skill in required_skills:
		if not req_skill in pelotita_data.learned_skills:
			return false
	
	# Verificar puntos disponibles
	if pelotita_data.skill_points[element] < skill_point_cost:
		return false
	
	return true


## Llamado cuando se aprende la habilidad
func on_learn() -> void:
	pass


## Override en subclases
func get_ability_type() -> String:
	return "base"


## ========================================
## Sistema de Triggers
## ========================================

## Trigger: Al equipar la habilidad (inicio de loadout)
func on_equip(_player: Player) -> void:
	pass


## Trigger: Al iniciar el match
func on_match_start(_player: Player) -> void:
	pass


## Trigger: Al colisionar con otro jugador
func on_collide_player(self_player: Player, other_player: Player) -> void:
	pass


## Trigger: Al colisionar con pared
func on_collide_wall(player: Player, impact_point: Vector2, wall_normal: Vector2) -> void:
	pass
