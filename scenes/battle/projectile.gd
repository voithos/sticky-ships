class_name Projectile
extends Area2D

# The speed of motion.
@export var speed := 200.0
# The damage inflicted.
@export var damage := 10.0

var direction := Vector2.ZERO
# The entity that shot this projectile
var shooter: Node


func _ready() -> void:
	direction = -GSAIUtils.angle_to_vector2(rotation)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_area_entered(area: Area2D):
	die()


func _on_body_entered(body: Node2D):
	die()


func die() -> void:
	print('died')
	queue_free()
