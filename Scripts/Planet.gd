extends Spatial

var _chunks = {}
var _stitches = {}
var _unloaded_chunks = {}
var _unloaded_stitches = {}

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
	player.translation.y = _radius/2.0 + 20.0

func _process(_delta):
	load_world()

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

	if add_chunk(id.x, id.y, id.z):
		return
	
	# Load all 26 neighboring chunks.
	load_face(queue, id.x + 1, id.y, id.z,  1,  0,  0, 0b100, 1)
	load_face(queue, id.x - 1, id.y, id.z, -1,  0,  0, 0b100, 1)
	load_face(queue, id.x, id.y + 1, id.z,  0,  1,  0, 0b010, 1)
	load_face(queue, id.x, id.y - 1, id.z,  0, -1,  0, 0b010, 1)
	load_face(queue, id.x, id.y, id.z + 1,  0,  0,  1, 0b001, 1)
	load_face(queue, id.x, id.y, id.z - 1,  0,  0, -1, 0b001, 1)

	load_edge(queue, id.x, id.y + 1, id.z + 1, 0,  1,  1, 0b100, 1)
	load_edge(queue, id.x, id.y + 1, id.z - 1, 0,  1, -1, 0b100, 1)
	load_edge(queue, id.x, id.y - 1, id.z + 1, 0, -1,  1, 0b100, 1)
	load_edge(queue, id.x, id.y - 1, id.z - 1, 0, -1, -1, 0b100, 1)

	load_edge(queue, id.x + 1, id.y, id.z + 1,  1, 0,  1, 0b010, 1)
	load_edge(queue, id.x + 1, id.y, id.z - 1,  1, 0, -1, 0b010, 1)
	load_edge(queue, id.x - 1, id.y, id.z + 1, -1, 0,  1, 0b010, 1)
	load_edge(queue, id.x - 1, id.y, id.z - 1, -1, 0, -1, 0b010, 1)

	load_edge(queue, id.x + 1, id.y + 1, id.z,  1,  1, 0, 0b001, 1)
	load_edge(queue, id.x + 1, id.y - 1, id.z,  1, -1, 0, 0b001, 1)
	load_edge(queue, id.x - 1, id.y + 1, id.z, -1,  1, 0, 0b001, 1)
	load_edge(queue, id.x - 1, id.y - 1, id.z, -1, -1, 0, 0b001, 1)

	load_vert(queue, id.x + 1, id.y + 1, id.z + 1,  1,  1,  1, 1)
	load_vert(queue, id.x + 1, id.y + 1, id.z - 1,  1,  1, -1, 1)
	load_vert(queue, id.x + 1, id.y - 1, id.z + 1,  1, -1,  1, 1)
	load_vert(queue, id.x + 1, id.y - 1, id.z - 1,  1, -1, -1, 1)
	load_vert(queue, id.x - 1, id.y + 1, id.z + 1, -1,  1,  1, 1)
	load_vert(queue, id.x - 1, id.y + 1, id.z - 1, -1,  1, -1, 1)
	load_vert(queue, id.x - 1, id.y - 1, id.z + 1, -1, -1,  1, 1)
	load_vert(queue, id.x - 1, id.y - 1, id.z - 1, -1, -1, -1, 1)

	# Use queue to recursively traverse the grid area.
	while not queue.empty():
		var call = queue.pop_front()
		match call[0]:
			"face":
				load_face(queue, call[1], call[2], call[3], call[4], call[5], call[6], call[7], call[8])
			"edge":
				load_edge(queue, call[1], call[2], call[3], call[4], call[5], call[6], call[7], call[8])
			"vert":
				load_vert(queue, call[1], call[2], call[3], call[4], call[5], call[6], call[7])

func load_vert(queue, x, y, z, d_x, d_y, d_z, dist):
	# Stop rendering past a set distance.
	if dist > _render_distance:
		return

	if add_chunk(x, y, z):
		return

	# Add stitches.
	if add_stitch(x, y, z, x - d_x, y - d_y, z - d_z, "v", null): return

	if add_stitch(x, y, z, x, y - d_y, z - d_z, "e", 0b100): return
	if add_stitch(x, y, z, x - d_x, y, z - d_z, "e", 0b010): return
	if add_stitch(x, y, z, x - d_x, y - d_y, z, "e", 0b001): return

	if add_stitch(x, y, z, x - d_x, y, z, "f", 0b100): return
	if add_stitch(x, y, z, x, y - d_y, z, "f", 0b010): return
	if add_stitch(x, y, z, x, y, z - d_z, "f", 0b001): return

	# Use queue to recursively traverse the grid area.
	queue.push_back(["vert", x + d_x, y + d_y, z + d_z, d_x, d_y, d_z, dist + 1])

