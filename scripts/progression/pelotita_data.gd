extends Resource
class_name PelotitaData
## [FUTURO/STUB] Recurso tipado para datos de progresión de pelotitas
##
## Reemplaza el Dictionary usado actualmente en Progression.gd
## para representar datos de pelotitas de forma más estructurada y type-safe.
##
## Migración gradual: Progression puede seguir usando Dictionary internamente
## y exponer PelotitaData mediante conversores, o migrar completamente.

enum Elemento {
	FUEGO,
	AGUA,
	TIERRA,
	AIRE
}

@export var pelotita_id: String = ""
@export var level: int = 1
@export var experience: int = 0

## Pesos de afinidad elemental (secretos, nunca mostrar al jugador)
## Estos determinan la probabilidad de recibir puntos de cada elemento al subir de nivel
## Suma total debe ser 100
@export var affinity_weights: Dictionary = {
	Elemento.FUEGO: 25,
	Elemento.AGUA: 25,
	Elemento.TIERRA: 25,
	Elemento.AIRE: 25
}

## Puntos de habilidad disponibles por elemento
@export var skill_points: Dictionary = {
	Elemento.FUEGO: 0,
	Elemento.AGUA: 0,
	Elemento.TIERRA: 0,
	Elemento.AIRE: 0
}

## IDs de habilidades aprendidas
@export var learned_skills: Array[String] = []

## Stats de combate base (pueden escalar con nivel)
@export var ataque: int = 10
@export var defensa: int = 5
@export var velocidad: float = 1.0
@export var masa: float = 1.0


## Crear nueva pelotita con pesos de afinidad aleatorios
static func create_new(id: String) -> PelotitaData:
	var data = PelotitaData.new()
	data.pelotita_id = id
	data.affinity_weights = _roll_affinity_weights()
	return data


## Generar pesos de afinidad aleatorios (suma 100)
static func _roll_affinity_weights() -> Dictionary:
	var total = 100
	var weights = {}
	
	# Distribución aleatoria simple
	weights[Elemento.FUEGO] = randi_range(10, 40)
	weights[Elemento.AGUA] = randi_range(10, 40)
	var remaining = total - weights[Elemento.FUEGO] - weights[Elemento.AGUA]
	weights[Elemento.TIERRA] = randi_range(10, min(40, remaining - 10))
	weights[Elemento.AIRE] = remaining - weights[Elemento.TIERRA]
	
	return weights


## Convertir a Dictionary (compatibilidad con sistema actual)
func to_dict() -> Dictionary:
	return {
		"id": pelotita_id,
		"level": level,
		"experience": experience,
		"affinity_weights": affinity_weights,
		"skill_points": skill_points,
		"learned_skills": learned_skills,
		"ataque": ataque,
		"defensa": defensa,
		"velocidad": velocidad,
		"masa": masa
	}


## Crear desde Dictionary (compatibilidad con sistema actual)
static func from_dict(dict: Dictionary) -> PelotitaData:
	var data = PelotitaData.new()
	data.pelotita_id = dict.get("id", "")
	data.level = dict.get("level", 1)
	data.experience = dict.get("experience", 0)
	data.affinity_weights = dict.get("affinity_weights", {})
	data.skill_points = dict.get("skill_points", {})
	data.learned_skills = dict.get("learned_skills", [])
	data.ataque = dict.get("ataque", 10)
	data.defensa = dict.get("defensa", 5)
	data.velocidad = dict.get("velocidad", 1.0)
	data.masa = dict.get("masa", 1.0)
	return data
