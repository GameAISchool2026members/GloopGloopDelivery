class_name GameManager extends Node2D

@onready var gui : GameGUI = $"../CanvasLayer/GUI"

@export var game_length :float = 100
@export var score_table: Dictionary[Item, int]
@export var human_player : Player
@export var robot_player : Player
@export var terrain : Terrain
@export var objectives_manager : ObjectivesManager


var score : float = 0
var timer : float = 0
enum State { START, GAME, END }
var state : State = State.START

func _signal_bus_item_collected(item: Item) -> void:
	print("score!")
	for item_score in score_table:
		if item==item_score:
			score_table[item_score] -= 1
		else:
			score_table[item_score] += 1
	var points = score_table[item]
	score += points

func _enter_tree() -> void:
	terrain.generate()
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_game()
	SignalBus.item_collected.connect(_signal_bus_item_collected)
	state = State.GAME
	
func _start_game() -> void:
	timer = game_length
	
	
	
	objectives_manager.find_all_objectes()
	human_player.global_position = terrain.map_to_local(terrain.spawns[0])
	robot_player.global_position = terrain.map_to_local(terrain.spawns[1]) 
	
	# todo play start animation?

func _process_game(delta: float) -> void:
	timer -= delta
	
	gui.set_score_value(score)
	gui.set_timer_value(timer)
	gui.set_score_table_value(score_table)
	if timer <= 0:
		_end_game()
	
func _end_game() -> void:
	state = State.END
	print("game over")
	
	#show end screen?
	

func _process(delta: float) -> void:
	if state == State.GAME:
		_process_game(delta)
