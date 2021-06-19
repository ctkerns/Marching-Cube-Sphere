#pragma once

#include <Godot.hpp>
#include <SurfaceTool.hpp>

#define THRESHOLD 0.5f

using godot::Vector3;
using godot::SurfaceTool;

class MarchingCubes {

public:
	static void draw_cube(Vector3 v[8], float d[8], SurfaceTool *st);
	static Vector3 vector_abs(Vector3 v);
	static Vector3 find_vert(int edge_index, Vector3 v[8], float d[8]);
};