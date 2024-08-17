class_name Hurtbox
extends Area2D

@export var health_component: HealthComponent

func _ready() -> void:
	assert(health_component != null)


func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	maybe_take_damage(area)


func _on_body_entered(body: Node2D) -> void:
	maybe_take_damage(body)


func maybe_take_damage(damager: Node2D) -> void:
	if damager is Projectile:
		health_component.take_damage(damager.damage)
