class_name GameGUI extends Control

@onready var timer_label : Label = $Timer
@onready var score_label : Label = $Score
@onready var score_table : Label = $PanelContainer/ScoreTable
@onready var bored_bar : ProgressBar = $ProgressBar
func set_timer_value(value: float) -> void:
	timer_label.text = str(int(value))
	
func set_score_value(value: float) -> void:
	score_label.text = "Score: " + str(int(value))
func set_score_table_value(table: Dictionary[Item,float]) -> void:
	var text = "worth: \n"
	for item in table:
		var value = round(table[item])
		text +="%s: %d\n" % [item.name, value]
	score_table.text = text
func set_progress_bar(value: float) -> void:
	bored_bar.value = value
	
