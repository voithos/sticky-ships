class_name Hud
extends PanelContainer


func set_health_ratio(ratio: float) -> void:
	%HealthProgress.value = ratio


func set_growth_ratio(ratio: float) -> void:
	%GrowthProgress.value = ratio
	%GrowthRow.visible = true


func disable_growth() -> void:
	%GrowthProgress.value = 0.0
	%GrowthRow.visible = false
