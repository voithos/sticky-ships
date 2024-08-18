extends Node


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

const LEVEL_UP_EFFECT_SCENE := preload("res://scenes/player/level_up_effect.tscn")
const PART_FIRE_LOW_EFFECT_SCENE := preload("res://scenes/player/part_fire_low_effect.tscn")
const PART_FIRE_MEDIUM_EFFECT_SCENE := preload("res://scenes/player/part_fire_medium_effect.tscn")
const PART_FIRE_HIGH_EFFECT_SCENE := preload("res://scenes/player/part_fire_high_effect.tscn")

const INITIAL_CAMERA_ZOOM := 1.0
const GROWTH_LEVEL_CAMERA_ZOOM_FACTOR := 4.0

const SMALL_ITEM_HEALTH_MULTIPLIER := 0.25
const SMALL_ITEM_DAMAGE_MULTIPLIER := 0.25
const SMALL_ITEM_XP_MULTIPLIER := 0.25

const DEFAULT_NEXT_LEVEL_XP := 100

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
		part_hp_multiplier = 1,
		next_level_xp_multiplier = 1,
		core_scene = CORE_1_PART_SCENE,
		enemies = [
			EnemyType.Gunner,
		],
	},
	{
		# Level 2
		part_hp_multiplier = 4,
		next_level_xp_multiplier = 4,
		core_scene = CORE_2_PART_SCENE,
		enemies = [
			EnemyType.Gunner,
		],
	},
	{
		# Level 3
		part_hp_multiplier = 16,
		next_level_xp_multiplier = 16,
		core_scene = CORE_3_PART_SCENE,
		enemies = [
			EnemyType.Gunner,
		],
	},
]

const PART_TYPE_CONFIG := {
	PartType.Core: {
		base_hp = 100,
		base_xp = 0,
	},
	PartType.BasicGun: {
		base_hp = 50,
		base_xp = 10,
	},
	PartType.BasicThruster: {
		base_hp = 50,
		base_xp = 10,
	},
}

var level: Level
var player: Player


static func get_xp_for_part(part_type: PartType, size_type: SizeType, growth_level: int) -> float:
	assert(PART_TYPE_CONFIG.has(part_type))
	var level_config := get_current_level_config(growth_level)
	var size_multiplier := get_item_size_xp_multiplier(size_type)
	return PART_TYPE_CONFIG[part_type].base_xp * level_config.next_level_xp_multiplier * size_multiplier


static func get_hp_for_part(part_type: PartType, size_type: SizeType, growth_level: int) -> float:
	assert(PART_TYPE_CONFIG.has(part_type))
	var level_config := get_current_level_config(growth_level)
	var size_multiplier := get_item_size_health_multiplier(size_type)
	return PART_TYPE_CONFIG[part_type].base_xp * level_config.part_hp_multiplier * size_multiplier


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


static func get_item_size_xp_multiplier(type: SizeType) -> float:
	match type:
		SizeType.Small:
			return SMALL_ITEM_XP_MULTIPLIER
		SizeType.Normal:
			return 1.0
		_:
			assert(false)
			return 0.0


static func get_max_health(growth_level: int) -> float:
	return get_hp_for_part(PartType.Core, SizeType.Normal, growth_level)


static func get_next_level_xp(growth_level: int) -> float:
	var level_config := get_current_level_config(growth_level)
	return DEFAULT_NEXT_LEVEL_XP * level_config.next_level_xp_multiplier


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
