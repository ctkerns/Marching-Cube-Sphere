extends Spatial

var Octree = preload("res://Scripts/Octree/Octree.gd")
var Mesher = preload("res://Scripts/Octree/Mesher.gd")

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")

onready var octree = Octree.Octree.new()
onready var mesher = Mesher.Mesher.new(octree)

func init():
	octree.split(0b1)
	# octree.split(0b1000)
	# octree.split(0b1001)
	# octree.split(0b1010)
	# octree.split(0b1011)
	# split(0b1000000)
	pass

func draw():
	mesher.draw_tree(borders)
	mesher.draw_dual(dual, surface)
