#pragma once

#include <Godot.hpp>

#include "Material.hpp"

class Octnode {

private:
	float m_volume;
	Material::MaterialType m_material;

public:
	Octnode(float volume, Material::MaterialType material = Material::MaterialType::dirt);
	
	float get_volume();
	void set_volume(float volume);
	Material::MaterialType get_material();
	void set_material(Material::MaterialType material);
};