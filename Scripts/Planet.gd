extends Spatial

var _chunks = {}
var _stitches = {}
var _unloaded_chunks = {}

onready var _thread = Thread.new()
onready var _draw_thread = Thread.new()

var _radius
var _chunk_depth = 4
var _render_distance = 3
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
	player.translation.y = _radius/1.5

func _process(_delta):
	load_world
	return
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

func load_world():
	var id = get_chunk_id(player.translation.x, player.translation.y, player.translation.z)
	var queue = []
	
	load_face(queue, id.x + 1, id.y, id.z, 1,  1,  0,  0)
	load_face(queue, id.x - 1, id.y, id.z, 1, -1,  0,  0)
	load_face(queue, id.x, id.y + 1, id.z, 1,  0,  1,  0)
	load_face(queue, id.x, id.y - 1, id.z, 1,  0, -1,  0)
	load_face(queue, id.x, id.y, id.z + 1, 1,  0,  0,  1)
	load_face(queue, id.x, id.y, id.z - 1, 1,  0,  0, -1)

	load_edge(queue, id.x, id.y + 1, id.z + 1, 1, 0,  1,  1)
	load_edge(queue, id.x, id.y + 1, id.z - 1, 1, 0,  1, -1)
	load_edge(queue, id.x, id.y - 1, id.z + 1, 1, 0, -1,  1)
	load_edge(queue, id.x, id.y - 1, id.z - 1, 1, 0, -1, -1)

	load_edge(queue, id.x + 1, id.y, id.z + 1, 1,  1, 0,  1)
	load_edge(queue, id.x + 1, id.y, id.z - 1, 1,  1, 0, -1)
	load_edge(queue, id.x - 1, id.y, id.z + 1, 1, -1, 0,  1)
	load_edge(queue, id.x - 1, id.y, id.z - 1, 1, -1, 0, -1)

	load_edge(queue, id.x + 1, id.y + 1, id.z, 1,  1,  1, 0)
	load_edge(queue, id.x + 1, id.y - 1, id.z, 1,  1, -1, 0)
	load_edge(queue, id.x - 1, id.y + 1, id.z, 1, -1,  1, 0)
	load_edge(queue, id.x - 1, id.y - 1, id.z, 1, -1, -1, 0)

	load_vert(queue, id.x + 1, id.y + 1, id.z + 1, 1,  1,  1,  1)
	load_vert(queue, id.x + 1, id.y + 1, id.z - 1, 1,  1,  1, -1)
	load_vert(queue, id.x + 1, id.y - 1, id.z + 1, 1,  1, -1,  1)
	load_vert(queue, id.x + 1, id.y - 1, id.z - 1, 1,  1, -1, -1)
	load_vert(queue, id.x - 1, id.y + 1, id.z + 1, 1, -1,  1,  1)
	load_vert(queue, id.x - 1, id.y + 1, id.z - 1, 1, -1,  1, -1)
	load_vert(queue, id.x - 1, id.y - 1, id.z + 1, 1, -1, -1,  1)
	load_vert(queue, id.x - 1, id.y - 1, id.z - 1, 1, -1, -1, -1)

	# Use queue to recursively traverse the grid area.
	while not queue.empty():
		var call = queue.pop_front()
		match call[0]:
			"face":
				load_face(queue, call[1], call[2], call[3], call[4], call[5], call[6], call[7])
			"edge":
				load_edge(queue, call[1], call[2], call[3], call[4], call[5], call[6], call[7])
			"vert":
				load_vert(queue, call[1], call[2], call[3], call[4], call[5], call[6], call[7])

func load_vert(queue, x, y, z, dist, d_x, d_y, d_z):
	# Stop rendering past a set distance.
	if dist > _render_distance:
		return

	add_chunk(x, y, z)

	# Use queue to recursively traverse the grid area.
	queue.push_back(["vert", x + d_x, y + d_y, z + d_z, dist + 1, d_x, d_y, d_z])

	queue.push_back(["edge", x, y + d_y, z + d_z, dist + 1, 0, d_y, d_z])
	queue.push_back(["edge", x + d_x, y, z + d_z, dist + 1, d_x, 0, d_z])
	queue.push_back(["edge", x + d_x, y + d_y, z, dist + 1, d_x, d_y, 0])

	queue.push_back(["face", x + d_x, y, z, dist + 1, d_x, 0, 0])
	queue.push_back(["face", x, y + d_y, z, dist + 1, 0, d_y, 0])
	queue.push_back(["face", x, y, z + d_z, dist + 1, 0, 0, d_z])

