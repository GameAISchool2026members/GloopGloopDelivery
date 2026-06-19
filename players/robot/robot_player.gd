class_name RobotPlayer extends Player

@export var game_manager : GameManager
@onready var policy_predictor : PolicyPredictor = $PolicyPredictor

var human_player : HumanPlayer
var terrain : Terrain
var objectives_manager : ObjectivesManager

var path_index: int = 0
var path: PackedVector2Array = []

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
	
	print("TODO: CONNEC TPLAYER TOUCHING TO _on_player_interacted")
	human_player.pickup_objective.connect(_on_player_interacted)
	_move_to_global_pos(human_player.global_position)
	
	find_target()

func _physics_process(delta):
	if path_index >= path.size():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target := path[path_index]

	if global_position.distance_to(target) < 4.0:
		path_index += 1
	else:
		velocity = global_position.direction_to(target) * speed
		
	move_and_slide()

func _move_to_global_pos(global_target_pos: Vector2):
	var this_local = terrain.local_to_map(terrain.to_local(global_position))
	var target_local = terrain.local_to_map(terrain.to_local(global_target_pos))
	path = terrain.astar.get_point_path(this_local, target_local)
	path_index = 0


func find_target() -> void:
	print("finding target")
	var prediction_probs := policy_predictor.predict(human_player)
	if prediction_probs.is_empty():
		return

	var sorted_indices: Array[int] = []
	for i in range(prediction_probs.size()):
		sorted_indices.append(i)
	
	sorted_indices.sort_custom(func(a, b): return prediction_probs[a] < prediction_probs[b])
	
	var target_position : Vector2
	var target_found := false
	for idx in sorted_indices:
		if idx >= policy_predictor.active_objectives.size():
			continue
			
		var potential_objective = policy_predictor.active_objectives[idx]
		
		if  (potential_objective):
			target_position = potential_objective.global_position
			target_found = true
			
			print("Robot targeted: %s | Probability: %.1f%%" % [
				potential_objective.name, 
				prediction_probs[idx] * 100.0
			])
			break
			
	_move_to_global_pos(target_position)
			
	if not target_found:
		print("All neglected objectives are currently invalid or unreachable.")
		
	await get_tree().create_timer(4.0).timeout
	
	find_target()

func _is_objective_valid_target(objective: Node2D) -> bool:
	if objective.has_method("is_available") and not objective.is_available():
		return false
	return true
	
func _on_player_interacted(node : Node2D) -> void:
	print("hi!!")
	return
	var id = objectives_manager.object_to_id()
	policy_predictor.train(id, human_player)
	
