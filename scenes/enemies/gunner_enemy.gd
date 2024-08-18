extends Enemy


func _ready() -> void:
	super()
	_setup_steering()

# TODO: Try to fire the gun

func _setup_steering() -> void:
	super()

	# Setup the core behavior.
	var seek := GSAISeek.new(agent, player_agent)
	var face := GSAIFace.new(agent, _direction_face)
	face.alignment_tolerance = deg_to_rad(5)
	face.deceleration_radius = deg_to_rad(30)

	agent.bounding_radius = $CollisionShape2D.shape.radius

	var proximity := GSAIRadiusProximity.new(agent, [player_agent], 140)
	var separation := GSAISeparation.new(agent, proximity)
	separation.decay_coefficient = 200000
	# This one does an "orbit" instead
	#var avoid := GSAIAvoidCollisions.new(agent, proximity)

	var blend := GSAIBlend.new(agent)

	blend.add(face, 1)
	blend.add(seek, 1)
	blend.add(separation, 1)

	var priority := GSAIPriority.new(agent, 0.0001)
	priority.add(separation)
	priority.add(blend)

	_steering = blend
