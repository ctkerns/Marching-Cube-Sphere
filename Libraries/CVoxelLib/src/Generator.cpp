#include <stdlib.h>
#include <time.h>

#include "Generator.hpp"
#include "Material.hpp"

using namespace Material;

void Generator::_register_methods() {
	godot::register_method("set_radius", &Generator::set_radius);
	godot::register_method("sample", &Generator::sample);
	godot::register_method("sample_material", &Generator::sample_material);
}

void Generator::_init() {
	m_noise = OpenSimplexNoise::_new();
	m_material_noise = OpenSimplexNoise::_new();

	srand(time(0));
	m_noise->set_seed(rand());

	srand(time(0));
	m_material_noise->set_seed(rand());
}

void Generator::set_radius(float radius) {
	m_radius = radius;
}

float Generator::sample(float x, float y, float z) {
	float vol = m_noise->get_noise_3d(x, y, z);

	float magnitude = Vector3(x, y, z).length();

	// Add sphere shape and randomness.
	vol += 1.0 - magnitude/m_radius;
	vol += (float(rand())/RAND_MAX*2.0 - 1.0)/48.0;

	if (vol > 1.0)
		vol = 1.0;
	else if (vol < 0.0)
		vol = 0.0;

	return vol;
}

float Generator::sample_fluid(float x, float y, float z) {
	float magnitude = Vector3(x, y, z).length();
	float vol = 1.0 - magnitude/m_radius;

	if (vol > 1.0)
		vol = 1.0;
	else if (vol < 0.0)
		vol = 0.0;

	return vol;
}

int Generator::sample_material(float x, float y, float z) {
	float noise_value = (m_material_noise->get_noise_3d(x, y, z) + 1.0)/2.0;

	float dist = Vector3(x, y, z).length();
	float scaled_dist = dist/m_radius;

	if (scaled_dist + noise_value < 1.0)
		return stone;
	if (noise_value < 0.6)
		return sand;
	return dirt;
}

int Generator::sample_covering(float x, float y, float z) {
	float magnitude = Vector3(x, y, z).length();

	// Remove covering if this should be underwater.
	if (1.0 - magnitude/m_radius > 0.5)
		return none;
	
	if (z > m_radius)
		return snow;
	if (magnitude > m_radius/1.5)
		return snow;
	return grass;
}