class_name GameManager extends Node2D

@onready var gui : GameGUI = $"../CanvasLayer/GUI"

@export var game_length :float = 100

@export var human_player : Player
@export var robot_player : Player
@export var terrain : Terrain
@export var objectives_manager : ObjectivesManager

var score : float = 0
var timer : float = 0

enum State { START, GAME, END }
var state : State = State.START

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_start_game()
	
func _start_game() -> void:
	timer = game_length
	
	terrain.generate()
	objectives_manager.find_all_objectes()
	human_player.position = terrain.to_global(terrain.map_to_local(Vector2(terrain.spawns[0])+Vector2(0.5,0.5)))
	robot_player.position = terrain.to_global(terrain.map_to_local(Vector2(terrain.spawns[1])+Vector2(0.5,0.5)))
	
	# todo play start animation?

func _process_game(delta: float) -> void:
	timer -= delta
	
	gui.set_score_value(score)
	gui.set_timer_value(timer)
	
	if timer <= 0:
		_end_game()
	
func _end_game() -> void:
	state = State.END
	print("game over")
	
	#show end screen?
	

func _process(delta: float) -> void:
	if state == State.GAME:
		_process_game(delta)
