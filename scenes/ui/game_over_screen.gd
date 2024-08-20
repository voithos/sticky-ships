class_name GameOverScreen
extends PanelContainer


const REDUCED_SFX_VOLUME := -7.0

var default_sfx_volume: float


func _ready() -> void:
	var sfx_index := AudioServer.get_bus_index("SFX")
	default_sfx_volume = AudioServer.get_bus_volume_db(sfx_index)


func open() -> void:
	%GrowthProgressLabel.text = "Destroyed %d enemies." % Session.enemies_destroyed
	%EnemiesKilledLabel.text = "Reached level %d." % Session.current_growth_level
	if Session.did_player_win:
		%Title.text = "You win!"
	else:
		%Title.text = "Game Over"
	visible = true

	var sfx_index := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_index, REDUCED_SFX_VOLUME)


func _on_play_button_pressed() -> void:
	var sfx_index := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_index, default_sfx_volume)

	Global.level_container.start()


func _on_zaven_link_pressed() -> void:
	OS.shell_open("https://voithos.io")


func _on_alden_link_pressed() -> void:
	OS.shell_open("https://www.instagram.com/aldenwitty")


func _on_levi_link_pressed() -> void:
	OS.shell_open("https://levi.dev")
