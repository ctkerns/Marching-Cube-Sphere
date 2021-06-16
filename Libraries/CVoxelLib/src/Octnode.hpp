#pragma once

#include <Godot.hpp>
#include <Object.hpp>

class Octnode: public godot::Object {
	GODOT_CLASS(Octnode, godot::Object)

private:
	float m_volume = 0.0;

public:
	static void _register_methods();
	void _init();
	float get_volume();
	void set_volume(float volume);
};