func load_edge(queue, x, y, z, d_x, d_y, d_z, axis, dist):
	# Stop rendering past a set distance.
	if dist > _render_distance:
		return
	
	if add_chunk(x, y, z):
		return

	# Add stitches.
	if add_stitch(x, y, z, x - d_x, y - d_y, z - d_z, "e", axis): return
	
	# Use queue to recursively traverse the grid area.
	if d_x == 0:
		if add_stitch(x, y, z, x, y - d_y, z, "f", 0b010): return
		if add_stitch(x, y, z, x, y, z - d_z, "f", 0b001): return
		queue.push_back(["vert", x + 1, y + d_y, z + d_z,  1, d_y, d_z, dist + 1])
		queue.push_back(["vert", x - 1, y + d_y, z + d_z, -1, d_y, d_z, dist + 1])
	elif d_y == 0:
		if add_stitch(x, y, z, x - d_x, y, z, "f", 0b100): return
		if add_stitch(x, y, z, x, y, z - d_z, "f", 0b001): return
		queue.push_back(["vert", x + d_x, y + 1, z + d_z, d_x,  1, d_z, dist + 1])
		queue.push_back(["vert", x + d_x, y - 1, z + d_z, d_x, -1, d_z, dist + 1])
	elif d_z == 0:
		if add_stitch(x, y, z, x - d_x, y, z, "f", 0b100): return
		if add_stitch(x, y, z, x, y - d_y, z, "f", 0b010): return
		queue.push_back(["vert", x + d_x, y + d_y, z + 1, d_x, d_y,  1, dist + 1])
		queue.push_back(["vert", x + d_x, y + d_y, z - 1, d_x, d_y, -1, dist + 1])

	queue.push_back(["edge", x + d_x, y + d_y, z + d_z, d_x, d_y, d_z, axis, dist + 1])

func load_face(queue, x, y, z, d_x, d_y, d_z, axis, dist):
	# Stop rendering past a set distance.
	if dist > _render_distance:
		return
	
	if add_chunk(x, y, z):
		return
	
	# Add stitch.
	if add_stitch(x, y, z, x - d_x, y - d_y, z - d_z, "f", axis):
		return
	
	# Use queue to recursively traverse the grid area.
	queue.push_back(["face", x + d_x, y + d_y, z + d_z, d_x, d_y, d_z, axis, dist + 1])

	match axis:
		0b100:
			queue.push_back(["edge", x + d_x, y + 1, z,		d_x,  1,  0, 0b001, dist + 1])
			queue.push_back(["edge", x + d_x, y - 1, z,		d_x, -1,  0, 0b001, dist + 1])
			queue.push_back(["edge", x + d_x, y,	 z + 1, d_x,  0,  1, 0b010, dist + 1])
			queue.push_back(["edge", x + d_x, y,	 z - 1, d_x,  0, -1, 0b010, dist + 1])

			queue.push_back(["vert", x + d_x, y - 1, z - 1,	d_x, -1, -1, dist + 1])
			queue.push_back(["vert", x + d_x, y - 1, z + 1,	d_x, -1,  1, dist + 1])
			queue.push_back(["vert", x + d_x, y + 1, z - 1, d_x,  1, -1, dist + 1])
			queue.push_back(["vert", x + d_x, y + 1, z + 1, d_x,  1,  1, dist + 1])
		0b010:
			queue.push_back(["edge", x + 1, y + d_y, z,		 1, d_y,  0, 0b001, dist + 1])
			queue.push_back(["edge", x - 1, y + d_y, z,		-1, d_y,  0, 0b001, dist + 1])
			queue.push_back(["edge", x,		y + d_y, z + 1,  0, d_y,  1, 0b100, dist + 1])
			queue.push_back(["edge", x,		y + d_y, z - 1,  0, d_y, -1, 0b100, dist + 1])

			queue.push_back(["vert", x - 1, y - d_y, z + 1,	-1, d_y, -1, dist + 1])
			queue.push_back(["vert", x - 1, y + d_y, z + 1,	-1, d_y,  1, dist + 1])
			queue.push_back(["vert", x + 1,	y - d_y, z + 1,  1, d_y, -1, dist + 1])
			queue.push_back(["vert", x + 1,	y + d_y, z + 1,  1, d_y,  1, dist + 1])
		0b001:
			queue.push_back(["edge", x + 1, y,	   z + d_z,  1,  0, d_z, 0b010, dist + 1])
			queue.push_back(["edge", x - 1, y,	   z + d_z, -1,  0, d_z, 0b010, dist + 1])
			queue.push_back(["edge", x,		y + 1, z + d_z,  0,  1, d_z, 0b100, dist + 1])
			queue.push_back(["edge", x,		y - 1, z + d_z,  0, -1, d_z, 0b100, dist + 1])

			queue.push_back(["vert", x - 1, y - 1, z + d_z, -1, -1, d_z, dist + 1])
			queue.push_back(["vert", x - 1, y + 1, z + d_z, -1,  1, d_z, dist + 1])
			queue.push_back(["vert", x + 1,	y - 1, z + d_z,  1, -1, d_z, dist + 1])
			queue.push_back(["vert", x + 1,	y + 1, z + d_z,  1,  1, d_z, dist + 1])

