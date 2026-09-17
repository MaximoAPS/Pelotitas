extends Node
## Autoload para sistema de progresión y afinidad elemental
##
## Diccionarios internos siguen el shape de PelotitaData.to_dict().
## Las fórmulas viven en GameRules para no divergir del GDD.

signal level_up(pelotita_id: String, new_level: int, skill_point_element: Element)
signal skill_learned(pelotita_id: String, skill_id: String)

enum Element {
	FUEGO,
	AGUA,
	TIERRA,
	AIRE
}

## Datos de progresión de cada pelotita (key: pelotita_id)
var pelotitas_data: Dictionary = {}
var selected_id: String = ""
const ROSTER_PATH := "user://pelotitas.cfg"
const ROSTER_CAP := 1


func _ready() -> void:
	print("[Progression] Autoload inicializado")
	ensure_roster()


## Crea una nueva pelotita con pesos de afinidad y stats de creación
func create_pelotita(pelotita_id: String) -> Dictionary:
	var bonus: PackedInt32Array = GameRules.distribute_points(GameRules.CREATE_STAT_BONUS, 3)
	var data = {
		"id": pelotita_id,
		"level": 1,
		"experience": 0,
		"affinity_weights": GameRules.roll_affinity_weights(),
		"skill_points": {
			Element.FUEGO: 0,
			Element.AGUA: 0,
			Element.TIERRA: 0,
			Element.AIRE: 0
		},
		"learned_skills": [],
		"ataque": GameRules.CREATE_STAT_BASE + bonus[0],
		"defensa": GameRules.CREATE_STAT_BASE + bonus[1],
		"velocidad": float(GameRules.CREATE_STAT_BASE + bonus[2]),
		"masa": GameRules.DEFAULT_MASA,
		"bonus_hp": 0,
	}
	GameRules.apply_vitality_roll(data)
	var el := GameRules.dominant_element(data.affinity_weights)
	data["learned_skills"] = [GameRules.basic_shot_id(el)]
	data["dominant_element"] = el
	pelotitas_data[pelotita_id] = data
	if selected_id.is_empty():
		selected_id = pelotita_id
	print("[Progression] Pelotita creada: %s, dominante: %s" % [pelotita_id, GameRules.element_label(el)])
	return data


func _roll_affinity_weights() -> Dictionary:
	return GameRules.roll_affinity_weights()


func grant_experience(pelotita_id: String, amount: int) -> void:
	if not pelotitas_data.has(pelotita_id):
		push_error("[Progression] Pelotita no encontrada: %s" % pelotita_id)
		return
	var data = pelotitas_data[pelotita_id]
	data.experience += amount
	while data.level < GameRules.LEVEL_CAP_TIER_1 and data.experience >= xp_required_for_level(data.level + 1):
		data.experience -= xp_required_for_level(data.level + 1)
		_level_up(pelotita_id)


func award_xp_for_match(pelotita_id: String, won: bool, opponent_level: int) -> Dictionary:
	var xp_gained: int = GameRules.XP_LOSS
	if not pelotitas_data.has(pelotita_id):
		return {"xp_gained": 0, "level_ups": [], "capped": false}
	var data = pelotitas_data[pelotita_id]
	if won:
		xp_gained = calculate_win_xp(data.level, opponent_level)
	var before_level: int = data.level
	grant_experience(pelotita_id, xp_gained)
	var level_ups: Array[int] = []
	for lv in range(before_level + 1, data.level + 1):
		level_ups.append(lv)
	_save_roster()
	return {
		"xp_gained": xp_gained,
		"level_ups": level_ups,
		"capped": data.level >= GameRules.LEVEL_CAP_TIER_1
	}


func calculate_win_xp(your_level: int, opponent_level: int) -> int:
	return GameRules.calculate_win_xp(your_level, opponent_level)


func xp_required_for_level(level: int) -> int:
	return _calculate_exp_for_level(level)


func _level_up(pelotita_id: String) -> void:
	var data = pelotitas_data[pelotita_id]
	data.level += 1
	var stats: PackedInt32Array = GameRules.distribute_points(GameRules.LEVELUP_STAT_POINTS, 3)
	data.ataque += stats[0]
	data.defensa += stats[1]
	data.velocidad += float(stats[2])
	var vitality := GameRules.apply_vitality_roll(data)
	var element = _roll_element_by_affinity(data.affinity_weights)
	data.skill_points[element] += 1
	print("[Progression] ¡Level up! %s -> Nivel %d, +1 punto de %s, +%s" % [pelotita_id, data.level, Element.keys()[element], vitality])
	level_up.emit(pelotita_id, data.level, element)


