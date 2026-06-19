class_name GameManager extends Node2D

@onready var gui : GameGUI = $"../CanvasLayer/GUI"

@export var game_length :float = 100
@export var score_table: Dictionary[Item, float]
@export var human_player : Player
@export var robot_player : Player
@export var terrain : Terrain
@export var objectives_manager : ObjectivesManager


var score : float = 0
var timer : float = 0
enum State { START, GAME, END }
var state : State = State.START
var boredness: float = 0

func _signal_bus_item_collected(item: Item) -> void:
	print("score!")
	for item_score in score_table:
		if item==item_score:
			score_table[item_score] -= 0.2
		else:
			score_table[item_score] += 0.2
	var points = round(score_table[item])
	score += points
func _boredness_meter_process(item: Item) -> void:
	var robot_history = robot_player.history_items
	var counts = {}
	var most_common = null
	var highest = 0
	print("processing boredness")
	print(robot_history)
	for prev_item in robot_history:
		counts[prev_item] = counts.get(prev_item, 0) + 1
		print(counts)
		if counts[prev_item] > highest:
			highest = counts[prev_item]
			most_common = prev_item
	if highest > 2:
		print("robot is bored")
		(robot_player as RobotPlayer).bored_particles()
		boredness +=1
func _enter_tree() -> void:
	terrain.generate()
	if objectives_manager:
		objectives_manager.game_manager = self
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_game()
	SignalBus.item_collected.connect(_signal_bus_item_collected)
	robot_player.pickup_objective.connect(_boredness_meter_process)
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
	gui.set_progress_bar(boredness)
	if timer <= 0:
		_end_game()
	
func _end_game() -> void:
	state = State.END
	print("game over")
	
	#show end screen?
	

func _process(delta: float) -> void:
	if state == State.GAME:
		_process_game(delta)
