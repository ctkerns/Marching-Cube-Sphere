#pragma once

#include <Godot.hpp>

using godot::Color;

namespace Material {
	enum MaterialType {dirt, sand, stone};

	static Color get_color(MaterialType m) {
		switch(m) {
			case dirt:
				return Color(0.14, 0.11, 0.04);
			case sand:
				return Color(0.93, 0.90, 0.67);
			case stone:
				return Color(0.61, 0.60, 0.58);
			default:
				return Color(1.0, 0.0, 1.0);
		}
	}
};