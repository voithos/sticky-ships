class_name Level
extends Node2D


signal level_up

const GROWTH_LEVEL_TRANSITION_DURATION := 0.7

var levelling_up := false

var player: Player
var drops: Array[Drop] = []

var growth_level_tween: Tween


func _enter_tree() -> void:
	Global.level = self

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


func increment_growth_level() -> void:
	var next_level := Session.current_growth_level + 1

	levelling_up = true

	var camera := get_viewport().get_camera_2d()

	var next_zoom := Vector2.ONE * Global.INITIAL_CAMERA_ZOOM / pow(Global.GROWTH_LEVEL_CAMERA_ZOOM_FACTOR, next_level - 1)

	# FIXME: Implement growth system
	#
	# - Add a new growth_level property on all parts, projectiles, and enemies.
	# - Implement MVP end condition.
	#   - Grow to level 3.
	# - And update systems to spawn new items at the correct scale and resolution.
	#   - No tiny guys on the first level.
	# - Create high and low res copies of all parts, projectiles, and enemies.
	# - Add some logic for spawning large-version drops in the current level.
	#   - And chunks of them.
	# - Reduce enemy drops to compensate.
	# - Balance config multipliers for each growth level.
	#
	# - Show some sort of particle effect.
	# - Damage everything within a radius.
	#
	# - Show sprite overlays for whichever aspects have been upgraded.

	if is_instance_valid(growth_level_tween):
		growth_level_tween.kill()

	player.level_up(next_level)

	await get_tree().create_timer(LevelUpEffect.ANIMATION_FULL_SHIELD_DELAY).timeout

	Session.current_growth_level = next_level
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
