extends Spatial

var Octree = preload("res://Scripts/Octree/Octree.gd")
var Mesher = preload("res://Scripts/Octree/Mesher.gd")

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var collision_shape = get_node("StaticBody/CollisionShape")

onready var octree = Octree.Octree.new()
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
			# Split each node in the queue, and add the upper nodes to the queue.
			var node = queue.pop_front()
			octree.split(node)

			queue.push_back((node << 3) | 0b001)
			queue.push_back((node << 3) | 0b011)
			queue.push_back((node << 3) | 0b101)
			queue.push_back((node << 3) | 0b111)
