#pragma once

#include <Godot.hpp>
#include <Object.hpp>

using godot::Array;
using godot::PoolVector3Array;

class Geometry: public godot::Object {
	GODOT_CLASS(Geometry, godot::Object)

public:
	static void _register_methods();
	void _init();

	PoolVector3Array draw_cuboid_edge(
		godot::Vector3 p1, godot::Vector3 p2, PoolVector3Array verts
	);

	PoolVector3Array draw_hexahedron_edge(
		Array v, PoolVector3Array verts
	);
};