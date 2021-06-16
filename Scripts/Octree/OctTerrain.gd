extends Spatial

var Octree = preload("res://Scripts/Octree/Octree.gdns")
var octree

var _depth
var threshold = 0.5 # This will be temporary.

func init(depth):
	_depth = depth
	
	var scale = pow(2, _depth)
	self.scale = Vector3(scale, scale, scale)
		
	octree = Octree.new()
	_generate()

func get_tree():
	return octree

# Generate the tree while removing empty space.
func _generate():
	var queue = []
	var backtrack = []
	queue.push_back(0b1)
	
	backtrack.push_back(0b1)

	# Subdivide each node for each level in depth.
	for i in range(_depth):
		for _j in range(queue.size()):
			# Find the volume for each child before they are created.
			var node = queue.pop_front()
			var volumes = []
			for k in range(8):
				var child = octree.get_child(node, k)
				var vert = octree.get_vertex(child)

				# This needs to change if the planet is going to move.
				vert = self.to_global(vert)

				volumes.append(Generator.sample(vert.x, vert.y, vert.z, 1, 3))
			
			# Split each node in the queue, and add the nodes to the queue.
			octree.split(node, volumes)

			var prefix = node << 3
			for k in range(8):
				queue.push_back(prefix | k)

			if i != _depth - 1:
				for k in range(8):
					backtrack.push_back(prefix | k)

	# Backtrack each layer and remove nodes as necessary.
	for i in range(_depth - 1, -1, -1):
		for _j in range(pow(8, i)):
			var node = backtrack.pop_back()

			# Check if the children are homogenous.
			var homogenous = true
			var first_child = octree.get_density(octree.get_child(node, 0)) >= threshold

			for k in range(1, 8):
				var child = octree.get_density(octree.get_child(node, k)) >= threshold
				if child != first_child:
					homogenous = false
					break

			# Check if the children are all leaves.
			var all_leaves = true
			for k in range(8):
				if octree.is_branch(octree.get_child(node, k)):
					all_leaves = false
					break

			# Collapse homogenous branch nodes.
			if homogenous and all_leaves:
				for k in range(8):
					octree.delete_node(octree.get_child(node, k))
