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
	
func _interact():
	if(touching != null):
		var groups = touching.get_groups()
		#print("interacting with interactable")
		if ECS.has_component(touching, ResourceComponent):
			#print("has it!")
			item = ECS.get_component(touching, ResourceComponent).item
			pickup_objective.emit(item)
		if ECS.has_component(touching, InventoryComponent) and item:
			var inv = ECS.get_component(touching, InventoryComponent) as InventoryComponent
			inv.add(item)
			item = null
		#pickup_objective.emit(touching)
