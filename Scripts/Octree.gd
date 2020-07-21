extends Spatial

var Octnode = preload("res://Scripts/Octree/Octnode.gd")
var Octleaf = preload("res://Scripts/Octree/Octleaf.gd")

onready var mesh_instance = get_node("MeshInstance")

var head
var _tree_depth

func init(tree_depth):
	pass
	# Do nothing.
	
func draw():
	# Set up array mesh.
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PoolVector3Array()

	# Draw octree.
	verts = Geometry.draw_bounds(Vector3(-1, -1, 1), Vector3(1, 1, 2), verts)

	# Create surface.
	arr[Mesh.ARRAY_VERTEX] = verts

	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
