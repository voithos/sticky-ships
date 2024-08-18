class_name Effect
extends AnimatedSprite2D


@export var random_rotation := true


func _ready() -> void:
	animation_finished.connect(die)
	if random_rotation:
		rotation = randi_range(0, 3) * PI / 2


func die() -> void:
	queue_free()
