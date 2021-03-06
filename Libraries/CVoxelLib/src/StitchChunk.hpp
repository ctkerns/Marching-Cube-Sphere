#pragma once

#include <Godot.hpp>
#include <SurfaceTool.hpp>
#include <Mesh.hpp>
#include <MeshInstance.hpp>
#include <ArrayMesh.hpp>

#include "MarchingCubes.hpp"
#include "Geometry.hpp"
#include "OctreeChunk.hpp"

using godot::Spatial;
using godot::Array;
using godot::Vector3;
using godot::SurfaceTool;
using godot::Mesh;
using godot::MeshInstance;
using godot::ArrayMesh;
using godot::Ref;

class StitchChunk: public Spatial {
	GODOT_CLASS(StitchChunk, Spatial)

private:
	MeshInstance *m_dual_mesh;
	MeshInstance *m_surface_mesh;
	MeshInstance *m_fluid_mesh;
	StaticBody *m_surface_body;
	CollisionShape *m_surface_shape;

	SurfaceTool *m_dual;
	SurfaceTool *m_surface;
	SurfaceTool *m_fluid;

	Array m_chunks;
	int m_axis;

	const int plane_x[4] = {0b000, 0b001, 0b010, 0b011};
	const int plane_y[4] = {0b000, 0b001, 0b100, 0b101};
	const int plane_z[4] = {0b000, 0b010, 0b100, 0b110};

	void begin();
	void end();

	inline void get_edge_children(
		Octree *octree, int t, int idx, int children[8], const int plane[4], int axis, int *num_leaves,
		int lod, int depth
	);
	inline void get_vert_children(
		Octree *octree, int t, int idx, int children[8], int *num_leaves, int lod, int depth
	);

public:
	void static _register_methods();
	void _init();

	void init(Array chunks, int axis);
	void draw();

	void StitchChunk::face_proc(
		OctreeChunk *c0, OctreeChunk *c1, int t0, int t1, int axis, int depth
	);
	void edge_proc(
		OctreeChunk *c0, OctreeChunk *c1, OctreeChunk *c2, OctreeChunk *c3,
		int t0, int t1, int t2, int t3, int axis, int depth
	);
	void vert_proc(
		OctreeChunk *c0, OctreeChunk *c1, OctreeChunk *c2, OctreeChunk *c3,
		OctreeChunk *c4, OctreeChunk *c5, OctreeChunk *c6, OctreeChunk *c7,
		int t0, int t1, int t2, int t3, int t4, int t5, int t6, int t7, int depth
	);

	void toggle_dual();
};