# If chunk is still being loaded, return true.
func add_chunk(x, y, z):
	# Do not create a new chunk if the current one already exists.
	var key = get_chunk_key(x, y, z)
	if _chunks.has(key):
		return false

	if _unloaded_chunks.has(key):
		return true

	# Load chunks in a separate thread.
	if not _thread.is_active():
		_thread.start(self, "load_chunk", [_thread, key, x, y, z])
		_unloaded_chunks[key] = 1
	
	return true

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
	chunk.init(_chunk_depth, _generator, _chunk_depth)

	# Generate the chunk.
	chunk.generate()
	chunk.draw()

	call_deferred("load_done", thread, chunk, key)
	
func load_done(thread, chunk, key):
	_chunks[key] = chunk
	_unloaded_chunks.erase(key)

	# Show debug lines.
	if _show_borders:
		chunk.toggle_borders()
	if _show_dual:
		chunk.toggle_dual()

	thread.wait_to_finish()

# If stitch is still being loaded, return true.
func add_stitch(x1, y1, z1, x2, y2, z2, stitch_type, axis):
	# Do not create a new stitch if the current one already exists.
	var key = get_stitch_key(x1, y1, z1, x2, y2, z2)
	if _stitches.has(key):
		return false

	if _unloaded_stitches.has(key):
		return true

	# Find midpoint.
	var m_x = (x1 + x2)/2.0
	var m_y = (y1 + y2)/2.0
	var m_z = (z1 + z2)/2.0

	var keys = []
	match(stitch_type):
		"f":
			keys.resize(2)
			match axis:
				0b100:
					keys[0] = get_chunk_key(m_x - 0.5, m_y, m_z)
					keys[1] = get_chunk_key(m_x + 0.5, m_y, m_z)
				0b010:
					keys[0] = get_chunk_key(m_x, m_y - 0.5, m_z)
					keys[1] = get_chunk_key(m_x, m_y + 0.5, m_z)
				0b001:
					keys[0] = get_chunk_key(m_x, m_y, m_z - 0.5)
					keys[1] = get_chunk_key(m_x, m_y, m_z + 0.5)
		"e":
			keys.resize(4)
			match axis:
				0b100:
					keys[0] = get_chunk_key(m_x, m_y - 0.5, m_z - 0.5)
					keys[1] = get_chunk_key(m_x, m_y - 0.5, m_z + 0.5)
					keys[2] = get_chunk_key(m_x, m_y + 0.5, m_z - 0.5)
					keys[3] = get_chunk_key(m_x, m_y + 0.5, m_z + 0.5)
				0b010:
					keys[0] = get_chunk_key(m_x - 0.5, m_y, m_z - 0.5)
					keys[1] = get_chunk_key(m_x - 0.5, m_y, m_z + 0.5)
					keys[2] = get_chunk_key(m_x + 0.5, m_y, m_z - 0.5)
					keys[3] = get_chunk_key(m_x + 0.5, m_y, m_z + 0.5)
				0b001:
					keys[0] = get_chunk_key(m_x - 0.5, m_y - 0.5, m_z)
					keys[1] = get_chunk_key(m_x - 0.5, m_y + 0.5, m_z)
					keys[2] = get_chunk_key(m_x + 0.5, m_y - 0.5, m_z)
					keys[3] = get_chunk_key(m_x + 0.5, m_y + 0.5, m_z)
		"v":
			keys.resize(8)
			keys[0] = get_chunk_key(m_x - 0.5, m_y - 0.5, m_z - 0.5)
			keys[1] = get_chunk_key(m_x - 0.5, m_y - 0.5, m_z + 0.5)
			keys[2] = get_chunk_key(m_x - 0.5, m_y + 0.5, m_z - 0.5)
			keys[3] = get_chunk_key(m_x - 0.5, m_y + 0.5, m_z + 0.5)
			keys[4] = get_chunk_key(m_x + 0.5, m_y - 0.5, m_z - 0.5)
			keys[5] = get_chunk_key(m_x + 0.5, m_y - 0.5, m_z + 0.5)
			keys[6] = get_chunk_key(m_x + 0.5, m_y + 0.5, m_z - 0.5)
			keys[7] = get_chunk_key(m_x + 0.5, m_y + 0.5, m_z + 0.5)

	# Get chunks, but do not create a stitch if the chunks don't exist yet.
	var chunks = []
	for chunk_key in keys:
		if not _chunks.has(chunk_key):
			return true

		chunks.append(_chunks[chunk_key])

	# Load stitches in a separate thread.
	if not _thread.is_active():
		_thread.start(self, "load_stitch", [_thread, key, chunks, axis])

