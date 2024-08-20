class_name WaveSpawner
extends Node2D

## Minimum time until next wave
@export var wave_min_time := 10.0
## Max time until next wave
@export var wave_max_time := 20.0

## The amount of "spawn currency" bonus from # of enemies defated (in total)
@export var enemies_defeated_bonus := 1.0
## The amount of "spawn currency" bonus based on growth level
@export var growth_level_bonus := 1.0

## The max number of enemies spawned at one time. If 0, no max
@export var max_spawned := 0

## TODO: Add multiple levels of spawnables
@export var spawnables: Array[Spawnable] = []

## This gets scaled by the level scale factor
const SPAWN_DISTANCE_OUTSIDE_VIEWPORT_RADIUS := 5

var is_paused := false
var time_remaining := 0.0

var minimum_cost: float = INF
var total_weights: float = 0.0

# TODO: Add a signal in case all enemies are destroyed early, we fire off the next wave

func _ready() -> void:
	for s in spawnables:
		minimum_cost = minf(minimum_cost, s.cost)
		total_weights += s.weight


func _physics_process(delta: float) -> void:
	time_remaining -= delta
	if time_remaining < 0:
		_spawn()


func _spawn() -> void:
	var currency := _calculate_currency()

	var spawn_radius := _get_spawn_radius()

	var spawn_count := 0
	while currency >= minimum_cost:
		var idx := _weighted_pick()
		var s := spawnables[idx]
		if s.cost <= currency:
			currency -= s.cost
			_spawn_one(s, _get_random_spawn_position(spawn_radius))
		spawn_count += 1
		if max_spawned > 0 and spawn_count >= max_spawned:
			# Stop spawning
			break

	_schedule_next_spawn()


func _weighted_pick() -> int:
	var target_weight := randf() * total_weights

	for i in spawnables.size():
		var s := spawnables[i]
		target_weight -= s.weight
		if target_weight <= 0.0:
			return i
	# Edge case, should only happen due to extreme fp precision error
	return 0


func _calculate_currency() -> float:
	return (
		Session.current_growth_level * growth_level_bonus +
		Session.enemies_destroyed * enemies_defeated_bonus +
		minimum_cost
	)


func _spawn_one(s: Spawnable, offset: Vector2) -> void:
	var spawned := s.scene.instantiate()

	spawned.global_position = global_position + offset
	spawned.global_rotation = Vector2.UP.angle_to(-offset)
	Global.level.add_child(spawned)


func _get_random_spawn_position(spawn_radius: float) -> Vector2:
	return Vector2.from_angle(randf() * PI * 2) * spawn_radius


func _get_spawn_radius() -> float:
	var viewport_radius := (Config.DEFAULT_VIEWPORT_SIZE / 2.0).length()
	return (viewport_radius + SPAWN_DISTANCE_OUTSIDE_VIEWPORT_RADIUS) *  Config.get_growth_level_scale(Session.current_growth_level)


func _schedule_next_spawn() -> void:
	time_remaining = randf_range(wave_min_time, wave_max_time)
