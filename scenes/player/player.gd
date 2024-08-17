class_name Player
extends CharacterBody2D

@export var drag_linear_coeff := 0.05
## The % of max speed when going backwards.
@export var reverse_multiplier := 0.25

@export var drag_angular_coeff := 0.1

const MAX_ACCELERATION = 1200
const MAX_LINEAR_SPEED = 540
const MAX_ANGULAR_SPEED = 200
const MAX_ANGULAR_ACCELERATION = 3600

var linear_velocity := Vector2.ZERO
var angular_velocity := 0.0
var is_reversing := false
var can_fire := true

func _ready() -> void:
	pass # Replace with function body.


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
	angular_velocity += movement.x * MAX_ANGULAR_ACCELERATION * delta

	linear_velocity = linear_velocity.limit_length(MAX_LINEAR_SPEED)
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, drag_linear_coeff)

	angular_velocity = clamp(angular_velocity, -deg_to_rad(MAX_ANGULAR_SPEED), deg_to_rad(MAX_ANGULAR_SPEED))
	angular_velocity = lerp(angular_velocity, 0.0, drag_angular_coeff)

	velocity = linear_velocity
	#print(velocity)
	move_and_slide()
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
