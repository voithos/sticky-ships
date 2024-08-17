class_name BasicGunPart
extends Part


func _ready() -> void:
	super()


func _process(delta: float) -> void:
	super(delta)


func _physics_process(delta: float) -> void:
	if Screen.is_debug_pressed():
		$BasicGun.try_fire()
