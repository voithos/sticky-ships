class_name LevelUpEffect
extends Node2D


signal half_finished
signal finished

const ANIMATION_FULL_SHIELD_DELAY := 0.5
const BOUNDING_BOX_SCALE_MULTIPLIER := 1.3


func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

	await get_tree().create_timer(ANIMATION_FULL_SHIELD_DELAY).timeout
	half_finished.emit()


func get_sprite_size() -> Vector2:
	var animation: StringName = $AnimatedSprite2D.animation
	var texture: Texture2D = $AnimatedSprite2D.sprite_frames.get_frame_texture(animation, 0)
	return texture.get_size()


func _on_animation_finished() -> void:
	finished.emit()
