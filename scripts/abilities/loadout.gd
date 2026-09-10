extends Node
class_name Loadout
## Contenedor de habilidades equipadas: 3 usables + 1 pasiva

const MAX_USABLE_ABILITIES = 3
const MAX_PASSIVE_ABILITIES = 1

var usable_abilities  # Completely untyped variable
var passive_ability: PassiveAbility = null
var owner_player: Player = null


func _ready() -> void:
	# Initialize as untyped array
	usable_abilities = []
	usable_abilities.resize(MAX_USABLE_ABILITIES)


## Equipa una habilidad usable en un slot (0-2)
func equip_usable(ability, slot: int) -> bool:
	if slot < 0 or slot >= MAX_USABLE_ABILITIES:
		push_error("[Loadout] Slot inválido: %d" % slot)
		return false
	
	usable_abilities[slot] = ability
	print("[Loadout] Equipada habilidad usable: %s en slot %d" % [ability.ability_name, slot])
	return true


## Equipa una habilidad pasiva
func equip_passive(ability: PassiveAbility) -> bool:
	if passive_ability and owner_player:
		passive_ability.remove(owner_player)
	
	passive_ability = ability
	
	if owner_player:
		passive_ability.apply(owner_player)
	
	print("[Loadout] Equipada habilidad pasiva: %s" % ability.ability_name)
	return true


## Usa una habilidad del slot (0-2) con dirección de apuntado
func use_ability(slot: int, aim_direction: Vector2 = Vector2.RIGHT) -> bool:
	if slot < 0 or slot >= MAX_USABLE_ABILITIES:
		return false
	
	var ability = usable_abilities[slot]
	if not ability:
		return false
	
	if not owner_player:
		push_error("[Loadout] No hay owner_player asignado")
		return false
	
	return ability.try_use(owner_player, aim_direction)


## Limpia todos los slots
func clear_loadout() -> void:
	usable_abilities = []
	usable_abilities.resize(MAX_USABLE_ABILITIES)
	
	if passive_ability and owner_player:
		passive_ability.remove(owner_player)
	passive_ability = null


## ========================================
## Sistema de Triggers para Habilidades
## ========================================

## Trigger: Al equipar el loadout (inicio de match)
func trigger_on_equip() -> void:
	for ability in usable_abilities:
		if ability:
			ability.on_equip(owner_player)
	
	if passive_ability:
		passive_ability.on_equip(owner_player)


## Trigger: Al iniciar el match
func trigger_on_match_start() -> void:
	for ability in usable_abilities:
		if ability:
			ability.on_match_start(owner_player)
	
	if passive_ability:
		passive_ability.on_match_start(owner_player)


## Trigger: Al colisionar con otro jugador
func trigger_on_collide_player(self_player: Player, other_player: Player) -> void:
	for ability in usable_abilities:
		if ability:
			ability.on_collide_player(self_player, other_player)
	
	if passive_ability:
		passive_ability.on_collide_player(self_player, other_player)


## Trigger: Al colisionar con pared
func trigger_on_collide_wall(player: Player, impact_point: Vector2, wall_normal: Vector2) -> void:
	for ability in usable_abilities:
		if ability:
			ability.on_collide_wall(player, impact_point, wall_normal)
	
	if passive_ability:
		passive_ability.on_collide_wall(player, impact_point, wall_normal)
