#include <vector>

#include "Mesher.hpp"

#include "Octree.hpp"

void Mesher::_register_methods() {
	godot::register_method("begin_tree", &Mesher::begin_tree);
	godot::register_method("begin_dual", &Mesher::begin_dual);
	godot::register_method("begin_surface", &Mesher::begin_surface);
	godot::register_method("end_tree", &Mesher::end_tree);
	godot::register_method("end_dual", &Mesher::end_dual);
	godot::register_method("end_surface", &Mesher::end_surface);
	godot::register_method("draw_tree", &Mesher::draw_tree);
	godot::register_method("draw", &Mesher::draw);
}

void Mesher::_init() {
	// Set up surface tools.
	m_tree = SurfaceTool::_new();
	m_dual = SurfaceTool::_new();
	m_surface = SurfaceTool::_new();
}

void Mesher::begin_tree() {
	m_tree->begin(Mesh::PRIMITIVE_LINES);
}

void Mesher::begin_dual() {
	m_dual->begin(Mesh::PRIMITIVE_LINES);
}

void Mesher::begin_surface() {
	m_surface->begin(Mesh::PRIMITIVE_TRIANGLES);
	m_surface->add_smooth_group(true);
}

Ref<ArrayMesh> Mesher::end_tree() {
	return m_tree->commit();
}

Ref<ArrayMesh> Mesher::end_dual() {
	return m_dual->commit();
}

Ref<ArrayMesh> Mesher::end_surface() {
	//m_surface->index();
	m_surface->generate_normals();
	return m_surface->commit();
}


void Mesher::draw_tree(OctreeChunk *chunk) {
	Octree *octree = chunk->get_tree();

	// Initialize stack.
	std::vector<int> stack;
	stack.push_back(0b1);

	// Perform a DFS traversal of the octree using stack.
	int id;
	while (!stack.empty()) {
		// Pop frame from stack.
		id = stack.back();
		stack.pop_back();

		// Check if this node is a leaf node.
		if (!octree->is_branch(id)) {
			// Draw the leaf node.
			Array bounds = octree->get_bounds(id);

			// Scale bounds from chunk space.
			Vector3 corner_a = chunk->to_global(bounds[0]);
			Vector3 corner_b = chunk->to_global((Vector3)(bounds[0]) + Vector3(bounds[1], bounds[1], bounds[1]));

			Geometry::draw_cuboid_edge(corner_a, corner_b, m_tree);
		} else {
			// Add this nodes children to the stack.
			for (int i=0; i < 8; i++)
				stack.push_back(octree->get_child(id, i));
		}
	}
}

void Mesher::draw(OctreeChunk *chunk) {
	// Recursively traverse the octree.
	cube_proc(chunk, 0b1);
}

void Mesher::cube_proc(OctreeChunk *chunk, int t) {
	Octree *octree = chunk->get_tree();

	// Terminate when t1 is a leaf node.
	if (!octree->is_branch(t))
		return;
	
	// Recursively traverse child nodes.
	int children[8];
	for (int i=0; i < 8; i++) {
		children[i] = octree->get_child(t, i);
			
		cube_proc(chunk, children[i]);
	}
	
	// Traverse octree faces.
	face_proc(chunk, new int[2] {children[0], children[1]}, 0b001);
	face_proc(chunk, new int[2] {children[0], children[2]}, 0b010);
	face_proc(chunk, new int[2] {children[0], children[4]}, 0b100);
	face_proc(chunk, new int[2] {children[1], children[3]}, 0b010);
	face_proc(chunk, new int[2] {children[1], children[5]}, 0b100);
	face_proc(chunk, new int[2] {children[2], children[3]}, 0b001);
	face_proc(chunk, new int[2] {children[2], children[6]}, 0b100);
	face_proc(chunk, new int[2] {children[3], children[7]}, 0b100);
	face_proc(chunk, new int[2] {children[4], children[5]}, 0b001);
	face_proc(chunk, new int[2] {children[4], children[6]}, 0b010);
	face_proc(chunk, new int[2] {children[5], children[7]}, 0b010);
	face_proc(chunk, new int[2] {children[6], children[7]}, 0b001);
	
	// Traverse octree edges.
	edge_proc(chunk, new int[4] {children[0], children[1], children[2], children[3]}, 0b100);
	edge_proc(chunk, new int[4] {children[0], children[1], children[4], children[5]}, 0b010);
	edge_proc(chunk, new int[4] {children[0], children[2], children[4], children[6]}, 0b001);
	edge_proc(chunk, new int[4] {children[1], children[3], children[5], children[7]}, 0b001);
	edge_proc(chunk, new int[4] {children[2], children[3], children[6], children[7]}, 0b010);
	edge_proc(chunk, new int[4] {children[4], children[5], children[6], children[7]}, 0b100);
	
	// Traverse octree vertices.
	vert_proc(chunk, children);
}

