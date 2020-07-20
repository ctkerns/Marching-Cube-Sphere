extends Spatial

var Octnode = preload("res://Scripts/Octree/Octnode.gd")
var Octleaf = preload("res://Scripts/Octree/Octleaf.gd")

var mesh_instance

var head
var _tree_depth

func _ready():
	mesh_instance = get_node("MeshInstance")

func init(tree_depth):
	_tree_depth = tree_depth
	
	if tree_depth > 0:
		head = Octnode.new()
	else:
		head = Octleaf.new()

	
func draw():
	# Set up array mesh.
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PoolVector3Array()

	# Draw octree.
	verts = _draw_cube(Vector3(0, 0, 0), Vector3(1, 1, 1), verts)

	# Create surface.
	arr[Mesh.ARRAY_VERTEX] = verts

	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
			
func _draw_cube(p1, p2, verts):
	print("drawing a cube")
	
	var v0 = p1
	var v1 = Vector3(p2.x, p1.y, p1.z)
	var v2 = Vector3(p1.x, p1.y, p2.z)
	var v3 = Vector3(p2.x, p1.y, p2.z)
	var v4 = Vector3(p1.x, p2.y, p1.z)
	var v5 = Vector3(p2.x, p2.y, p1.z)
	var v6 = Vector3(p1.x, p2.y, p2.z)
	var v7 = p2

	# Bottom face.
	verts.append(v0)
	verts.append(v1)

	verts.append(v0)
	verts.append(v2)

	verts.append(v1)
	verts.append(v3)

	verts.append(v2)
	verts.append(v3)

	# Top face.
	verts.append(v4)
	verts.append(v5)

	verts.append(v4)
	verts.append(v6)

	verts.append(v5)
	verts.append(v7)

	verts.append(v6)
	verts.append(v7)

	# Sides.
	verts.append(v0)
	verts.append(v4)

	verts.append(v1)
	verts.append(v5)

	verts.append(v2)
	verts.append(v6)

	verts.append(v3)
	verts.append(v7)
	
	return verts
