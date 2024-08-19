class_name GameOverScreen
extends PanelContainer


func open() -> void:
	%GrowthProgressLabel.text = "Destroyed %d enemies." % Session.enemies_destroyed
	%EnemiesKilledLabel.text = "Grew to level %d." % Session.current_growth_level
	visible = true


func _on_play_button_pressed() -> void:
	Global.level_container.start()


func _on_zaven_link_pressed() -> void:
	OS.shell_open("https://voithos.io")


func _on_alden_link_pressed() -> void:
	OS.shell_open("https://www.instagram.com/aldenwitty")


func _on_levi_link_pressed() -> void:
	OS.shell_open("https://levi.dev")
