extends Node2D
@onready var producer_component = $ProducerComponent
@onready var sprite = $Sprite2D
var furnace_on = preload("res://objects/furnace/furnace_on.png")
var furnace_off = preload("res://objects/furnace/furnace_off.png")

func _process(delta):
	if producer_component.production:
		sprite.texture = furnace_on
	else:
		sprite.texture = furnace_off
		
	
