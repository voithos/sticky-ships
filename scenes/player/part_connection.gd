class_name PartConnection
extends RefCounted

var parent: AttachPoint
var child: AttachPoint

func _init(parent_point: AttachPoint, child_point: AttachPoint):
	self.parent = parent_point
	self.child = child_point
	parent.connection = self
	child.connection = self
