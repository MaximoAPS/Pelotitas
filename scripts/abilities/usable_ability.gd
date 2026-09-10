extends Ability
class_name UsableAbility
## Habilidad activable (se usa presionando tecla)
##
## Ejemplos: disparos elementales, invocar summon, crear muro

@export var cooldown: float = 1.0
@export var mana_cost: int = 0

var last_use_time: float = -999.0


func get_ability_type() -> String:
	return "usable"


## Intenta usar la habilidad
func try_use(caster: Player) -> bool:
	if not can_use():
		return false
	
	last_use_time = Time.get_ticks_msec() / 1000.0
	execute(caster)
	return true


func can_use() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - last_use_time) >= cooldown


func get_cooldown_remaining() -> float:
	var current_time = Time.get_ticks_msec() / 1000.0
	var remaining = cooldown - (current_time - last_use_time)
	return max(0.0, remaining)


## Override en habilidades concretas
func execute(caster: Player) -> void:
	push_warning("[UsableAbility] execute() no implementado para %s" % ability_id)
	# TODO: Implementar en subclases:
	# - Spawns de proyectiles
	# - Invocación de summons
	# - Creación de muros
	# - Efectos de área
