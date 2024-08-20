extends LightGun

@export var rotation_per_fire := 5
@export var reverse_rotate := false

func _fire() -> void:
	$AnimatedSprite2D.play("fire")
	super()

	rotation += deg_to_rad(rotation_per_fire) * (-1 if reverse_rotate else 1)


func _on_basic_gun_animation_finished() -> void:
	$AnimatedSprite2D.play("idle")
