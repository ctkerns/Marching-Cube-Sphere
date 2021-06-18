#pragma once

#include <unordered_map>

#include <Godot.hpp>
#include <Object.hpp>

#include "Octnode.hpp"

using godot::Object;
using godot::Array;
using godot::Vector3;

class Octree: public Object {
	GODOT_CLASS(Octree, Object)

private:
	std::unordered_map<int, Octnode*> m_nodes = std::unordered_map<int, Octnode*>();

public:
	static void _register_methods();
	void _init();

	void split(int loc_code, Array);
	void delete_node(int loc_code);
	bool is_branch(int loc_code);

	int get_depth(int loc_code);
	int get_child(int loc_code, int div);
	int get_neighbor(int loc_code, int dir);
	float get_density(int loc_code);
	void set_density(int loc_code, float volume);
	Vector3 get_vertex(int loc_code);
	Array get_bounds(int loc_code);
};