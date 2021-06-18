#pragma once

#include <Godot.hpp>
#include <SurfaceTool.hpp>

#define THRESHOLD 0.5f

using godot::Array;
using godot::Vector3;
using godot::SurfaceTool;

class MarchingCubes {

public:
	static void draw_cube(Array v, Array d, SurfaceTool *st);
	static Vector3 vector_abs(Vector3 v);
	static Vector3 find_vert(int edge_index, Array v, Array d);
};