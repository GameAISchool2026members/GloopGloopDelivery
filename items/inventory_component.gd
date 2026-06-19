class_name InventoryComponent extends Node

@export var label: RichTextLabel

var inventory: Array[Item]

func add(item: Item):
	inventory.append(item)
	SignalBus.item_collected.emit(item)
	_display()
	
func _display():
	var counts := {}
	for item in inventory:
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