func load_edge(queue, x, y, z, dist, d_x, d_y, d_z):
	# Stop rendering past a set distance.
	if dist > _render_distance:
		return
	
	add_chunk(x, y, z)

	# Use queue to recursively traverse the grid area.
	queue.push_back(["edge", x + d_x, y + d_y, z + d_z, dist + 1, d_x, d_y, d_z])

	if d_x == 0:
		queue.push_back(["face", x, y + d_y, z, dist + 1, d_x, d_y, 0])
		queue.push_back(["face", x, y, z + d_z, dist + 1, d_x, 0, d_z])
	elif d_y == 0:
		queue.push_back(["face", x + d_x, y, z, dist + 1, d_x, d_y, 0])
		queue.push_back(["face", x, y, z + d_z, dist + 1, 0, d_y, d_z])
	elif d_z == 0:
		queue.push_back(["face", x + d_x, y, z, dist + 1, d_x, 0, d_z])
		queue.push_back(["face", x, y + d_y, z, dist + 1, 0, d_y, d_z])

func load_face(queue, x, y, z, dist, d_x, d_y, d_z):
	# Stop rendering past a set distance.
	if dist > _render_distance:
		return
	
	add_chunk(x, y, z)

	# Use queue to recursively traverse the grid area.
	queue.push_back(["face", x + d_x, y + d_y, z + d_z, dist + 1, d_x, d_y, d_z])

func add_chunk(x, y, z):
	# Do not create a new chunk if the current one already exists.
	var key = get_chunk_key(x, y, z)
	if _chunks.has(key) or _unloaded_chunks.has(key):
		return false

	# Load chunks in a separate thread.
	if not _thread.is_active():
		_thread.start(self, "load_chunk", [_thread, key, x, y, z])
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
	var key = get_stitch_key(x, y, z, stitch_type, axis)
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
			stitch.draw_vert(
				chunks[0], chunks[1], chunks[2], chunks[3],
				chunks[4], chunks[5], chunks[6], chunks[7]
			)

func load_chunk(args):
	# Retrieve arguments.
	var thread = args[0]
	var key = args[1]
	var x = args[2]
	var y = args[3]
	var z = args[4]

	# Create a new chunk.
	var chunk = Chunk.instance()
	chunk.translation = Vector3(x*_chunk_size, y*_chunk_size, z*_chunk_size)
	add_child(chunk)
	chunk.init(_chunk_depth, _generator)

	# Show debug lines.
	if _show_borders:
		chunk.toggle_borders()
	if _show_dual:
		chunk.toggle_dual()

	# Generate the chunk.
	chunk.generate()
	chunk.draw()

	call_deferred("load_done", thread, chunk, key)

func load_done(thread, chunk, key):
	_chunks[key] = chunk
	_unloaded_chunks.erase(key)

	thread.wait_to_finish()

func redraw_chunk(args):
	var thread = args[0]
	var key = args[1]

	var chunk = _chunks[key]

	chunk.draw()
	call_deferred("redraw_done", thread)

func redraw_done(thread):
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

	# Redraw chunk and stitches.
	if not _draw_thread.is_active():
		_draw_thread.start(self, "redraw_chunk", [_draw_thread, key])

func place_terrain(intersection: Vector3):
	# Find chunk.
	var id = get_chunk_id(intersection.x, intersection.y, intersection.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	var chunk = _chunks[key]
	
	chunk.change_terrain(intersection, 0.03)

	# Redraw chunk and stitches.
	if not _draw_thread.is_active():
		_draw_thread.start(self, "redraw_chunk", [_draw_thread, key])
	
func _underwater(point: Vector3, caller):
	# Find chunk.
	var id = get_chunk_id(player.translation.x, player.translation.y, player.translation.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	
	# Only check if underwater if the current chunk is loaded.
	if _chunks.has(key):
		var chunk = _chunks[key]
	
		var underwater = chunk.is_underwater(point)
		caller.underwater(underwater)
