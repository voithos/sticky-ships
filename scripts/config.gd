extends Node


const MAIN_LEVEL_SCENE := preload("res://scenes/level/main_level.tscn")
const LEVI_TEST_LEVEL_SCENE := preload("res://scenes/level/levi_test_level.tscn")
const ZAVEN_TEST_LEVEL_SCENE := preload("res://scenes/level/zaven_test_level.tscn")

const CORE_SMALL_PART_SCENE := preload("res://scenes/parts/core_small_part.tscn")
const CORE_MEDIUM_PART_SCENE := preload("res://scenes/parts/core_medium_part.tscn")
const CORE_LARGE_PART_SCENE := preload("res://scenes/parts/core_large_part.tscn")

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const EMPTY_PARTS_DROP_SCENE := preload("res://scenes/drops/empty_parts_drop.tscn")
const TRIPLE_GUN_DROP_CHUNK_SCENE := preload("res://scenes/drop_chunks/triple_gun_drop_chunk.tscn")
const EXPLOSION_SCENE := preload("res://scenes/fx/boom1.tscn")
const LEVEL_UP_EFFECT_SCENE := preload("res://scenes/player/level_up_effect.tscn")
const PART_FIRE_LOW_EFFECT_SCENE := preload("res://scenes/player/part_fire_low_effect.tscn")
const PART_FIRE_MEDIUM_EFFECT_SCENE := preload("res://scenes/player/part_fire_medium_effect.tscn")
const PART_FIRE_HIGH_EFFECT_SCENE := preload("res://scenes/player/part_fire_high_effect.tscn")

const DROPS_GROUP := "drops"
const ENEMIES_GROUP := "enemies"
const PARTS_GROUP := "parts"
const PROJECTILES_GROUP := "projectiles"

const DEFAULT_VIEWPORT_SIZE := Vector2(320, 180)

const GROWTH_LEVEL_SCALE_FACTOR := 8.0

const MAX_GROWTH_LEVEL := 3

const INITIAL_CAMERA_ZOOM := 1.0

const GROWTH_PROGRESS_TO_NEXT_LEVEL_MULTIPLIER := 1.0

const PLAYER_PART_HEALTH_MULTIPLIER := 1.0
const PLAYER_PART_DAMAGE_MULTIPLIER := 1.0
const PLAYER_PART_SCALE_MULTIPLIER := 1.0
const PLAYER_PART_GROWTH_PROGRESS_VALUE_MULTIPLIER := 1.0
const PLAYER_PART_MASS_MULTIPLIER := 1.0

const ENEMY_HEALTH_MULTIPLIER := 1.0
const ENEMY_DAMAGE_MULTIPLIER := 1.0
const ENEMY_SCALE_MULTIPLIER := 1.0

const PROJECTILE_DAMAGE_MULTIPLIER := 1.0
const PROJECTILE_SPEED_MULTIPLIER := 1.0
const PROJECTILE_SCALE_MULTIPLIER := 1.0

const DEFAULT_PART_DROP_RATE_MULTIPLIER := 1.0

# Collision layers
const PLAYER_COLLISION_LAYER = 1 << 0
const ENEMY_COLLISION_LAYER = 1 << 2
const LEVEL_COLLISION_LAYER = 1 << 5

# TODO: Adjust this.
const DEFAULT_NEXT_LEVEL_GROWTH := 10

const LEVEL_CONFIG := [
	{
		# Level 1
		part_health_multiplier = 1,
		growth_progress_to_next_level = DEFAULT_NEXT_LEVEL_GROWTH,
		core_scene = CORE_SMALL_PART_SCENE,
	},
	{
		# Level 2
		part_health_multiplier = 4,
		growth_progress_to_next_level = DEFAULT_NEXT_LEVEL_GROWTH * 4,
		core_scene = CORE_MEDIUM_PART_SCENE,
	},
	{
		# Level 3
		part_health_multiplier = 16,
		growth_progress_to_next_level = DEFAULT_NEXT_LEVEL_GROWTH * 16,
		core_scene = CORE_LARGE_PART_SCENE,
	},
]

# TODO: Adjust this.
const skip_main_menu := true

# TODO: Adjust this.
const force_win_when_reaching_max_growth_level := true

# TODO: Adjust this.
#const default_level_scene := MAIN_LEVEL_SCENE
#const default_level_scene := LEVI_TEST_LEVEL_SCENE
var default_level_scene := ZAVEN_TEST_LEVEL_SCENE


static func get_growth_level_scale(growth_level: int) -> float:
	return pow(Config.GROWTH_LEVEL_SCALE_FACTOR, growth_level - 1)


static func get_growth_progress_to_next_level(growth_level: int) -> float:
	var level_config := get_current_level_config(growth_level)
	return GROWTH_PROGRESS_TO_NEXT_LEVEL_MULTIPLIER * level_config.growth_progress_to_next_level


static func get_current_level_config(growth_level: int) -> Dictionary:
	growth_level = min(growth_level, LEVEL_CONFIG.size())
	return LEVEL_CONFIG[growth_level - 1]


static func get_previous_level_config(growth_level: int) -> Dictionary:
	var previous_growth_level := growth_level - 1
	previous_growth_level = clamp(previous_growth_level, 1, LEVEL_CONFIG.size())
	return LEVEL_CONFIG[previous_growth_level - 1]


static func get_next_level_config(growth_level: int) -> Dictionary:
	var next_growth_level := growth_level + 1
	next_growth_level = min(next_growth_level, LEVEL_CONFIG.size())
	return LEVEL_CONFIG[next_growth_level - 1]