func _roll_element_by_affinity(weights: Dictionary) -> Element:
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	if total_weight <= 0:
		return Element.FUEGO
	var roll = randi_range(1, total_weight)
	var cumulative = 0
	for element in weights:
		cumulative += weights[element]
		if roll <= cumulative:
			return element
	return Element.FUEGO


func _calculate_exp_for_level(level: int) -> int:
	return GameRules.xp_required_for_level(level)


func learn_skill(pelotita_id: String, skill_id: String, required_element: Element, cost: int) -> bool:
	if not pelotitas_data.has(pelotita_id):
		return false
	var data = pelotitas_data[pelotita_id]
	if data.skill_points[required_element] < cost:
		print("[Progression] Puntos insuficientes para aprender %s" % skill_id)
		return false
	data.skill_points[required_element] -= cost
	data.learned_skills.append(skill_id)
	skill_learned.emit(pelotita_id, skill_id)
	print("[Progression] Habilidad aprendida: %s" % skill_id)
	return true


func to_pelotita_data(pelotita_id: String) -> PelotitaData:
	if not pelotitas_data.has(pelotita_id):
		return null
	return PelotitaData.from_dict(pelotitas_data[pelotita_id])


func selected_pelotita() -> Dictionary:
	if selected_id.is_empty() or not pelotitas_data.has(selected_id):
		ensure_roster()
	return pelotitas_data.get(selected_id, {})


func selected_element() -> int:
	var data: Dictionary = selected_pelotita()
	if data.has("dominant_element"):
		return int(data.dominant_element)
	return GameRules.dominant_element(data.get("affinity_weights", {}))


func combat_payload() -> Dictionary:
	var payload := GameRules.combat_stats_from(selected_pelotita())
	payload["nickname"] = UserPrefs.nickname
	payload["element"] = selected_element()
	return payload


func ensure_roster() -> void:
	_load_roster()
	var before := pelotitas_data.size()
	_prune_roster()
	if pelotitas_data.is_empty():
		create_pelotita("starter")
		selected_id = "starter"
		_save_roster()
	elif selected_id.is_empty() or not pelotitas_data.has(selected_id):
		selected_id = str(pelotitas_data.keys()[0])
		_save_roster()
	elif pelotitas_data.size() != before:
		_save_roster()


func _prune_roster() -> void:
	if pelotitas_data.size() <= ROSTER_CAP:
		if selected_id.is_empty() and not pelotitas_data.is_empty():
			selected_id = str(pelotitas_data.keys()[0])
		return
	if selected_id.is_empty() or not pelotitas_data.has(selected_id):
		selected_id = str(pelotitas_data.keys()[0])
	var keep := {}
	keep[selected_id] = pelotitas_data[selected_id]
	pelotitas_data = keep


func select_pelotita(pelotita_id: String) -> void:
	if not pelotitas_data.has(pelotita_id):
		return
	selected_id = pelotita_id
	_save_roster()


func reset_pelotita(pelotita_id: String) -> Dictionary:
	if pelotita_id.is_empty():
		return {}
	var data := create_pelotita(pelotita_id)
	selected_id = pelotita_id
	_save_roster()
	return data


func _save_roster() -> void:
	_prune_roster()
	var config := ConfigFile.new()
	config.set_value("roster", "selected", selected_id)
	config.set_value("roster", "json", JSON.stringify(pelotitas_data))
	config.save(ROSTER_PATH)


func _load_roster() -> void:
	var config := ConfigFile.new()
	if config.load(ROSTER_PATH) != OK:
		return
	selected_id = str(config.get_value("roster", "selected", ""))
	var parsed: Variant = JSON.parse_string(str(config.get_value("roster", "json", "{}")))
	if parsed is Dictionary:
		pelotitas_data = parsed
		for pid in pelotitas_data.keys():
			var data: Dictionary = pelotitas_data[pid]
			if data.has("affinity_weights") and data.affinity_weights is Dictionary:
				data.affinity_weights = _int_keys(data.affinity_weights)
			if data.has("skill_points") and data.skill_points is Dictionary:
				data.skill_points = _int_keys(data.skill_points)
			if not data.has("dominant_element"):
				data.dominant_element = GameRules.dominant_element(data.get("affinity_weights", {}))


func _int_keys(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src.keys():
		out[int(k)] = src[k]
	return out
