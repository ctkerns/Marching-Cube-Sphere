#pragma once

#include <Godot.hpp>
#include <Object.hpp>
#include <SurfaceTool.hpp>

using godot::Vector3;
using godot::SurfaceTool;

class Geometry {

public:
	static void draw_cuboid_edge(Vector3 p1, Vector3 p2, SurfaceTool *st);

	static void draw_hexahedron_edge(Vector3 v[8], SurfaceTool *st);
};