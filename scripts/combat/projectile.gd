extends Area2D
class_name Projectile
## Proyectil base para habilidades
##
## Responsabilidades:
## - Movimiento en dirección fija
## - Colisión y daño
## - Autoridad de red (solo el servidor simula física)

@export var speed: float = 420.0
@export var base_damage: int = 10
@export var lifetime: float = 5.0
@export var pierce: bool = false
@export var knockback_strength: float = 280.0

var direction: Vector2 = Vector2.RIGHT
var owner_id: int = -1
var owner_ataque: int = 10
var traveled_time: float = 0.0

# Referencia a la habilidad que spawneó este proyectil (para triggers)
var source_ability: UsableAbility = null
var source_player: Player = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# Offline mode: allow movement without authority if no multiplayer peer
	var offline_mode = multiplayer.multiplayer_peer == null
	if not offline_mode and not Net.has_authority(self):
		return  # Solo el authority mueve proyectiles (excepto offline)
	
	position += direction * speed * delta
	traveled_time += delta
	
	if traveled_time >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Offline mode: allow collision without authority
	var offline_mode = multiplayer.multiplayer_peer == null
	if not offline_mode and not Net.has_authority(self):
		return
	
	# Don't damage source_player
	if body is Player and body != source_player:
		# Also check multiplayer authority for online mode
		if not offline_mode and body.get_multiplayer_authority() == owner_id:
			return
		
		# Calcular daño con fórmula: max(1, ataque - defensa * 0.5)
		var final_damage = max(1, owner_ataque - body.defensa * 0.5)
		
		# Calcular dirección de knockback (desde proyectil hacia víctima)
		var knockback_dir = (body.global_position - global_position).normalized()
		
		body.take_damage(int(final_damage), owner_id, knockback_dir, knockback_strength)
		
		# Trigger: on_hit_enemy
		if source_ability and source_player:
			source_ability.on_hit_enemy(source_player, body, self)
		
		if not pierce:
			queue_free()


func _on_area_entered(area: Area2D) -> void:
	# TODO: Colisión con otras entidades (muros, summons)
	pass


func initialize(spawn_pos: Vector2, spawn_dir: Vector2, owner_peer_id: int, ataque_stat: int = 10, ability: UsableAbility = null, player: Player = null) -> void:
	position = spawn_pos
	direction = spawn_dir.normalized()
	owner_id = owner_peer_id
	owner_ataque = ataque_stat
	source_ability = ability
	source_player = player
	
	# TODO: Configurar autoridad de red
