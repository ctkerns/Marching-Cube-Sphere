#pragma once

#include <Godot.hpp>
#include <Variant.hpp>
#include <Spatial.hpp>
#include <MeshInstance.hpp>
#include <Shape.hpp>
#include <CollisionShape.hpp>
#include <InputEvent.hpp>

class Mesher;
#include "Octree.hpp"
#include "Mesher.hpp"
#include "Generator.hpp"

using godot::Spatial;
using godot::Vector3;
using godot::Variant;
using godot::Array;
using godot::MeshInstance;
using godot::CollisionShape;
using godot::InputEvent;

class OctreeChunk: public Spatial {
	GODOT_CLASS(OctreeChunk, Spatial)

private:
	Octree *m_tree;
	int m_depth;
	Generator *m_generator;
	Mesher *m_mesher;

	MeshInstance *m_borders;
	MeshInstance *m_dual;
	MeshInstance *m_surface;
	MeshInstance *m_fluid;
	CollisionShape *m_surface_shape;

	const float threshold = 0.5;

	void generate();

public:
	static void _register_methods();
	void _init();
	void _input(Variant event);

	void init(int depth, Generator *generator);
	void draw();
	Octree *get_tree();
	void change_terrain(Vector3 intersection, float delta);
	bool is_underwater(Vector3 point);
};