class_name AttachPoint
extends Area2D


const ATTACH_POINT_DEFAULT_RADIUS := 6

const EDITOR_HINT_FILL_COLOR := Color(Color.AQUAMARINE, 0.3)
const EDITOR_HINT_OUTLINE_COLOR := Color(Color.AQUAMARINE, 0.7)

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


func _update_radius() -> void:
	$CollisionShape2D.shape.radius = ATTACH_POINT_DEFAULT_RADIUS * pow(Global.GROWTH_LEVEL_CAMERA_ZOOM_FACTOR, Global.level.current_growth_level - 1)


func _draw() -> void:
	# Not currently used.
	if Engine.is_editor_hint():
		var radius := ($CollisionShape2D.shape as CircleShape2D).radius
		draw_circle(Vector2.ZERO, radius, EDITOR_HINT_FILL_COLOR, true)
		draw_circle(Vector2.ZERO, radius, EDITOR_HINT_OUTLINE_COLOR, false)


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
