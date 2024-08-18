class_name Effect
extends AnimatedSprite2D


func _ready() -> void:
	animation_finished.connect(die)


func die() -> void:
	queue_free()
