class_name LevelContainer
extends Node2D


func _ready() -> void:
	Global.level_container = self

	var ui_container: UIContainer = get_node("UiContainer")
	assert(is_instance_valid(ui_container) and ui_container is UIContainer)
	Global.hud = ui_container.hud
	Global.main_menu = ui_container.main_menu
	Global.game_over_screen = ui_container.game_over_screen

	if Global.skip_main_menu:
		start()


func start() -> void:
	Session.current_growth_level = 1
	Session.enemies_destroyed = 0
	Session.is_game_over = false

	if is_instance_valid(Global.level):
		Global.player.queue_free()
		Global.level.queue_free()

	var level: Level = Global.default_level_scene.instantiate()
	add_child(level)

	Global.game_over_screen.visible = false
	Global.main_menu.visible = false
