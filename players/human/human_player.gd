class_name HumanPlayer extends Player

signal interact

@export var game_manager : GameManager
var objectives_manager : ObjectivesManager
var touching: Node2D
var carrying :Node2D
signal pickup_objective(Entity: Node2D)

func _ready() -> void:
	$InteractionArea.area_entered.connect(_on_interaction_area_entered)
	$InteractionArea.area_exited.connect(_on_interaction_area_exited)
	objectives_manager = game_manager.objectives_manager
	speed = 200
	
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		print("interact")
		if(touching != null):
			var groups = touching.get_groups()
			print("interacting with interactable")
			print(groups)
			carrying = touching.duplicate()
			carrying.scale = Vector2(0.5,0.5)
			carrying.position = Vector2(0,-5)
			add_child(carrying)
			pickup_objective.emit(touching)
func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	

func _physics_process(delta):
	get_input()
	move_and_slide()
	
func _on_interaction_area_entered(area: Area2D) -> void:
	print("touch")
	print(area.get_groups())
	if area.is_in_group("interactable"):
		print("interacts with other body ")
		touching = area.get_parent()
		print("Player touched interactable!")
		
func _on_interaction_area_exited(body: Area2D) -> void:
	print("touch")
	touching = null
	print("player stopped touching!")
	#if body.is_in_group("interactable"):  # or check body is a Player class
		#touching = null
		#print("Player stopped touching!")
		
		
func get_default_intent_vector() -> PackedFloat32Array:
	var result : PackedFloat32Array = []
	for o in objectives_manager.get_all_objectives():
		result.append(0)
		result.append(0)
		result.append(1.0)
	return []

# list of inputs for the policy, for each objective:
# distance to player
# player velocity towards it
# importance
func get_current_intent_vector() -> PackedFloat32Array:
	var result : PackedFloat32Array = []
	for o in objectives_manager.get_all_objectives():
		var dir := global_position.direction_to(o.global_position)
		result.append(o.global_position.distance_to(global_position))
		result.append(dir.dot(velocity))
		result.append(1.0)
	return []
