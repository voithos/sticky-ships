class_name Thruster
extends Node2D

# The propulsion contribution
@export var propulsion := 0.5

@export var animated_sprite: AnimatedSprite2D

func get_thrust_vector() -> Vector2:
	# Pointing up (_away_ from the direction of engine exhaust)
	return Vector2.from_angle(global_rotation - PI/2)

func set_is_thrusting(is_thrusting: bool):
	if is_thrusting:
		animated_sprite.play("thrust")
	else:
		animated_sprite.play("idle")
