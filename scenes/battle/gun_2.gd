extends LightGun

@export var angle_offset := 15.0


func _fire() -> void:
	$AnimatedSprite2D.play("fire")
	super()


## Override
func _spawn_projectiles() -> void:
	var p1: Projectile = projectile.instantiate()
	var p2: Projectile = projectile.instantiate()
	_apply_projectile_props(p1)
	p1.global_position = $SpawnPoint.global_position
	p1.rotation -= deg_to_rad(angle_offset)

	_apply_projectile_props(p2)
	p2.global_position = $SpawnPoint2.global_position
	p2.rotation += deg_to_rad(angle_offset)

	Global.level.add_child(p1)
	Global.level.add_child(p2)


func _on_basic_gun_animation_finished() -> void:
	$AnimatedSprite2D.play("idle")
