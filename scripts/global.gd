extends Node


const MAIN_LEVEL_SCENE = preload("res://scenes/level/main_level.tscn")
const LEVI_TEST_LEVEL_SCENE = preload("res://scenes/level/levi_test_level.tscn")
const ZAVEN_TEST_LEVEL_SCENE = preload("res://scenes/level/zaven_test_level.tscn")

const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const ENERGY_DROP_SCENE = preload("res://scenes/drops/energy_drop.tscn")
const EMPTY_PARTS_DROP_SCENE = preload("res://scenes/drops/empty_parts_drop.tscn")

const CORE_1_PART_SCENE := preload("res://scenes/parts/core_1_part.tscn")
const CORE_2_PART_SCENE := preload("res://scenes/parts/core_2_part.tscn")
const CORE_3_PART_SCENE := preload("res://scenes/parts/core_3_part.tscn")
const BASIC_GUN_PART_SCENE := preload("res://scenes/parts/basic_gun_part.tscn")
const BASIC_THRUSTER_PART_SCENE := preload("res://scenes/parts/basic_thruster_part.tscn")

const TRIPLE_GUN_DROP_CHUNK_SCENE := preload("res://scenes/drop_chunks/triple_gun_drop_chunk.tscn")

const GUNNER_ENEMY_SCENE := preload("res://scenes/enemies/gunner_enemy.tscn")

const EXPLOSION_SCENE := preload("res://scenes/fx/boom1.tscn")
const LEVEL_UP_EFFECT_SCENE := preload("res://scenes/player/level_up_effect.tscn")
const PART_FIRE_LOW_EFFECT_SCENE := preload("res://scenes/player/part_fire_low_effect.tscn")
const PART_FIRE_MEDIUM_EFFECT_SCENE := preload("res://scenes/player/part_fire_medium_effect.tscn")
const PART_FIRE_HIGH_EFFECT_SCENE := preload("res://scenes/player/part_fire_high_effect.tscn")

const INITIAL_CAMERA_ZOOM := 1.0
const GROWTH_LEVEL_CAMERA_ZOOM_FACTOR := 4.0

const SMALL_ITEM_HEALTH_MULTIPLIER := 0.25
const SMALL_ITEM_DAMAGE_MULTIPLIER := 0.25
const SMALL_ITEM_growth_MULTIPLIER := 0.25

const DEFAULT_NEXT_LEVEL_GROWTH := 100

const DEFAULT_PART_DROP_RATE_MULTIPLIER := 1.0

# Collision layers
const PLAYER_COLLISION_LAYER = 1 << 0
const ENEMY_COLLISION_LAYER = 1 << 2
const LEVEL_COLLISION_LAYER = 1 << 5

enum SizeType {
	UNKNOWN,
	Small,
	Normal,
	Large,
}

enum PartType {
	UNKNOWN,
	Core,
	BasicGun,
	BasicThruster,
}

enum EnemyType {
	UNKNOWN,
	Gunner,
}

const LEVEL_CONFIG := [
	{
		# Level 1
		part_health_multiplier = 1,
		next_level_growth_multiplier = 1,
		core_scene = CORE_1_PART_SCENE,
		enemies = [
			EnemyType.Gunner,
		],
	},
	{
		# Level 2
		part_health_multiplier = 4,
		next_level_growth_multiplier = 4,
		core_scene = CORE_2_PART_SCENE,
		enemies = [
			EnemyType.Gunner,
		],
	},
	{
		# Level 3
		part_health_multiplier = 16,
		next_level_growth_multiplier = 16,
		core_scene = CORE_3_PART_SCENE,
		enemies = [
			EnemyType.Gunner,
		],
	},
]

const PART_TYPE_CONFIG := {
	PartType.Core: {
		base_health = 20,
		base_growth = 0,
	},
	PartType.BasicGun: {
		base_health = 50,
		base_growth = 10,
	},
	PartType.BasicThruster: {
		base_health = 50,
		base_growth = 10,
	},
}

# TODO: Set this to true.
const skip_main_menu := false

# TODO: Adjust this.
var default_level_scene := MAIN_LEVEL_SCENE
#var default_level_scene := LEVI_TEST_LEVEL_SCENE
#var default_level_scene := ZAVEN_TEST_LEVEL_SCENE


var level_container
var hud: Hud
var main_menu: MainMenu
var game_over_screen: GameOverScreen
var level
var player: Player


static func get_growth_for_part(part_type: PartType, size_type: SizeType, growth_level: int) -> float:
	assert(PART_TYPE_CONFIG.has(part_type))
	var level_config := get_current_level_config(growth_level)
	var size_multiplier := get_item_size_growth_multiplier(size_type)
	return PART_TYPE_CONFIG[part_type].base_growth * level_config.next_level_growth_multiplier * size_multiplier


static func get_health_for_part(part_type: PartType, size_type: SizeType, growth_level: int) -> float:
	assert(PART_TYPE_CONFIG.has(part_type))
	var level_config := get_current_level_config(growth_level)
	var size_multiplier := get_item_size_health_multiplier(size_type)
	return PART_TYPE_CONFIG[part_type].base_health * level_config.part_health_multiplier * size_multiplier


static func get_item_size_health_multiplier(type: SizeType) -> float:
	match type:
		SizeType.Small:
			return SMALL_ITEM_HEALTH_MULTIPLIER
		SizeType.Normal:
			return 1.0
		_:
			assert(false)
			return 0.0


static func get_item_size_damage_multiplier(type: SizeType) -> float:
	match type:
		SizeType.Small:
			return SMALL_ITEM_DAMAGE_MULTIPLIER
		SizeType.Normal:
			return 1.0
		_:
			assert(false)
			return 0.0


static func get_item_size_growth_multiplier(type: SizeType) -> float:
	match type:
		SizeType.Small:
			return SMALL_ITEM_growth_MULTIPLIER
		SizeType.Normal:
			return 1.0
		_:
			assert(false)
			return 0.0


static func get_max_health(growth_level: int) -> float:
	return get_health_for_part(PartType.Core, SizeType.Normal, growth_level)


static func get_next_level_growth(growth_level: int) -> float:
	var level_config := get_current_level_config(growth_level)
	return DEFAULT_NEXT_LEVEL_GROWTH * level_config.next_level_growth_multiplier


static func get_enemies(growth_level: int) -> Array[EnemyType]:
	var level_config := get_current_level_config(growth_level)
	return level_config.enemies


static func part_type_to_packed_scene(type: PartType, growth_level: int) -> PackedScene:
	match type:
		PartType.Core:
			var level_config := get_current_level_config(growth_level)
			return level_config.core_scene
		PartType.BasicGun:
			return BASIC_GUN_PART_SCENE
		PartType.BasicThruster:
			return BASIC_THRUSTER_PART_SCENE
		_:
			assert(false)
			return null


static func enemy_to_packed_scene(type: EnemyType) -> PackedScene:
	match type:
		EnemyType.Gunner:
			return GUNNER_ENEMY_SCENE
		_:
			assert(false)
			return null


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
