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

	var drop = ENERGY_DROP_SCENE.instantiate()
	add_child(drop)


func _process(delta: float) -> void:
	pass


func destroy_player_part(part: Part) -> void:
	var descendant_parts: Array[Part] = []
	part.get_all_descendants(descendant_parts)

	dropped_parts.append_array(descendant_parts)

	for descendant_part in descendant_parts:
		descendant_part.reparent(self)
