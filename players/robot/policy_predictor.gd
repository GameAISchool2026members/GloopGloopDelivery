extends Node
class_name PolicyPredictor

@onready var mlp := GodotMLP.new()

# Set these from the main robot script or via inspector
var player: CharacterBody2D
var active_objectives: Array[Node2D] = []

var history_buffer: Array[PackedFloat32Array] = []

func init(num_objectves : int, player : CharacterBody2D) -> void:
	mlp = GodotMLP.new()
	mlp.build_structure([6, 16, num_objectves], [mlp.Activation.TANH, mlp.Activation.SOFTMAX])

func update_prediction(delta: float) -> PackedFloat32Array:
	if not is_instance_valid(player) or active_objectives.is_empty():
		return PackedFloat32Array([0.33, 0.33, 0.33]) # Return neutral distribution
		
	# 1. Calculate features relative to the closest objective
	var closest_obj := _get_closest_objective()
	var dist := player.global_position.distance_to(closest_obj.global_position)
	var norm_dist : float = clamp(dist / 1000.0, 0.0, 1.0) # Assume 1000px is max relevant distance
	var obj_importance : float = closest_obj.get("importance") if "importance" in closest_obj else 0.5
	
	var current_snapshot := PackedFloat32Array([norm_dist, obj_importance])
	
	# 2. Maintain rolling window (e.g., keep last 3 steps)
	history_buffer.append(current_snapshot)
	if history_buffer.size() > 3:
		history_buffer.pop_front()
		
	if history_buffer.size() < 3:
		return PackedFloat32Array([0.33, 0.33, 0.33])
		
	# 3. Flatten history for MLP input
	var input_vector := PackedFloat32Array()
	for snap in history_buffer:
		input_vector.append_array(snap)
		
	# 4. Predict current intent probabilities
	return mlp.predict(input_vector)

func train_on_actual_intent(target_intent: PackedFloat32Array) -> void:
	# Build input vector from current history to match the training target
	var input_vector := PackedFloat32Array()
	for snap in history_buffer:
		input_vector.append_array(snap)
		
	if input_vector.size() == 6:
		mlp.train_step(input_vector, target_intent)

func _get_closest_objective() -> Node2D:
	var closest = active_objectives[0]
	var min_dist = player.global_position.distance_to(closest.global_position)
	for obj in active_objectives:
		var d = player.global_position.distance_to(obj.global_position)
		if d < min_dist:
			min_dist = d
			closest = obj
	return closest
