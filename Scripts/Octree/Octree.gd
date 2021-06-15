extends Object

class Octree:
	var Octnode = preload("res://Scripts/Octree/Octnode.gdns")

	var nodes: Dictionary

	func _init():
		# Create octree.
		var head = Octnode.new()
		head.set_volume(0.5)
		nodes[1] = head
		
	# Subdivides this node by creating eight children.
	func split(loc_code: int, vol: Array):
		if _get_depth(loc_code) > 20:
			return
			
		var prefix = loc_code << 3
		
		for i in range(8):
			var node = Octnode.new()
			node.set_volume(vol[i])
			nodes[prefix | i] = node
			
	# Returns true if the node has children.
	func is_branch(loc_code: int):
		return nodes.has(get_child(loc_code, 0))
				
	# Returns the depth of this node. Head node has depth of 0.
	func _get_depth(loc_code: int) -> int:
		return int( (log(loc_code) / 3) / log(2) )
					
	# Returns the locational code of the child of this node in the given direction.
	func get_child(loc_code: int, div: int) -> int:
		return loc_code << 3 | div
						
	# Returns the adjacent neighboring leaf node in the given direction. Unimplemented.
	func _get_neighbor(loc_code: int, dir: int) -> int:
		return 1

	func get_density(loc_code: int) -> int:
		return nodes[loc_code].get_volume()

	func set_density(loc_code: int, volume):
		nodes[loc_code].set_volume(volume)

	# Returns the position of the center of this node relative to the octree.
	func get_vertex(loc_code: int) -> Vector3:
		var depth = _get_depth(loc_code)
		var scale = 2.0 / (pow(2, depth))

		# Start at the center of the head node.
		var vert = Vector3(0, 0, 0)

		# Traverse the path of the node bottom up.
		var n = loc_code
		var increment = scale
		for _i in range(depth):
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
	func get_bounds(loc_code: int):
		var depth = _get_depth(loc_code)
		var scale = 2.0 / (pow(2, depth))

		# Start at the corner of the head node.
		var vert = Vector3(-1, -1, -1)

		# Traverse the path of the node bottom up.
		var n = loc_code
		var increment = scale
		for _i in range(depth):
			# Move the vertex according to the locational code.
			if n & 4 == 4:
				vert.x += increment
			if n & 2 == 2:
				vert.y += increment
			if n & 1 == 1:
				vert.z += increment

			# Move up a level.
			increment *= 2
			n = n >> 3

		return [vert, scale]
