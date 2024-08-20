class_name PlayerBody
extends Node2D


const POTENTIAL_CONNECTION_INDICATOR_SCENE := preload("res://scenes/player/potential_connection_indicator.tscn")

var attaching := false

var core_part: Part
var parts: Array[Part] = []
# Dictionary<AttachPoint, PotentialConnectionOverlap>
var potential_connection_overlaps := {}

var total_mass := 0.0
var growth_progress := 0.0
var growth_progress_ratio := 0.0


func _ready() -> void:
	set_core(Session.current_growth_level)


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attach"):
		attach_overlapping_parts()


func attach_overlapping_parts() -> void:
	var overlaps: Array[PotentialConnectionOverlap] = []
	for attached_point in potential_connection_overlaps:
		overlaps.push_back(potential_connection_overlaps[attached_point])
	for overlap in overlaps:
		attach_part(overlap)


func _add_attached_sub_part(sub_part: Part) -> void:
	sub_part.looks_for_nearby_connections_when_entering_tree = false
	sub_part.reparent(self)
	move_child(sub_part, 0)

	for connection in sub_part.child_connections:
		_add_attached_sub_part(connection.child.part)


func set_core(growth_level: int) -> void:
	clear_parts()

	var config: Dictionary = Config.get_current_level_config(growth_level)
	core_part = config.core_scene.instantiate()
	add_child(core_part)

	core_part.health.health_changed.connect(_on_core_health_changed)
	_update_part_stats()
	_update_health_display()


func _on_core_health_changed(new_health: float, prev_health: float) -> void:
	_update_health_display()


func _update_health_display() -> void:
	var health_ratio := (
		core_part.health.health / core_part.health.max_health if
		is_instance_valid(core_part) else
		0.0)
	if Global.hud:
		Global.hud.set_health_ratio(health_ratio)


func _update_growth_display() -> void:
	if Global.is_at_max_growth_level():
		if Global.hud:
			Global.hud.disable_growth()
		return

	if Global.hud:
		Global.hud.set_growth_ratio(growth_progress_ratio)


func _update_total_mass() -> void:
	total_mass = parts.reduce(
		func (accum, part): return accum + part.mass
	, 0)


func _update_growth_progress() -> void:
	growth_progress = parts.reduce(func (accum, part):
		return accum + part.growth_progress_value
	, 0)
	growth_progress_ratio = growth_progress / Config.get_growth_progress_to_next_level(Session.current_growth_level)


func _update_part_stats() -> void:
	_update_total_mass()
	_update_growth_progress()
	_update_growth_display()


func get_bounding_box() -> Rect2:
	if !is_instance_valid(core_part):
		return Rect2()
	var bounds := core_part.get_bounding_box()
	for part in parts:
		bounds = bounds.merge(part.get_bounding_box())
	return bounds


func get_core_sprite_size() -> Vector2:
	if is_instance_valid(core_part):
		return core_part.get_sprite_size()
	else:
		return Vector2.ZERO


func clear_parts() -> void:
	for part in parts:
		part.on_removed()
		part.queue_free()
	parts.clear()
	core_part = null


func remove_too_small_parts(growth_level: int) -> void:
	var too_small_parts := parts.filter(func (part: Part): return part.growth_level < growth_level - 1)
	for part in too_small_parts:
		destroy_part(part)


func destroy_part(part: Part) -> void:
	part.destroy()
	_update_part_stats()


func on_part_added(part: Part) -> void:
	part.on_attached()

	var collision_shape := CollisionShape2D.new()
	Global.player.add_child(collision_shape)

	if is_instance_valid(part.player_collision_shape_instance):
		part.player_collision_shape_instance.queue_free()

	call_deferred("on_part_added_deferred", part, collision_shape)


func on_part_added_deferred(part: Part, collision_shape: CollisionShape2D) -> void:
	var healthbox_collision_shape := part.get_healthbox_collision_shape()
	collision_shape.shape = healthbox_collision_shape.shape
	collision_shape.global_transform = healthbox_collision_shape.global_transform
	part.player_collision_shape_instance = collision_shape


func attach_part(overlap: PotentialConnectionOverlap) -> void:
	call_deferred("attach_part_deferred", overlap)


func attach_part_deferred(overlap: PotentialConnectionOverlap) -> void:
	assert(is_instance_valid(overlap.attached_point) and
		is_instance_valid(overlap.detached_point) and
		overlap.attached_point.part.attached_to_player)

	_remove_potential_overlap_mapping(overlap.attached_point)

	if (overlap.detached_point.part.attached_to_player or
		is_instance_valid(overlap.detached_point.connection) or
		is_instance_valid(overlap.attached_point.connection)):
		# Already attached from another AttachPoint this frame.
		return

	var old_parent_node := overlap.detached_point.part.get_parent()
	assert(old_parent_node is PartsDrop)

	attaching = true

	# Re-orient the part subtree such that the newly-attached part is the root.
	overlap.detached_point.part.reassign_parent_connection(null)

	_add_attached_sub_part(overlap.detached_point.part)

	overlap.attached_point.part.add_child_connection(overlap.attached_point, overlap.detached_point)

	_update_part_stats()

	attaching = false

	assert(Global.level.drops.has(old_parent_node))
	Global.level.drops.erase(old_parent_node)
	old_parent_node.queue_free()

	overlap.attached_point.stop_animation()
	overlap.detached_point.stop_animation()

	if growth_progress_ratio >= 1:
		Global.level.level_up()

	Sfx.play(Sfx.PARTS_CONNECTED)


func on_potential_attach_point_overlap_started(point_a: AttachPoint, point_b: AttachPoint) -> void:
	if point_a.part.attached_to_player == point_b.part.attached_to_player:
		# The parts have already been attached (from the area_entered event on the
		# other AttachPoint this frame).
		return

	var attached_point: AttachPoint
	var detached_point: AttachPoint
	if point_a.part.attached_to_player:
		attached_point = point_a
		detached_point = point_b
	else:
		attached_point = point_b
		detached_point = point_a

	if potential_connection_overlaps.has(attached_point):
		var overlap: PotentialConnectionOverlap = potential_connection_overlaps[attached_point]
		if overlap.detached_point == detached_point:
			# Already recorded this overlap from the other AttachPoint's
			# on-intersection event.
			return
		# This might be because a different possible fallen AttachPoint was recorded.
		_remove_potential_overlap_mapping(attached_point)

	var overlap := PotentialConnectionOverlap.new()
	overlap.attached_point = attached_point
	overlap.detached_point = detached_point

	if Input.is_action_pressed("attach"):
		attach_part(overlap)
	else:
		potential_connection_overlaps[attached_point] = overlap

		var indicator := POTENTIAL_CONNECTION_INDICATOR_SCENE.instantiate()
		add_child(indicator)
		indicator.global_position = lerp(attached_point.global_position, detached_point.global_position, 0.5)
		overlap.indicator = indicator

		Sfx.play(Sfx.CONNECTION_AVAILABLE)


func on_potential_attach_point_overlap_ended(point_a: AttachPoint, point_b: AttachPoint) -> void:
	assert(point_a.part.attached_to_player != point_b.part.attached_to_player)

	_remove_potential_overlap_mapping(point_a)
	_remove_potential_overlap_mapping(point_b)


func _remove_potential_overlap_mapping(point: AttachPoint) -> void:
	if potential_connection_overlaps.has(point):
		var overlap: PotentialConnectionOverlap = potential_connection_overlaps[point]
		assert(is_instance_valid(overlap.indicator))
		overlap.indicator.queue_free()
		potential_connection_overlaps.erase(point)
