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

# The number of line segments in a great circle polygon around the sphere.
var _segments

# Radius at a vertex of a great circle polygon.
var _circumradius

func init(subdivision):
	_subdivision = subdivision
	_segments = pow(2, subdivision)*4
	_circumradius = 1/(2*sin(PI/_segments))

	mesher = Mesher.Mesher.new(octree, _circumradius)

	octree.split(0b1)
	# octree.split(0b1000)
	octree.split(0b1001)
	# octree.split(0b1010)
	octree.split(0b1011)
	# octree.split(0b1100)
	octree.split(0b1101)
	# octree.split(0b1110)
	octree.split(0b1111)
	# split(0b1000000)
	pass

func draw():
	mesher.draw_tree(borders)
	var shape = mesher.draw_dual(dual, surface)

	collision_shape.set_shape(shape)
