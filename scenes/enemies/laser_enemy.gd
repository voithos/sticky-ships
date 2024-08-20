class_name LaserEnemy
extends Enemy


const ROTATION_PERIOD_SEC := 28.0

var elapsed_time := 0.0

var starting_angle_from_player := 0.0
var is_rotating_cw_multiplier := 1.0


func _ready() -> void:
	super()

	starting_angle_from_player = Global.player.position.angle_to_point(position)
	is_rotating_cw_multiplier = 1 if randf() >= 0.5 else -1

	_setup_steering()


func _physics_process(delta: float) -> void:
	super(delta)

	elapsed_time += delta

	if accel.linear.length_squared() < 1000:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("thrust")


func _steering_process(delta: float) -> void:
	# Calculate offset by a fixed distance
	var player_position: Vector3 = Global.player.agent.position
	var angle_from_player := \
		fmod(elapsed_time, ROTATION_PERIOD_SEC) / ROTATION_PERIOD_SEC * TAU * \
		is_rotating_cw_multiplier + \
		starting_angle_from_player
	var direction_from_player_2d := Vector2.RIGHT.rotated(angle_from_player)
	var direction_from_player := Vector3(
		direction_from_player_2d.x, direction_from_player_2d.y, 0.0)
	var target: Vector3 = player_position + direction_from_player * player_seek_offset
	_player_seek_location.position = target


func _setup_steering() -> void:
	super()

	agent.bounding_radius = $CollisionShape2D.shape.radius

	var player_agent: GSAISteeringAgent = Global.player.agent

	# Setup the core behavior.
	var arrive := GSAIArrive.new(agent, _player_seek_location)
	arrive.deceleration_radius = 3
	var face := GSAIFace.new(agent, player_agent)
	face.alignment_tolerance = deg_to_rad(5)
	face.deceleration_radius = deg_to_rad(30)

	# This one does an "orbit" instead
	#var avoid := GSAIAvoidCollisions.new(agent, proximity)

	var blend := GSAIBlend.new(agent)

	blend.add(face, 1)
	blend.add(arrive, 1)

	_steering = blend
