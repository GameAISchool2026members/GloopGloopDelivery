extends Node2D

@export var game: PackedScene

func _on_play_pressed() -> void:
	get_tree().change_scene_to_packed(game)
