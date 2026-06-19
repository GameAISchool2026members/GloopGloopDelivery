extends Node
class_name ECS

static func get_component(p: Node, v: Variant):
	for c in p.get_children():
		if is_instance_of(c, v):
			return c
	return null

static func has_component(p: Node, v: Variant):
	for c in p.get_children():
		if is_instance_of(c, v):
			return c
	return null
