class_name Drop
extends RigidBody2D


@export var growth_level := 1


func _init() -> void:
	add_to_group(Config.DROPS_GROUP)


func _exit_tree() -> void:
	if Global.level.drops.has(self):
		Global.level.drops.erase(self)
