#pragma once

#include <Godot.hpp>
#include <Variant.hpp>
#include <Spatial.hpp>

#include "Octree.hpp"
#include "Generator.hpp"

class OctreeChunk: public godot::Spatial {
	GODOT_CLASS(OctreeChunk, godot::Spatial)

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
};