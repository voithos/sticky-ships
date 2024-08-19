class_name PartsDrop
extends Drop


var parts: Array[Part] = []


func _ready() -> void:
	super()
	Global.level.drops.push_back(self)


func _exit_tree() -> void:
	for part in parts:
		_on_part_removed(part)


func remove_part(part: Part) -> void:
	parts.erase(part)
	remove_child(part)


func on_part_added(part: Part) -> void:
	part.on_detached()

	var collision_shape := CollisionShape2D.new()
	collision_shape.shape = part.get_healthbox_collision_shape().shape

	if is_instance_valid(part.player_collision_shape_instance):
		part.player_collision_shape_instance.queue_free()

	call_deferred("deferred_on_part_added", part, collision_shape)


func deferred_on_part_added(part: Part, collision_shape: CollisionShape2D) -> void:
	add_child(collision_shape)
	collision_shape.global_transform = part.get_healthbox_collision_shape().global_transform
	part.player_collision_shape_instance = collision_shape


func _on_part_removed(part: Part) -> void:
	if is_instance_valid(part.player_collision_shape_instance):
		part.player_collision_shape_instance.queue_free()
	part.player_collision_shape_instance = null
