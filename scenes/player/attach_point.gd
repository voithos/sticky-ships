class_name AttachPoint
extends Area2D


const EDITOR_HINT_FILL_COLOR := Color(Color.AQUAMARINE, 0.3)
const EDITOR_HINT_OUTLINE_COLOR := Color(Color.AQUAMARINE, 0.7)

var part: Part

var connection: PartConnection


func _enter_tree() -> void:
	var parent := get_parent()
	assert(get_parent() is Part)
	part = parent
	part.attach_points.push_back(self)


func _process(delta: float) -> void:
	pass


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
