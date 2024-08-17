class_name Part
extends Area2D


enum Type {
	Core,
}

var attached_to_player := false

var attach_points: Array[AttachPoint] = []

var parent_connection: Connection
var child_connections: Array[Connection] = []


func _ready() -> void:
	self.connect("area_entered", _on_area_entered)
	self.connect("area_exited", _on_area_exited)


func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	Global.player.on_area_entered(area, self)


func _on_area_exited(area: Area2D) -> void:
	Global.player.on_area_exited(area, self)


func get_all_descendants(out_descendants: Array[Part]) -> void:
	for connection in child_connections:
		out_descendants.append(connection.child.part)
		connection.get_all_descendants(out_descendants)


func add_child_connection(parent_point: AttachPoint, child_point: AttachPoint) -> void:
	assert(!is_instance_valid(child_point.part.parent_connection))
	for connection in child_connections:
		assert(connection.parent != parent_point)
		assert(connection.child != child_point)
	for connection in child_point.part.child_connections:
		assert(connection.parent != child_point)
		assert(connection.child != parent_point)

	var connection := Connection.new(parent_point, child_point)
	child_connections.push_back(connection)
	child_point.part.parent_connection = connection


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
	var old_parent := old_parent_connection.parent
	var old_child := old_parent_connection.child
	parent_connection = new_parent_connection
	old_parent_connection.parent = old_child
	old_parent_connection.child = old_parent
	old_parent.reassign_parent_connection(old_parent_connection)


class Connection extends RefCounted:
	var parent: AttachPoint
	var child: AttachPoint
	func _init(parent_point: AttachPoint, child_point: AttachPoint):
		self.parent = parent_point
		self.child = child_point
