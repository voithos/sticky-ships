class_name Drop
extends RigidBody2D


@export var growth_level := 1


func _init() -> void:
	add_to_group(Global.DROPS_GROUP)
