class_name Level
extends Node2D


var PLAYER_SCENE = preload("res://scenes/player/player.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player = PLAYER_SCENE.instantiate()
	self.add_child(player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
