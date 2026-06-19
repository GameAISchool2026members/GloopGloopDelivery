extends Node
class_name PolicyPredictor

@onready var mlp := GodotMLP.new()
@export var history_interval : float = 0.2
@export var history_horizon : int = 50

var history_buffer: Array[PackedFloat32Array] = []
var objectives_count : int = 0
var initialized := false

func init(num_objectves : int, player: HumanPlayer) -> void:
	objectives_count = num_objectves
	mlp = GodotMLP.new()
	print("init mlp: ", num_objectves)
	mlp.build_structure([6, 16, num_objectves], [mlp.Activation.TANH, mlp.Activation.LINEAR])
	_reset_history_buffer(player)
	mlp.print_structure()
	initialized = true
	_update_history_buffer(player)

func _reset_history_buffer(player: HumanPlayer) -> void:
	history_buffer.clear()
	for i in history_horizon:
		history_buffer.append(player.get_default_intent_vector())

func _update_history_buffer(player: HumanPlayer) -> void:
	if player == null: 
		return
	# collect user data to add to history buffer
	history_buffer.pop_back()
	history_buffer.push_front(player.get_current_intent_vector())
	
	await get_tree().create_timer(history_interval).timeout
	_update_history_buffer(player)

func train(found_objective_index : int, player: HumanPlayer) -> void:
	if not initialized or objectives_count <= 0:
		return
	var target : PackedFloat32Array
	target.resize(objectives_count)
	target[found_objective_index] = 1
	for i in history_buffer:
		mlp.train_step(i, target)
		
	_reset_history_buffer(player)

func predict(player: HumanPlayer) -> PackedFloat32Array:
	if not initialized or objectives_count <= 0:
		return []
	return mlp.predict(player.get_current_intent_vector())
