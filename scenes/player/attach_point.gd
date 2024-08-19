class_name AttachPoint
extends Area2D


const ATTACH_POINT_DEFAULT_RADIUS := 6

const ATTACH_HINT_MAX_RADIUS_MULTIPLIER := 1.5
const ATTACH_HINT_PULSE_PERIOD_SEC := 1.0

const ATTACH_HINT_FILL_COLOR := Color("22c278", 0.1)
const ATTACH_HINT_OUTLINE_COLOR := Color("22c278", 0.4)

var start_time := -1

var part: Part

var connection: PartConnection


func _enter_tree() -> void:
	var parent := get_parent()
	assert(get_parent() is Part)
	part = parent
	part.attach_points.push_back(self)


func stop_animation() -> void:
	$Anchor.play("idle")


func _ready() -> void:
	_update_radius()
	Global.level.level_up.connect(_update_radius)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attach"):
		start_time = Time.get_ticks_msec()

	if Input.is_action_pressed("attach") or Input.is_action_just_released("attach"):
		queue_redraw()


func _update_radius() -> void:
	$CollisionShape2D.shape.radius = ATTACH_POINT_DEFAULT_RADIUS * pow(Global.GROWTH_LEVEL_CAMERA_ZOOM_FACTOR, Session.current_growth_level - 1)


func _draw() -> void:
	if Input.is_action_pressed("attach") and !is_instance_valid(connection):
		var current_time := Time.get_ticks_msec()
		var period_ms := ATTACH_HINT_PULSE_PERIOD_SEC * 1000
		var min_radius: float = $CollisionShape2D.shape.radius
		var max_radius := min_radius * ATTACH_HINT_MAX_RADIUS_MULTIPLIER
		var pulse_progress := fmod((current_time - start_time), period_ms)
		var cyclical_progress = sin(pulse_progress / period_ms * PI)
		var radius: float = lerp(min_radius, max_radius, cyclical_progress)
		draw_circle(Vector2.ZERO, radius, ATTACH_HINT_FILL_COLOR, true)
		draw_circle(Vector2.ZERO, radius, ATTACH_HINT_OUTLINE_COLOR, false)


func _on_area_entered(area: Area2D) -> void:
	if Global.player.body.attaching:
		# This overlap event is happening while reparenting parts during attachment.
		return

	if area is AttachPoint:
		if (connection == null and
				area.connection == null and
				area.part.attached_to_player != part.attached_to_player):
			Global.player.body.on_potential_attach_point_overlap_started(self, area)


func _on_area_exited(area: Area2D) -> void:
	if Global.player.body.attaching:
		# This overlap event is happening while reparenting parts during attachment.
		return

	if area is AttachPoint:
		if area.part.attached_to_player != part.attached_to_player:
			Global.player.body.on_potential_attach_point_overlap_ended(self, area)
