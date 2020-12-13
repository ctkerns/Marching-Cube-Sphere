extends Spatial

var Octree = preload("res://Scripts/Octree/Octree.gd")
var Mesher = preload("res://Scripts/Octree/Mesher.gd")

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var collision_shape = get_node("StaticBody/CollisionShape")

var octree = Octree.Octree.new()
var mesher

# Hyperparameters.
var _x_offset = 0.0
var _x_scale = 2.0
var _y_offset = 0.0
var _y_scale = 2.0
var _floor_radius = 5.0
var _ceil_radius = 32.0

var _depth = 3 # Depth of the octree.

func init():
	octree = Octree.Octree.new()
	_full_subdivision()

	mesher = Mesher.Mesher.new(octree, _x_offset, _x_scale, _y_offset, _y_scale, _floor_radius, _ceil_radius)

func draw():
	mesher.draw_tree(borders)
	var shape = mesher.draw_dual(dual, surface)

	collision_shape.set_shape(shape)

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
				var vert = _global_vert(_chunk_vert(octree.get_vertex(child)))
				var bounds = octree.get_bounds(child)

				var base = bounds[0].z
				var top = base + bounds[1]

				# Clear top and fill bottom.
				if top == 1.0:
					volumes.append(0.0)
				elif base == -1.0:
					volumes.append(1.0)
				else:
					volumes.append(Generator.sample(vert.x, vert.y, vert.z, _floor_radius, _ceil_radius))
			
			# Split each node in the queue, and add the nodes to the queue.
			octree.split(node, volumes)

			var prefix = node << 3
			for k in range(8):
				queue.push_back(prefix | k)

# Takes a location in the octree and converts it based on chunk location.
func _chunk_vert(vert: Vector3):
	var x = vert.x*_x_scale/2.0 + _x_offset
	var y = vert.y*_y_scale/2.0 + _y_offset
	var z = (vert.z*(_ceil_radius - _floor_radius) + _ceil_radius)/2

	return Vector3(x, y, z)

# Takes a location in the chunk and converts it to global space.
func _global_vert(vert: Vector3):
	var transform = self.get_transform()

	var local_vert = Cube2Sphere.cube2sphere(vert.x, vert.y, vert.z)
	var global_vert = transform.xform(local_vert)

	return global_vert
