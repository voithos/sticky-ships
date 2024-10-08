class_name Gun
extends Node2D


@export var growth_level := 1

@export var projectile: PackedScene
# A node used as the spawn position when spawning bullets
@export var spawn_point: Node2D
@export var sfx: AudioStreamPlayer
@export var cooldown: float = 0.5

# The angle in degrees of spread when firing
@export var spread: float = 0.0
# The speed variation when firing (relative to projectile speed)
@export var speed_spread: float = 0.0

@export var bullet_damage_multiplier := 1.0

@export_flags_2d_physics var projectile_collision_mask: int

var cooldown_left := 0.0


func _physics_process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


func try_fire() -> void:
	if cooldown_left > 0:
		return
	_fire()


func _fire() -> void:
	_spawn_projectiles()

	if sfx:
		sfx.play()

	cooldown_left = cooldown


func _spawn_projectiles() -> void:
	var p: Projectile = projectile.instantiate()
	_apply_projectile_props(p)
	Global.level.add_child(p)


func _apply_projectile_props(p: Projectile) -> void:
	p.global_position = spawn_point.global_position
	p.rotation = spawn_point.global_rotation + deg_to_rad(random_spread(spread))
	p.speed *= (1.0 + random_spread(speed_spread))
	p.collision_mask = projectile_collision_mask
	p.shooter = owner
	p.damage *= bullet_damage_multiplier


static func random_spread(value: float) -> float:
	var half_spread := value / 2.0
	return randf_range(-half_spread, half_spread)
