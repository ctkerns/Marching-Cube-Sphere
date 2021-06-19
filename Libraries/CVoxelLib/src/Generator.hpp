#pragma once

#include <Godot.hpp>
#include <OpenSimplexNoise.hpp>

using godot::Object;
using godot::OpenSimplexNoise;
using godot::Vector3;

class Generator: public Object {
	GODOT_CLASS(Generator, Object)

private:
	OpenSimplexNoise *m_noise;
	float m_radius;

public:
	static void _register_methods();
	void _init();

	void set_radius(float radius);
	float sample(float x, float y, float z);
};