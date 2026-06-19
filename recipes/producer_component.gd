class_name ProducerComponent extends Node

@export var label: RichTextLabel
@export var recipes: Array[Recipe]
@export var delay: int

var raw_items : Array[Item]
var processed_items : Array[Item]
var is_producing : bool = false

func is_input_empty() -> bool:
	return raw_items.size() <= 0

func is_output_empty() -> bool:
	return processed_items.size() <= 0

func produce_item(input_recipe: Item) -> bool:
	for r in recipes:
		if r.input == input_recipe:
			raw_items.append(input_recipe)
			return true
	return false

func pickup() -> Item:
	if is_output_empty():
		print("wanted to pickup item but component is empty")
		return null
	
	var item = processed_items.pop_front()
	_display()
	return item

func peak_item() -> Item:
	if processed_items.is_empty():
		return null
	return processed_items.front()

func process_item() -> void:
	if is_input_empty():
		return
	is_producing = true
	await get_tree().create_timer(delay).timeout
	var item = raw_items.pop_front()
	for r in recipes:
		if r.input == item:
			processed_items.append(r.output)
	_display()
	is_producing = false

func _process(delta: float) -> void:
	if not is_producing and not is_input_empty():
		process_item()

func _display():
	var counts := {}
	for item in processed_items:
		var name = item.name
		if not counts.has(name):
			counts[name] = {
				"item": item,
				"count": 0
			}
		counts[name].count += 1
	label.clear()
	for entry in counts.values():
		label.add_image(entry.item.texture, 8, 8)
		label.append_text(" %d\n" % entry.count)
