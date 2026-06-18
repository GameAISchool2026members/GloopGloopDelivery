extends TileMapLayer

# On ready, generates a WxH map
# places 2 resources, 1 processor and 1 collection point and 2 spawn points
# uses navigation agent to check that every path is reachable
# if not, regenerates

@export var width = 100
@export var height = 100
@export var min_line_size = 5
@export var max_line_size = 10
@export var line_count = 5
@export var min_poi_dist = 5
@export var background_tiles: Array[Vector2i] = []
@export var obstacle_tiles: Array[Vector2i] = []
@export var wall_tiles: Array[Vector2i] = []

@export var resource_scenes: Array[PackedScene] = []
@export var processor_scenes: Array[PackedScene] = []
@export var collection_scene: PackedScene = null

var astar: AStarGrid2D

# keeps track of the positions of resources and processors
# during generation, such that they can be spaced apart sufficiently
var _pois: Array[Vector2i] = []

# get random position that doesn't collide
func _random_pos() -> Vector2i:
	var rand = Vector2i.ZERO
	while rand == Vector2i.ZERO:
		rand = Vector2i(randi_range(1, width -2), randi_range(1, height -2))
		if astar.is_point_solid(rand): 
			rand = Vector2i.ZERO
			break # reject
	return rand

# 
func _add_pois(pois: Array[PackedScene]):
	for res in pois:
		var obj = res.instantiate() as Node2D
		var pos = Vector2i.ZERO
		while pos == Vector2i.ZERO:
			pos = _random_pos()
			for other in _pois:
				if other.distance_to(pos) < min_poi_dist:
					pos = Vector2i.ZERO
					break # reject
		obj.global_position = map_to_local(pos)
		add_child(obj)
		_pois.append(pos)

func _ready():
	_generate_all()
	var valid: bool = _validate_all()
	while not valid:
		print("generate new level")
		_generate_all()
		valid = _validate_all()

func _generate_all():
	# clean potential old level
	_pois = []
	for c in get_children():
		c.queue_free()
	
	_init_astar()
	_init_base_map()
	_add_walls()
	_add_resources()
	_add_processors()
	_add_collection_point()
	_choose_spawn_points()
	_add_border()
	
func _validate_all():
	# all pois must be able to reach eachother
	for poi in _pois:
		for other in _pois:
			if other != poi: # ignore self
				var path = astar.get_id_path(poi, other)
				if len(path) == 0:
					return false # invalid
	return true
	
func _init_astar():
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0,0,width,height)
	astar.cell_size = tile_set.tile_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.offset = tile_set.tile_size / 2.0
	astar.update()
	
# fills the map with ground tiles and a couple of small obstacle tiles
func _init_base_map():
	for x in width:
		for y in height:
			var pos = Vector2i(x,y)
			var tile: Vector2i = Vector2i.ZERO
			if randf() < 0.05:
				tile = obstacle_tiles.pick_random()
				astar.set_point_solid(pos)
			else:
				tile = background_tiles.pick_random()
			set_cell(pos, 0, tile)
			
# generate a couple of straight lines as more interesting obstacles
func _add_walls():
	for n in line_count:
		var line_w = 1
		var line_h = randi_range(min_line_size, max_line_size)
		if randf() < 0.5:
			line_w = randi_range(min_line_size, max_line_size)
			line_h = 1
		var tile = obstacle_tiles.pick_random()
		var start_pos = _random_pos()
		for w in line_w:
			for h in line_h:
				var pos = start_pos + Vector2i(w,h)
				if pos.x > width -1 or pos.y > height -1:
					break
				astar.set_point_solid(pos)
				set_cell(pos, 0, tile)

# add things like iron
func _add_resources():
	_add_pois(resource_scenes)
	
# add things like furnaces
func _add_processors():
	_add_pois(processor_scenes)
	
func _add_collection_point():
	_add_pois([collection_scene])
	
func _choose_spawn_points():
	pass
		
func _add_border():
	var tile = obstacle_tiles.pick_random()
	for x in width:
		set_cell(Vector2i(x,0), 0, tile)
		set_cell(Vector2i(x,height-1), 0, tile)
	for y in height:
		set_cell(Vector2i(0,y), 0, tile)
		set_cell(Vector2i(width-1,y), 0, tile)
			
