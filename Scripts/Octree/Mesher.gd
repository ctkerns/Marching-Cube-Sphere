extends Object

class Mesher:
	var _tree_verts
	var _dual_verts
	var _surface_verts
	var _surface_normals

	var _arb_factor = 4
	var _octree

	func _init(oct):
		_tree_verts = PoolVector3Array()
		_dual_verts = PoolVector3Array()
		_surface_verts = PoolVector3Array()
		_surface_normals = PoolVector3Array()
		
		_octree = oct

	func draw_tree(tree_mesh):
		# Set up array mesh.
		var tree_arr = []
		tree_arr.resize(Mesh.ARRAY_MAX)

		# Initialize stack.
		var stack = []
		stack.push_back(0b1)

		# Perform a DFS traversal of the octree using stack.
		var id
		while !stack.empty():
			# Pop frame from stack.
			id = stack.pop_back()

			# Check if this node is a leaf node.
			if not _octree.is_branch(id):
				# Draw the leaf node.
				var bounds = _octree.get_bounds(id)
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
					stack.push_back(_octree.get_child(id, i))

		# Create mesh from array.
		tree_arr[Mesh.ARRAY_VERTEX] = _tree_verts

		tree_mesh.mesh = ArrayMesh.new()
		tree_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, tree_arr)

	func draw_dual(dual_mesh, surface_mesh) -> Shape:
		# Set up array meshes.
		var dual_arr = []
		dual_arr.resize(Mesh.ARRAY_MAX)
		var surface_arr = []
		surface_arr.resize(Mesh.ARRAY_MAX)

		# Recursively traverse the octree.
		_cube_proc(0b1)

		# Create mesh from array.
		dual_arr[Mesh.ARRAY_VERTEX] = _dual_verts
		surface_arr[Mesh.ARRAY_VERTEX] = _surface_verts
		surface_arr[Mesh.ARRAY_NORMAL] = _surface_normals

		dual_mesh.mesh = ArrayMesh.new()
		dual_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, dual_arr)
		surface_mesh.mesh = ArrayMesh.new()
		surface_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arr)

		return surface_mesh.mesh.create_trimesh_shape()

	func _cube_proc(t: int):
		# Terminate when t1 is a leaf node.
		if not _octree.is_branch(t):
			return
	
		# Recursively traverse child nodes.
		var children = []
		children.resize(8)
		for i in range(8):
			children[i] = _octree.get_child(t, i)
			
			_cube_proc(children[i])
	
		# Traverse octree faces.
		_face_proc([children[0], children[1]], 0b001)
		_face_proc([children[0], children[2]], 0b010)
		_face_proc([children[0], children[4]], 0b100)
		_face_proc([children[1], children[3]], 0b010)
		_face_proc([children[1], children[5]], 0b100)
		_face_proc([children[2], children[3]], 0b001)
		_face_proc([children[2], children[6]], 0b100)
		_face_proc([children[3], children[7]], 0b100)
		_face_proc([children[4], children[5]], 0b001)
		_face_proc([children[4], children[6]], 0b010)
		_face_proc([children[5], children[7]], 0b010)
		_face_proc([children[6], children[7]], 0b001)
	
		# Traverse octree edges.
		_edge_proc([children[0], children[1], children[2], children[3]], 0b100)
		_edge_proc([children[0], children[1], children[4], children[5]], 0b010)
		_edge_proc([children[0], children[2], children[4], children[6]], 0b001)
		_edge_proc([children[1], children[3], children[5], children[7]], 0b001)
		_edge_proc([children[2], children[3], children[6], children[7]], 0b010)
		_edge_proc([children[4], children[6], children[5], children[7]], 0b100)
	
		# Traverse octree vertices.
		_vert_proc(children)
	
	# Octree face, dual edge, takes two nodes as arguments.
	# Assume that t_0 is inferior on given axis and t_1 is superior.
	func _face_proc(t: Array, axis: int):
		var num_leaves = 0
	
		var children = []
		children.resize(8)
	
		# Find interior plane that needs to be connected, with the value at the given axis always 0.
		var plane
		match axis:
			0b001:
				plane = [0b000, 0b010, 0b100, 0b110]
			0b010:
				plane = [0b000, 0b001, 0b100, 0b101]
			0b100:
				plane = [0b000, 0b001, 0b010, 0b011]
	
		# Find children to be connected.
		if _octree.is_branch(t[0]):
			for i in range(4):
				children[i] = _octree.get_child(t[0], plane[i] | axis)
		else:
			# If node is a leaf, use the node as a stand in for its child.
			for i in range(4):
				children[i] = t[0]
			num_leaves += 1
		
		if _octree.is_branch(t[1]):
			for i in range(4):
				children[i + 4] = _octree.get_child(t[1], plane[i])
		else:
			# If node is a leaf, use the node as a stand in for its child.
			for i in range(4):
				children[i + 4] = t[1]
			num_leaves += 1
		
		if num_leaves < 2:
			# Recursively traverse child nodes.
			_face_proc([children[0], children[4]], axis)
			_face_proc([children[1], children[5]], axis)
			_face_proc([children[2], children[6]], axis)
			_face_proc([children[3], children[7]], axis)
	
			# Traverse octree edges.
			_edge_proc([children[0], children[1], children[4], children[5]], 0b010)
			_edge_proc([children[0], children[2], children[4], children[6]], 0b001)
			_edge_proc([children[1], children[3], children[5], children[7]], 0b001)
			_edge_proc([children[2], children[3], children[6], children[7]], 0b010)
	
			# Traverse octree vertices.
			_vert_proc(children) # Assure that these are in the right order.
	
	# Octree edge, dual face, takes four nodes as arguments.
	# Assume a node's location t in bit form is also it's location relative to the other nodes on valid
	# axes.
	func _edge_proc(t: Array, axis: int):
		var num_leaves = 0
	
		var children = []
		children.resize(8)
	
		# Find exterior plane that needs to be connected, with the value at the given axis always 0.
		var plane
		match axis:
			0b001:
				plane = [0b000, 0b010, 0b100, 0b110]
			0b010:
				plane = [0b000, 0b001, 0b100, 0b101]
			0b100:
				plane = [0b000, 0b001, 0b010, 0b011]
	
		# Find children to be connected.
		for i in range(4):
			if _octree.is_branch(t[i]):
				children[i] = _octree.get_child(t[i], plane[3 - i])
				children[i + 4] = _octree.get_child(t[i], plane[3 - i] | axis)
			else:
				children[i] = t[i]
				children[i + 4] = t[i]
				num_leaves += 1
	
		if num_leaves < 4:
			# Recursively traverse child nodes.
			_edge_proc([children[0], children[1], children[2], children[3]], axis)
			_edge_proc([children[4], children[5], children[6], children[7]], axis)
	
			# Traverse octree vertices.
			_vert_proc(children)
	
	# Octree vertex, dual hexahedron, takes eight nodes as arguments.
	# Assume a node's location in t in bit form is also its location relative to the other nodes.
	func _vert_proc(t: Array):
		var num_leaves = 0
	
		var children = []
		children.resize(8)
	
		for i in range(8):
			if _octree.is_branch(t[i]):
				# If node is a branch, get its child that is connected to the octree vertex.
				children[i] = _octree.get_child(t[i], 7 - i)
			else:
				# If node is a leaf, use the node as a stand in for its child.
				children[i] = t[i]
				num_leaves += 1
		
		if num_leaves >= 8:
			# All nodes surrounding the vertex are leaves so draw the dual volume here.
			var v = []
			v.resize(8)
			var d = []
			d.resize(8)
			for i in range(8):
				v[i] = _octree.get_vertex(t[i])
				v[i].z *= _arb_factor
				d[i] = _octree.get_density(t[i])
	
			_dual_verts = Geometry.draw_hexahedron_edge(v, _dual_verts)
			var surface = MarchingCubes.draw_cube(v[0], v[7], d, _surface_verts, _surface_normals)
			_surface_verts = surface[0]
			_surface_normals = surface[1]
		else:
			# Recursively traverse child nodes.
			_vert_proc(children)
