extends Node
class_name Loadout
## Contenedor de habilidades equipadas: 3 usables + 1 pasiva

const MAX_USABLE_ABILITIES = 3
const MAX_PASSIVE_ABILITIES = 1

var usable_abilities: Array[UsableAbility] = []
var passive_ability: PassiveAbility = null
var owner_player: Player = null


func _ready() -> void:
	usable_abilities.resize(MAX_USABLE_ABILITIES)


## Equipa una habilidad usable en un slot (0-2)
func equip_usable(ability: UsableAbility, slot: int) -> bool:
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


## Usa una habilidad del slot (0-2)
func use_ability(slot: int) -> bool:
	if slot < 0 or slot >= MAX_USABLE_ABILITIES:
		return false
	
	var ability = usable_abilities[slot]
	if not ability:
		return false
	
	if not owner_player:
		push_error("[Loadout] No hay owner_player asignado")
		return false
	
	return ability.try_use(owner_player)


## Limpia todos los slots
func clear_loadout() -> void:
	usable_abilities.clear()
	usable_abilities.resize(MAX_USABLE_ABILITIES)
	
	if passive_ability and owner_player:
		passive_ability.remove(owner_player)
	passive_ability = null
