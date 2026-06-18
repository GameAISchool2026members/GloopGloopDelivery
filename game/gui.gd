class_name GameGUI extends Control

@onready var timer_label : Label = $Timer
@onready var score_label : Label = $Score


func set_timer_value(value: float) -> void:
	timer_label.text = str(int(value))
	
func set_score_value(value: float) -> void:
	score_label.text = "Score: " + str(int(value))
