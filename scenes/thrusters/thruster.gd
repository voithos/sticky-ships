class_name Thruster
extends Node2D


@export var growth_level := 1

# The propulsion contribution
@export var propulsion := 0.5

@export var animated_sprite: AnimatedSprite2D

@onready var thruster_sfx = $Thruster_SFX


func get_thrust_vector() -> Vector2:
	# Pointing up (_away_ from the direction of engine exhaust)
	return Vector2.from_angle(global_rotation - PI/2)


func set_is_thrusting(is_thrusting: bool):
	if is_thrusting:
		animated_sprite.play("thrust")
		if !thruster_sfx.playing:
			thruster_sfx.play()

	else:
		animated_sprite.play("idle")
		if thruster_sfx.playing:
			thruster_sfx.stop()
