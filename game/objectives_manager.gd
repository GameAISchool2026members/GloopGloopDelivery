extends Node2D

var objectives : Array[Node2D]

func find_all_objectes() -> void:
	objectives = get_tree().get_nodes_in_group("interactables") as Array[Node2D]

func get_all_resources() -> Array[Node2D]:
	return []

func number_of_objectives() -> int:
	return objectives.size()

func objective_data_size() -> int:
	return number_of_objectives() * 3

# list of inputs for the policy, for each objective:
# distance to player
# player velocity towards it
# importance
func get_objectives_data(player : CharacterBody2D) -> PackedFloat32Array:
	var result : PackedFloat32Array = []
	for o in objectives:
		var dir := player.position.direction_to(o.position)
		result.append(o.position.distance_to(player.position))
		result.append(dir.dot(player.velocity))
		result.append(1.0)
	return []
	
