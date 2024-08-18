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

	# TODO: Adjust this.
	#level_scene = Global.MAIN_LEVEL_SCENE
	#level_scene = Global.LEVI_TEST_LEVEL_SCENE
	level_scene = Global.ZAVEN_TEST_LEVEL_SCENE

	var level: Level = level_scene.instantiate()
	add_child(level)

	Global.main_menu.visible = false
