extends Node

# Takes a location in the local cube and converts it to global space.
func cube2global(vert: Vector3, transform: Transform):
	var local_vert = vert #cube2sphere(vert.x, vert.y, vert.z)
	var global_vert = transform.xform(local_vert)

	return global_vert
	
