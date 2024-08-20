class_name Drop
extends RigidBody2D


@export var growth_level := 1

@export var max_linear_speed := 30.0
@export var max_rotation_speed := 2
@export var linear_damp_override := 0.3
@export var angular_damp_override := 0.1


func _init() -> void:
	add_to_group(Config.DROPS_GROUP)


func _enter_tree() -> void:
	var linear_speed := randf() * max_linear_speed
	var linear_direction := Vector2.UP.rotated(randf() * TAU)
	linear_velocity = linear_direction * linear_speed

	var rotation_direction := -1 if randf() <= 0.5 else 1
	angular_velocity = randf() * max_rotation_speed * rotation_direction

	linear_damp = linear_damp_override
	angular_damp = angular_damp_override


func _exit_tree() -> void:
	if Global.level.drops.has(self):
		Global.level.drops.erase(self)
