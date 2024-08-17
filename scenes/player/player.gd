class_name Player
extends CharacterBody2D


@export var drag_linear_coeff := 0.05
@export var drag_angular_coeff := 0.1
## The % of max speed when going backwards. This is just the default, added thrusters will not be affected.
@export var reverse_multiplier := 0.25

@export var acceleration_factor := 500.0
@export var MAX_ANGULAR_SPEED := 200.0
@export var MAX_ANGULAR_ACCELERATION := 3000.0

var linear_velocity := Vector2.ZERO
var angular_velocity := 0.0
var is_reversing := false
var can_fire := true

const MIN_THRUSTER_CONTRIBUTION_COS := cos(deg_to_rad(45.0))

# Components.
@onready var health: HealthComponent = $HealthComponent

var body: PlayerBody


func _ready() -> void:
	Global.player = self
	body = PlayerBody.new()
	add_child(body)


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	handle_movement(delta)

	# Try to fire every frame when it's held down
	if Input.is_action_pressed("fire"):
		try_fire()


func handle_movement(delta: float) -> void:
	var movement := get_movement()
	is_reversing = movement.y < 0

	var forward := get_orientation()
	var direction := -forward if is_reversing else forward

	# TODO: If this is too slow, we can pull it out and only calculate it when attaching/detaching.
	# We start with the core's default movement capabilities.
	var max_propulsion := (reverse_multiplier if is_reversing else 1.0)

	for part in body.parts:
		for thruster in part.thrusters:
			var thrust_vector := thruster.get_thrust_vector()
			# Only add contribution when it is at least a certain degrees aligned.
			if direction.dot(thrust_vector) > MIN_THRUSTER_CONTRIBUTION_COS:
				max_propulsion += thruster.propulsion

	print((max_propulsion / body.total_mass))
	linear_velocity += (
		movement.y
		* forward
		* acceleration_factor
		* (max_propulsion / body.total_mass)
		* delta
	)

	linear_velocity = linear_velocity.lerp(Vector2.ZERO, drag_linear_coeff)

	velocity = linear_velocity
	move_and_slide()

	# Rotation.
	angular_velocity += movement.x * MAX_ANGULAR_ACCELERATION * delta
	angular_velocity = clamp(angular_velocity, -deg_to_rad(MAX_ANGULAR_SPEED), deg_to_rad(MAX_ANGULAR_SPEED))
	angular_velocity = lerp(angular_velocity, 0.0, drag_angular_coeff)

	rotation += angular_velocity * delta


func try_fire() -> void:
	for part in body.parts:
		for gun in part.light_guns:
			gun.try_fire()


func get_movement() -> Vector2:
	return Vector2(
		Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)


func unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return


func get_orientation() -> Vector2:
	return Vector2.from_angle(global_rotation - PI/2)


func _on_health_component_health_depleted() -> void:
	die()


func die() -> void:
	print('we died!')
