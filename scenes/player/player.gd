class_name Player
extends CharacterBody2D

## The % of max speed when going backwards.
@export var reverse_multiplier := 0.25

@export var drag_linear_coeff := 0.05
@export var drag_angular_coeff := 0.1

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

func _ready() -> void:
	Global.player = self


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

	if Input.is_action_just_pressed("debug") and OS.is_debug_build():
		health.adjust_health(-20)


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


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area is Drop:
		pass
		area.on_player_entered(self)
	elif area is Enemy:
		pass
		area.on_player_entered(self)


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area is Drop:
		pass
		area.on_player_entered(self)
	elif area is Enemy:
		pass
		area.on_player_entered(self)


func _on_health_component_health_depleted() -> void:
	die()

func die() -> void:
	print('we died!')
