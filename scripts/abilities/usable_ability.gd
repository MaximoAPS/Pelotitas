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


## Intenta usar la habilidad con dirección de apuntado
func try_use(caster: Player, aim_direction: Vector2 = Vector2.RIGHT) -> bool:
	if not can_use():
		return false
	
	last_use_time = Time.get_ticks_msec() / 1000.0
	on_activate(caster, aim_direction)
	execute(caster, aim_direction)
	return true


func can_use() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - last_use_time) >= cooldown


func get_cooldown_remaining() -> float:
	var current_time = Time.get_ticks_msec() / 1000.0
	var remaining = cooldown - (current_time - last_use_time)
	return max(0.0, remaining)


## Override en habilidades concretas
## aim_direction: dirección normalizada en la que el jugador apuntó (desde press-hold-drag-release)
func execute(caster: Player, aim_direction: Vector2) -> void:
	push_warning("[UsableAbility] execute() no implementado para %s" % ability_id)
	print("[UsableAbility] Dirección de apuntado: %v" % aim_direction)
	# TODO: Implementar en subclases usando aim_direction:
	# - Spawns de proyectiles en aim_direction
	# - Invocación de summons facing aim_direction
	# - Creación de muros perpendiculares a aim_direction
	# - Efectos de área centrados en caster + aim_direction offset


## ========================================
## Triggers adicionales para UsableAbility
## ========================================

## Trigger: Al activar/usar la habilidad (después de pasar cooldown)
func on_activate(caster: Player, aim_direction: Vector2) -> void:
	pass


## Trigger: Cuando un proyectil de esta habilidad impacta enemigo
## Llamado desde el proyectil mismo
func on_hit_enemy(caster: Player, target: Player, projectile: Node2D) -> void:
	pass
