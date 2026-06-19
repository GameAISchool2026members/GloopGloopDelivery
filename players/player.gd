class_name Player extends CharacterBody2D
signal interact
signal pickup_objective(item: Item)

@export var speed = 200
@onready var item_sprite: Sprite2D = $ItemSprite
@export var game_manager : GameManager
@onready var interaction_area: Area2D = $InteractionArea

var objectives_manager : ObjectivesManager
var touching: Node2D

var item : Item

func obtain_item(item : Item) -> void:
	pass

func _process(delta):
	# Display current item
	if item:
		item_sprite.texture = item.texture
	else:
		item_sprite.texture = null
		
	if game_manager.state == GameManager.State.END:
		speed = 0
		
	
func _interact() -> bool:
	if(touching == null):
		return false
		
	var groups = touching.get_groups()
	if ECS.has_component(touching, ResourceComponent) and not item:
		#print("has it!")
		item = ECS.get_component(touching, ResourceComponent).item
		
		pickup_objective.emit(item)
		return true
	if ECS.has_component(touching, InventoryComponent) and item:
		var inv = ECS.get_component(touching, InventoryComponent) as InventoryComponent
		inv.add(item)
		item = null
		return true
	if ECS.has_component(touching, ProducerComponent) and item:
		var furnace = ECS.get_component(touching, ProducerComponent) as ProducerComponent
		var delivered = furnace.produce_item(item)
		if delivered:	
			item = null
		return true
	if ECS.has_component(touching, ProducerComponent) and not item:
		var furnace = ECS.get_component(touching, ProducerComponent) as ProducerComponent
		item = furnace.pickup()
		if item:
			pickup_objective.emit(item)
		return true
		#pickup_objective.emit(touching)
	return false
