class_name GodotMLP
extends RefCounted

enum Activation { RELU, SIGMOID, TANH, LINEAR, SOFTMAX }
enum LossFunction { MSE, CROSS_ENTROPY }

class Layer:
	var n_in: int
	var n_out: int
	var activation: Activation
	
	var weights: Array[PackedFloat32Array]
	var biases: PackedFloat32Array

	func _init(_n_in: int, _n_out: int, _activation: Activation):
		n_in = _n_in
		n_out = _n_out
		activation = _activation
		
		biases = PackedFloat32Array()
		biases.resize(n_out)
		biases.fill(0.0)
		
		weights = []
		var variance = sqrt(2.0 / n_in) # He initialization
		for i in range(n_out):
			var neuron_weights = PackedFloat32Array()
			neuron_weights.resize(n_in)
			for j in range(n_in):
				# Godot 4 has randfn for normal distribution
				neuron_weights[j] = randfn(0.0, variance)
			weights.append(neuron_weights)

var layers: Array[Layer] = []
var learning_rate: float = 0.01
var loss_function: LossFunction = LossFunction.MSE
var _mutex := Mutex.new()

func _init(_learning_rate: float = 0.01, _loss: LossFunction = LossFunction.MSE):
	learning_rate = _learning_rate
	loss_function = _loss

func add_layer(n_in: int, n_out: int, activation: Activation) -> void:
	layers.append(Layer.new(n_in, n_out, activation))

# Performs a forward pass and returns an array of all layer activations (including input)
func _forward_pass(inputs: PackedFloat32Array) -> Array[PackedFloat32Array]:
	var a_cache: Array[PackedFloat32Array] = [inputs]
	var current_a = inputs
	
	for layer in layers:
		var z = PackedFloat32Array()
		z.resize(layer.n_out)
		
		# Matrix multiplication: Z = W * A + b
		for i in range(layer.n_out):
			var sum = layer.biases[i]
			for j in range(layer.n_in):
				sum += layer.weights[i][j] * current_a[j]
			z[i] = sum
		
		current_a = _apply_activation_array(z, layer.activation)
		a_cache.append(current_a)
		
	return a_cache

# Performs one step of online learning (Gradient Descent) and returns the loss
func _internal_train_logic(inputs: PackedFloat32Array, targets: PackedFloat32Array) -> float:
	var a_cache = _forward_pass(inputs)
	var output = a_cache.back()
	
	# 1. Calculate Loss
	var loss: float = 0.0
	if loss_function == LossFunction.CROSS_ENTROPY:
		for i in range(targets.size()):
			# Add small epsilon to prevent log(0)
			loss -= targets[i] * log(max(output[i], 1e-7)) 
	else: # MSE
		for i in range(targets.size()):
			var diff = output[i] - targets[i]
			loss += 0.5 * diff * diff

	# 2. Calculate Output Layer Error (dz)
	var dz = PackedFloat32Array()
	dz.resize(targets.size())
	
	var clip_val := 1.0
	
	var output_layer = layers.back()
	if loss_function == LossFunction.CROSS_ENTROPY and output_layer.activation == Activation.SOFTMAX:
		# Mathematical simplification for Softmax + Cross Entropy
		for i in range(targets.size()):
			dz[i] = clamp(output[i] - targets[i], -clip_val, clip_val)
	else:
		# Standard MSE Error
		for i in range(targets.size()):
			dz[i] = clamp((output[i] - targets[i]) * _get_derivative(output[i], output_layer.activation), -clip_val, clip_val)
			
	

	# 3. Backpropagation & Weight Update
	for i in range(layers.size() - 1, -1, -1):
		var layer = layers[i]
		var a_prev = a_cache[i]
		
		var next_dz = PackedFloat32Array()
		next_dz.resize(layer.n_in)
		next_dz.fill(0.0)
		
		for j in range(layer.n_out):
			var delta = dz[j]
			
			for k in range(layer.n_in):
				# Accumulate error for the previous layer using current weights
				next_dz[k] += layer.weights[j][k] * delta
				# Update weight: W = W - lr * dz * a_prev
				layer.weights[j][k] -= learning_rate * delta * a_prev[k]
				
			# Update bias: b = b - lr * dz
			layer.biases[j] -= learning_rate * delta
			
		# Apply derivative of activation for the previous layer (if not input layer)
		if i > 0:
			var prev_activation = layers[i-1].activation
			for k in range(layer.n_in):
				next_dz[k] *= _get_derivative(a_prev[k], prev_activation)
				
		dz = next_dz

	return loss

# --- Math & Activation Helpers ---

func _apply_activation_array(z: PackedFloat32Array, act: Activation) -> PackedFloat32Array:
	var a = PackedFloat32Array()
	a.resize(z.size())
	
	if act == Activation.SOFTMAX:
		var max_z = -1e9
		for val in z: 
			max_z = max(max_z, val)
		var sum_exp = 0.0
		for i in range(z.size()):
			a[i] = exp(z[i] - max_z) # Subtract max_z for numerical stability
			sum_exp += a[i]
		for i in range(a.size()):
			a[i] /= sum_exp
		return a

	for i in range(z.size()):
		match act:
			# Leaky ReLU (0.01 slope) prevents dead neurons
			Activation.RELU: a[i] = z[i] if z[i] > 0 else 0.01 * z[i]
			Activation.SIGMOID: a[i] = 1.0 / (1.0 + exp(-z[i]))
			Activation.TANH: a[i] = tanh(z[i])
			Activation.LINEAR: a[i] = z[i]
	return a

# Use a slightly more robust derivative for Tanh or ensure the range is handled
func _get_derivative(a: float, act: Activation) -> float:
	match act:
		Activation.RELU: return 1.0 if a > 0 else 0.01
		Activation.SIGMOID: return a * (1.0 - a)
		# Add a tiny epsilon to prevent complete vanishing
		Activation.TANH: return max(1.0 - (a * a), 0.001) 
		Activation.LINEAR: return 1.0
	return 1.0


### API
func build_structure(sizes: Array[int], activations: Array[Activation]) -> void:
	_mutex.lock()
	layers.clear()
	for i in range(sizes.size() - 1):
		add_layer(sizes[i], sizes[i+1], activations[i])
	_mutex.unlock()

func predict(inputs: PackedFloat32Array) -> PackedFloat32Array:
	_mutex.lock()
	var activations = _forward_pass(inputs)
	_mutex.unlock()
	return activations.back()

func train_step(inputs: PackedFloat32Array, targets: PackedFloat32Array) -> float:
	_mutex.lock()
	var loss = _internal_train_logic(inputs, targets)
	_mutex.unlock()
	return loss
