#include "Geometry.hpp"

#include <assert.h>

void Geometry::draw_cuboid_edge(Vector3 p1, Vector3 p2, SurfaceTool *st) {
	// Arrange corners of the cube.
	Vector3 v[8] = {
		Vector3(p1.x, p1.y, p1.z),
		Vector3(p2.x, p1.y, p1.z),
		Vector3(p1.x, p1.y, p2.z),
		Vector3(p2.x, p1.y, p2.z),
		Vector3(p1.x, p2.y, p1.z),
		Vector3(p2.x, p2.y, p1.z),
		Vector3(p1.x, p2.y, p2.z),
		Vector3(p2.x, p2.y, p2.z)
	};

	draw_hexahedron_edge(v, st);
}

void Geometry::draw_hexahedron_edge(Vector3 v[8], SurfaceTool *st) {
	// Traverse hexahedron edges using bitstring method.
	int i = 0x2ef0298;
	while (i > 0x2ef0) {
		// Draw each edge of the hexahedron.
		st->add_vertex(v[i&7]);
		st->add_vertex(v[(i >> 14)&7]);

		i >>= 1;
	}
}