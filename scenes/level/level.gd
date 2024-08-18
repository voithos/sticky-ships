class_name Level
extends Node2D


var current_growth_level := 1

var player: Player
var drops: Array[Drop] = []


func _ready() -> void:
	Global.level = self

	player = Global.PLAYER_SCENE.instantiate()
	add_child(player)

	# TODO: Remove.
	#var drop = Global.ENERGY_DROP_SCENE.instantiate()
	#add_child(drop)

	# TODO: Remove this extra drop.
	var drop_chunk := Global.TRIPLE_GUN_DROP_CHUNK_SCENE.instantiate()
	drop_chunk.position = Vector2(0.0, 48.0)
	add_child(drop_chunk)



func _process(delta: float) -> void:
	pass


func destroy_player_part(part: Part) -> void:
	var descendant_parts: Array[Part] = []
	part.get_all_descendants(descendant_parts)

	# Detach from children.
	for connection in part.child_connections:
		connection.child.connection = null
		connection.child.part.parent_connection = null

	# Detach from parent.
	if part.parent_connection != null:
		part.parent_connection.parent.connection = null
		part.parent_connection.parent.part.child_connections.erase(part.parent_connection)

	var drop := Global.EMPTY_PARTS_DROP_SCENE.instantiate()
	add_child(drop)
	drops.push_back(drop)

	for descendant_part in descendant_parts:
		descendant_part.looks_for_nearby_connections_when_entering_tree = false
		drop.add_child(descendant_part)
		Global.player.body.on_part_removed(descendant_part)

	Global.player.body.on_part_removed(part)
	part.queue_free()


func grow_player() -> void:
	# FIXME: Implement growth system
	# - Zoom-out
	# - For every non-player sprite:
	#   - Fade in/out new/old sprites for that entity.
	# - For the all player-ship sprites:
	#   - Fade-out
	# - For the new core:
	#   - Fade-in
	# - Show some sort of particle effect
	# - Damage everything within a radius?
	# - Show sprite overlays for whichever aspects have been upgraded
	pass
