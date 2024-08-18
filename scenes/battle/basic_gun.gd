extends LightGun

func _fire() -> void:
	$AnimatedSprite2D.play("fire")
	super()


func _on_basic_gun_animation_finished() -> void:
	$AnimatedSprite2D.play("idle")
