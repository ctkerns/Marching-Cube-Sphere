extends Spatial

var OctTerrain = preload("res://Scripts/Octree/OctTerrain.gd")
var Mesher = preload("res://Scripts/Octree/Mesher.gd")

onready var borders = get_node("Borders")
onready var dual = get_node("Dual")
onready var surface = get_node("Surface")
onready var collision_shape = get_node("StaticBody/CollisionShape")

var _mesher
var _chunk

func init():
	_chunk = OctTerrain.OctTerrain.new()
	_chunk.init(self.get_transform())

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
	_mesher.draw_tree(_chunk)
	_mesher.draw(_chunk)

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

