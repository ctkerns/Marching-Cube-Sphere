extends Spatial

var OctTerrain = preload("res://Scripts/Octree/OctTerrain.gd")
var Mesher = preload("res://Scripts/Octree/Mesher.gd")

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var collision_shape = get_node("StaticBody/CollisionShape")

var _mesher
var _chunks = []
var _num_chunks = 4

var _core = 0.805
var _roof

func init():
	# Find the roof of the entire planet.
	var base = _core
	for i in range(_num_chunks):
		base += pow(2, i+1)
	
	_roof = base
	
	# Generate each chunk.
	base = _core
	_chunks.resize(_num_chunks)
	for i in range(_num_chunks):
		var height = pow(2, i+1)
		
		_chunks[i] = OctTerrain.OctTerrain.new()
		_chunks[i].init(0.0, 0.0, 2.0, base, base + height, i + 1, _core, _roof, self.get_transform())
		
		base += height

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

	# Create surfaces.
	borders.mesh = ArrayMesh.new()
	dual.mesh = ArrayMesh.new()
	surface.mesh = ArrayMesh.new()

	borders.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, tree_arr)
	dual.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, dual_arr)
	surface.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_arr)

	collision_shape.set_shape(surface.mesh.create_trimesh_shape())

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
