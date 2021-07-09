extends Spatial

var _chunks = []

var _radius
var _chunk_depth = 5

var Mesher = preload("res://Scripts/Octree/Mesher.gdns")
var Generator = preload("res://Scripts/Generator.gdns")

var _mesher
var _generator

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var fluid = get_node("Fluid")
onready var surface_shape = get_node("SurfaceBody/CollisionShape")
onready var player = get_node("Player")

func _ready():
	_chunks.append(get_node("Chunk"))

func init(radius):
	_radius = radius
	_generator = Generator.new()
	_generator.set_radius(_radius)

	# Set the players position so they don't get stuck.
	player.translation.y = _radius
	
	for chunk in _chunks:
		chunk.init(_chunk_depth, _generator)
		
	_mesher = Mesher.new()

func draw():
	_mesher.begin_tree()
	_mesher.begin_dual()
	_mesher.begin_surface()
	_mesher.begin_fluid()

	# Create vertex data.
	for chunk in _chunks:
		_mesher.draw_tree(chunk)
		_mesher.draw(chunk)

	borders.mesh = _mesher.end_tree()
	dual.mesh = _mesher.end_dual()
	surface.mesh = _mesher.end_surface()
	fluid.mesh = _mesher.end_fluid()

	# Create shapes for physics.
	surface_shape.set_shape(surface.mesh.create_trimesh_shape())

func _process(_delta):
	pass#draw()
	
func _input(event):
	if event.is_action_pressed("toggle_borders"):
		if borders.is_visible_in_tree():
			borders.hide()
		else:
			borders.show()
	if event.is_action_pressed("toggle_dual"):
		if dual.is_visible_in_tree():
			dual.hide()
		else:
			dual.show()
			
func carve_terrain(intersection: Vector3):
	for chunk in _chunks:
		chunk.change_terrain(intersection, -0.5)
	draw()

func place_terrain(intersection: Vector3):
	for chunk in _chunks:
		chunk.change_terrain(intersection, 0.5)
	draw()
	
func _underwater(point: Vector3, caller):
	var underwater = false
	for chunk in _chunks:
		if chunk.is_underwater(point):
			underwater = true
	
	caller.underwater(underwater)
