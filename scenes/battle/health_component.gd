class_name HealthComponent
extends Node

@export var max_health := 100.0
@onready var health := max_health

signal health_depleted
signal health_changed(new_health: float, prev_health: float)

func adjust_health(delta: float) -> void:
	var prev_health = health
	health = clamp(health + delta, 0.0, max_health)
	if health != prev_health:
		health_changed.emit(health, prev_health)
	if is_equal_approx(health, 0.0):
		health_depleted.emit()
