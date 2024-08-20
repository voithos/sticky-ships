extends Enemy


@export var firing_distance := 100.0


func _ready() -> void:
	super()
	_setup_steering()


func _physics_process(delta: float) -> void:
	super(delta)
	try_fire_light()

	if accel.linear.length_squared() < 1000:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("thrust")


func _steering_process(delta: float) -> void:
	super(delta)


func _setup_steering() -> void:
	super()

	agent.bounding_radius = $CollisionShape2D.shape.radius

	var player_agent: GSAISteeringAgent = Global.player.agent

	# Setup the core behavior.
	var arrive := GSAIArrive.new(agent, _player_seek_location)
	arrive.deceleration_radius = 10
	var face := GSAIFace.new(agent, player_agent)
	face.alignment_tolerance = deg_to_rad(5)
	face.deceleration_radius = deg_to_rad(30)

	# This one does an "orbit" instead
	#var avoid := GSAIAvoidCollisions.new(agent, proximity)

	var blend := GSAIBlend.new(agent)

	blend.add(face, 1)
	blend.add(arrive, 1)

	_steering = blend
