extends Node

var current_growth_level := 1
var enemy_count := 0
var enemies_destroyed := 0
var is_game_over := false
var did_player_win := false

signal enemy_count_changed(current: int, previous: int)


func on_enemy_created() -> void:
	var previous := enemy_count
	enemy_count += 1
	enemy_count_changed.emit(enemy_count, previous)


func on_enemy_destroyed() -> void:
	var previous := enemy_count
	enemy_count -= 1
	enemies_destroyed += 1
	enemy_count_changed.emit(enemy_count, previous)
