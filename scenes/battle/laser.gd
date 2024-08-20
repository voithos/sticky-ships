class_name Laser
extends Node2D


@export var fires_automatically := true

@export var growth_level := 2

@export var sfx: AudioStreamPlayer
@export var fire_duration := 1.0
@export var fire_period := 4.0
@export var damage_cooldown := 0.125
@export var telegraph_duration := 1.0

@export var damage := 8

@export_flags_2d_physics var damage_collision_mask: int

const LASER_BEAM_SCENE := preload("res://scenes/battle/laser_beam.tscn")
const TELEGRAPH_SCENE := preload("res://scenes/battle/laser_beam_telegraph.tscn")

var damage_cooldown_left := 0.0
var fire_start_cooldown_left := 0.0
var telegraph_start_cooldown_left := 0.0
var fire_end_cooldown_left := 0.0

var is_firing := false

var laser_beam: Node2D
var telegraph: Node2D

var intersecting_objects: Array[Node2D] = []


func _ready() -> void:
	$HitBox.collision_mask = damage_collision_mask

	fire_start_cooldown_left = fire_period


func _physics_process(delta: float) -> void:
	# Don't fire the laser when it is dropped.
	var parent := get_parent()
	if is_instance_valid(parent) and parent is Part and !parent.attached_to_player:
		return

	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	fire_start_cooldown_left = maxf(fire_start_cooldown_left - delta, 0.0)
	fire_end_cooldown_left = maxf(fire_end_cooldown_left - delta, 0.0)
	telegraph_start_cooldown_left = maxf(fire_start_cooldown_left - telegraph_duration, 0.0)

	if is_firing and fire_end_cooldown_left == 0:
		is_firing = false
		if sfx:
			sfx.stop()
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		if is_instance_valid(laser_beam):
			laser_beam.queue_free()
		fire_start_cooldown_left = fire_period - fire_duration
	elif !is_firing and telegraph_start_cooldown_left == 0 and !is_instance_valid(telegraph):
		if is_instance_valid(laser_beam):
			laser_beam.queue_free()
		telegraph = TELEGRAPH_SCENE.instantiate()
		telegraph.position = $SpawnPoint.position
		add_child(telegraph)
		move_child(telegraph, 0)
	elif !is_firing and fire_start_cooldown_left == 0:
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		is_firing = true
		if sfx:
			sfx.play()
		laser_beam = LASER_BEAM_SCENE.instantiate()
		laser_beam.position = $SpawnPoint.position
		add_child(laser_beam)
		move_child(laser_beam, 0)
		fire_end_cooldown_left = fire_duration

	try_damage()


func try_damage() -> void:
	if damage_cooldown_left > 0 or !is_firing:
		return
	_damage()


func _damage() -> void:
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
			if is_firing:
				# Apply damage immediately.
				_damage_intersecting_object(parent_node)


func _on_hit_box_area_exited(area: Area2D) -> void:
	if area is Hurtbox:
		var parent_node: Node2D = area.get_parent()
		if (parent_node is Enemy or
				parent_node is Part or
				parent_node is Projectile):
			intersecting_objects.erase(parent_node)