func load_stitch(args):
	# Retrieve args.
	var thread = args[0]
	var key = args[1]
	var chunks = args[2]
	var axis = args[3]

	# Create a new stitch and add it to the scene tree.
	var stitch = StitchChunk.instance()
	add_child(stitch)

	# Initialize and draw the stitch.
	stitch.init(chunks, axis)
	stitch.draw()
	
	call_deferred("load_stitch_done", thread, stitch, key)

func load_stitch_done(thread, stitch, key):
	_stitches[key] = stitch
	_unloaded_stitches.erase(key)

	# Show debug lines.
	if _show_dual:
		stitch.toggle_dual()

	thread.wait_to_finish()

func redraw_chunk(args):
	var thread = args[0]
	var x = args[1]
	var y = args[2]
	var z = args[3]
	
	# Redraw center chunk.
	_chunks[get_chunk_key(x, y, z)].draw()

	redraw_stitch(get_stitch_key(x, y, z, x + 1, y,		z))
	redraw_stitch(get_stitch_key(x, y, z, x,	 y + 1, z))
	redraw_stitch(get_stitch_key(x, y, z, x,	 y,		z + 1))
	redraw_stitch(get_stitch_key(x, y, z, x - 1, y,		z))
	redraw_stitch(get_stitch_key(x, y, z, x,	 y - 1, z))
	redraw_stitch(get_stitch_key(x, y, z, x,	 y,		z - 1))

	redraw_stitch(get_stitch_key(x, y, z, x, y - 1, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x, y - 1, z + 1))
	redraw_stitch(get_stitch_key(x, y, z, x, y + 1, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x, y + 1, z + 1))

	redraw_stitch(get_stitch_key(x, y, z, x - 1, y, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x - 1, y, z + 1))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y, z + 1))

	redraw_stitch(get_stitch_key(x, y, z, x - 1, y - 1, z))
	redraw_stitch(get_stitch_key(x, y, z, x - 1, y + 1, z))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y - 1, z))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y + 1, z))

	redraw_stitch(get_stitch_key(x, y, z, x - 1, y - 1, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x - 1, y - 1, z + 1))
	redraw_stitch(get_stitch_key(x, y, z, x - 1, y + 1, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x - 1, y + 1, z + 1))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y - 1, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y - 1, z + 1))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y + 1, z - 1))
	redraw_stitch(get_stitch_key(x, y, z, x + 1, y + 1, z + 1))

	call_deferred("redraw_done", thread)

func redraw_stitch(key):
	if _stitches.has(key):
		_stitches[key].draw()

func redraw_done(thread):
	thread.wait_to_finish()

func get_chunk_id(x, y, z):
	var id_x = floor(x/_chunk_size + 0.5)
	var id_y = floor(y/_chunk_size + 0.5)
	var id_z = floor(z/_chunk_size + 0.5)

	return Vector3(id_x, id_y, id_z)

func get_chunk_key(x, y, z):
	return str(int(x)) + "," + str(int(y)) + "," + str(int(z))

func get_stitch_key(x1, y1, z1, x2, y2, z2):
	return str((x1 + x2)/2.0) + "," + str((y1 + y2)/2.0) + "," + str((z1 + z2)/2.0)

# Here the mesh can get detached because terrain is being generated in the middle of
# this being drawn.
func carve_terrain(intersection: Vector3):
	# Find chunk.
	var id = get_chunk_id(intersection.x, intersection.y, intersection.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	var chunk = _chunks[key]
	
	chunk.change_terrain(intersection, -0.03)

	# Redraw chunk and stitches.
	if not _draw_thread.is_active():
		_draw_thread.start(self, "redraw_chunk", [_draw_thread, id.x, id.y, id.z])

func place_terrain(intersection: Vector3):
	# Find chunk.
	var id = get_chunk_id(intersection.x, intersection.y, intersection.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	var chunk = _chunks[key]
	
	chunk.change_terrain(intersection, 0.03)

	# Redraw chunk and stitches.
	if not _draw_thread.is_active():
		_draw_thread.start(self, "redraw_chunk", [_draw_thread, id.x, id.y, id.z])
	
func _underwater(point: Vector3, caller):
	# Find chunk.
	var id = get_chunk_id(player.translation.x, player.translation.y, player.translation.z)
	var key = get_chunk_key(id.x, id.y, id.z)
	
	# Only check if underwater if the current chunk is loaded.
	if _chunks.has(key):
		var chunk = _chunks[key]
	
		var underwater = chunk.is_underwater(point)
		caller.underwater(underwater)
