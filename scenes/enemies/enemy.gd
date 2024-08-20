class_name Enemy
extends CharacterBody2D


@export var growth_level := 1

@export var explosion_scene: PackedScene

var health: HealthComponent = null

var light_guns: Array[LightGun] = []
var heavy_guns: Array[HeavyGun] = []

## Steering behaviors
var _steering: GSAISteeringBehavior

@export var linear_drag_coefficient := 0.025
@export var angular_drag := 0.1

@onready var agent := await GSAICharacterBody2DAgent.new(self)
@onready var accel := GSAITargetAcceleration.new()

## Helper location that computes arrive distance from the player
## Not active by default, you have to use it in `_setup_steering`
var _player_seek_location := GSAIAgentLocation.new()

@export var linear_accel_max := 1800.0
@export var linear_speed_max := 150.0
@export var angular_accel_max := 5000
@export var angular_speed_max := 360

@export var player_seek_offset := 50.0

@export var droppables: Array[Droppable] = []


func _init() -> void:
	add_to_group(Config.ENEMIES_GROUP)
	Session.on_enemy_created()


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


func try_fire_light() -> void:
	for gun in light_guns:
		gun.try_fire()


func _init_health_component(h: HealthComponent) -> void:
	assert(health == null)
	health = h
	health.health_changed.connect(_health_changed)
	health.health_depleted.connect(die)


func player_distance_squared() -> float:
	return Global.player.global_position.distance_squared_to(global_position)


## Subclasses should override to prepare steering params / agents for a frame.
func _steering_process(delta: float) -> void:
	# Calculate offset by a fixed distance
	var playerpos: Vector3 = Global.player.agent.position
	var target: Vector3 = playerpos + (agent.position - playerpos).normalized() * player_seek_offset
	_player_seek_location.position = target


## Must assign to _steering
func _setup_steering() -> void:
	# Basic agent stuff.
	agent.angular_acceleration_max = deg_to_rad(angular_accel_max)
	agent.angular_speed_max = deg_to_rad(angular_speed_max)
	agent.linear_acceleration_max = linear_accel_max
	agent.linear_speed_max = linear_speed_max


func _physics_process(delta: float) -> void:
	_steering_process(delta)

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


func maybe_drop_part() -> void:
	for droppable in droppables:
		var chance := droppable.chance * Config.DEFAULT_PART_DROP_RATE_MULTIPLIER
		if randf() < chance:
			var dropped_scene := droppable.drop.instantiate()
			var empty_drop := Config.EMPTY_PARTS_DROP_SCENE.instantiate()
			empty_drop.add_child(dropped_scene)
			empty_drop.global_position = global_position
			empty_drop.global_rotation = global_rotation
			add_sibling(empty_drop)
			# Only drop at most one thing
			break


func _health_changed(new_health: float, old_health: float) -> void:
	if new_health < old_health:
		_flash_damage()


func _flash_damage() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	sprite.material.set_shader_parameter("brightening", 2.0)
	await get_tree().create_timer(0.05).timeout
	sprite.material.set_shader_parameter("brightening", 1.0)


func die() -> void:
	die_deferred.call_deferred()


func die_deferred() -> void:
	if explosion_scene:
		var explosion := explosion_scene.instantiate()
		explosion.global_position = global_position
		add_sibling(explosion)
	Session.on_enemy_destroyed()
	maybe_drop_part()
	queue_free()
