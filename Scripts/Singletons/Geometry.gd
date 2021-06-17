extends Node

func draw_cuboid_edge(p1: Vector3, p2: Vector3, verts: PoolVector3Array):
	# Arrange corners of the cube.
	var v = [
		Vector3(p1.x, p1.y, p1.z),
		Vector3(p2.x, p1.y, p1.z),
		Vector3(p1.x, p1.y, p2.z),
		Vector3(p2.x, p1.y, p2.z),
		Vector3(p1.x, p2.y, p1.z),
		Vector3(p2.x, p2.y, p1.z),
		Vector3(p1.x, p2.y, p2.z),
		Vector3(p2.x, p2.y, p2.z)
	]
	
	return draw_hexahedron_edge(v, verts)

func draw_hexahedron_edge(v: Array, verts: PoolVector3Array):
	# Traverse hexahedron edges using bitstring method.
	var i = 0x2ef0298
	while i > 0x2ef0:
		# Draw each edge of the hexahedron.
		verts.append(v[i&7])
		verts.append(v[(i >> 14)&7])

		i >>= 1

	return verts
