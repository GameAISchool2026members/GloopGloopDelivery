class_name InventoryComponent extends Node

signal added_to_inventory(item: Item)

@export var label: RichTextLabel

var inventory: Array[Item]

func add(item: Item):
	inventory.append(item)
	added_to_inventory.emit(item)
	display()
	
func display():
	var counts := {}
	for item in inventory:
		var name = item.name
		if not counts.has(name):
			counts[name] = {
				"item": item,
				"count": 0
			}
		counts[name].count += 1
	for entry in counts.values():
		label.add_image(entry.item.texture, 24, 24)
		label.append_text(" %s x%d\n" % [entry.item.name, entry.count])
