extends Spatial

var _chunks = []

var _radius
var _chunk_depth = 7

var Generator = preload("res://Scripts/Generator.gdns")

var _generator

onready var player = get_node("Player")

func _ready():
	_chunks.append(get_node("Chunk"))

func init(radius):
	_radius = radius
	_generator = Generator.new()
	_generator.set_radius(_radius)

	# Set the players position so they don't get stuck.
	player.translation.y = _radius
	
	for chunk in _chunks:
		chunk.init(_chunk_depth, _generator)

func draw():
	# Create vertex data.
	for chunk in _chunks:
		chunk.draw()

func carve_terrain(intersection: Vector3):
	for chunk in _chunks:
		var found_vertex = chunk.change_terrain(intersection, -0.5)
		if found_vertex:
			chunk.draw()

func place_terrain(intersection: Vector3):
	for chunk in _chunks:
		var found_vertex = chunk.change_terrain(intersection, 0.5)
		if found_vertex:
			chunk.draw()
	
func _underwater(point: Vector3, caller):
	var underwater = false
	for chunk in _chunks:
		if chunk.is_underwater(point):
			underwater = true
	
	caller.underwater(underwater)
