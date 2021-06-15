#include "Octnode.hpp"

void Octnode::_register_methods() {
	godot::register_method("_init", &Octnode::_init);
	godot::register_method("get_volume", &Octnode::get_volume);
	godot::register_method("set_volume", &Octnode::set_volume);
}

void Octnode::_init() {
	
}

float Octnode::get_volume() {
	return m_volume;
}

void Octnode::set_volume(float volume) {
	m_volume = volume;
}