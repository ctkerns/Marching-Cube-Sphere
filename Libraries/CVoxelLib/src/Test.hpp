#include <Godot.hpp>
#include <Object.hpp>

class Test: public godot::Object {
	GODOT_CLASS(Test, godot::Object)

public:
	static void _register_methods();
	void _init();
};