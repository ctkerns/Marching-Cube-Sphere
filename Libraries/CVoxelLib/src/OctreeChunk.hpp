#pragma once

#include <Godot.hpp>
#include <Variant.hpp>
#include <Spatial.hpp>

#include "Octree.hpp"
#include "Generator.hpp"

using godot::Spatial;
using godot::Vector3;
using godot::Variant;
using godot::Array;

class OctreeChunk: public Spatial {
	GODOT_CLASS(OctreeChunk, Spatial)

private:
	Octree *m_tree;
	int m_depth;
	Generator *m_generator;

	const float threshold = 0.5;

	void generate();

public:
	static void _register_methods();
	void _init();

	void init(int depth, Generator *generator);
	Octree *get_tree();
	void change_terrain(Vector3 intersection, float delta);
};