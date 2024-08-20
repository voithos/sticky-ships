class_name Player
extends CharacterBody2D


@export var drag_linear_coeff := 0.05
@export var drag_angular_coeff := 0.1
## The % of max speed when going backwards. This is just the default, added thrusters will not be affected.
@export var reverse_multiplier := 0.5

## These are like the "starting point" for movement. The actual propulsion + mass determine the final speed.
@export var acceleration_factor := 300.0
@export var angular_acceleration_factor := 300.0

var linear_velocity := Vector2.ZERO
var angular_velocity := 0.0
var is_reversing := false
var can_fire := true

const MIN_THRUSTER_CONTRIBUTION_COS := cos(deg_to_rad(45.0))

var agent := GSAISteeringAgent.new()

var body: PlayerBody

## Default propulsion applied to everything
@export var inherent_propulsion := 10.0

func _ready() -> void:
	Global.player = self
	agent.bounding_radius = 1
	body = PlayerBody.new()
	add_child(body)

	$Camera2D.make_current()


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if Session.is_game_over:
		return

	handle_movement(delta)

	# Try to fire every frame when it's held down
	if Input.is_action_pressed("fire"):
		try_fire()


func rot_90_cw(v: Vector2) -> Vector2:
	return Vector2(-v.y, v.x)


func rot_90_ccw(v: Vector2) -> Vector2:
	return Vector2(v.y, -v.x)


func gather_thrust(movement: Vector2, forward: Vector2, direction_x: Vector2, direction_y: Vector2) -> Vector2:
	# TODO: If this is too slow, we can pull it out and only calculate it when attaching/detaching.
	# We start with the core's default movement capabilities.
	var max_propulsion := Vector2(inherent_propulsion, (inherent_propulsion * reverse_multiplier if is_reversing else inherent_propulsion))

	for part in body.parts:
		for thruster in part.thrusters:
			var thrust_vector := thruster.get_thrust_vector()
			# First compute forward/back component
			# Only add contribution when it is at least a certain degrees aligned.
			var satisfies_y := direction_y.dot(thrust_vector) > MIN_THRUSTER_CONTRIBUTION_COS
			if satisfies_y:
				max_propulsion.y += thruster.propulsion

			var dir_x_cos := direction_x.dot(thrust_vector)
			var satisfies_x := absf(dir_x_cos) > MIN_THRUSTER_CONTRIBUTION_COS
			if satisfies_x:
				var rel_pos := thruster.global_position - global_position
				var is_front_of_center := rel_pos.project(forward).dot(forward) > 0
				# Figure out if it's in the same dir as the desired turn, or in the opposite dir
				if (dir_x_cos > 0 and is_front_of_center) or dir_x_cos <= 0 and !is_front_of_center:
					max_propulsion.x += thruster.propulsion
				else:
					satisfies_x = false

			thruster.set_is_thrusting((satisfies_y and movement.y != 0) or (satisfies_x and movement.x != 0))
	return max_propulsion


func handle_movement(delta: float) -> void:
	var movement := get_movement()
	is_reversing = movement.y < 0

	var forward := get_orientation()
	var direction_y := -forward if is_reversing else forward
	var direction_x := rot_90_ccw(forward) if movement.x < 0 else rot_90_cw(forward)

	var max_propulsion := gather_thrust(movement, forward, direction_x, direction_y)
	var propulsion_factor := (max_propulsion / body.total_mass)

	linear_velocity += (
		movement.y
		* forward
		* acceleration_factor
		* propulsion_factor.y
		* delta
	)

	linear_velocity = linear_velocity.lerp(Vector2.ZERO, drag_linear_coeff)

	velocity = linear_velocity
	move_and_slide()

	# Rotation.
	#angular_velocity += movement.x * deg_to_rad(angular_acceleration_factor) * propulsion_factor.x * delta
	angular_velocity = lerp(angular_velocity, movement.x * angular_acceleration_factor * propulsion_factor.x * delta, 0.15)
	#angular_velocity = clamp(angular_velocity, -deg_to_rad(MAX_ANGULAR_SPEED), deg_to_rad(MAX_ANGULAR_SPEED))
	angular_velocity = lerp(angular_velocity, 0.0, drag_angular_coeff)

	rotation += angular_velocity * delta

	_update_agent()


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
	var explosion := Config.EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	add_sibling(explosion)
	visible = false
	Session.is_game_over = true
	Session.did_player_win = false
	# TODO: SFX.
	Global.game_over_screen.open()


# TODO: Call this.
func win() -> void:
	print('we won!')
	Session.is_game_over = true
	Session.did_player_win = true
	# TODO: SFX.
	Global.game_over_screen.open()


func _update_agent() -> void:
	agent.position.x = global_position.x
	agent.position.y = global_position.y
	agent.linear_velocity.x = linear_velocity.x
	agent.linear_velocity.y = linear_velocity.y
	agent.angular_velocity = angular_velocity
	agent.orientation = rotation


func level_up(next_level: int) -> void:
	var level_up_effect: LevelUpEffect = Config.LEVEL_UP_EFFECT_SCENE.instantiate()
	add_child(level_up_effect)
	var level_up_effect_sprite_size := level_up_effect.get_sprite_size()

	var bounding_box := body.get_bounding_box()
	var desired_level_up_effect_size := bounding_box.size * LevelUpEffect.BOUNDING_BOX_SCALE_MULTIPLIER
	var level_up_effect_scale := desired_level_up_effect_size / level_up_effect_sprite_size
	if level_up_effect_scale.x > level_up_effect_scale.y:
		level_up_effect_scale.y = level_up_effect_scale.x
	else:
		level_up_effect_scale.x = level_up_effect_scale.y

	#level_up_effect.global_position = bounding_box.get_center() - desired_level_up_effect_size / 2
	level_up_effect.scale = level_up_effect_scale

	await level_up_effect.half_finished

	body.set_core(next_level)

	await level_up_effect.finished

	level_up_effect.queue_free()
