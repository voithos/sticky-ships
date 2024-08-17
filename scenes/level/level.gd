class_name Level
extends Node2D


var PLAYER_SCENE = preload("res://scenes/player/player.tscn")
var ENERGY_DROP_SCENE = preload("res://scenes/drops/energy_drop.tscn")

var player: Player
var dropped_parts: Array[Part] = []


func _ready() -> void:
	Global.level = self

	player = PLAYER_SCENE.instantiate()
	add_child(player)

	# TODO: Remove.
	#var drop = ENERGY_DROP_SCENE.instantiate()
	#add_child(drop)

	# TODO: Remove these extra parts.

	var gun_part_1: Part = Global.part_type_to_packed_scene(Global.PartType.BasicGun).instantiate()
	dropped_parts.push_back(gun_part_1)
	add_child(gun_part_1)
	gun_part_1.rotation = -PI / 2
	gun_part_1.position = Vector2(0.0, 48.0)

	var gun_part_2: Part = Global.part_type_to_packed_scene(Global.PartType.BasicGun).instantiate()
	dropped_parts.push_back(gun_part_2)
	add_child(gun_part_2)
	gun_part_2.rotation = PI / 2
	var gun_part_1_attach_point := gun_part_1.get_node("RearAttachPoint")
	var gun_part_2_attach_point := gun_part_2.get_node("RearAttachPoint")
	gun_part_1.add_child_connection(gun_part_1_attach_point, gun_part_2_attach_point)

	var gun_part_3: Part = Global.part_type_to_packed_scene(Global.PartType.BasicGun).instantiate()
	dropped_parts.push_back(gun_part_3)
	add_child(gun_part_3)
	gun_part_3.rotation = PI
	gun_part_1_attach_point = gun_part_1.get_node("LeftAttachPoint")
	var gun_part_3_attach_point := gun_part_3.get_node("RearAttachPoint")
	gun_part_1.add_child_connection(gun_part_1_attach_point, gun_part_3_attach_point)


func _process(delta: float) -> void:
	pass


func destroy_player_part(part: Part) -> void:
	var descendant_parts: Array[Part] = []
	part.get_all_descendants(descendant_parts)

	dropped_parts.append_array(descendant_parts)

	for descendant_part in descendant_parts:
		descendant_part.reparent(self)
		Global.player.body.on_part_removed(descendant_part)

	Global.player.body.on_part_removed(part)
	part.queue_free()
