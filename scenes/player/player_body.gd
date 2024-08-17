class_name PlayerBody
extends Node


const CORE_PART_SCENE := preload("res://scenes/parts/core_part.tscn")
const BASIC_GUN_PART_SCENE := preload("res://scenes/parts/basic_gun_part.tscn")
const POTENTIAL_CONNECTION_INDICATOR_SCENE := preload("res://scenes/parts/potential_connection_indicator.tscn")

var parts: Array[Part] = []
# Dictionary<AttachPoint, PotentialConnectionOverlap>
var potential_connection_overlaps := {}


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
	sub_part.reparent(self)
	parts.push_back(sub_part)
	sub_part.attached_to_player = true

	for connection in sub_part.child_connections:
		_add_attached_sub_part(connection.child.part)


func add_root_part() -> void:
	var core_part: Part = part_type_to_packed_scene(Part.Type.Core).instantiate()
	parts.push_back(core_part)
	add_child(core_part)
	core_part.attached_to_player = true

	# TODO: Remove this extra part.
	var gun_part: Part = part_type_to_packed_scene(Part.Type.BasicGun).instantiate()
	parts.push_back(gun_part)
	add_child(gun_part)
	# FIXME: LEFT OFF HERE: Update add_child_connection to adjust the transforms of all newly-connected sub-parts to snap accordingly to fit the new AttachPoint Connection.
	gun_part.position = Vector2(16.0, 0.0)
	var core_part_attach_point := core_part.get_node("RightAttachPoint")
	var gun_part_attach_point := gun_part.get_node("LeftAttachPoint")
	core_part.add_child_connection(core_part_attach_point, gun_part_attach_point)


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


func part_type_to_packed_scene(type: Part.Type) -> PackedScene:
	match type:
		Part.Type.Core:
			return CORE_PART_SCENE
		Part.Type.BasicGun:
			return BASIC_GUN_PART_SCENE
		_:
			assert(false)
			return null


func attach_part(overlap: PotentialConnectionOverlap) -> void:
	assert(overlap.is_valid())

	Sfx.play(Sfx.PARTS_CONNECTED)

	_remove_potential_overlap_mapping(overlap.attached_point)

	# Re-orient the part subtree such that the newly-attached part is the root.
	overlap.detached_point.part.reassign_parent_connection(null)

	overlap.attached_point.part.add_child_connection(overlap.attached_point, overlap.detached_point)

	_add_attached_sub_part(overlap.detached_point.part)


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
		# This should have been caught by the check above.
		assert(overlap.detached_point != detached_point)
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

	func is_valid() -> bool:
		return (
			is_instance_valid(attached_point) and
			is_instance_valid(detached_point) and
			attached_point.part.attached_to_player and
			!detached_point.part.attached_to_player
			)
