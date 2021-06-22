#pragma once

#include <Godot.hpp>

using godot::Color;

namespace Material {
	enum MaterialType {dirt=0, sand, stone};

	static Color get_color(MaterialType m) {
		switch(m) {
			case dirt:
				return Color(0.14, 0.11, 0.04);
			case sand:
				return Color(0.68, 0.57, 0.18);
			case stone:
				return Color(0.31, 0.29, 0.29);
			default:
				return Color(1.0, 0.0, 1.0);
		}
	}
};