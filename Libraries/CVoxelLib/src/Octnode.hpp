#pragma once

#include <Godot.hpp>

#include "Material.hpp"

class Octnode {

private:
	float m_volume;
	float m_fluid;
	Material::MaterialType m_material;
	Material::CoveringType m_covering;

public:
	Octnode(
		float volume,
		float fluid,
		Material::MaterialType material = Material::MaterialType::dirt,
		Material::CoveringType covering = Material::CoveringType::grass
	);
	
	float get_volume();
	void set_volume(float volume);
	float get_fluid();
	void set_fluid(float fluid);
	Material::MaterialType get_material();
	void set_material(Material::MaterialType material);
	Material::CoveringType get_covering();
	void set_covering(Material::CoveringType covering);
};