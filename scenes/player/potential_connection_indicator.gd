class_name PotentialConnectionIndicator
extends Node2D


const MIN_RADIUS := 12.0
const MAX_RADIUS := 18.0
const PULSE_PERIOD_SEC := 1.0

const FILL_COLOR := Color(Color.AQUAMARINE, 0.1)
const OUTLINE_COLOR := Color(Color.AQUAMARINE, 0.7)

var start_time := -1


func _ready() -> void:
	start_time = Time.get_ticks_msec()


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var current_time := Time.get_ticks_msec()
	var period_ms := PULSE_PERIOD_SEC * 1000
	var pulse_progress := fmod((current_time - start_time), period_ms)
	var cyclical_progress = sin(pulse_progress / period_ms * PI)
	var radius: float = lerp(MIN_RADIUS, MAX_RADIUS, cyclical_progress)
	draw_circle(Vector2.ZERO, radius, FILL_COLOR, true)
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR, false)
