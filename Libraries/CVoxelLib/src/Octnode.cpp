#include "Octnode.hpp"

Octnode::Octnode(float volume): m_volume(volume) {

}

float Octnode::get_volume() {
	return m_volume;
}

void Octnode::set_volume(float volume) {
	m_volume = volume;
}