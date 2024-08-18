class_name PlayerBody
extends Node2D


const POTENTIAL_CONNECTION_INDICATOR_SCENE := preload("res://scenes/player/potential_connection_indicator.tscn")

var attaching := false

var parts: Array[Part] = []
# Dictionary<AttachPoint, PotentialConnectionOverlap>
var potential_connection_overlaps := {}

var total_mass := 0.0

func _ready() -> void:
	add_root_part()


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

	for connection in sub_part.child_connections:
		_add_attached_sub_part(connection.child.part)


func add_root_part() -> void:
	var core_part: Part = Global.part_type_to_packed_scene(
		Global.PartType.Core,
		Global.level.current_growth_level).instantiate()
	core_part.looks_for_nearby_connections_when_entering_tree = false
	add_child(core_part)


func destroy_part(part: Part) -> void:
	assert(is_instance_valid(part))
	assert(parts.has(part), "destroy_part: Player does not have part.")

	_remove_sub_part(part)

	for connection in part.child_connections:
		part.remove_child_connection(connection)
	if is_instance_valid(part.parent_connection):
		part.parent_connection.parent.part.remove_child_connection(part.parent_connection)

	part.queue_free()


func _remove_sub_part(part: Part) -> void:
	assert(is_instance_valid(part))
	assert(parts.has(part), "_remove_sub_part: Player does not have part.")

	part.attached_to_player = false
	parts.erase(part)

	for child in part.children:
		_remove_sub_part(child)


func on_part_added(part: Part) -> void:
	total_mass += part.mass
	assert(total_mass > 0)

	var collision_shape := CollisionShape2D.new()
	Global.player.add_child(collision_shape)

	call_deferred("deferred_on_part_added", part, collision_shape)


func deferred_on_part_added(part: Part, collision_shape: CollisionShape2D) -> void:
	var healthbox_collision_shape := part.get_healthbox_collision_shape()
	collision_shape.shape = healthbox_collision_shape.shape
	collision_shape.global_transform = healthbox_collision_shape.global_transform
	part.player_collision_shape_instance = collision_shape


func on_part_removed(part: Part) -> void:
	Global.player.remove_child(part.player_collision_shape_instance)
	part.player_collision_shape_instance = null

	total_mass -= part.mass
	assert(total_mass >= 0)


func attach_part(overlap: PotentialConnectionOverlap) -> void:
	call_deferred("attach_part_deferred", overlap)


func attach_part_deferred(overlap: PotentialConnectionOverlap) -> void:
	assert(is_instance_valid(overlap.attached_point) and
		is_instance_valid(overlap.detached_point) and
		overlap.attached_point.part.attached_to_player)

	_remove_potential_overlap_mapping(overlap.attached_point)

	if overlap.detached_point.part.attached_to_player:
		# Already attached from another AttachPoint this frame.
		return

	var old_parent_node := overlap.detached_point.part.get_parent()
	assert(old_parent_node is Drop)

	attaching = true

	# Re-orient the part subtree such that the newly-attached part is the root.
	overlap.detached_point.part.reassign_parent_connection(null)

	_add_attached_sub_part(overlap.detached_point.part)

	overlap.attached_point.part.add_child_connection(overlap.attached_point, overlap.detached_point)

	attaching = false

	old_parent_node.queue_free()

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


class PotentialConnectionOverlap extends RefCounted:
	var attached_point: AttachPoint
	var detached_point: AttachPoint
	var indicator: PotentialConnectionIndicator
