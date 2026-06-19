class_name ProducerComponent extends Node

@export var recipes: Array[Recipe]
@export var delay: int
var production = false
var output: Item
func produce_item(input_recipe: Item) -> bool:
	if production == false && output == null:
		for recipe in recipes:
			if recipe.input==input_recipe:
				production = true
				wait_on_production()
				output = recipe.output
				return true
	return false

func pickup() -> Item:
	if production == true:
		print("wanted to pickup item but component is busy")
		return null
	var placeholder = output
	output = null
	return placeholder

func wait_on_production():
	await get_tree().create_timer(delay).timeout
	production = false
	
