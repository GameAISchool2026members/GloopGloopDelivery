class_name RobotPlayer extends Player

@export var game_manager : GameManager
@onready var policy_predictor : PolicyPredictor = $PolicyPredictor

var human_player : HumanPlayer
var terrain : Terrain
var objectives_manager : ObjectivesManager

enum State { IDLE, WALKING_TO_ITEM, WALKING_WITH_ITEM, WAITING }
var state : State = State.IDLE
#store target
#if no target -> use policy predictor

func _ready() -> void:
	if game_manager == null:
		print("uh oh")
		return
	human_player = game_manager.human_player
	terrain = game_manager.terrain
	objectives_manager = game_manager.objectives_manager
	
	policy_predictor.init(objectives_manager.get_number_of_objectives(), human_player)

func _process_next():
	pass
