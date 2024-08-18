class_name Enemy
extends CharacterBody2D


var health: HealthComponent = null

var light_guns: Array[LightGun] = []
var heavy_guns: Array[HeavyGun] = []

var _direction_face := GSAIAgentLocation.new()

var _steering: GSAISteeringBehavior

@export var linear_drag_coefficient := 0.025
@export var angular_drag := 0.1

@onready var agent := await GSAICharacterBody2DAgent.new(self)
@onready var player_agent: GSAISteeringAgent = Global.player.agent
@onready var accel := GSAITargetAcceleration.new()

@export var linear_accel_max := 3000.0
@export var linear_speed_max := 120.0
@export var angular_accel_max := 5000
@export var angular_speed_max := 360

func _ready() -> void:
	_init_components(self)


func _init_components(node: Node) -> void:
	if node is HealthComponent:
		_init_health_component(node)
	elif node is LightGun:
		light_guns.push_back(node)
	elif node is HeavyGun:
		heavy_guns.push_back(node)

	for child in node.get_children():
		_init_components(child)


func _init_health_component(h: HealthComponent) -> void:
	assert(health == null)
	health = h
	health.health_depleted.connect(die)


func _process(delta: float) -> void:
	pass

func _setup_steering() -> void:
	# Basic agent stuff.
	agent.angular_acceleration_max = deg_to_rad(angular_accel_max)
	agent.angular_speed_max = deg_to_rad(angular_speed_max)
	agent.linear_acceleration_max = linear_accel_max
	agent.linear_speed_max = linear_speed_max

func _physics_process(delta: float) -> void:
	_direction_face.position = agent.position + accel.linear.normalized()

	_steering.calculate_steering(accel)

	agent.angular_velocity = clamp(
		agent.angular_velocity + accel.angular * delta, -agent.angular_speed_max, agent.angular_speed_max
	)
	agent.angular_velocity = lerp(agent.angular_velocity, 0.0, angular_drag)

	rotation += agent.angular_velocity * delta

	var linear_velocity := GSAIUtils.to_vector2(agent.linear_velocity + accel.linear * delta)

	linear_velocity = linear_velocity.limit_length(agent.linear_speed_max)
	linear_velocity = linear_velocity.lerp(Vector2.ZERO, linear_drag_coefficient)

	velocity = linear_velocity
	move_and_slide()
	linear_velocity = velocity
	agent.linear_velocity = GSAIUtils.to_vector3(linear_velocity)


func die() -> void:
	queue_free()
