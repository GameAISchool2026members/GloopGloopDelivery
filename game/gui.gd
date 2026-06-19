class_name GameGUI extends Control

@onready var timer_label : Label = $Timer
@onready var score_label : Label = $Score
@onready var score_table : Label = $PanelContainer/ScoreTable

func set_timer_value(value: float) -> void:
	timer_label.text = str(int(value))
	
func set_score_value(value: float) -> void:
	score_label.text = "Score: " + str(int(value))
func set_score_table_value(table: Dictionary[Item,int]) -> void:
	var text = "worth: \n"
	for item in table:
		var value = table[item]
		text +="%s: %d\n" % [item.name, value]
	score_table.text = text
