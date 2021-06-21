#include "Octnode.hpp"

using namespace Material;

Octnode::Octnode(float volume, MaterialType material): m_volume(volume), m_material(material) {

}

float Octnode::get_volume() {
	return m_volume;
}

void Octnode::set_volume(float volume) {
	m_volume = volume;
}

MaterialType Octnode::get_material() {
	return m_material;
}

void Octnode::set_material(MaterialType material) {
	m_material = material;
}