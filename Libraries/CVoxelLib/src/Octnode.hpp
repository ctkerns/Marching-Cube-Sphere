#pragma once

#include <Godot.hpp>

class Octnode {

private:
	float m_volume = 0.0;

public:
	Octnode(float volume);
	
	float get_volume();
	void set_volume(float volume);
};