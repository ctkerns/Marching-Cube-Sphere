extends Spatial

var _face_size
var _face_depth
var _chunk_size

var _base_radius

var mesh_instance
var projection

func _ready():
	mesh_instance = get_node("MeshInstance")
	projection = get_node("/root/ProjectionASC")

func init():
	_face_size = get_parent()._planet_size
	_face_depth = get_parent()._planet_depth
	_chunk_size = get_parent()._chunk_size
	
	# Base radius in terms of chunk size.
	_base_radius = _face_size*2/PI

func _draw_grid():
	# Set up array mesh.
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts = PoolVector3Array()
	
	# Draw sphere.
	var vert
	var last_vert_i = []
	last_vert_i.resize(_face_size)
	var last_vert_j
	
	for layer in range(_face_depth):
		for i in range(_face_size + 1):
			for j in range(_face_size + 1):
				# Establish starting vertex.
				vert = Vector3(0, 1, 0)
				
				# Project plane to spherical coordinates. Sans radius.
				var ang = projection.inverse(i*2.0/_face_size - 1, j*2.0/_face_size - 1)
				
				# Perform first quaternion rotation.
				var ax1 = Vector3(0, 0, 1)
				var quat1 = Quat(ax1, ang.x)
				vert = quat1.xform(vert)
				
				# Perform second quaterion rotation.
				var ax2 = Vector3(cos(ang.x), sin(ang.x), 0)
				var quat2 = Quat(ax2, ang.y)
				vert = quat2.xform(vert)
				
				# Scale layer to appropriate radius.
				vert *= (_base_radius + layer)*_chunk_size
				
				# Add lines to array mesh.
				if i != 0 and j != _face_size:
					verts.append(last_vert_i[j])
					verts.append(vert)
				
				if j != 0 and i != _face_size:
					verts.append(last_vert_j)
					verts.append(vert)
				
				# Update last vertices.
				if i != _face_size and j != _face_size:
					last_vert_i[j] = vert
					last_vert_j = vert
	
	arr[Mesh.ARRAY_VERTEX] = verts
	
	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
