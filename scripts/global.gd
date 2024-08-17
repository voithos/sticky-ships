extends Node


const CORE_PART_SCENE := preload("res://scenes/parts/core_part.tscn")
const BASIC_GUN_PART_SCENE := preload("res://scenes/parts/basic_gun_part.tscn")
const BASIC_THRUSTER_PART_SCENE := preload("res://scenes/parts/basic_thruster_part.tscn")

var level: Level
var player: Player


enum PartType {
	Core,
	BasicGun,
	BasicThruster,
}

static func part_type_to_packed_scene(type: PartType) -> PackedScene:
	match type:
		PartType.Core:
			return CORE_PART_SCENE
		PartType.BasicGun:
			return BASIC_GUN_PART_SCENE
		PartType.BasicThruster:
			return BASIC_THRUSTER_PART_SCENE
		_:
			assert(false)
			return null
