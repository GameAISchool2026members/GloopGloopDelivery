class_name Player extends CharacterBody2D

@export var speed = 200
@onready var item_sprite: Sprite2D = $ItemSprite

var item : Item

func obtain_item(item : Item) -> void:
	pass

func _process(delta):
	# Display current item
	if item:
		item_sprite.texture = item.texture
	else:
		item_sprite.texture = null
	
