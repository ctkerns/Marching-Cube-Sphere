#include "Geometry.hpp"

#include <assert.h>

void Geometry::_register_methods() {
	godot::register_method("draw_cuboid_edge", &Geometry::draw_cuboid_edge);
	godot::register_method("draw_hexahedron_edge", &Geometry::draw_hexahedron_edge);
}

void Geometry::_init() {

}

PoolVector3Array Geometry::draw_cuboid_edge(
	godot::Vector3 p1, godot::Vector3 p2, PoolVector3Array verts
) {
	// Arrange corners of the cube.
	godot::Array v = godot::Array::make<godot::Vector3>(
		godot::Vector3(p1.x, p1.y, p1.z),
		godot::Vector3(p2.x, p1.y, p1.z),
		godot::Vector3(p1.x, p1.y, p2.z),
		godot::Vector3(p2.x, p1.y, p2.z),
		godot::Vector3(p1.x, p2.y, p1.z),
		godot::Vector3(p2.x, p2.y, p1.z),
		godot::Vector3(p1.x, p2.y, p2.z),
		godot::Vector3(p2.x, p2.y, p2.z)
	);

	return draw_hexahedron_edge(v, verts);
}

PoolVector3Array Geometry::draw_hexahedron_edge(
	Array v, PoolVector3Array verts
) {
	// Traverse hexahedron edges using bitstring method.
	int i = 0x2ef0298;
	while (i > 0x2ef0) {
		// Draw each edge of the hexahedron.
		verts.append(v[i&7]);
		verts.append(v[(i >> 14)&7]);

		i >>= 1;
	}

	return verts;
}