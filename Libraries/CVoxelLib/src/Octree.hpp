#include <Godot.hpp>
#include <Object.hpp>

class Octree: public godot::Object {
	GODOT_CLASS(Octree, godot::Object)

private:
	godot::Dictionary m_nodes = godot::Dictionary();

public:
	static void _register_methods();
	void _init();

	void split(int loc_code, godot::Array);
	bool is_branch(int loc_code);

	int get_depth(int loc_code);
	int get_child(int loc_code, int div);
	int get_neighbor(int loc_code, int dir);
	float get_density(int loc_code);
	void set_density(int loc_code, float volume);
	godot::Vector3 get_vertex(int loc_code);
	godot::Array get_bounds(int loc_code);
};