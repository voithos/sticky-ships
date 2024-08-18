class_name PartsDrop
extends Drop


var parts: Array[Part] = []


func _ready() -> void:
	super()
	Global.level.drops.push_back(self)


func remove_part(part: Part) -> void:
	parts.erase(part)
	remove_child(part)


func on_part_added(part: Part) -> void:
	var healthbox_collision_shape := part.get_healthbox_collision_shape()
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = healthbox_collision_shape.shape
	call_deferred("deferred_on_part_added", part, collision_shape, healthbox_collision_shape.global_transform)


func deferred_on_part_added(part: Part, collision_shape: CollisionShape2D, global_transform: Transform2D) -> void:
	add_child(collision_shape)
	collision_shape.global_transform = global_transform
	part.player_collision_shape_instance = collision_shape


func on_part_removed(part: Part) -> void:
	remove_child(part.player_collision_shape_instance)
	part.player_collision_shape_instance = null
