extends Spatial

var Octnode = preload("res://Scripts/Octree/Octnode.gd")

onready var mesh_instance = get_node("MeshInstance")

onready var head = Octnode.Octnode.new()

func init():
	head._split()
	head._get_child(0)._split()
	head._get_child(0)._get_child(0)._split()
	
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
	var stack = []
	stack.push_back(head)
	
	var vert = Vector3(-1, -1, 1)
	var vert_stack = [vert]

	var edge = 2.0
	var edge_stack = [edge]
	
	var arb_factor = 4

	# Perform a DFS traversal of the octree.
	var n
	while (!stack.empty()):
		# Pop frame from stack.
		n = stack.pop_back()
		vert = vert_stack.pop_back()
		edge = edge_stack.pop_back()

		if (n._is_leaf()):
			# Draw the leaf node.
			var arb_stretch = Vector3(vert.x, vert.y, vert.z*arb_factor)
			
			verts = Geometry.draw_bounds(arb_stretch, arb_stretch + Vector3(edge, edge, edge*arb_factor), verts)
		else:
			# Add this nodes children to the stack.
			edge /= 2

			for i in range(8):
				# Calculate the first vertex of each child node.
				var new_vert = vert
				
				if i & 4 == 4:
					new_vert.x += edge
				if i & 2 == 2:
					new_vert.y += edge
				if i & 1 == 1:
					new_vert.z += edge
				
				# Push frame onto stack.
				stack.push_back(n._get_child(i))
				vert_stack.push_back(new_vert)
				edge_stack.push_back(edge)

	return verts
