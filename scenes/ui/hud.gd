class_name Hud
extends PanelContainer


func set_health_ratio(ratio: float) -> void:
	%HPProgress.value = ratio


func set_growth_ratio(ratio: float) -> void:
	%XPProgress.value = ratio
