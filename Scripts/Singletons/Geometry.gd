extends Node

func draw_bounds(p1, p2, verts):
	var v0 = Cube2Sphere.cube2sphere(p1.x, p1.y, p1.z)
	var v1 = Cube2Sphere.cube2sphere(p2.x, p1.y, p1.z)
	var v2 = Cube2Sphere.cube2sphere(p1.x, p1.y, p2.z)
	var v3 = Cube2Sphere.cube2sphere(p2.x, p1.y, p2.z)
	var v4 = Cube2Sphere.cube2sphere(p1.x, p2.y, p1.z)
	var v5 = Cube2Sphere.cube2sphere(p2.x, p2.y, p1.z)
	var v6 = Cube2Sphere.cube2sphere(p1.x, p2.y, p2.z)
	var v7 = Cube2Sphere.cube2sphere(p2.x, p2.y, p2.z)

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