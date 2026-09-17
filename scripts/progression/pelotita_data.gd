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
@export var ataque: int = 50
@export var defensa: int = 50
@export var velocidad: float = 50.0
@export var masa: float = 1.0
@export var bonus_hp: int = 0


## Crear nueva pelotita con pesos de afinidad aleatorios
static func create_new(id: String) -> PelotitaData:
	var data = PelotitaData.new()
	data.pelotita_id = id
	data.affinity_weights = GameRules.roll_affinity_weights()
	var bonus: PackedInt32Array = GameRules.distribute_points(GameRules.CREATE_STAT_BONUS, 3)
	data.ataque = GameRules.CREATE_STAT_BASE + bonus[0]
	data.defensa = GameRules.CREATE_STAT_BASE + bonus[1]
	data.velocidad = float(GameRules.CREATE_STAT_BASE + bonus[2])
	data.masa = GameRules.DEFAULT_MASA
	data.bonus_hp = 0
	var rolled := {"masa": data.masa, "bonus_hp": 0}
	GameRules.apply_vitality_roll(rolled)
	data.masa = float(rolled.masa)
	data.bonus_hp = int(rolled.bonus_hp)
	var el := GameRules.dominant_element(data.affinity_weights)
	var learned: Array[String] = []
	learned.append(GameRules.basic_shot_id(el))
	data.learned_skills = learned
	return data


static func _roll_affinity_weights() -> Dictionary:
	return GameRules.roll_affinity_weights()


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
		"masa": masa,
		"bonus_hp": bonus_hp
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
	data.ataque = dict.get("ataque", GameRules.CREATE_STAT_BASE)
	data.defensa = dict.get("defensa", GameRules.CREATE_STAT_BASE)
	data.velocidad = dict.get("velocidad", GameRules.CREATE_STAT_BASE)
	data.masa = dict.get("masa", GameRules.DEFAULT_MASA)
	data.bonus_hp = dict.get("bonus_hp", 0)
	return data
