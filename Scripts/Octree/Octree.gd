extends Planetary

var Octnode = preload("res://Scripts/Octree/Octnode.gd")

onready var mesh_instance = get_node("MeshInstance")

onready var head = Octnode.Octnode.new(0.5)

onready var _tree_verts = PoolVector3Array()
onready var _dual_verts = PoolVector3Array()

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
	
# Returns the depth of this node.
func _get_depth(loc_code: int) -> int:
	return int( (log(loc_code) / 3) / log(2) )
	
# Returns the locational code of the child of this node in the given direction.
func _get_child(loc_code: int, div: int) -> int:
	return loc_code << 3 | div

# Returns the position of the center of this node.
func _get_vertex(loc_code: int) -> Vector3:
	return Vector3(0, 0, 0)

# Returns the bounding box of the node. 
func _get_bounds(loc_code: int):
	var depth = _get_depth(loc_code)
	var edge = 2.0 / (pow(2, depth))

	var vert = Vector3(-1, -1, 1)

	var n = loc_code
	var working_edge = edge
	for i in range(depth):
		if n & 4 == 4:
			vert.x += working_edge
		if n & 2 == 2:
			vert.y += working_edge
		if n & 1 == 1:
			vert.z += working_edge

		n = n >> 3

		working_edge *= 2

	return [vert, edge]

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
	stack.push_back(1)
	
	var arb_factor = 4

	# Perform a DFS traversal of the octree using stack.
	var id
	while !stack.empty():
		# Pop frame from stack.
		id = stack.pop_back()

		# Get the address of a child of this node.
		var check = _get_child(id, 0)

		# Check if this node has children.
		if !nodes.has(check):
			# Draw the leaf node.
			var bounds = _get_bounds(id)
			var vert = bounds[0]
			var edge = bounds[1]

			var arb_stretch = Vector3(vert.x, vert.y, vert.z*arb_factor)

			_tree_verts = Geometry.draw_bounds(
				arb_stretch,
				arb_stretch + Vector3(edge, edge, edge*arb_factor),
				_tree_verts
			)
		else:
			# Add this nodes children to the stack.
			for i in range(8):
				stack.push_back(_get_child(id, i))

func _draw_dual():
	pass

func _cube_proc(q1):
	pass

func _face_proc(q1, q2, q3, q4):
	pass

func _edge_proc(q1, q2):
	pass

func _vert_proc(q1, q2, q3, q4, q5, q6, q7, q8):
	pass
