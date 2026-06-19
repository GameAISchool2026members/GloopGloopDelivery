class_name ObjectivesManager extends Node2D

var objectives : Array[Node2D]
var game_manager : GameManager


func find_all_objectes() -> void:
	objectives.clear()
	var all = get_tree().get_nodes_in_group("interactable")
	print("foudn this many:", all.size())
	for o in all:
		if not o.is_queued_for_deletion():
			objectives.append(o)
			
	print("final size:", objectives.size())
	#print(get_number_of_objectives())
	
	#for o in objectives:
		#print(o)

func get_source_objective_given_item(item: Item) -> Node2D:
	for o in objectives:
		if ECS.has_component(o, ResourceComponent):
			var rc = ECS.get_component(o, ResourceComponent) as ResourceComponent
			if rc.item == item:
				return o
	return null
func get_all_target_objectives() -> Array[Dictionary]:
	var result : Array[Dictionary]
	var i : int = 0
	for o in objectives:
		if ECS.has_component(o, ProducerComponent):
			var pc = ECS.get_component(o, ProducerComponent) as ProducerComponent
			var item = pc.peak_item()
			if item:
				var score = game_manager.score_table[item]
				result.append({
					"node" : o,
					"index" : i,
					"result_score" : score,
					"prediction_score" : 0
				})
		if ECS.has_component(o, ResourceComponent):
			var rc = ECS.get_component(o, ResourceComponent) as ResourceComponent
			var item = rc.item
			if item:
				var score = game_manager.score_table[item]
				result.append({
					"node" : o,
					"index" : i,
					"result_score" : score,
					"prediction_score" : 0
				})
		i += 1
	return result
	
func get_all_target_objectives_given_item(item: Item) -> Array[Dictionary]:
	var result : Array[Dictionary]
	var i : int = 0
	for o in objectives:
		if ECS.has_component(o, ProducerComponent):
			var pc = ECS.get_component(o, ProducerComponent) as ProducerComponent
			for r : Recipe in pc.recipes:
				if r.input == item:
					var score = game_manager.score_table[r.output]
					result.append({
						"node" : o,
						"index" : i,
						"result_score" : score,
						"prediction_score" : 0
					})
		if ECS.has_component(o, InventoryComponent):
			var score = game_manager.score_table[item]
			result.append({
				"node" : o,
				"index" : i,
				"result_score" : score,
				"prediction_score" : 0
			})
		i += 1
	return result
	
#func get_target_objective_given_item(item: Item) -> Node2D:
	#var collector : Node2D
	#for o in objectives:
		#if ECS.has_component(o, ProducerComponent):
			#var pc = ECS.get_component(o, ProducerComponent) as ProducerComponent
			#for r : Recipe in pc.recipes:
				#if r.input == item:
					#return o
		#if ECS.has_component(o, InventoryComponent):
			#collector = o			
	#return collector

func get_id_given_objective(objective : Node2D) -> int:
	var i : int = 0
	for o in objectives:
		if o == objective:
			return i
		i += 1
	return -1
		

func get_all_resources() -> Array[Node2D]:
	return []
	
func get_all_objectives() -> Array[Node2D]:
	return objectives

func get_number_of_objectives() -> int:
	return objectives.size()

func objective_data_size() -> int:
	return get_number_of_objectives() * 3
	
