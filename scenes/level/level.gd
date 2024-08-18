class_name Level
extends Node2D


signal level_up

const GROWTH_LEVEL_TRANSITION_DURATION := 0.7

var hud: Hud
var main_menu: MainMenu

var current_growth_level := 1
var levelling_up := false

var player: Player
var drops: Array[Drop] = []

var growth_level_tween: Tween


func _enter_tree() -> void:
	Global.level = self


func start() -> void:
	var ui_container: UIContainer = get_node("UiContainer")
	assert(is_instance_valid(ui_container) and ui_container is UIContainer)
	hud = ui_container.hud
	main_menu = ui_container.main_menu

	player = Global.PLAYER_SCENE.instantiate()
	Global.player = player
	add_child(player)

	# TODO: Remove.
	#var drop = Global.ENERGY_DROP_SCENE.instantiate()
	#add_child(drop)

	# TODO: Remove.
	var drop_chunk := Global.TRIPLE_GUN_DROP_CHUNK_SCENE.instantiate()
	drop_chunk.position = Vector2(0.0, 48.0)
	add_child(drop_chunk)

	# TODO: Remove.
	#await get_tree().create_timer(1.0).timeout
	#increment_growth_level()

	main_menu.visible = false


func destroy_player_part(part: Part) -> void:
	var descendant_parts: Array[Part] = []
	part.get_all_descendants(descendant_parts)

	# Detach from children.
	for connection in part.child_connections:
		connection.child.connection = null
		connection.child.part.parent_connection = null

	# Detach from parent.
	if part.parent_connection != null:
		part.parent_connection.parent.connection = null
		part.parent_connection.parent.part.child_connections.erase(part.parent_connection)

	var drop := Global.EMPTY_PARTS_DROP_SCENE.instantiate()
	add_child(drop)
	drops.push_back(drop)

	for descendant_part in descendant_parts:
		descendant_part.looks_for_nearby_connections_when_entering_tree = false
		drop.add_child(descendant_part)
		Global.player.body.on_part_removed(descendant_part)

	Global.player.body.on_part_removed(part)
	part.queue_free()


func increment_growth_level() -> void:
	var next_level := current_growth_level + 1

	levelling_up = true

	var camera := get_viewport().get_camera_2d()

	var next_zoom := Vector2.ONE * Global.INITIAL_CAMERA_ZOOM / pow(Global.GROWTH_LEVEL_CAMERA_ZOOM_FACTOR, next_level - 1)

	# TODO: Implement growth system
	# - For every non-player sprite:
	#   - Fade in/out new/old sprites for that entity.
	# - Show some sort of particle effect.
	# - Show sprite overlays for whichever aspects have been upgraded.
	# - Damage everything within a radius?
	# - Heal core health?

	if is_instance_valid(growth_level_tween):
		growth_level_tween.kill()

	player.level_up(next_level)

	await get_tree().create_timer(LevelUpEffect.ANIMATION_FULL_SHIELD_DELAY).timeout

	current_growth_level = next_level
	level_up.emit()

	growth_level_tween = get_tree() \
		.create_tween() \
		.set_ease(Tween.EaseType.EASE_IN_OUT) \
		.set_trans(Tween.TransitionType.TRANS_QUINT)
	growth_level_tween.parallel().tween_property(
		camera, "zoom", next_zoom, GROWTH_LEVEL_TRANSITION_DURATION)
	growth_level_tween.parallel().tween_property(
		player.body, "modulate:a", 1.0, GROWTH_LEVEL_TRANSITION_DURATION / 2).from(0.0)
	growth_level_tween.tween_callback(_on_growth_transition_finished)


func _on_growth_transition_finished() -> void:
	growth_level_tween = null
	levelling_up = false
