class_name HumanPlayer extends Player

var touching: Node2D
var carrying :Node2D
signal pickup_objective(Entity: Node2D)

func _ready() -> void:
	$InteractionArea.area_entered.connect(_on_interaction_area_entered)
	$InteractionArea.area_exited.connect(_on_interaction_area_exited)
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
