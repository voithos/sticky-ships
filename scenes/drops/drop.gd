@tool
class_name Drop
extends Node2D


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func get_area() -> Area2D:
	var area = get_node_or_null("Area2D")
	if area is Area2D:
		return area
	return null


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	var area = get_area()
	if !is_instance_valid(area):
		warnings.push_back("Drop scenes must have a child node named 'Area2D' of type Area2D.")
	return warnings
