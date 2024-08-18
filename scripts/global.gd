extends Node


const PLAYER_SCENE = preload("res://scenes/player/player.tscn")
const ENERGY_DROP_SCENE = preload("res://scenes/drops/energy_drop.tscn")
const EMPTY_PARTS_DROP_SCENE = preload("res://scenes/drops/empty_parts_drop.tscn")

const CORE_1_PART_SCENE := preload("res://scenes/parts/core_1_part.tscn")
const CORE_2_PART_SCENE := preload("res://scenes/parts/core_2_part.tscn")
const BASIC_GUN_PART_SCENE := preload("res://scenes/parts/basic_gun_part.tscn")
const BASIC_THRUSTER_PART_SCENE := preload("res://scenes/parts/basic_thruster_part.tscn")

const TRIPLE_GUN_DROP_CHUNK_SCENE := preload("res://scenes/drop_chunks/triple_gun_drop_chunk.tscn")

var level: Level
var player: Player


enum PartType {
	UNKNOWN,
	Core,
	BasicGun,
	BasicThruster,
}


static func part_type_to_packed_scene(type: PartType, growth_level: int) -> PackedScene:
	match type:
		PartType.Core:
			match growth_level:
				1:
					return CORE_1_PART_SCENE
				2:
					return CORE_2_PART_SCENE
				_:
					return CORE_2_PART_SCENE
		PartType.BasicGun:
			return BASIC_GUN_PART_SCENE
		PartType.BasicThruster:
			return BASIC_THRUSTER_PART_SCENE
		_:
			assert(false)
			return null
