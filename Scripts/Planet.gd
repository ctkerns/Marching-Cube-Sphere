extends Spatial

var _chunks = {}
var _stitches = {}

var _radius
var _chunk_depth = 4
var _render_distance = 1
onready var _chunk_size = pow(2, _chunk_depth)

var Generator = preload("res://Scripts/Generator.gdns")
var Chunk = preload("res://Scenes/Chunk.tscn")
var StitchChunk = preload("res://Scenes/StitchChunk.tscn")

var _generator

onready var player = get_node("Player")

var _show_borders = false
var _show_dual = false

func init(radius):
	_radius = radius
	_generator = Generator.new()
	_generator.set_radius(_radius)

	# Set the players position so they don't get stuck.
	player.translation.y = _radius

func _process(_delta):
	# Add chunks.
	var id = get_chunk_id(player.translation.x, player.translation.y, player.translation.z)

	for i in range(id.x - _render_distance, id.x + _render_distance + 1):
		for j in range(id.y - _render_distance, id.y + _render_distance + 1):
			for k in range(id.z - _render_distance, id.z + _render_distance + 1):
				add_chunk(i, j, k)
	
	# Add stitches.
	for i in range(id.x - _render_distance, id.x + _render_distance):
		for j in range(id.y - _render_distance, id.y + _render_distance):
			for k in range(id.z - _render_distance, id.z + _render_distance):
				add_corner_stitch(i, j, k,
					_chunks[get_chunk_key(i,	 j,		k	 )],
					_chunks[get_chunk_key(i,	 j,		k + 1)],
					_chunks[get_chunk_key(i,	 j + 1, k	 )],
					_chunks[get_chunk_key(i,	 j + 1, k + 1)],
					_chunks[get_chunk_key(i + 1, j, 	k	 )],
					_chunks[get_chunk_key(i + 1, j, 	k + 1)],
					_chunks[get_chunk_key(i + 1, j + 1, k	 )],
					_chunks[get_chunk_key(i + 1, j + 1, k + 1)]
				)

				add_edge_stitch(i, j, k,
					_chunks[get_chunk_key(i,	 j,	    k)],
					_chunks[get_chunk_key(i,	 j + 1, k)],
					_chunks[get_chunk_key(i + 1, j,		k)],
					_chunks[get_chunk_key(i + 1, j + 1, k)],
					1
				)

				add_edge_stitch(i, j, k,
					_chunks[get_chunk_key(i, 	 j, k	 )],
					_chunks[get_chunk_key(i, 	 j, k + 1)],
					_chunks[get_chunk_key(i + 1, j, k	 )],
					_chunks[get_chunk_key(i + 1, j, k + 1)],
					2
				)

				add_edge_stitch(i, j, k,
					_chunks[get_chunk_key(i, j,		k	 )],
					_chunks[get_chunk_key(i, j,		k + 1)],
					_chunks[get_chunk_key(i, j + 1, k	 )],
					_chunks[get_chunk_key(i, j + 1, k + 1)],
					4
				)

				add_side_stitch(i, j, k,
					_chunks[get_chunk_key(i, j, k	 )],
					_chunks[get_chunk_key(i, j, k + 1)],
					1
				)

				add_side_stitch(i, j, k,
					_chunks[get_chunk_key(i, j,		k)],
					_chunks[get_chunk_key(i, j + 1, k)],
					2
				)

				add_side_stitch(i, j, k,
					_chunks[get_chunk_key(i,	 j, k)],
					_chunks[get_chunk_key(i + 1, j, k)],
					4
				)

func _input(event):
	if event.is_action_pressed("toggle_borders"):
		for key in _chunks:
			_chunks[key].toggle_borders()
		_show_borders = not _show_borders

	if event.is_action_pressed("toggle_dual"):
		for key in _chunks:
			_chunks[key].toggle_dual()
		for key in _stitches:
			_stitches[key].toggle_dual()
		_show_dual = not _show_dual

func add_chunk(x, y, z):
	# Do not create a new chunk if the current one already exists.
	var key = get_chunk_key(x, y, z)
	if _chunks.has(key):
		return

	# Create a new chunk, add it to the scene tree, and draw it.
	var chunk = Chunk.instance()
	add_child(chunk)
	chunk.translation = Vector3(x*_chunk_size, y*_chunk_size, z*_chunk_size)
	chunk.init(_chunk_depth, _generator)
	
	# Show debug lines.
	if _show_borders:
		chunk.toggle_borders()
	if _show_dual:
		chunk.toggle_dual()
	
	chunk.draw()

	_chunks[key] = chunk

func add_side_stitch(x, y, z, c0, c1, axis):
	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + "f" + str(axis)
	if _stitches.has(key):
		return

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()

	stitch.draw_face(c0, c1, axis)

	_stitches[key] = stitch

func add_edge_stitch(x, y, z, c0, c1, c2, c3, axis):
	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + "e" + str(axis)
	if _stitches.has(key):
		return

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()

	stitch.draw_edge(c0, c1, c2, c3, axis)

	_stitches[key] = stitch

func add_corner_stitch(x, y, z, c0, c1, c2, c3, c4, c5, c6, c7):
	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + "v"
	if _stitches.has(key):
		return

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()
	
	stitch.draw_vert(c0, c1, c2, c3, c4, c5, c6, c7)

	_stitches[key] = stitch

func get_chunk_id(x, y, z):
	var id_x = floor(x/_chunk_size + 0.5)
	var id_y = floor(y/_chunk_size + 0.5)
	var id_z = floor(z/_chunk_size + 0.5)

	return Vector3(id_x, id_y, id_z)

func get_chunk_key(x, y, z):
	return str(int(x)) + "," + str(int(y)) + "," + str(int(z))

func carve_terrain(intersection: Vector3):
	# Find chunk.
	var id = get_chunk_id(intersection.x, intersection.y, intersection.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	var chunk = _chunks[key]
	
	chunk.change_terrain(intersection, -0.03)
	chunk.draw()

func place_terrain(intersection: Vector3):
	# Find chunk.
	var id = get_chunk_id(intersection.x, intersection.y, intersection.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	var chunk = _chunks[key]
	
	chunk.change_terrain(intersection, 0.03)
	chunk.draw()
	
func _underwater(point: Vector3, caller):
	# Find chunk.
	var id = get_chunk_id(player.translation.x, player.translation.y, player.translation.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	var chunk = _chunks[key]
	
	var underwater = chunk.is_underwater(point)
	caller.underwater(underwater)
