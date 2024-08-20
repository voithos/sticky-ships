class_name Blade
extends Node2D


@export var growth_level := 1

@export var sfx: AudioStreamPlayer
@export var cooldown: float = 0.25

@export var damage := 2

@export var projectile_damage_multiplier := 0.2

@export_flags_2d_physics var damage_collision_mask: int

var cooldown_left := 0.0

var intersecting_objects: Array[Node2D] = []


func _ready() -> void:
	$HitBox.collision_mask = damage_collision_mask


func _physics_process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)


func try_cut() -> void:
	if cooldown_left > 0:
		return
	_cut()


func _cut() -> void:
	if !intersecting_objects.is_empty() and sfx:
		sfx.play()

	_damage_intersecting_objects()

	cooldown_left = cooldown


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
