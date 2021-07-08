#include "Octnode.hpp"

using namespace Material;

Octnode::Octnode(float volume, float fluid, MaterialType material, CoveringType covering)
: m_volume(volume), m_fluid(fluid), m_material(material), m_covering(covering) {

}

float Octnode::get_volume() {
	return m_volume;
}

void Octnode::set_volume(float volume) {
	m_volume = volume;
}

float Octnode::get_fluid() {
	return m_fluid;
}

void Octnode::set_fluid(float fluid) {
	m_fluid = fluid;
}

MaterialType Octnode::get_material() {
	return m_material;
}

void Octnode::set_material(MaterialType material) {
	m_material = material;
}

CoveringType Octnode::get_covering() {
	return m_covering;
}

void Octnode::set_covering(CoveringType covering) {
	m_covering = covering;
}