extends Node2D
@onready var producer_component = $ProducerComponent
@onready var sprite = $Sprite2D
@onready var particles: GPUParticles2D = $Particles
var furnace_on = preload("res://objects/furnace/furnace_on.png")
var furnace_off = preload("res://objects/furnace/furnace_off.png")

func _process(delta):
	particles.emitting = producer_component.is_producing
	if producer_component.is_producing:
		sprite.texture = furnace_on
	else:
		sprite.texture = furnace_off
		
	
