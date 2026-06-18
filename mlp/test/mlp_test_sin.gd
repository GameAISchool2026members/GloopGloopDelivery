extends Node2D

@onready var mlp := GodotMLP.new()
@onready var true_line := $TrueLine
@onready var pred_line := $PredLine

var training_thread := Thread.new()

func _ready() -> void:
	mlp.learning_rate = 0.001
	mlp.loss_function = mlp.LossFunction.MSE
	mlp.build_structure([1, 32, 32, 1], [mlp.Activation.TANH, mlp.Activation.TANH, mlp.Activation.LINEAR])
	
	# Start training in background
	training_thread.start(_train_and_validate)

func _train_and_validate() -> void:
	var epochs := 1000
	var examples_per_epoch := 50
	
	for epoch in range(epochs):
		var total_loss := 0.0
		for i in range(examples_per_epoch):
			var x := randf_range(0.0, 3.0)
			total_loss += mlp.train_step(PackedFloat32Array([x]), PackedFloat32Array([sin(x)]))
		
		if epoch % 20 == 0:
			print("Epoch %d | Avg Loss: %.6f" % [epoch, total_loss / examples_per_epoch])
			_update_graph.call_deferred()
			
	_perform_validation()
	# Update visualization on the main thread
	call_deferred("_update_graph")

func _perform_validation() -> void:
	print("\n--- Starting Validation ---")
	var num_tests := 100
	var total_error := 0.0
	for i in range(num_tests):
		var x := 3.0 * (float(i) / float(num_tests))
		var pred := mlp.predict(PackedFloat32Array([x]))[0]
		total_error += abs(sin(x) - pred)
		print("x: ", x)
		print("y: ", pred)
	print("Average Validation Error: %.6f" % (total_error / num_tests))

func _update_graph() -> void:
	true_line.clear_points()
	pred_line.clear_points()
	var graph_width := 800.0
	var graph_height := 200.0
	
	for i in range(100):
		var x := 10.0 * (float(i) / 100.0)
		var y_true := sin(x)
		var y_pred := mlp.predict(PackedFloat32Array([x]))[0]
		
		true_line.add_point(Vector2(i * (graph_width / 100), (graph_height / 2.0) - (y_true * 80)))
		pred_line.add_point(Vector2(i * (graph_width / 100), (graph_height / 2.0) - (y_pred * 80)))

func _exit_tree() -> void:
	if training_thread.is_started():
		training_thread.wait_to_finish()
