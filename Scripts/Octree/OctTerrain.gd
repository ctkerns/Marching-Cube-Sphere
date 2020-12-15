extends Object

class OctTerrain:
	var Octree = preload("res://Scripts/Octree/Octree.gd")
	
	var octree

	var _x_offset
	var _y_offset
	var _scale
	var _floor
	var _ceil
	var _depth

	var _core
	var _roof
	var _transform

	func init(x_offset, y_offset, scale, floor_rad, ceil_rad, depth, core, roof, transform):
		_x_offset = x_offset
		_y_offset = y_offset
		_scale = scale
		_floor = floor_rad
		_ceil = ceil_rad
		_depth = depth

		_core = core
		_roof = roof

		octree = Octree.Octree.new()
		_transform = transform
		_full_subdivision()

	func get_tree():
		return octree

	# Fully subdivide the tree.
	func _full_subdivision():
		var queue = []
		queue.push_back(0b1)

		# Subdivide each node for each level in depth.
		for i in range(_depth):
			for j in range(queue.size()):
				# Find the volume for each child before they are created.
				var node = queue.pop_front()
				var volumes = []
				for k in range(8):
					var child = octree.get_child(node, k)
					var vert = Transformations.cube2global(chunk2cube(octree.get_vertex(child)), _transform)
					var bounds = octree.get_bounds(child)

					var base = bounds[0].z
					var top = base + bounds[1]

					# Clear top and fill bottom.
					if top == 1.0 and _ceil == _roof:
						volumes.append(0.0)
					elif base == -1.0 and _floor == _core:
						volumes.append(1.0)
					else:
						volumes.append(Generator.sample(vert.x, vert.y, vert.z, _core, _roof))
				
				# Split each node in the queue, and add the nodes to the queue.
				octree.split(node, volumes)

				var prefix = node << 3
				for k in range(8):
					queue.push_back(prefix | k)

	# Takes a location in the octree and converts it based on chunk location.
	func chunk2cube(vert: Vector3):
		var x = vert.x*_scale/2.0 + _x_offset
		var y = vert.y*_scale/2.0 + _y_offset
		var z = (vert.z*(_ceil - _floor) + _ceil)/2

		return Vector3(x, y, z)

	func length2cube(length):
		var x = length*2.0/_scale
		var y = length*2.0/_scale
		var z = length*(_ceil - _floor)/2.0

		return Vector3(x, y, z)
