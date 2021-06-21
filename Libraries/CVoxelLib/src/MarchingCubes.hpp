#pragma once

#include <Godot.hpp>
#include <SurfaceTool.hpp>

#define THRESHOLD 0.5f

using godot::Vector3;
using godot::Color;
using godot::SurfaceTool;

class MarchingCubes {

private:
	static Vector3 vector_abs(Vector3 v);
	static void find_vert(int edge_index, Vector3 v[8], float d[8], Color c[8], Vector3 *vec, Color *col);

public:
	static void draw_cube(Vector3 v[8], float d[8], Color c[8], SurfaceTool *st);
};