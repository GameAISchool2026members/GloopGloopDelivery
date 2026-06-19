class_name HumanPlayer extends Player

func _ready() -> void:
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	objectives_manager = game_manager.objectives_manager
	
func _process(delta):
	# interactions
	super(delta)
	if Input.is_action_just_pressed("interact"):
		_interact()

			

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	

func _physics_process(delta):
	get_input()
	move_and_slide()
	
func _on_interaction_area_entered(area: Area2D) -> void:
	print(area.get_groups())
	touching = area.get_parent()
		
func _on_interaction_area_exited(body: Area2D) -> void:
	touching = null
	#if body.is_in_group("interactable"):  # or check body is a Player class
		#touching = null
		#print("Player stopped touching!")
		
		
func get_default_intent_vector() -> PackedFloat32Array:
	var result : PackedFloat32Array = []
	for o in objectives_manager.get_all_objectives():
		result.append(0)
		result.append(0)
		result.append(1.0)
	return result

# list of inputs for the policy, for each objective:
# distance to player
# player velocity towards it
# importance
func get_current_intent_vector() -> PackedFloat32Array:
	var result : PackedFloat32Array = []
	for o in objectives_manager.get_all_objectives():
		#var o_gpos = o.global_position
		var o_gpos = global_position
		var dir := global_position.direction_to(o_gpos)
		result.append(o_gpos.distance_to(global_position))
		result.append(dir.dot(velocity))
		result.append(1.0)
	return result
