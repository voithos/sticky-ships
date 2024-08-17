class_name Level
extends Node2D


var PLAYER_SCENE = preload("res://scenes/player/player.tscn")
var ENERGY_DROP_SCENE = preload("res://scenes/drops/energy_drop.tscn")


func _ready() -> void:
	var player = PLAYER_SCENE.instantiate()
	add_child(player)

	var drop = ENERGY_DROP_SCENE.instantiate()
	add_child(drop)


func _process(delta: float) -> void:
	pass
