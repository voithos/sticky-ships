class_name Player
extends CharacterBody2D


const CORE_PART_SCENE := preload("res://scenes/parts/core_part.tscn")

@export var drag_linear_coeff := 0.05
@export var drag_angular_coeff := 0.1
## The % of max speed when going backwards.
@export var reverse_multiplier := 0.25

@export var MAX_ACCELERATION = 600
@export var MAX_LINEAR_SPEED = 180
@export var MAX_ANGULAR_SPEED = 200
@export var MAX_ANGULAR_ACCELERATION = 3000

var linear_velocity := Vector2.ZERO
var angular_velocity := 0.0
var is_reversing := false
var can_fire := true

# Components.
@onready var health: HealthComponent = $HealthComponent

var parts: Array[Part] = []

func _ready() -> void:
	Global.player = self
	add_new_part(Enums.PartType.Core, null, Vector2.ZERO)


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	var movement := get_movement()
	is_reversing = movement.y < 0

	var direction := get_orientation()

	linear_velocity += (
		movement.y
		* direction
		* MAX_ACCELERATION
		* (reverse_multiplier if is_reversing else 1)
		* delta
	)

	linear_velocity = linear_velocity.limit_length(MAX_LINEAR_SPEED)
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, drag_linear_coeff)

	velocity = linear_velocity
	move_and_slide()

	# Rotation.
	angular_velocity += movement.x * MAX_ANGULAR_ACCELERATION * delta
	angular_velocity = clamp(angular_velocity, -deg_to_rad(MAX_ANGULAR_SPEED), deg_to_rad(MAX_ANGULAR_SPEED))
	angular_velocity = lerp(angular_velocity, 0.0, drag_angular_coeff)

	rotation += angular_velocity * delta


func get_movement() -> Vector2:
	return Vector2(
		Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)


func unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return


func get_orientation() -> Vector2:
	return Vector2.from_angle(rotation - PI/2)


func _on_health_component_health_depleted() -> void:
	die()


func die() -> void:
	print('we died!')


func on_area_entered(area: Area2D, part: Part) -> void:
	if area is Drop:
		area.on_player_part_entered(self)
	elif area is Enemy:
		area.on_player_part_entered(self)
	elif area is EnemyProjectile:
		area.on_player_part_entered(self)


func on_area_exited(area: Area2D, part: Part) -> void:
	if area is Drop:
		area.on_player_part_exited(self)
	elif area is Enemy:
		area.on_player_part_exited(self)
	elif area is EnemyProjectile:
		area.on_player_part_exited(self)


func add_fallen_parts(sub_part: Part, parent_part: Part) -> void:
	# TODO: Re-orient the part tree such that the given sub_part is the root.

	parent_part.add_child_part(sub_part)

	_add_fallen_sub_part(sub_part)


func _add_fallen_sub_part(sub_part: Part) -> void:
	sub_part.reparent(self)
	parts.push_back(sub_part)
	sub_part.attached_to_player = true

	for child in sub_part.children:
		_add_fallen_sub_part(child)


func add_new_part(type: Enums.PartType, parent_part: Part, player_relative_position: Vector2) -> void:
	assert(is_instance_valid(parent_part) or type == Enums.PartType.Core)

	var part: Part = part_type_to_packed_scene(type).instantiate()

	parts.push_back(part)
	if is_instance_valid(parent_part):
		parent_part.add_child_part(part)
	add_child(part)

	part.attached_to_player = true

	part.position = player_relative_position


func destroy_part(part: Part) -> void:
	assert(is_instance_valid(part))
	assert(parts.has(part), "destroy_part: Player does not have part.")

	_remove_sub_part(part)

	for child in part.children:
		part.remove_child_part(child)
	if is_instance_valid(part.parent):
		part.parent.remove_child_part(part)

	part.queue_free()


func _remove_sub_part(part: Part) -> void:
	assert(is_instance_valid(part))
	assert(parts.has(part), "_remove_sub_part: Player does not have part.")

	part.attached_to_player = false
	parts.erase(part)

	for child in part.children:
		_remove_sub_part(child)


func part_type_to_packed_scene(type: Enums.PartType) -> PackedScene:
	match type:
		Enums.PartType.Core:
			return CORE_PART_SCENE
		_:
			assert(false)
			return null
