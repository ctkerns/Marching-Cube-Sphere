extends Spatial

var Octree = preload("res://Scripts/Octree/Octree.gdns")
var octree

var _depth

func init(depth):
	_depth = depth
	
	var scale = pow(2, _depth)
	self.scale = Vector3(scale, scale, scale)
		
	octree = Octree.new()
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
				var vert = octree.get_vertex(child)

				# This needs to change if the planet is going to move.
				vert = self.to_global(vert)

				volumes.append(Generator.sample(vert.x, vert.y, vert.z, 1, 3))
				
			# Split each node in the queue, and add the nodes to the queue.
			octree.split(node, volumes)

			var prefix = node << 3
			for k in range(8):
				queue.push_back(prefix | k)

# Subdivide the tree, but remove empty space.
func _subdivision():
	var threshold = 0.5 # This will be temporary.