extends Control

@export var GUI: Control
@export var game_manager: GameManager
@export var score_label: Label

func _on_play_pressed() -> void:
	var game_scene = load("res://menu/menu.tscn") 
	get_tree().change_scene_to_packed(game_scene)

func _enter_tree() -> void:
	modulate.a = 0.0
	visible = false

func trigger_end_screen() -> void:
	visible = true
	var tween = create_tween().set_parallel(true)
	
	if GUI:
		tween.tween_property(GUI, "modulate:a", 0.0, 0.5)
	
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	for child in get_children():
		if child is Label or child is Button:
			child.pivot_offset = child.size / 2.0
			child.scale = Vector2.ZERO
			tween.tween_property(child, "scale", Vector2.ONE, 0.4)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)
				
	score_label.text = "Final Score: " + str(int(game_manager.score))
