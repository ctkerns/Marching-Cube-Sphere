#include "Octree.hpp"

void Octree::_register_methods() {
	godot::register_method("split", &Octree::split);
	godot::register_method("delete_node", &Octree::delete_node);
	godot::register_method("is_branch", &Octree::is_branch);
	godot::register_method("get_depth", &Octree::get_depth);
	godot::register_method("get_child", &Octree::get_child);
	godot::register_method("get_neighbor", &Octree::get_neighbor);
	godot::register_method("get_density", &Octree::get_density);
	godot::register_method("set_density", &Octree::set_density);
	godot::register_method("get_vertex", &Octree::get_vertex);
	godot::register_method("get_bounds", &Octree::get_bounds);

	void split(int loc_code, Array);
	bool is_branch(int loc_code);
}

void Octree::_init() {
	// Create octree.
	Octnode *head = new Octnode(0.5);

	m_nodes[1] = head;
}

// Subdivides this node by creating eight children.
void Octree::split(int loc_code, Array vol) {
	if (get_depth(loc_code) > 20)
		return;
		
	int prefix = loc_code << 3;
	
	for(int i=0; i < 8; i++) {
		Octnode *node = new Octnode(vol[i]);
		node->set_volume(vol[i]);
		m_nodes[prefix | i] = node;
	}
}

// Deletes this node, but not its children. This is unsafe.
void Octree::delete_node(int loc_code) {
	Octnode *node = m_nodes[loc_code];
	delete node;

	m_nodes.erase(loc_code);
}

// Returns true if the node has children.
bool Octree::is_branch(int loc_code) {
	return m_nodes.count(get_child(loc_code, 0)) > 0;
}
			
// Returns the depth of this node. Head node has depth of 0.
int Octree::get_depth(int loc_code) {
	return int( (log(loc_code) / 3.0) / log(2) );
}
				
// Returns the locational code of the child of this node in the given direction.
int Octree::get_child(int loc_code, int div) {
	return loc_code << 3 | div;
}
					
// Returns the adjacent neighboring leaf node in the given direction. Unimplemented.
int Octree::get_neighbor(int loc_code, int dir) {
	return 1;
}

float Octree::get_density(int loc_code) {
	Octnode *node = m_nodes[loc_code];
	return node->get_volume();
}

void Octree::set_density(int loc_code, float volume) {
	Octnode *node = m_nodes[loc_code];
	return node->set_volume(volume);
}

// Returns the position of the center of this node relative to the octree.
Vector3 Octree::get_vertex(int loc_code) {
	int depth = get_depth(loc_code);
	float scale = 2.0 / pow(2, depth);

	// Start at the center of the head node.
	Vector3 vert = Vector3(0, 0, 0);

	// Traverse the path of the node bottom up.
	int n = loc_code;
	float increment = scale;
	for (int i=0; i < depth; i++) {
		// Move the vertex according to the locational code.
		if ((n & 4) == 4)
			vert.x += increment/2.0;
		else
			vert.x -= increment/2.0;

		if ((n & 2) == 2)
			vert.y += increment/2.0;
		else
			vert.y -= increment/2.0;

		if ((n & 1) == 1)
			vert.z += increment/2.0;
		else
			vert.z -= increment/2.0;

		// Move up a level.
		increment *= 2.0;
		n >>= 3;
	}

	return vert;
}

// Returns the bounding box of the node. 
Array Octree::get_bounds(int loc_code) {
	int depth = get_depth(loc_code);
	float scale = 2.0 / pow(2, depth);

	// Start at the corner of the head node.
	Vector3 vert = Vector3(-1, -1, -1);

	// Traverse the path of the node bottom up.
	int n = loc_code;
	float increment = scale;
	for (int i=0; i < depth; i++) {
		// Move the vertex according to the locational code.
		if ((n & 4) == 4)
			vert.x += increment;
		if ((n & 2) == 2)
			vert.y += increment;
		if ((n & 1) == 1)
			vert.z += increment;

		// Move up a level.
		increment *= 2.0;
		n >>= 3;
	}

	Array retval = Array();
	retval.push_back(vert);
	retval.push_back(scale);
	return retval;
}