extends Node


var level_container
var hud: Hud
var main_menu: MainMenu
var game_over_screen: GameOverScreen
var level: Level
var player: Player


func is_at_max_growth_level() -> bool:
	return Session.current_growth_level == Config.MAX_GROWTH_LEVEL
