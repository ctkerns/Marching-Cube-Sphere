extends Planetary

var Octnode = preload("res://Scripts/Octree/Octnode.gd")

onready var mesh_instance = get_node("MeshInstance")

onready var head = Octnode.Octnode.new(0.5)

onready var _tree_verts = PoolVector3Array()
onready var _dual_verts = PoolVector3Array()

var _arb_factor = 4

enum Division {SW_Down, NW_Down, SW_Up, NW_Up, SE_Down, NE_Down, SE_Up, NE_Up}
enum Direction {Up, Down, North, South, East, West}

var nodes: Dictionary

func init():
	nodes[1] = Octnode.Octnode.new(0.5)
	
	split(0b1)
	split(0b1000)
	split(0b1000000)
	pass
	
# Subdivides this node by creating eight children.
func split(loc_code: int):
	if _get_depth(loc_code) > 20:
		return
		
	var prefix = loc_code << 3
	var suffix = 0
	
	for i in range(8):
		nodes[prefix | suffix] = Octnode.Octnode.new(0.5)
		suffix += 1

func _is_branch(loc_code: int):
	return nodes.has(_get_child(loc_code, 0))
	
# Returns the depth of this node.
func _get_depth(loc_code: int) -> int:
	return int( (log(loc_code) / 3) / log(2) )
	
# Returns the locational code of the child of this node in the given direction.
func _get_child(loc_code: int, div: int) -> int:
	return loc_code << 3 | div

# Returns the position of the center of this node.
func _get_vertex(loc_code: int) -> Vector3:
	var depth = _get_depth(loc_code)
	var scale = 2.0 / (pow(2, depth))

	# Start at the center of the head node.
	var vert = Vector3(0, 0, 2)

	# Traverse the path of the node bottom up.
	var n = loc_code
	var increment = scale
	for i in range(depth):
		# Move the vertex according to the locational code.
		if n & 4 == 4:
			vert.x += increment/2
		else:
			vert.x -= increment/2

		if n & 2 == 2:
			vert.y += increment/2
		else:
			vert.y -= increment/2

		if n & 1 == 1:
			vert.z += increment/2
		else:
			vert.z -= increment/2

		# Move up a level.
		increment *= 2
		n = n >> 3

	return vert
		
# Returns the bounding box of the node. 
func _get_bounds(loc_code: int):
	var depth = _get_depth(loc_code)
	var scale = 2.0 / (pow(2, depth))

	# Start at the center of the head node.
	var vert = Vector3(-1, -1, 1)

	# Traverse the path of the node bottom up.
	var n = loc_code
	var increment = scale
	for i in range(depth):
		# Move the vertex according to the locational code.
		if n & 4 == 4:
			vert.x += increment
		if n & 2 == 2:
			vert.y += increment
		if n & 1 == 1:
			vert.z += increment

		# Move up a level.
		n = n >> 3
		increment *= 2

	return [vert, scale]

# Returns the adjacent neighboring leaf node in the given direction. Not yet implemented.
func _get_neighbor(loc_code: int, dir: int) -> int:
	return 1
	
func draw():
	# Set up array meshes.
	var tree_arr = []
	var dual_arr = []
	tree_arr.resize(Mesh.ARRAY_MAX)
	dual_arr.resize(Mesh.ARRAY_MAX)

	# Draw octree and dual.
	_draw_tree()
	_draw_dual()

	# Create mesh from array.
	tree_arr[Mesh.ARRAY_VERTEX] = _tree_verts
	dual_arr[Mesh.ARRAY_VERTEX] = _dual_verts

	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, tree_arr)
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, dual_arr)

func _draw_tree():
	# Initialize stack.
	var stack = []
	stack.push_back(0b1)

	# Perform a DFS traversal of the octree using stack.
	var id
	while !stack.empty():
		# Pop frame from stack.
		id = stack.pop_back()

		# Check if this node is a leaf node.
		if not _is_branch(id):
			# Draw the leaf node.
			var bounds = _get_bounds(id)
			var vert = bounds[0]
			var scale = bounds[1]

			var arb_stretch = Vector3(vert.x, vert.y, vert.z*_arb_factor)

			_tree_verts = Geometry.draw_cuboid_edge(
				arb_stretch,
				arb_stretch + Vector3(scale, scale, scale*_arb_factor),
				_tree_verts
			)
		else:
			# Add this nodes children to the stack.
			for i in range(8):
				stack.push_back(_get_child(id, i))

func _draw_dual():
	_cube_proc(0b1)

func _cube_proc(t: int):
	# Terminate when t1 is a leaf node.
	if not _is_branch(t):
		return

	# Recursively traverse child nodes.
	var children = []
	children.resize(8)
	for i in range(8):
		children[i] = _get_child(t, i)
		
		_cube_proc(children[i])

	_vert_proc(children)

func _face_proc(t1, t2, t3, t4):
	pass

func _edge_proc(t1, t2):
	pass

func _vert_proc(t: Array):
	var num_leaves = 0

	var children = []
	children.resize(8)

	for i in range(8):
		if _is_branch(t[i]):
			# If node is a branch, get its child that is connected to the octree vertex.
			children[i] = _get_child(t[i], 7 - i)
		else:
			# If node is a leaf, use the node as a stand in for its child.
			children[i] = t[i]
			num_leaves += 1
	
	if num_leaves >= 8:
		# All nodes surrounding the vertex are leaves so draw the dual volume here.
		var v = []
		v.resize(8)
		for i in range(8):
			v[i] = _get_vertex(t[i])
			v[i].z *= _arb_factor

		_dual_verts = Geometry.draw_hexahedron_edge(v, _dual_verts)
	else:
		# Recursively traverse child nodes.
		_vert_proc(children)
