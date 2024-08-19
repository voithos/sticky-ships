@tool
class_name MyButton
extends Button


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	# TODO: SFX.
	pass
