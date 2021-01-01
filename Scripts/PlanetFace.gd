extends Spatial

var OctTerrain = preload("res://Scripts/Octree/OctTerrain.gd")
var Mesher = preload("res://Scripts/Octree/Mesher.gd")

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var collision_shape = get_node("StaticBody/CollisionShape")

var _mesher
var _chunks = []
var _num_levels
var _base_depth

var _core
var _roof

func init(top_level, base_depth, max_depth):
	_num_levels = top_level - base_depth + 1
	_base_depth = base_depth

	var base_segments = pow(2, base_depth)*4
	var circumradius = 1/(2*sin(PI/base_segments))
	_core = circumradius - 0.5

	# Find the roof of the entire planet.
	var base = _core
	for i in range(_num_levels):
		base += pow(2, i + base_depth)
	
	_roof = base
	
	# Generate each chunk.
	base = _core
	_chunks.resize(_num_levels)
	for i in range(_num_levels):
		var depth = base_depth + i
		var height = pow(2, depth)
		
		_chunks[i] = OctTerrain.OctTerrain.new()
		_chunks[i].init(0.0, 0.0, 2.0, base, base + height, depth, _core, _roof, self.get_transform())
		
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
