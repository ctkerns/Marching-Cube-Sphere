extends Planetary

var Octnode = preload("res://Scripts/Octree/Octnode.gd")

onready var mesh_instance = get_node("MeshInstance")

onready var head = Octnode.Octnode.new(0.5)

enum Division {SW_down, NW_down, SW_up, NW_up, SE_down, NE_down, SE_up, NE_up}

var nodes: Dictionary

func init():
	nodes[1] = Octnode.Octnode.new(0.5)
	
	#split(0b1)
	#split(0b1000)
	#split(0b1000000)
	pass
	
func split(loc_code: int):
	if _depth(loc_code) > 20:
		return
		
	var prefix = loc_code << 3
	var suffix = 0
	
	for i in range(8):
		nodes[prefix | suffix] = Octnode.Octnode.new(0.5)
		suffix += 1
	
func _depth(loc_code: int) -> int:
	return int( (log(loc_code) / 3) / log(2) )
	
func _get_child(loc_code: int, dir: int) -> int:
	return loc_code << 3 | dir
	
func draw():
	# Set up array mesh.
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PoolVector3Array()

	# Draw octree.
	verts = _draw_tree(verts)

	# Create surface.
	arr[Mesh.ARRAY_VERTEX] = verts

	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)

func _draw_tree(verts):
	# Initialize stack.
	var stack = []
	stack.push_back(1)
	
	var vert = Vector3(-1, -1, 1)
	var vert_stack = [vert]

	var edge = 2.0
	var edge_stack = [edge]
	
	var arb_factor = 4

	# Perform a DFS traversal of the octree using stack.
	var id; var n
	while !stack.empty():
		# Pop frame from stack.
		id = stack.pop_back()
		vert = vert_stack.pop_back()
		edge = edge_stack.pop_back()

		# Get the address of a child of this node.
		var check = _get_child(id, 0)

		# Check if this node has children.
		if !nodes.has(check):
			# Draw the leaf node.
			var arb_stretch = Vector3(vert.x, vert.y, vert.z*arb_factor)
			
			verts = Geometry.draw_bounds(arb_stretch, arb_stretch + Vector3(edge, edge, edge*arb_factor), verts)
		else:
			# Add this nodes children to the stack.
			edge /= 2

			for i in range(8):
				# Calculate the first vertex of each child node.
				var new_vert = vert
				
				# No idea if this is accurate to the enum direction I set up.
				# Double check this.
				if i & 4 == 4:
					new_vert.x += edge
				if i & 2 == 2:
					new_vert.y += edge
				if i & 1 == 1:
					new_vert.z += edge
				
				# Push frame onto stack.
				stack.push_back(_get_child(id, i))
				vert_stack.push_back(new_vert)
				edge_stack.push_back(edge)

	return verts
