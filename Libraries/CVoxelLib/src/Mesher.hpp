#pragma once

#include <Godot.hpp>
#include <SurfaceTool.hpp>
#include <Mesh.hpp>
#include <ArrayMesh.hpp>

class OctreeChunk;
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
	SurfaceTool *m_fluid;

	void cube_proc(OctreeChunk *chunk, int t, int depth);
	void face_proc(OctreeChunk *chunk, int t0, int t1, int axis, int depth);
	void edge_proc(OctreeChunk *chunk, int t0, int t1, int t2, int t3, int axis, int depth);
	void vert_proc(OctreeChunk *chunk, int t0, int t1, int t2, int t3, int t4, int t5, int t6, int t7, int depth);

	const int plane_x[4] = {0b000, 0b001, 0b010, 0b011};
	const int plane_y[4] = {0b000, 0b001, 0b100, 0b101};
	const int plane_z[4] = {0b000, 0b010, 0b100, 0b110};

	inline void get_edge_children(Octree *octree, int t, int idx, int children[8], const int plane[4], int axis, int *num_leaves);
	inline void get_vert_children(Octree *octree, int t, int idx, int children[8], int *num_leaves);

public:
	void static _register_methods();
	void _init();

	void begin_tree();
	void begin_dual();
	void begin_surface();
	void begin_fluid();
	Ref<ArrayMesh> end_tree();
	Ref<ArrayMesh> end_dual();
	Ref<ArrayMesh> end_surface();
	Ref<ArrayMesh> end_fluid();

	void draw_tree(OctreeChunk *chunk);
	void draw(OctreeChunk *chunk);
};