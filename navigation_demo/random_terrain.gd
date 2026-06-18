extends TileMapLayer

# On ready, generates a WxH map
# places 2 resources, 1 processor and 1 collection point and 2 spawn points
# uses navigation agent to check that every path is reachable
# if not, regenerates

@export var width := 100
@export var height := 100

const SOURCE_ID := 0
const GRASS := Vector2i(4, 5)
const TREE := Vector2i(0, 8)

var astar_grid: AStarGrid2D

func _ready():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0,0,width,height)
	astar_grid.cell_size = tile_set.tile_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.offset = tile_set.tile_size / 2.0
	astar_grid.update()
	
	for x in width:
		for y in height:
			var tile := GRASS
			var pos = Vector2i(x,y)
			if randf() < 0.2:
				tile = TREE
				astar_grid.set_point_solid(pos)
			set_cell(pos, SOURCE_ID, tile)
