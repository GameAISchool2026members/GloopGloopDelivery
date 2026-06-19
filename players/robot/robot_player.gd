class_name RobotPlayer extends Player

@onready var policy_predictor : PolicyPredictor = $PolicyPredictor

var human_player : HumanPlayer
var terrain : Terrain

var path_index: int = 0
var path: PackedVector2Array = []

enum State { IDLE, WALKING_TO_ITEM, WALKING_WITH_ITEM, WAITING }
var state : State = State.IDLE
var target_node : Node2D



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
	
	if target_node == null:
		state = State.IDLE
	
	if target_node != null and state == State.IDLE:
		state = State.WALKING_TO_ITEM
	
	if item != null and state == State.WALKING_TO_ITEM:
		#var target = objectives_manager.get_target_objective_given_item(item)
		#if target == null:
			#return
		state = State.WALKING_WITH_ITEM
		#_move_to_global_pos(target.global_position)
		find_target()
	
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
	
func get_current_objectives() -> Array[Dictionary]:
	if item:
		return objectives_manager.get_all_target_objectives_given_item(item)
	
	return objectives_manager.get_all_target_objectives()

func find_target() -> void:
	print("finding target")
	var prediction_probs := policy_predictor.predict(human_player)
	if prediction_probs.is_empty():
		return

	target_node = null
	var objectives : Array[Dictionary] = get_current_objectives()
	for i in range(objectives.size()):
		objectives[i].prediction_score = prediction_probs[objectives[i].index]
	
	objectives.sort_custom(func(a, b): return a.prediction_score < b.prediction_score)
	
	for o in objectives:
		var potential_objective_node = o.node
		var potential_objective_index = o.index
		var potential_objective_score = o.result_score
		var potential_objective_prediction_score = o.prediction_score
		
		target_node = potential_objective_node
		print("Robot targeted: %s | Probability: %.1f%%" % [
			potential_objective_node.name, 
			potential_objective_prediction_score * 100.0
		])			
		_emote(potential_objective_node)
		_move_to_global_pos(target_node.global_position)
		break
			
	if not target_node:
		print("All neglected objectives are currently invalid or unreachable.")
	
func _emote(node: Node2D):
	var resource = ECS.get_component(node, ResourceComponent) as ResourceComponent
	if resource:
		$PanelContainer/TextureRect.texture = resource.item.texture

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
	if touching == target_node:
		if _interact():
			target_node = null
		
func _on_interaction_area_exited(body: Area2D) -> void:
	touching = null
