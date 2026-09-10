extends Area2D
class_name Projectile
## Proyectil base para habilidades
##
## Responsabilidades:
## - Movimiento en dirección fija
## - Colisión y daño
## - Autoridad de red (solo el servidor simula física)

@export var speed: float = 300.0
@export var damage: int = 10
@export var lifetime: float = 5.0
@export var pierce: bool = false

var direction: Vector2 = Vector2.RIGHT
var owner_id: int = -1
var traveled_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not Net.has_authority(self):
		return  # Solo el authority mueve proyectiles
	
	position += direction * speed * delta
	traveled_time += delta
	
	if traveled_time >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not Net.has_authority(self):
		return
	
	if body is Player and body.get_multiplayer_authority() != owner_id:
		body.take_damage(damage, owner_id)
		
		if not pierce:
			queue_free()


func _on_area_entered(area: Area2D) -> void:
	# TODO: Colisión con otras entidades (muros, summons)
	pass


func initialize(spawn_pos: Vector2, spawn_dir: Vector2, owner_peer_id: int) -> void:
	position = spawn_pos
	direction = spawn_dir.normalized()
	owner_id = owner_peer_id
	
	# TODO: Configurar autoridad de red
