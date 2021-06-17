extends Spatial

var _chunks = []

var _radius
var _chunk_depth = 5

var Mesher = preload("res://Scripts/Octree/Mesher.gd")
var Generator = preload("res://Scripts/Generator.gdns")

var _mesher
var _generator

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var collision_shape = get_node("StaticBody/CollisionShape")

func _ready():
	_chunks.append(get_node("Chunk"))

func init(radius):
	_radius = radius
	_generator = Generator.new()
	_generator.set_radius(_radius)

	for chunk in _chunks:
		chunk.init(_chunk_depth, _generator)
		
	_mesher = Mesher.Mesher.new()
	_mesher.init()

func draw():
	# Set up array meshes.
	var tree_arr = []
	var dual_arr = []
	var surface_arr = []

	tree_arr.resize(Mesh.ARRAY_MAX)
	dual_arr.resize(Mesh.ARRAY_MAX)
	surface_arr.resize(Mesh.ARRAY_MAX)

	# Create vertex data.
	for chunk in _chunks:
		_mesher.draw_tree(chunk)
		_mesher.draw(chunk)

	# Add data to array meshes.
	tree_arr[Mesh.ARRAY_VERTEX] = _mesher.get_tree_verts()
	dual_arr[Mesh.ARRAY_VERTEX] = _mesher.get_dual_verts()
	surface_arr[Mesh.ARRAY_VERTEX] = _mesher.get_surface_verts()
	surface_arr[Mesh.ARRAY_NORMAL] = _mesher.get_surface_normals()

	borders.mesh = ArrayMesh.new()
	dual.mesh = ArrayMesh.new()
	surface.mesh = ArrayMesh.new()

	borders.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, tree_arr)
	dual.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, dual_arr)
	surface.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arr)

	collision_shape.set_shape(surface.mesh.create_trimesh_shape())

func clear():
	_mesher.begin()

	borders.mesh = Mesh.new()
	dual.mesh = Mesh.new()
	surface.mesh = Mesh.new()

func _process(_delta):
	pass
	#clear()
	#draw()
	
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
