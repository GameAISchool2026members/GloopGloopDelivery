extends CharacterBody2D

@export var speed: float = 100.0
@onready var line: Line2D = %Line2D
@onready var tilemap: TileMapLayer = %Terrain
var path_index: int = 0
var path: PackedVector2Array = []

func _physics_process(delta):
	if path_index >= path.size():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target := path[path_index]

	if global_position.distance_to(target) < 4.0:
		path_index += 1
	else:
		velocity = global_position.direction_to(target) * speed

	move_and_slide()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var player_local = tilemap.local_to_map(global_position)
		print(player_local)
		var target_local = tilemap.local_to_map(get_global_mouse_position())
		print(target_local)
		path = tilemap.astar.get_point_path(player_local, target_local)
		path_index = 0
		# show path for debug
		line.points = path
