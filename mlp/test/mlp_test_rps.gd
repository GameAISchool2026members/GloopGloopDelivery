extends Node

@onready var mlp := GodotMLP.new()
@onready var label := $Control/Label

enum Move { ROCK, PAPER, SCISSORS, NONE }

# History buffer tracking the last 3 moves made by the player
var player_history: Array[Move] = [Move.NONE, Move.NONE, Move.NONE]

var training_thread := Thread.new()
var is_training := false

# Game Stats
var total_rounds := 0
var ai_wins := 0
var player_wins := 0
var draws := 0

func _ready() -> void:
	# 9 inputs: 3 history entries * 3-wide One-Hot encoding
	# 16 hidden units (using TANH to handle the encoded states nicely)
	# 3 outputs (SOFTMAX) providing probabilities for [Rock, Paper, Scissors]
	mlp.loss_function = mlp.LossFunction.CROSS_ENTROPY
	mlp.learning_rate = 0.02
	mlp.build_structure([9, 16, 3], [mlp.Activation.TANH, mlp.Activation.SOFTMAX])
	
	print("--- Pre-training AI on Human Psychological Biases ---")
	is_training = true
	training_thread.start(_pre_train_network)

func _process(_delta: float) -> void:
	# Check if background initialization thread is done
	if is_training and not training_thread.is_alive():
		training_thread.wait_to_finish()
		is_training = false
		print("--- AI Brain Ready! Play by calling play_round() ---")

func _update_label() -> void:
	label.text = "AI Wins: %d\nPlayer Wins: %d\nDraws: %d" % [ai_wins, player_wins, draws]
	

# --- Core Game Loop ---

func play_round(player_move: Move) -> void:
	if is_training:
		print("AI is still thinking/initializing. Wait a moment!")
		return
		
	var input_vector := _encode_history(player_history)
	
	# 1. AI Predicts player move using the current model state
	var prediction_probs := mlp.predict(input_vector)
	var predicted_player_move: Move = _get_argmax(prediction_probs) as Move
	
	# 2. AI selects its winning counter counter-move
	var ai_move: Move = _get_counter_move(predicted_player_move)
	
	# 3. Process game results
	_evaluate_winner(player_move, ai_move, predicted_player_move, prediction_probs)
	
	# 4. Trigger Online Learning Step (Async/Threaded so frame rate stays smooth)
	var target_vector := PackedFloat32Array([0.0, 0.0, 0.0])
	target_vector[player_move] = 1.0
	
	is_training = true
	training_thread.start(_run_online_train_step.bind(input_vector, target_vector))
	
	await training_thread.wait_to_finish()
	print("training over!")
	
	# 5. Append this move to the rolling window history
	player_history.pop_front()
	player_history.append(player_move)

# --- Online & Background Learning ---

func _run_online_train_step(inputs: PackedFloat32Array, targets: PackedFloat32Array) -> void:
	# Perform multiple small epochs on the current single sequence to lock in local adjustments
	for epoch in range(5):
		mlp.train_step(inputs, targets)
	is_training = false

func _pre_train_network() -> void:
	# Simulates 2,000 rounds of "Win-Stay, Lose-Shift" logic to build a base strategy
	var mock_history: Array[Move] = [Move.ROCK, Move.PAPER, Move.SCISSORS]
	var last_result_was_win := true
	
	for i in range(2000):
		var input_vec := _encode_history(mock_history)
		var current_last_move = mock_history.back()
		
		# Strategy: if won, human repeats. If lost, human shifts to what beats their last play
		var expected_next_move: Move = current_last_move
		if not last_result_was_win:
			expected_next_move = ((current_last_move + 1) % 3) as Move
			
		var target_vec := PackedFloat32Array([0.0, 0.0, 0.0])
		target_vec[expected_next_move] = 1.0
		
		mlp.train_step(input_vec, target_vec)
		
		# Cycle mock game states
		mock_history.pop_front()
		mock_history.append(expected_next_move)
		last_result_was_win = (randf() > 0.4) # Add randomness to choices

# --- Helper Utilities ---

func _encode_history(history_array: Array[Move]) -> PackedFloat32Array:
	var vector := PackedFloat32Array()
	vector.resize(9)
	vector.fill(0.0)
	
	for step in range(3):
		var current_move: Move = history_array[step]
		if current_move != Move.NONE:
			# One-hot position mapping
			vector[(step * 3) + current_move] = 1.0
	return vector

func _get_counter_move(player_predicted: Move) -> Move:
	# Rock (0) -> Paper (1), Paper (1) -> Scissors (2), Scissors (2) -> Rock (0)
	return ((player_predicted + 1) % 3) as Move

func _get_argmax(arr: PackedFloat32Array) -> int:
	var max_idx := 0
	for i in range(1, arr.size()):
		if arr[i] > arr[max_idx]:
			max_idx = i
	return max_idx

func _evaluate_winner(p_move: Move, a_move: Move, pred_move: Move, probs: PackedFloat32Array) -> void:
	total_rounds += 1
	var confidence := probs[pred_move] * 100.0
	
	var out_str := "Round %d | Player: %s, AI: %s (Predicted %s with %d%% confidence) -> "
	var move_names := ["ROCK", "PAPER", "SCISSORS"]
	var round_summary := out_str % [total_rounds, move_names[p_move], move_names[a_move], move_names[pred_move], confidence]
	
	if p_move == a_move:
		draws += 1
		print(round_summary + "DRAW")
	elif (p_move == Move.ROCK and a_move == Move.PAPER) or \
		 (p_move == Move.PAPER and a_move == Move.SCISSORS) or \
		 (p_move == Move.SCISSORS and a_move == Move.ROCK):
		ai_wins += 1
		print(round_summary + "AI WINS")
	else:
		player_wins += 1
		print(round_summary + "PLAYER WINS")
		
	print("Score -> AI: %d | Player: %d | Draws: %d\n" % [ai_wins, player_wins, draws])
	_update_label()

func _exit_tree() -> void:
	if training_thread.is_started():
		training_thread.wait_to_finish()


func _on_button_pressed_rock() -> void:
	play_round(Move.ROCK)


func _on_button_pressed_paper() -> void:
	play_round(Move.PAPER)


func _on_button_pressed_scissors() -> void:
	play_round(Move.SCISSORS)
