#pragma once

#include <Godot.hpp>
#include <SurfaceTool.hpp>
#include <Mesh.hpp>
#include <ArrayMesh.hpp>

#include "MarchingCubes.hpp"
#include "Geometry.hpp"
#include "OctreeChunk.hpp"

using godot::Object;
using godot::Vector3;
using godot::SurfaceTool;
using godot::Mesh;
using godot::ArrayMesh;
using godot::Ref;

class Mesher: public Object {
	GODOT_CLASS(Mesher, Object)

private:
	SurfaceTool *m_tree;
	SurfaceTool *m_dual;
	SurfaceTool *m_surface;

	void cube_proc(OctreeChunk *chunk, int t);
	void face_proc(OctreeChunk *chunk, int t[2], int axis);
	void edge_proc(OctreeChunk *chunk, int t[4], int axis);
	void vert_proc(OctreeChunk *chunk, int t[8]);

public:
	void static _register_methods();
	void _init();

	void begin_tree();
	void begin_dual();
	void begin_surface();
	Ref<ArrayMesh> end_tree();
	Ref<ArrayMesh> end_dual();
	Ref<ArrayMesh> end_surface();

	void draw_tree(OctreeChunk *chunk);
	void draw(OctreeChunk *chunk);
};