extends Node
## Autoload para preferencias locales del usuario
##
## Responsabilidades:
## - Guardar/cargar nickname local (sin backend)
## - Persistir configuración en user://
## - Proveer acceso global a preferencias

const SAVE_PATH = "user://user_prefs.cfg"

var nickname: String = ""


func _ready() -> void:
	print("[UserPrefs] Autoload inicializado")
	load_prefs()


## Carga preferencias desde disco
func load_prefs() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		nickname = config.get_value("user", "nickname", "")
		print("[UserPrefs] Preferencias cargadas: nickname='%s'" % nickname)
	else:
		print("[UserPrefs] No se encontraron preferencias guardadas, usando defaults")
		# Generar nickname por defecto
		nickname = "Jugador%d" % randi_range(1000, 9999)
		save_prefs()


## Guarda preferencias a disco
func save_prefs() -> void:
	var config = ConfigFile.new()
	config.set_value("user", "nickname", nickname)
	
	var err = config.save(SAVE_PATH)
	if err == OK:
		print("[UserPrefs] Preferencias guardadas")
	else:
		push_error("[UserPrefs] Error al guardar preferencias: %d" % err)


## Establece el nickname del usuario
func set_nickname(new_nickname: String) -> void:
	nickname = new_nickname.strip_edges()
	if nickname.is_empty():
		nickname = "Jugador%d" % randi_range(1000, 9999)
	save_prefs()
