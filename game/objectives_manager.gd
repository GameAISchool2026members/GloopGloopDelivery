class_name ObjectivesManager extends Node2D

var objectives : Array[Node2D]

func find_all_objectes() -> void:
	print("findnig")
	objectives.assign(get_tree().get_nodes_in_group("interactable"))
	print(get_number_of_objectives())

func get_target_given_item(item: Node2D) -> Node2D:
	print("TODO")
	return null

func get_all_resources() -> Array[Node2D]:
	return []
	
func get_all_objectives() -> Array[Node2D]:
	return objectives

func get_number_of_objectives() -> int:
	return objectives.size()

func objective_data_size() -> int:
	return get_number_of_objectives() * 3
	
