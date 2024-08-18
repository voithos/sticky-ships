class_name Part
extends Node2D

# The mass of this part, as a whole.
@export var mass: float = 0.5

var attached_to_player := false

var attach_points: Array[AttachPoint] = []

var parent_connection: Connection
var child_connections: Array[Connection] = []

var player_collision_shape_instance: CollisionShape2D

# Component constituents of this part. These are auto-registered.
var light_guns: Array[LightGun] = []
var heavy_guns: Array[HeavyGun] = []
var thrusters: Array[Thruster] = []

# Health is special, as there's only ever one
var health: HealthComponent = null
# TODO: Add thrusters, shields, heavy guns, etc


func _enter_tree() -> void:
	_init_shape()


func _ready() -> void:
	_init_components(self)


func _init_shape() -> void:
	var hurtbox = get_node("Hurtbox")
	assert(hurtbox != null and hurtbox is Hurtbox)
	assert(hurtbox.get_children().size() == 1 and hurtbox.get_children()[0] is CollisionShape2D)


func _init_components(node: Node) -> void:
	if node is HealthComponent:
		_init_health_component(node)
	elif node is LightGun:
		light_guns.push_back(node)
	elif node is HeavyGun:
		heavy_guns.push_back(node)
	elif node is Thruster:
		thrusters.push_back(node)

	for child in node.get_children():
		_init_components(child)


func _init_health_component(h: HealthComponent) -> void:
	assert(health == null)
	health = h
	health.health_depleted.connect(destroy_part)


func destroy_part() -> void:
	print('part destroyed!')
	queue_free()


func _process(delta: float) -> void:
	pass


func get_healthbox_collision_shape() -> CollisionShape2D:
	return get_node("Hurtbox").get_children()[0]


func get_all_descendants(out_descendants: Array[Part]) -> void:
	for connection in child_connections:
		out_descendants.append(connection.child.part)
		connection.get_all_descendants(out_descendants)


func add_child_connection(parent_point: AttachPoint, child_point: AttachPoint) -> void:
	assert(!is_instance_valid(child_point.part.parent_connection))
	assert(attach_points.has(parent_point))
	for connection in child_connections:
		assert(connection.parent != parent_point)
		assert(connection.child != child_point)
	for connection in child_point.part.child_connections:
		assert(connection.parent != child_point)
		assert(connection.child != parent_point)

	var connection := Connection.new(parent_point, child_point)
	child_connections.push_back(connection)
	child_point.part.parent_connection = connection

	child_point.part.attached_to_player = parent_point.part.attached_to_player

	# Snap the new part to align attachment points.
	var translation := parent_point.global_position - child_point.global_position
	child_point.part.translate_part(translation)


func remove_child_connection(connection: Connection) -> void:
	assert(child_connections.has(connection))
	assert(connection.parent == self)

	child_connections.erase(connection)
	connection.child.part.parent_connection = null
	connection.child.part.attached_to_player = false


func reassign_parent_connection(new_parent_connection: Connection) -> void:
	if parent_connection == new_parent_connection:
		# Already done.
		return

	var old_parent_connection := parent_connection
	var old_parent := old_parent_connection.parent if parent_connection != null else null
	var old_child := old_parent_connection.child if parent_connection != null else null

	parent_connection = new_parent_connection

	# Make sure this part no longer considers the new parent as a child.
	if new_parent_connection != null:
		var old_child_connection: Connection
		for connection in child_connections:
			if (connection.child.part == new_parent_connection.parent.part or
					connection.parent.part == new_parent_connection.parent.part):
				old_child_connection = connection
				break
		if old_child_connection != null:
			child_connections.erase(old_child_connection)

	if old_parent_connection == null:
		# We don't need to recurse to re-assign the old parent's connection since
		# this part used to be the root.
		return

	child_connections.push_back(old_parent_connection)

	# Update the old parent to now consider this part as its parent.
	old_parent_connection.parent = old_child
	old_parent_connection.child = old_parent
	old_parent.part.reassign_parent_connection(old_parent_connection)


func translate_part(translation: Vector2) -> void:
	position += translation
	for connection in child_connections:
		connection.child.part.translate_part(translation)


class Connection extends RefCounted:
	var parent: AttachPoint
	var child: AttachPoint
	func _init(parent_point: AttachPoint, child_point: AttachPoint):
		self.parent = parent_point
		self.child = child_point
