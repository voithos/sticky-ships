class_name Level
extends Node2D


signal leveled_up

const GROWTH_LEVEL_TRANSITION_DURATION := 0.7

var levelling_up := false

var player: Player
var drops: Array[Drop] = []

var growth_level_tween: Tween


func _enter_tree() -> void:
	Global.level = self

	player = Config.PLAYER_SCENE.instantiate()
	Global.player = player
	add_child(player)

	# TODO: Remove.
	#var drop := Config.ENERGY_DROP_SCENE.instantiate()
	#add_child(drop)

	# TODO: Remove.
	var drop_chunk := Config.TRIPLE_GUN_DROP_CHUNK_SCENE.instantiate()
	drop_chunk.position = Vector2(0.0, 48.0)
	add_child(drop_chunk)

	# TODO: Remove.
	#await get_tree().create_timer(1.0).timeout
	#level_up()
	#await get_tree().create_timer(4.0).timeout
	#level_up()


func level_up() -> void:
	assert(!Global.is_at_max_growth_level())

	var next_level := Session.current_growth_level + 1

	levelling_up = true

	var camera := get_viewport().get_camera_2d()

	var next_zoom := Vector2.ONE * Config.INITIAL_CAMERA_ZOOM / Config.get_growth_level_scale(next_level)

	# FIXME: Implement growth system
	#
	# - Reduce projectile damage when it's small.
	# - Update systems to spawn new items at the correct scale and resolution.
	#   - Enemy-wave system.
	#   - Guns shooting projectiles.
	#   - No tiny guys on the first level.
	# - Create a new set of enemies, projectiles, and parts for each growth level.
	# - Add some logic for spawning large-version drops in the current level?
	#   - And chunks of them.
	#   - These will be stationary, non-interactive obstacles for the player to move around.
	#   - Then add logic to activate these as interactible when leveling-up.
	#   - We could do the same thing for enemies.
	#   - For this to work, we might need the scale factor to be bigger. x16?
	#     - We probably would still want to only create art at x8 though, and then scale the art differently.
	#   - Slightly reduce enemy drops to compensate.
	# - Balance config multipliers for each growth level.
	#
	# - Damage/destroy all enemies within a radius when leveling-up.
	#
	# - Show sprite overlays for whichever aspects have been upgraded.

	if is_instance_valid(growth_level_tween):
		growth_level_tween.kill()

	player.level_up(next_level)

	await get_tree().create_timer(LevelUpEffect.ANIMATION_FULL_SHIELD_DELAY).timeout

	Session.current_growth_level = next_level
	leveled_up.emit()

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
	# Remove too-small parts from the player.
	player.body.remove_too_small_parts(Session.current_growth_level)

	# Remove too-small parts from drops.
	for drop in drops:
		if drop is PartsDrop:
			drop.remove_too_small_parts(Session.current_growth_level)

	# Remove any drops that are now empty or too small.
	var drops_to_remove := drops.filter(func (drop: Drop): return drop.growth_level < Session.current_growth_level - 1 or drop.parts.is_empty())
	for drop in drops_to_remove:
		drop.queue_free()

	# Remove too-small enemies.
	var enemies := get_tree().get_nodes_in_group(Config.ENEMIES_GROUP)
	var enemies_to_remove := enemies.filter(func (enemy: Node):
		assert(enemy is Enemy)
		return enemy.growth_level < Session.current_growth_level - 1
	)
	for enemy in enemies_to_remove:
		# No boom, no drops.
		enemy.queue_free()

	# Remove too-small projectiles.
	var projectiles := get_tree().get_nodes_in_group(Config.PROJECTILES_GROUP)
	var projectiles_to_remove := projectiles.filter(func (projectile: Node):
		assert(projectile is Projectile)
		return projectile.growth_level < Session.current_growth_level - 1
	)
	for projectile in projectiles_to_remove:
		# No pop.
		projectile.queue_free()

	growth_level_tween = null
	levelling_up = false
	if Global.is_at_max_growth_level() and Config.force_win_when_reaching_max_growth_level:
		player.win()
