extends Node2D

func _on_play_pressed() -> void:
	var game_scene = load("res://game/game.tscn") 
	get_tree().change_scene_to_packed(game_scene)
