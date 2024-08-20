class_name Laser
extends Node2D


@export var growth_level := 1

@export var sfx: AudioStreamPlayer
@export var fire_duration := 1.0
@export var fire_period := 3.0
@export var damage_cooldown := 0.25

@export var damage := 1.8

@export_flags_2d_physics var damage_collision_mask: int

var damage_cooldown_left := 0.0
var fire_start_cooldown_left := 0.0
var fire_end_cooldown_left := 0.0

var is_firing := false

var intersecting_objects: Array[Node2D] = []


func _ready() -> void:
	$HitBox.collision_mask = damage_collision_mask


func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	fire_start_cooldown_left = maxf(fire_start_cooldown_left - delta, 0.0)
	fire_end_cooldown_left = maxf(fire_end_cooldown_left - delta, 0.0)

	if is_firing:
		if fire_end_cooldown_left == 0:
			is_firing = false
			$LaserBeam.visible = false
	else:
		if fire_start_cooldown_left == 0:
			is_firing = true
			$LaserBeam.visible = true


func try_damage() -> void:
	if damage_cooldown_left > 0 or !is_firing:
		return
	_damage()


func _damage() -> void:
	if !intersecting_objects.is_empty() and sfx:
		sfx.play()

	_damage_intersecting_objects()

	damage_cooldown_left = damage_cooldown


func _damage_intersecting_objects() -> void:
	var dead_objects: Array[Node2D] = []
	for object in intersecting_objects:
		if !is_instance_valid(object):
			dead_objects.push_back(object)
			continue
		_damage_intersecting_object(object)
	for object in dead_objects:
		intersecting_objects.erase(object)


func _damage_intersecting_object(object: Node2D) -> void:
	if object is Enemy or object is Part:
		object.health.take_damage(damage)
	elif object is Projectile:
		var parent_node: Node2D = get_parent()
		assert(parent_node is Enemy or parent_node is Part)
		parent_node.health.take_damage(object.damage * projectile_damage_multiplier)
		object.die()
	else:
		assert(false)


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var parent_node: Node2D = area.get_parent()
		if (parent_node is Enemy or
				parent_node is Part or
				parent_node is Projectile):
			intersecting_objects.push_back(parent_node)
			# Apply damage immediately.
			_damage_intersecting_object(parent_node)
			if sfx:
				sfx.play()


func _on_hit_box_area_exited(area: Area2D) -> void:
	if area is Hurtbox:
		var parent_node: Node2D = area.get_parent()
		if (parent_node is Enemy or
				parent_node is Part or
				parent_node is Projectile):
			intersecting_objects.erase(parent_node)
