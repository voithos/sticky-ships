class_name LevelContainer
extends Node2D


func _ready() -> void:
	Global.level_container = self

	var ui_container: UIContainer = get_node("UiContainer")
	assert(is_instance_valid(ui_container) and ui_container is UIContainer)
	Global.hud = ui_container.hud
	Global.main_menu = ui_container.main_menu

	if Global.skip_main_menu:
		start()


func start() -> void:
	var level_scene: PackedScene

	var level: Level = Global.default_level_scene.instantiate()
	add_child(level)

	Global.main_menu.visible = false
