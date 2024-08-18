class_name Hud
extends PanelContainer


func set_hp_ratio(ratio: float) -> void:
	%HPProgress.value = ratio


func set_xp_ratio(ratio: float) -> void:
	%XPProgress.value = ratio
