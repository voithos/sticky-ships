extends Node

var is_paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Never pause this node.
	if not OS.is_debug_build():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_ESCAPE and not OS.has_feature("HTML5"):
			# Quitting doesn't make sense for web.
			get_tree().quit()
		if event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

		# TODO: Add this back in.
		#if OS.is_debug_build():
			#if event.keycode == KEY_P:
				#is_paused = not is_paused
				#get_tree().set_pause(is_paused)


func is_debug_pressed():
	return OS.is_debug_build() and Input.is_action_just_pressed("debug")
