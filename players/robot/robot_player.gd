class_name RobotPlayer extends Player

@onready var policy_predictor : PolicyPredictor = $PolicyPredictor

var human_player : HumanPlayer
var terrain : Terrain

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
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	objectives_manager = game_manager.objectives_manager
	
	policy_predictor.init(objectives_manager.get_number_of_objectives(), human_player)
	
	human_player.pickup_objective.connect(_on_player_interacted)
	
	
func _process(delta):
	super(delta)
	
	if item != null and state == State.WALKING_TO_ITEM:
		var target = objectives_manager.get_target_objective_given_item(item)
		if target == null:
			return
		state = State.WALKING_WITH_ITEM
		_move_to_global_pos(target.global_position)
	
	if item == null and state == State.WALKING_WITH_ITEM:
		state = State.IDLE
	
	match state:
		State.IDLE:
			find_target()
		State.WALKING_TO_ITEM:
			pass
		State.WALKING_WITH_ITEM:
			pass
		

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
	var objectives = objectives_manager.get_all_objectives()
	for idx in sorted_indices:
		if idx >= objectives.size():
			continue
			
		var potential_objective = objectives[idx]
		
		if ECS.has_component(potential_objective, InventoryComponent):
			continue
		if ECS.has_component(potential_objective, ProducerComponent):
			continue
		
		target_position = potential_objective.global_position
		target_found = true
		
		print("Robot targeted: %s | Probability: %.1f%%" % [
			potential_objective.name, 
			prediction_probs[idx] * 100.0
		])			
		_move_to_global_pos(target_position)
		state = State.WALKING_TO_ITEM
		break
			
	if not target_found:
		print("All neglected objectives are currently invalid or unreachable.")
	

func _is_objective_valid_target(objective: Node2D) -> bool:
	return true
	# TODO: CHECK IF WE NEED RESOURCE OR IF RESOURCE IS READY (e.g. FURNACE)
	if objective.has_method("is_available") and not objective.is_available():
		return false
	return true
	
func _on_player_interacted(item : Item) -> void:
	var source = objectives_manager.get_source_objective_given_item(item)
	var id = objectives_manager.get_id_given_objective(source)
	policy_predictor.train(id, human_player)
	
func _on_interaction_area_entered(area: Area2D) -> void:
	print(area.get_groups())
	touching = area.get_parent()
	_interact()
		
func _on_interaction_area_exited(body: Area2D) -> void:
	touching = null
