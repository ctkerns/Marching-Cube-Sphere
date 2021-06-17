#include <stdlib.h>
#include <time.h>

#include "Generator.hpp"

void Generator::_register_methods() {
	godot::register_method("set_radius", &Generator::set_radius);
	godot::register_method("sample", &Generator::sample);
}

void Generator::_init() {
	m_noise = godot::OpenSimplexNoise::_new();

	srand(time(0));

	m_noise->set_seed(rand());
}

void Generator::set_radius(float radius) {
	m_radius = radius;
}

float Generator::sample(float x, float y, float z) {
	float vol = m_noise->get_noise_3d(x, y, z);

	float magnitude = godot::Vector3(x, y, z).length();

	vol = magnitude/-m_radius + 1.0 + vol/1.0 + (float(rand())/RAND_MAX*2.0 - 1.0)/48.0;

	if (vol > 1.0)
		vol = 1.0;
	else if (vol < 0.0)
		vol = 0.0;

	return vol;
}