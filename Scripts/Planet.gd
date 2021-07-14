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
	player.translation.y = _radius/2.0

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
				add_stitch(i, j, k, [
					get_chunk_key(i,	 j,		k	 ),
					get_chunk_key(i,	 j,		k + 1),
					get_chunk_key(i,	 j + 1, k	 ),
					get_chunk_key(i,	 j + 1, k + 1),
					get_chunk_key(i + 1, j, 	k	 ),
					get_chunk_key(i + 1, j, 	k + 1),
					get_chunk_key(i + 1, j + 1, k	 ),
					get_chunk_key(i + 1, j + 1, k + 1)
				], null)

				add_stitch(i, j, k, [
					get_chunk_key(i,	 j,	    k),
					get_chunk_key(i,	 j + 1, k),
					get_chunk_key(i + 1, j,		k),
					get_chunk_key(i + 1, j + 1, k)
				], 1)

				add_stitch(i, j, k, [
					get_chunk_key(i, 	 j, k	 ),
					get_chunk_key(i, 	 j, k + 1),
					get_chunk_key(i + 1, j, k	 ),
					get_chunk_key(i + 1, j, k + 1)
				], 2)

				add_stitch(i, j, k, [
					get_chunk_key(i, j,		k	 ),
					get_chunk_key(i, j,		k + 1),
					get_chunk_key(i, j + 1, k	 ),
					get_chunk_key(i, j + 1, k + 1)
				], 4)

				add_stitch(i, j, k, [get_chunk_key(i, j, k), get_chunk_key(i, j, k + 1)], 1)
				add_stitch(i, j, k, [get_chunk_key(i, j, k), get_chunk_key(i, j + 1, k)], 2)
				add_stitch(i, j, k, [get_chunk_key(i, j, k), get_chunk_key(i + 1, j, k)], 4)

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

func add_stitch(x, y, z, keys, axis):
	var stitch_type
	match keys.size():
		2:
			stitch_type = "f"
		4:
			stitch_type = "e"
		8:
			stitch_type = "v"

	# Do not create a new stitch if the current one already exists.
	var key = get_chunk_key(x, y, z) + stitch_type + str(axis)
	if _stitches.has(key):
		return

	# Get chunks, but do not create a stitch if the chunks don't exist yet.
	var chunks = []
	for chunk_key in keys:
		if not _chunks.has(chunk_key):
			return

		chunks.append(_chunks[chunk_key])

	# Create a new stitch, add it to the scene tree, and draw it.
	var stitch = StitchChunk.instance()
	add_child(stitch)
	stitch.init()
	_stitches[key] = stitch

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()

	# Draw the stitch.
	match keys.size():
		2:
			stitch.draw_face(chunks[0], chunks[1], axis)
		4:
			stitch.draw_edge(chunks[0], chunks[1], chunks[2], chunks[3], axis)
		8:
			stitch.draw_vert(chunks[0], chunks[1], chunks[2], chunks[3], chunks[4], chunks[5], chunks[6], chunks[7])

func load_chunk(args):
	# Retrieve arguments.
	var thread = args[0]
	var x = args[1]
	var y = args[2]
	var z = args[3]
	var key = get_chunk_key(x, y, z)

	# Create a new chunk.
	var chunk = Chunk.instance()
	chunk.translation = Vector3(x*_chunk_size, y*_chunk_size, z*_chunk_size)

	call_deferred("load_done", thread, chunk, key)

func load_done(thread, chunk, key):
	# Instantiate the chunk.
	add_child(chunk)
	chunk.init(_chunk_depth, _generator)
	chunk.generate()
	
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

func get_stitch_key(x, y, z, stitch_type, axis):
	return get_chunk_key(x, y, z) + stitch_type + str(axis)

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
