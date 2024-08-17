class_name Part
extends Area2D


var attached_to_player := false

var parent: Part
var children: Array[Part] = []


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
	out_descendants.append_array(children)
	for child in children:
		child.get_all_descendants(out_descendants)


func add_child_part(part: Part) -> void:
	assert(!children.has(part))
	assert(!is_instance_valid(part.parent))

	children.push_back(part)
	part.parent = self


func remove_child_part(part: Part) -> void:
	assert(children.has(part))
	assert(part.parent == self)

	children.erase(part)
	part.parent = null
