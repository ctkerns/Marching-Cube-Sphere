#pragma once

#include <Godot.hpp>
#include <Object.hpp>

#define THRESHOLD 0.5f

class MarchingCubes: public godot::Object {
	GODOT_CLASS(MarchingCubes, godot::Object)

public:
	static void _register_methods();
	void _init();

	godot::Array draw_cube(
		godot::Array v, godot::Array d, godot::PoolVector3Array verts, godot::PoolVector3Array normals
	);
	godot::Vector3 vector_abs(godot::Vector3 v);
	godot::Vector3 find_vert(int edge_index, godot::Array v, godot::Array d);
};