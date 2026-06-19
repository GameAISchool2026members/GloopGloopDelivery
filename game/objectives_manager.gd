class_name ObjectivesManager extends Node2D

var objectives : Array[Node2D]


func find_all_objectes() -> void:
	objectives.assign(get_tree().get_nodes_in_group("interactable"))
	print(get_number_of_objectives())
	
	for o in objectives:
		print(o)

func get_source_objective_given_item(item: Item) -> Node2D:
	for o in objectives:
		if ECS.has_component(o, ResourceComponent):
			var rc = ECS.get_component(o, ResourceComponent) as ResourceComponent
			if rc.item == item:
				return o
	return null

func get_target_objective_given_item(item: Item) -> Node2D:
	print("TODO: fix inventory objecive")
	for o in objectives:
		if ECS.has_component(o, ProducerComponent):
			var pc = ECS.get_component(o, ProducerComponent) as ProducerComponent
			for r : Recipe in pc.recipes:
				if r.input == item:
					return o
		#if ECS.has_component(o, InventoryComponent):
			#var pc = ECS.get_component(o, InventoryComponent) as InventoryComponent
			#for r : Recipe in pc.recipes:
				#if r.input == item:
					#return o
	return null

func get_id_given_objective(objective : Node2D) -> int:
	var i : int = 0
	for o in objectives:
		if o == objective:
			return i
		i += 1
	return i
		

func get_all_resources() -> Array[Node2D]:
	return []
	
func get_all_objectives() -> Array[Node2D]:
	return objectives

func get_number_of_objectives() -> int:
	return objectives.size()

func objective_data_size() -> int:
	return get_number_of_objectives() * 3
	
