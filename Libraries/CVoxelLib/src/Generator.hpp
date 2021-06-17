#pragma once

#include <Godot.hpp>
#include <OpenSimplexNoise.hpp>

class Generator: public godot::Object {
	GODOT_CLASS(Generator, godot::Object)

private:
	godot::OpenSimplexNoise *m_noise;
	float m_radius;

public:
	static void _register_methods();
	void _init();

	void set_radius(float radius);
	float sample(float x, float y, float z);
};