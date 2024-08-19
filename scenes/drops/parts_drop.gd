class_name PartsDrop
extends Drop


var parts: Array[Part] = []


func _ready() -> void:
	Global.level.drops.push_back(self)


func _exit_tree() -> void:
	super()
	for part in parts:
		part.on_removed()


func remove_too_small_parts(growth_level: int) -> void:
	var too_small_parts := parts.filter(func (part: Part): return part.growth_level < growth_level - 1)
	for part in too_small_parts:
		part.destroy()


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
