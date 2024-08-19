class_name Projectile
extends Area2D


@export var growth_level := 1
# The speed of motion.
@export var speed := 200.0
# The damage inflicted.
@export var damage := 1.0

@export var visibility_notifier: VisibleOnScreenNotifier2D
@export var explosion_effect_scene: PackedScene

var direction := Vector2.ZERO
# The entity that shot this projectile
var shooter: Node


func _init() -> void:
	add_to_group(Global.PROJECTILES_GROUP)


func _ready() -> void:
	direction = -GSAIUtils.angle_to_vector2(rotation)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	if visibility_notifier:
		visibility_notifier.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_area_entered(area: Area2D):
	maybe_do_damage(area)


func _on_body_entered(body: Node2D):
	maybe_do_damage(body)


func maybe_do_damage(to: Node2D) -> void:
	if to is Hurtbox:
		to.maybe_take_damage(self)
	die()


func die() -> void:
	if explosion_effect_scene:
		var fx := explosion_effect_scene.instantiate()
		fx.global_position = global_position
		add_sibling(fx)
	queue_free()
