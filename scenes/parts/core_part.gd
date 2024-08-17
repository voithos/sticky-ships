class_name CorePart
extends Part


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if Screen.is_debug_pressed():
		$BasicGun.try_fire()
