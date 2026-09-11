extends Node
## Autoload para sistema de progresión y afinidad elemental
##
## Responsabilidades:
## - Gestionar nivel y experiencia de pelotitas
## - Calcular subidas de nivel y puntos de habilidad
## - Aplicar sistema de afinidad (pesos elementales secretos)
## - Mantener y persistir árboles de habilidades
##
## ⚠️ FUTURO: Migrar de Dictionary a PelotitaData Resource
## Ver scripts/progression/pelotita_data.gd para versión tipada

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


func _ready() -> void:
	print("[Progression] Autoload inicializado")
	# TODO: Cargar datos persistentes de pelotitas


## Crea una nueva pelotita con pesos de afinidad aleatorios
func create_pelotita(pelotita_id: String) -> Dictionary:
	var affinity_weights = _roll_affinity_weights()
	
	var data = {
		"id": pelotita_id,
		"level": 1,
		"experience": 0,
		"affinity_weights": affinity_weights,  # Secreto, nunca mostrar al jugador
		"skill_points": {
			Element.FUEGO: 0,
			Element.AGUA: 0,
			Element.TIERRA: 0,
			Element.AIRE: 0
		},
		"learned_skills": []
	}
	
	pelotitas_data[pelotita_id] = data
	print("[Progression] Pelotita creada: %s, afinidad: %s" % [pelotita_id, affinity_weights])
	return data


## Genera pesos de afinidad permanentes (al estilo DinoRPG)
func _roll_affinity_weights() -> Dictionary:
	# TODO: Implementar generación aleatoria balanceada que sume 100
	# Ejemplo temporal (debería ser aleatorio):
	var total = 100
	var weights = {}
	
	# Distribución aleatoria simple
	weights[Element.FUEGO] = randi_range(10, 40)
	weights[Element.AGUA] = randi_range(10, 40)
	var remaining = total - weights[Element.FUEGO] - weights[Element.AGUA]
	weights[Element.TIERRA] = randi_range(10, min(40, remaining - 10))
	weights[Element.AIRE] = remaining - weights[Element.TIERRA]
	
	return weights


## Otorga experiencia y maneja subida de nivel
func grant_experience(pelotita_id: String, amount: int) -> void:
	if not pelotitas_data.has(pelotita_id):
		push_error("[Progression] Pelotita no encontrada: %s" % pelotita_id)
		return
	
	var data = pelotitas_data[pelotita_id]
	data.experience += amount
	
	# TODO: Calcular nivel desde experiencia, detectar level-up
	var exp_for_next_level = _calculate_exp_for_level(data.level + 1)
	
	if data.experience >= exp_for_next_level:
		_level_up(pelotita_id)


## Sube de nivel y otorga punto de habilidad elemental según afinidad
func _level_up(pelotita_id: String) -> void:
	var data = pelotitas_data[pelotita_id]
	data.level += 1
	
	# Elegir elemento según pesos de afinidad
	var element = _roll_element_by_affinity(data.affinity_weights)
	data.skill_points[element] += 1
	
	print("[Progression] ¡Level up! %s -> Nivel %d, +1 punto de %s" % [pelotita_id, data.level, Element.keys()[element]])
	level_up.emit(pelotita_id, data.level, element)


## Tira elemento según pesos de afinidad (aleatorio ponderado)
func _roll_element_by_affinity(weights: Dictionary) -> Element:
	var total_weight = 0
	for weight in weights.values():
		total_weight += weight
	
	var roll = randi_range(1, total_weight)
	var cumulative = 0
	
	for element in weights:
		cumulative += weights[element]
		if roll <= cumulative:
			return element
	
	return Element.FUEGO  # Fallback


func _calculate_exp_for_level(level: int) -> int:
	# TODO: Fórmula de experiencia balanceada
	return level * 100


## Aprende una habilidad si el jugador tiene puntos suficientes
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
