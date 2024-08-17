class_name Thruster
extends Node2D

# The propulsion contribution
@export var propulsion := 0.5

func get_thrust_vector() -> Vector2:
	# Pointing up (_away_ from the direction of engine exhaust)
	return Vector2.from_angle(global_rotation - PI/2)