// Octree face, dual edge, takes two nodes as arguments.
// Assume that t_0 is inferior on given axis and t_1 is superior.
void Mesher::face_proc(OctreeChunk *chunk, int t[2], int axis) {
	Octree *octree = chunk->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	// Find interior plane that needs to be connected, with the value at the given axis always 0.
	int *plane;
	switch(axis) {
		case 0b001:
			plane = new int[4] {0b000, 0b010, 0b100, 0b110};
			break;
		case 0b010:
			plane = new int[4] {0b000, 0b001, 0b100, 0b101};
			break;
		case 0b100:
			plane = new int[4] {0b000, 0b001, 0b010, 0b011};
			break;
	}
	
	// Find children to be connected. Location in the array will be on the opposite side through
	// the axis.

	// Inferior node.
	if (octree->is_branch(t[0]))
		for (int i=0; i < 4; i++)
			children[plane[i]] = octree->get_child(t[0], plane[i] | axis);
	else {
		// If node is a leaf, use the node as a stand in for its child.
		for (int i=0; i < 4; i++)
			children[plane[i]] = t[0];
		num_leaves++;
	}
		
	// Superior node.
	if (octree->is_branch(t[1]))
		for (int i=0; i < 4; i++)
			children[plane[i] | axis] = octree->get_child(t[1], plane[i]);
	else {
		// If node is a leaf, use the node as a stand in for its child.
		for (int i=0; i < 4; i++)
			children[plane[i] | axis] = t[1];
		num_leaves ++;
	}
		
	if (num_leaves < 2) {
		// Recursively traverse child nodes.
		for (int i=0; i < 4; i++)
			face_proc(chunk, new int[2] {children[plane[i]], children[plane[i] | axis]}, axis);
	
		switch(axis) {
			case 0b001:
				edge_proc(chunk, new int[4] {children[0], children[1], children[4], children[5]}, 0b010);
				edge_proc(chunk, new int[4] {children[0], children[1], children[2], children[3]}, 0b100);
				edge_proc(chunk, new int[4] {children[4], children[5], children[6], children[7]}, 0b100);
				edge_proc(chunk, new int[4] {children[2], children[3], children[6], children[7]}, 0b010);
				break;
			case 0b010:
				edge_proc(chunk, new int[4] {children[0], children[2], children[4], children[6]}, 0b001);
				edge_proc(chunk, new int[4] {children[0], children[1], children[2], children[3]}, 0b100);
				edge_proc(chunk, new int[4] {children[4], children[5], children[6], children[7]}, 0b100);
				edge_proc(chunk, new int[4] {children[1], children[3], children[5], children[7]}, 0b001);
				break;
			case 0b100:
				edge_proc(chunk, new int[4] {children[0], children[2], children[4], children[6]}, 0b001);
				edge_proc(chunk, new int[4] {children[0], children[1], children[4], children[5]}, 0b010);
				edge_proc(chunk, new int[4] {children[2], children[3], children[6], children[7]}, 0b010);
				edge_proc(chunk, new int[4] {children[1], children[3], children[5], children[7]}, 0b001);
				break;
		}

		vert_proc(chunk, children);
	}
}

// Octree edge, dual face, takes four nodes as arguments.
// Assume a node's location t in bit form is also it's location relative to the other nodes on valid
// axes. Axis represents the commmon dimension.
void Mesher::edge_proc(OctreeChunk *chunk, int t[4], int axis) {
	Octree *octree = chunk->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	// Find exterior plane that needs to be connected, with the value at the given axis always 0.
	int *plane;
	switch(axis) {
		case 0b001:
			plane = new int[4] {0b000, 0b010, 0b100, 0b110};
			break;
		case 0b010:
			plane = new int[4] {0b000, 0b001, 0b100, 0b101};
			break;
		case 0b100:
			plane = new int[4] {0b000, 0b001, 0b010, 0b011};
			break;
	}
	
	// Find children to be connected.
	for (int i=0; i < 4; i++) {
		if (octree->is_branch(t[i])) {
			children[i] = octree->get_child(t[i], plane[3 - i]);
			children[i + 4] = octree->get_child(t[i], plane[3 -i] | axis);
		} else {
			children[i] = t[i];
			children[i + 4] = t[i];
			num_leaves++;
		}
	}
	
	if (num_leaves < 4) {
		// Recursively traverse child nodes.
		edge_proc(chunk, new int[4] {children[0], children[1], children[2], children[3]}, axis);
		edge_proc(chunk, new int[4] {children[4], children[5], children[6], children[7]}, axis);
	
		// Traverse octree vertices.
		switch(axis) {
			case 0b001:
				vert_proc(chunk, new int[8] {children[0], children[4], children[1], children[5], children[2], children[6], children[3], children[7]});
				break;
			case 0b010:
				vert_proc(chunk, new int[8] {children[0], children[1], children[4], children[5], children[2], children[3], children[6], children[7]});
				break;
			case 0b100:
				vert_proc(chunk, children);
				break;
		}
	}
}

// Octree vertex, dual hexahedron, takes eight nodes as arguments.
// Assume a node's location in t in bit form is also its location relative to the other nodes.
void Mesher::vert_proc(OctreeChunk *chunk, int t[8]) {
	Octree *octree = chunk->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	for (int i=0; i < 8; i++) {
		if (octree->is_branch(t[i]))
			// If node is a branch, get its child that is connected to the octree vertex.
			children[i] = octree->get_child(t[i], 7 - i);
		else {
			// If node is a leaf, use the node as a stand in for its child.
			children[i] = t[i];
			num_leaves++;
		}
	}
		
	if (num_leaves >= 8) {
		// All nodes surrounding the vertex are leaves so draw the dual volume here.
		Array v;
		Array d;
		for (int i=0; i < 8; i++) {
			Vector3 vert = octree->get_vertex(t[i]);
			v.push_back(chunk->to_global(vert));

			d.push_back(octree->get_density(t[i]));
		}
	
		Geometry::draw_hexahedron_edge(v, m_dual);
		MarchingCubes::draw_cube(v, d, m_surface);
	} else
		// Recursively traverse child nodes.
		vert_proc(chunk, children);
}