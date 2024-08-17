class_name PartsDrop
extends Drop


var parts: Array[Part] = []


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func add_part(part: Part, is_reparenting := false) -> void:
	parts.push_back(part)
	if is_reparenting:
		part.reparent(self)
	else:
		add_child(part)


func remove_part(part: Part) -> void:
	parts.erase(part)
	remove_child(part)


func on_part_added(part: Part) -> void:
	var healthbox_collision_shape := part.get_healthbox_collision_shape()
	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = healthbox_collision_shape.shape
	add_child(collision_shape)
	collision_shape.global_transform = healthbox_collision_shape.global_transform
	part.player_collision_shape_instance = collision_shape


func on_part_removed(part: Part) -> void:
	remove_child(part.player_collision_shape_instance)
	part.player_collision_shape_instance = null
