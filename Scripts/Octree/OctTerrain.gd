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
# How many times the lowest level of an octree subdivided.
var _subdivision

# The number of vertical levels in the planet.
var _levels

# The number of line segments in a great circle polygon around the sphere.
var _segments

# Radius at a vertex of a great circle polygon.
var _circumradius

func init(subdivision, levels):
	_subdivision = subdivision
	_levels = levels

	_segments = pow(2, subdivision)*4
	_circumradius = 1/(2*sin(PI/_segments))

	octree = Octree.Octree.new()
	mesher = Mesher.Mesher.new(octree, _circumradius)

	_full_subdivision()

func draw():
	mesher.draw_tree(borders)
	var shape = mesher.draw_dual(dual, surface)

	collision_shape.set_shape(shape)

# Fully subdivide the tree as far as is allowed.
func _full_subdivision():
	var queue = []

	queue.push_back(0b1)

	for i in range(_levels):
		for j in range(queue.size()):
			# Find the volume for each child.
			var node = queue.pop_front()
			var volumes = []
			for k in range(8):
				var child = octree.get_child(node, k)
				var vert = _global_vert(octree.get_vertex(child))
				volumes.append(Generator.sample(vert.x, vert.y, vert.z))

			# Fill bottom layer.
			if i == 0:
				for k in range(4):
					volumes[k*2] = 1.0

			# Clear top layer.
			if i == _levels - 1:
				for k in range(4):
					volumes[k*2 + 1] = 0.0
			
			# Split each node in the queue, and add the upper nodes to the queue.
			octree.split(node, volumes)

			queue.push_back((node << 3) | 0b001)
			queue.push_back((node << 3) | 0b011)
			queue.push_back((node << 3) | 0b101)
			queue.push_back((node << 3) | 0b111)

# Takes a location in the octree and converts it to global space.
func _global_vert(vert: Vector3):
	var transform = self.get_transform()

	var arb_factor = 3
	var base = _circumradius/arb_factor + 1 - 0.5
	var local_vert = Cube2Sphere.cube2sphere(vert.x, vert.y, (vert.z + base)*arb_factor)

	var global_vert = transform.xform(local_vert)

	return global_vert
