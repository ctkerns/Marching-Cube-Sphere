extends Object

class OctTerrain:
	var Octree = preload("res://Scripts/Octree/Octree.gd")
	
	var octree

	# Hyperparameters.
	var _x_offset = 0.0
	var _y_offset = 0.0
	var _scale = 2.0
	var _floor = 16.0
	var _ceil = 64.0

	var _depth = 4 # Depth of the octree.

	var _transform

	func init(transform):
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
					if top == 1.0:
						volumes.append(0.0)
					elif base == -1.0:
						volumes.append(1.0)
					else:
						volumes.append(Generator.sample(vert.x, vert.y, vert.z, _floor, _ceil))
				
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
