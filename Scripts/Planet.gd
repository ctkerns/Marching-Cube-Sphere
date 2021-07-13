extends Spatial

var _chunks = {}
var _stitches = {}
var _unloaded_chunks = {}

onready var _thread = Thread.new()

var _radius
var _chunk_depth = 4
var _render_distance = 2
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
	for i in range(id.x - _render_distance, id.x + _render_distance + 1):
		for j in range(id.y - _render_distance, id.y + _render_distance + 1):
			for k in range(id.z - _render_distance, id.z + _render_distance + 1):
				add_corner_stitch(i, j, k,
					get_chunk_key(i,	 j,		k	 ),
					get_chunk_key(i,	 j,		k + 1),
					get_chunk_key(i,	 j + 1, k	 ),
					get_chunk_key(i,	 j + 1, k + 1),
					get_chunk_key(i + 1, j, 	k	 ),
					get_chunk_key(i + 1, j, 	k + 1),
					get_chunk_key(i + 1, j + 1, k	 ),
					get_chunk_key(i + 1, j + 1, k + 1)
				)

				add_edge_stitch(i, j, k,
					get_chunk_key(i,	 j,	    k),
					get_chunk_key(i,	 j + 1, k),
					get_chunk_key(i + 1, j,		k),
					get_chunk_key(i + 1, j + 1, k),
					1
				)

				add_edge_stitch(i, j, k,
					get_chunk_key(i, 	 j, k	 ),
					get_chunk_key(i, 	 j, k + 1),
					get_chunk_key(i + 1, j, k	 ),
					get_chunk_key(i + 1, j, k + 1),
					2
				)

				add_edge_stitch(i, j, k,
					get_chunk_key(i, j,		k	 ),
					get_chunk_key(i, j,		k + 1),
					get_chunk_key(i, j + 1, k	 ),
					get_chunk_key(i, j + 1, k + 1),
					4
				)

				add_side_stitch(i, j, k,
					get_chunk_key(i, j, k	 ),
					get_chunk_key(i, j, k + 1),
					1
				)

				add_side_stitch(i, j, k,
					get_chunk_key(i, j,		k),
					get_chunk_key(i, j + 1, k),
					2
				)

				add_side_stitch(i, j, k,
					get_chunk_key(i,	 j, k),
					get_chunk_key(i + 1, j, k),
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
	if _chunks.has(key) or _unloaded_chunks.has(key):
		return

	# Load chunks in a separate thread.
	if not _thread.is_active():
		_thread.start(self, "load_chunk", [_thread, x, y, z])
		_unloaded_chunks[key] = 1

func add_side_stitch(x, y, z, c0, c1, axis):
	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + "f" + str(axis)
	if _stitches.has(key):
		return

	# Do not create a stitch if the requisit chunks do not exist.
	if not (_chunks.has(c0) and _chunks.has(c1)):
		return

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()

	stitch.draw_face(_chunks[c0], _chunks[c1], axis)

	_stitches[key] = stitch

func add_edge_stitch(x, y, z, c0, c1, c2, c3, axis):
	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + "e" + str(axis)
	if _stitches.has(key):
		return

	# Do not create a stitch if the requisit chunks do not exist.
	if not (_chunks.has(c0) and _chunks.has(c1) and _chunks.has(c2) and _chunks.has(c3)):
		return

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()

	stitch.draw_edge(_chunks[c0], _chunks[c1], _chunks[c2], _chunks[c3], axis)

	_stitches[key] = stitch

func add_corner_stitch(x, y, z, c0, c1, c2, c3, c4, c5, c6, c7):
	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + "v"
	if _stitches.has(key):
		return

	# Do not create a stitch if the requisit chunks do not exist.
	if not (_chunks.has(c0) and _chunks.has(c1) and _chunks.has(c2) and _chunks.has(c3) and _chunks.has(c4) and _chunks.has(c5) and _chunks.has(c6) and _chunks.has(c7)):
		return

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()
	
	stitch.draw_vert(_chunks[c0], _chunks[c1], _chunks[c2], _chunks[c3], _chunks[c4], _chunks[c5], _chunks[c6], _chunks[c7])

	_stitches[key] = stitch

func load_chunk(args):
	# Retrieve arguments.
	var thread = args[0]
	var x = args[1]
	var y = args[2]
	var z = args[3]
	var key = get_chunk_key(x, y, z)

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
	_unloaded_chunks.erase(key)
	thread.wait_to_finish()

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
	
	# Only check if underwater if the current chunk is loaded.
	if _chunks.has(key):
		var chunk = _chunks[key]
	
		var underwater = chunk.is_underwater(point)
		caller.underwater(underwater)
