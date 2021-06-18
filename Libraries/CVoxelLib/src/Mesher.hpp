#pragma once

#include <Godot.hpp>

#include "MarchingCubes.hpp"
#include "Geometry.hpp"
#include "OctreeChunk.hpp"

using godot::Object;
using godot::PoolVector3Array;
using godot::Vector3;

class Mesher: public Object {
	GODOT_CLASS(Mesher, Object)

private:
	PoolVector3Array m_tree_verts;
	PoolVector3Array m_dual_verts;
	PoolVector3Array m_surface_verts;
	PoolVector3Array m_surface_normals;

	MarchingCubes *m_marching_cubes;
	Geometry *m_geometry;

	void cube_proc(OctreeChunk *chunk, int t);
	void face_proc(OctreeChunk *chunk, int t[2], int axis);
	void edge_proc(OctreeChunk *chunk, int t[4], int axis);
	void vert_proc(OctreeChunk *chunk, int t[8]);

public:
	void static _register_methods();
	void _init();

	void begin();

	PoolVector3Array get_tree_verts();
	PoolVector3Array get_dual_verts();
	PoolVector3Array get_surface_verts();
	PoolVector3Array get_surface_normals();

	void draw_tree(OctreeChunk *chunk);
	void draw(OctreeChunk *chunk);
};