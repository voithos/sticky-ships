extends Node


const CORE_PART_SCENE := preload("res://scenes/parts/core_part.tscn")
const BASIC_GUN_PART_SCENE := preload("res://scenes/parts/basic_gun_part.tscn")
const BASIC_THRUSTER_PART_SCENE := preload("res://scenes/parts/basic_thruster_part.tscn")

var level: Level
var player: Player


static func part_type_to_packed_scene(type: Part.Type) -> PackedScene:
	match type:
		Part.Type.Core:
			return CORE_PART_SCENE
		Part.Type.BasicGun:
			return BASIC_GUN_PART_SCENE
		Part.Type.BasicThruster:
			return BASIC_THRUSTER_PART_SCENE
		_:
			assert(false)
			return null
