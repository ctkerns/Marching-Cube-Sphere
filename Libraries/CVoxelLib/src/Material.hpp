#pragma once

#include <Godot.hpp>

#define EPSILON 0.000001

using godot::Vector2;
using godot::Color;

namespace Material {
	enum MaterialType {dirt=0, sand, stone, num_materials};
	enum CoveringType {grass, snow, none, num_colors};

	static Vector2 get_material_ids(MaterialType mat, CoveringType cov) {
		return Vector2(
			float(mat)/(num_materials - 1),
			float(cov)/(num_materials - 1)
		);
	}
};