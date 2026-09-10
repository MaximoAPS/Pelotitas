extends Ability
class_name PassiveAbility
## Habilidad pasiva (efecto permanente)
##
## Ejemplos: +10% velocidad, regeneración, resistencia elemental

@export var stat_modifiers: Dictionary = {}


func get_ability_type() -> String:
	return "passive"


## Aplicar el efecto pasivo al jugador
func apply(player: Player) -> void:
	push_warning("[PassiveAbility] apply() no implementado para %s" % ability_id)
	# TODO: Implementar modificación de stats
	# Ejemplos:
	# - player.move_speed *= stat_modifiers.get("speed_multiplier", 1.0)
	# - player.health_regen = stat_modifiers.get("health_regen", 0)


## Remover el efecto pasivo
func remove(player: Player) -> void:
	push_warning("[PassiveAbility] remove() no implementado para %s" % ability_id)
