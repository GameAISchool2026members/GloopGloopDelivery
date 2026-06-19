class_name RobotPlayer extends Player

@onready var policy_predictor : PolicyPredictor = $PolicyPredictor

var human_player : HumanPlayer
var terrain : Terrain

var path_index: int = 0
var path: PackedVector2Array = []

enum State { IDLE, WALKING, WAITING }
var state : State = State.IDLE
var target_node : Node2D

var history_items: Array = []
var max_history_size: int = 10

func _ready() -> void:
	if game_manager == null:
		print("uh oh")
		return
	human_player = game_manager.human_player
	terrain = game_manager.terrain
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	objectives_manager = game_manager.objectives_manager
	pickup_objective.connect(_on_robot_interacted)
	policy_predictor.init(objectives_manager.get_number_of_objectives(), human_player)
	
	human_player.pickup_objective.connect(_on_player_interacted)
	
	
func _process(delta):
	super(delta)
	
	match state:
		State.IDLE:
			if target_node == null:
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
	
func get_current_objectives() -> Array[Dictionary]:
	if item:
		return objectives_manager.get_all_target_objectives_given_item(item)
	
	return objectives_manager.get_all_target_objectives()

# Hyperparameter weights to control the robot's priorities
@export var policy_weight: float = 1.0  # How much the AI's prediction matters
@export var result_weight: float = 0.5  # How much the built-in game score matters

func find_target() -> void:
	print("finding target")
	var prediction_probs := policy_predictor.predict(human_player)
	if prediction_probs.is_empty():
		return

	target_node = null
	var objectives: Array[Dictionary] = get_current_objectives()
	if objectives.is_empty():
		return
			
	var raw_neglect_scores := PackedFloat32Array()
	var raw_result_scores := PackedFloat32Array()
	
	for o in objectives:
		raw_neglect_scores.append(-prediction_probs[o.index])
		raw_result_scores.append(o.result_score)
		
	var neglect_distribution := _softmax(raw_neglect_scores)
	var result_distribution := _softmax(raw_result_scores)
	
	var combined_probs := PackedFloat32Array()
	var total_distribution_sum := 0.0
	
	for i in range(objectives.size()):
		var mixed_score = (neglect_distribution[i] * policy_weight) + (result_distribution[i] * result_weight)
		combined_probs.append(mixed_score)
		total_distribution_sum += mixed_score
		
	for i in range(combined_probs.size()):
		combined_probs[i] /= total_distribution_sum
		objectives[i].sampling_weight = combined_probs[i]
		
	var roll := randf()
	var cumulative_probability := 0.0
	var selected_objective_dict: Dictionary
	
	for o in objectives:
		cumulative_probability += o.sampling_weight
		if roll <= cumulative_probability:
			selected_objective_dict = o
			break
			
	if selected_objective_dict.is_empty():
		selected_objective_dict = objectives.back()
		
	var potential_objective_node = selected_objective_dict.node
	target_node = potential_objective_node
	
	print("Robot targeted: %s | Total Sampling Chance: %.1f%%" % [
		potential_objective_node.name, 
		selected_objective_dict.sampling_weight * 100.0
	])            
	
	_emote(target_node)
	_move_to_global_pos(target_node.global_position)
			
	if not target_node:
		print("All neglected objectives are currently invalid or unreachable.")
	
	state = State.WALKING
func _softmax(raw_scores: PackedFloat32Array) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(raw_scores.size())
	if raw_scores.is_empty():
		return result
		
	var max_val := -1e9
	for val in raw_scores:
		max_val = max(max_val, val)
		
	var sum_exp := 0.0
	for i in range(raw_scores.size()):
		result[i] = exp(raw_scores[i] - max_val)
		sum_exp += result[i]
		
	for i in range(result.size()):
		result[i] /= sum_exp
		
	return result
	
func _emote(node: Node2D):
	# all nodes should have a sprite2d
	var sprite = ECS.get_component(node, Sprite2D) as Sprite2D
	if sprite:
		$Panel/PanelContainer/TextureRect.texture = sprite.texture

func _is_objective_valid_target(objective: Node2D) -> bool:
	return true
	# TODO: CHECK IF WE NEED RESOURCE OR IF RESOURCE IS READY (e.g. FURNACE)
	if objective.has_method("is_available") and not objective.is_available():
		return false
	return true
	
func _on_player_interacted(item : Item) -> void:
	var source = objectives_manager.get_source_objective_given_item(item)
	var id = objectives_manager.get_id_given_objective(source)
	if id < 0:
		return
	policy_predictor.train(id, human_player)
	
func _on_robot_interacted(item: Item) -> void:
	history_items.append(item)
	if history_items.size() > max_history_size:
		history_items.pop_front()
func _on_interaction_area_entered(area: Area2D) -> void:
	print(area.get_groups())
	touching = area.get_parent()
	if touching == target_node:
		if _interact():
			target_node = null
			state = State.IDLE
		
func _on_interaction_area_exited(body: Area2D) -> void:
	touching = null
