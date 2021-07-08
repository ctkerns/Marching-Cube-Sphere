#pragma once

#include <unordered_map>

#include <Godot.hpp>
#include <Object.hpp>

#include "Octnode.hpp"

#include "Material.hpp"

using godot::Array;
using godot::Vector3;

class Octree {

private:
	std::unordered_map<int, Octnode*> m_nodes = std::unordered_map<int, Octnode*>();

public:
	Octree();

	void split(
		int loc_code, float vol[8], float fld[8],
		Material::MaterialType mat[8], Material::CoveringType cov[8]
	);
	void delete_node(int loc_code);
	bool is_branch(int loc_code);

	// Getters and setters.
	int get_depth(int loc_code);
	int get_child(int loc_code, int div);
	int get_neighbor(int loc_code, int dir);
	float get_density(int loc_code);
	void set_density(int loc_code, float volume);
	float get_fluid(int loc_code);
	void set_fluid(int loc_code, float fluid);
	Material::MaterialType get_material(int loc_code);
	void set_material(int loc_code, Material::MaterialType material);
	Material::CoveringType get_covering(int loc_code);
	void set_covering(int loc_code, Material::CoveringType covering);
	Vector3 get_vertex(int loc_code);
	Array get_bounds(int loc_code);

	int find_node(Vector3 position, int depth);
};