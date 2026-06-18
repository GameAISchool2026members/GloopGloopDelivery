class_name RobotPlayer extends Player

@export var game_manager : GameManager
@onready var policy_predictor : PolicyPredictor

var human_player : HumanPlayer
var tile_map_layer : TileMapLayer
var objectives_manager : ObjectivesManager

enum State { IDLE, WALKING_TO_ITEM, WALKING_WITH_ITEM, WAITING }
var state : State = State.IDLE
#store target
#if no target -> use policy predictor

func _ready() -> void:
	human_player = game_manager.human_player
	tile_map_layer = game_manager.tile_map_layer
	objectives_manager = game_manager.objectives_manager
	
	policy_predictor.init(objectives_manager.get_number_of_objectives(), human_player)

func _process_next():
	pass
