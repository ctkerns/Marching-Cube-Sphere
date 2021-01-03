extends Object

class Mesher:
	var _tree_verts
	var _dual_verts
	var _surface_verts
	var _surface_normals
	
	func init():
		_tree_verts = PackedVector3Array()
		_dual_verts = PackedVector3Array()
		_surface_verts = PackedVector3Array()
		_surface_normals = PackedVector3Array()

	func get_tree_verts():
		return _tree_verts

	func get_dual_verts():
		return _dual_verts

	func get_surface_verts():
		return _surface_verts

	func get_surface_normals():
		return _surface_normals

	func draw_tree(chunk):
		var octree = chunk.get_tree()

		# Initialize stack.
		var stack = []
		stack.push_back(0b1)

		# Perform a DFS traversal of the octree using stack.
		var id
		while not stack.is_empty():
			# Pop frame from stack.
			id = stack.pop_back()

			# Check if this node is a leaf node.
			if not octree.is_branch(id):
				# Draw the leaf node.
				var bounds = octree.get_bounds(id)

				# Scale bounds from chunk space.
				var corner = chunk.chunk2cube(bounds[0])
				var length = chunk.length2cube(bounds[1])

				_tree_verts = Geometry.draw_cuboid_edge(corner, corner + length, _tree_verts)
			else:
				# Add this nodes children to the stack.
				for i in range(8):
					stack.push_back(octree.get_child(id, i))

	func draw(chunk):
		# Recursively traverse the octree.
		_cube_proc(chunk, 0b1)

	func _cube_proc(chunk, t: int):
		var octree = chunk.get_tree()

		# Terminate when t1 is a leaf node.
		if not octree.is_branch(t):
			return
	
		# Recursively traverse child nodes.
		var children = []
		children.resize(8)
		for i in range(8):
			children[i] = octree.get_child(t, i)
			
			_cube_proc(chunk, children[i])
	
		# Traverse octree faces.
		_face_proc(chunk, [children[0], children[1]], 0b001)
		_face_proc(chunk, [children[0], children[2]], 0b010)
		_face_proc(chunk, [children[0], children[4]], 0b100)
		_face_proc(chunk, [children[1], children[3]], 0b010)
		_face_proc(chunk, [children[1], children[5]], 0b100)
		_face_proc(chunk, [children[2], children[3]], 0b001)
		_face_proc(chunk, [children[2], children[6]], 0b100)
		_face_proc(chunk, [children[3], children[7]], 0b100)
		_face_proc(chunk, [children[4], children[5]], 0b001)
		_face_proc(chunk, [children[4], children[6]], 0b010)
		_face_proc(chunk, [children[5], children[7]], 0b010)
		_face_proc(chunk, [children[6], children[7]], 0b001)
	
		# Traverse octree edges.
		_edge_proc(chunk, [children[0], children[1], children[2], children[3]], 0b100)
		_edge_proc(chunk, [children[0], children[1], children[4], children[5]], 0b010)
		_edge_proc(chunk, [children[0], children[2], children[4], children[6]], 0b001)
		_edge_proc(chunk, [children[1], children[3], children[5], children[7]], 0b001)
		_edge_proc(chunk, [children[2], children[3], children[6], children[7]], 0b010)
		_edge_proc(chunk, [children[4], children[5], children[6], children[7]], 0b100)
	
		# Traverse octree vertices.
		_vert_proc(chunk, children)
	
	# Octree face, dual edge, takes two nodes as arguments.
	# Assume that t_0 is inferior on given axis and t_1 is superior.
	func _face_proc(chunk, t: Array, axis: int):
		var octree = chunk.get_tree()
		
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
	
		# Find children to be connected. Location in the array will be on the opposite side through
		# the axis.

		# Inferior node.
		if octree.is_branch(t[0]):
			for i in range(4):
				children[plane[i]] = octree.get_child(t[0], plane[i] | axis)
		else:
			# If node is a leaf, use the node as a stand in for its child.
			for i in range(4):
				children[plane[i]] = t[0]
			num_leaves += 1
		
		# Superior node.
		if octree.is_branch(t[1]):
			for i in range(4):
				children[plane[i] | axis] = octree.get_child(t[1], plane[i])
		else:
			# If node is a leaf, use the node as a stand in for its child.
			for i in range(4):
				children[plane[i] | axis] = t[1]
			num_leaves += 1
		
		if num_leaves < 2:
			# Recursively traverse child nodes.
			for i in range(4):
				_face_proc(chunk, [children[plane[i]], children[plane[i] | axis]], axis)
	
			match axis:
				0b001:
					_edge_proc(chunk, [children[0], children[1], children[4], children[5]], 0b010)
					_edge_proc(chunk, [children[0], children[1], children[2], children[3]], 0b100)
					_edge_proc(chunk, [children[4], children[5], children[6], children[7]], 0b100)
					_edge_proc(chunk, [children[2], children[3], children[6], children[7]], 0b010)
				0b010:
					_edge_proc(chunk, [children[0], children[2], children[4], children[6]], 0b001)
					_edge_proc(chunk, [children[0], children[1], children[2], children[3]], 0b100)
					_edge_proc(chunk, [children[4], children[5], children[6], children[7]], 0b100)
					_edge_proc(chunk, [children[1], children[3], children[5], children[7]], 0b001)
				0b100:
					_edge_proc(chunk, [children[0], children[2], children[4], children[6]], 0b001)
					_edge_proc(chunk, [children[0], children[1], children[4], children[5]], 0b010)
					_edge_proc(chunk, [children[2], children[3], children[6], children[7]], 0b010)
					_edge_proc(chunk, [children[1], children[3], children[5], children[7]], 0b001)

			_vert_proc(chunk, children)
				
	# Octree edge, dual face, takes four nodes as arguments.
	# Assume a node's location t in bit form is also it's location relative to the other nodes on valid
	# axes. Axis represents the commmon dimension.
	func _edge_proc(chunk, t: Array, axis: int):
		var octree = chunk.get_tree()
		
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
			if octree.is_branch(t[i]):
				children[i] = octree.get_child(t[i], plane[3 - i])
				children[i + 4] = octree.get_child(t[i], plane[3 -i] | axis)
			else:
				children[i] = t[i]
				children[i + 4] = t[i]
				num_leaves += 1
	
		if num_leaves < 4:
			# Recursively traverse child nodes.
			_edge_proc(chunk, [children[0], children[1], children[2], children[3]], axis)
			_edge_proc(chunk, [children[4], children[5], children[6], children[7]], axis)
	
			# Traverse octree vertices.
			match axis:
				0b001:
					_vert_proc(chunk, [children[0], children[4], children[1], children[5], children[2], children[6], children[3], children[7]])
				0b010:
					_vert_proc(chunk, [children[0], children[1], children[4], children[5], children[2], children[3], children[6], children[7]])
				0b100:
					_vert_proc(chunk, children)
	
	# Octree vertex, dual hexahedron, takes eight nodes as arguments.
	# Assume a node's location in t in bit form is also its location relative to the other nodes.
	func _vert_proc(chunk, t: Array):
		var octree = chunk.get_tree()
		
		var num_leaves = 0
	
		var children = []
		children.resize(8)
	
		for i in range(8):
			if octree.is_branch(t[i]):
				# If node is a branch, get its child that is connected to the octree vertex.
				children[i] = octree.get_child(t[i], 7 - i)
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
				var vert = octree.get_vertex(t[i])
				v[i] = chunk.chunk2cube(vert)

				d[i] = octree.get_density(t[i])
	
			_dual_verts = Geometry.draw_hexahedron_edge(v, _dual_verts)
			var surface = MarchingCubes.draw_cube(v, d, _surface_verts, _surface_normals)
			_surface_verts = surface[0]
			_surface_normals = surface[1]
		else:
			# Recursively traverse child nodes.
			_vert_proc(chunk, children)
