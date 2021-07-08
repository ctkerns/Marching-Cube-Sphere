#include <vector>

#include "Mesher.hpp"

#include "Octree.hpp"
#include "Material.hpp"

using Material::get_material_ids;

void Mesher::_register_methods() {
	godot::register_method("begin_tree", &Mesher::begin_tree);
	godot::register_method("begin_dual", &Mesher::begin_dual);
	godot::register_method("begin_surface", &Mesher::begin_surface);
	godot::register_method("begin_fluid", &Mesher::begin_fluid);
	godot::register_method("end_tree", &Mesher::end_tree);
	godot::register_method("end_dual", &Mesher::end_dual);
	godot::register_method("end_surface", &Mesher::end_surface);
	godot::register_method("end_fluid", &Mesher::end_fluid);
	godot::register_method("draw_tree", &Mesher::draw_tree);
	godot::register_method("draw", &Mesher::draw);
}

void Mesher::_init() {
	// Set up surface tools.
	m_tree = SurfaceTool::_new();
	m_dual = SurfaceTool::_new();
	m_surface = SurfaceTool::_new();
	m_fluid = SurfaceTool::_new();
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

void Mesher::begin_fluid() {
	m_fluid->begin(Mesh::PRIMITIVE_TRIANGLES);
	m_fluid->add_smooth_group(true);	
}

Ref<ArrayMesh> Mesher::end_tree() {
	return m_tree->commit();
}

Ref<ArrayMesh> Mesher::end_dual() {
	return m_dual->commit();
}

Ref<ArrayMesh> Mesher::end_surface() {
	m_surface->generate_normals();
	return m_surface->commit();
}

Ref<ArrayMesh> Mesher::end_fluid() {
	m_fluid->generate_normals();
	return m_fluid->commit();
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
	face_proc(chunk, children[0], children[1], 0b001);
	face_proc(chunk, children[0], children[2], 0b010);
	face_proc(chunk, children[0], children[4], 0b100);
	face_proc(chunk, children[1], children[3], 0b010);
	face_proc(chunk, children[1], children[5], 0b100);
	face_proc(chunk, children[2], children[3], 0b001);
	face_proc(chunk, children[2], children[6], 0b100);
	face_proc(chunk, children[3], children[7], 0b100);
	face_proc(chunk, children[4], children[5], 0b001);
	face_proc(chunk, children[4], children[6], 0b010);
	face_proc(chunk, children[5], children[7], 0b010);
	face_proc(chunk, children[6], children[7], 0b001);
	
	// Traverse octree edges.
	edge_proc(chunk, children[0], children[1], children[2], children[3], 0b100);
	edge_proc(chunk, children[0], children[1], children[4], children[5], 0b010);
	edge_proc(chunk, children[0], children[2], children[4], children[6], 0b001);
	edge_proc(chunk, children[1], children[3], children[5], children[7], 0b001);
	edge_proc(chunk, children[2], children[3], children[6], children[7], 0b010);
	edge_proc(chunk, children[4], children[5], children[6], children[7], 0b100);
	
	// Traverse octree vertices.
	vert_proc(chunk, children[0], children[1], children[2], children[3], children[4], children[5], children[6], children[7]);
}

// Octree face, dual edge, takes two nodes as arguments.
// Assume that t_0 is inferior on given axis and t_1 is superior.
void Mesher::face_proc(OctreeChunk *chunk, int t0, int t1, int axis) {
	Octree *octree = chunk->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	// Find interior plane that needs to be connected, with the value at the given axis always 0.
	const int (*plane)[4];
	switch(axis) {
		case 0b001:
			plane = &plane_z;
			break;
		case 0b010:
			plane = &plane_y;
			break;
		case 0b100:
			plane = &plane_x;
			break;
	}
	
	// Find children to be connected. Location in the array will be on the opposite side through
	// the axis.

	// Inferior node.
	if (octree->is_branch(t0))
		for (int i=0; i < 4; i++)
			children[(*plane)[i]] = octree->get_child(t0, (*plane)[i] | axis);
	else {
		// If node is a leaf, use the node as a stand in for its child.
		for (int i=0; i < 4; i++)
			children[(*plane)[i]] = t0;
		num_leaves++;
	}
		
	// Superior node.
	if (octree->is_branch(t1))
		for (int i=0; i < 4; i++)
			children[(*plane)[i] | axis] = octree->get_child(t1, (*plane)[i]);
	else {
		// If node is a leaf, use the node as a stand in for its child.
		for (int i=0; i < 4; i++)
			children[(*plane)[i] | axis] = t1;
		num_leaves++;
	}
		
	if (num_leaves < 2) {
		// Recursively traverse child nodes.
		for (int i=0; i < 4; i++)
			face_proc(chunk, children[(*plane)[i]], children[(*plane)[i] | axis], axis);
	
		switch(axis) {
			case 0b001:
				edge_proc(chunk, children[0], children[1], children[4], children[5], 0b010);
				edge_proc(chunk, children[0], children[1], children[2], children[3], 0b100);
				edge_proc(chunk, children[4], children[5], children[6], children[7], 0b100);
				edge_proc(chunk, children[2], children[3], children[6], children[7], 0b010);
				break;
			case 0b010:
				edge_proc(chunk, children[0], children[2], children[4], children[6], 0b001);
				edge_proc(chunk, children[0], children[1], children[2], children[3], 0b100);
				edge_proc(chunk, children[4], children[5], children[6], children[7], 0b100);
				edge_proc(chunk, children[1], children[3], children[5], children[7], 0b001);
				break;
			case 0b100:
				edge_proc(chunk, children[0], children[2], children[4], children[6], 0b001);
				edge_proc(chunk, children[0], children[1], children[4], children[5], 0b010);
				edge_proc(chunk, children[2], children[3], children[6], children[7], 0b010);
				edge_proc(chunk, children[1], children[3], children[5], children[7], 0b001);
				break;
		}

		vert_proc(chunk, children[0], children[1], children[2], children[3], children[4], children[5], children[6], children[7]);
	}
}

// Octree edge, dual face, takes four nodes as arguments.
// Assume a node's location t in bit form is also it's location relative to the other nodes on valid
// axes. Axis represents the commmon dimension.
void Mesher::edge_proc(OctreeChunk *chunk, int t0, int t1, int t2, int t3, int axis) {
	Octree *octree = chunk->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	// Find exterior plane that needs to be connected, with the value at the given axis always 0.
	const int (*plane)[4];
	switch(axis) {
		case 0b001:
			plane = &plane_z;
			break;
		case 0b010:
			plane = &plane_y;
			break;
		case 0b100:
			plane = &plane_x;
			break;
	}
	
	// Find children to be connected.
	get_edge_children(octree, t0, 0, children, *plane, axis, &num_leaves);
	get_edge_children(octree, t1, 1, children, *plane, axis, &num_leaves);
	get_edge_children(octree, t2, 2, children, *plane, axis, &num_leaves);
	get_edge_children(octree, t3, 3, children, *plane, axis, &num_leaves);
	
	if (num_leaves < 4) {
		// Recursively traverse child nodes.
		edge_proc(chunk, children[0], children[1], children[2], children[3], axis);
		edge_proc(chunk, children[4], children[5], children[6], children[7], axis);
	
		// Traverse octree vertices.
		switch(axis) {
			case 0b001:
				vert_proc(chunk, children[0], children[4], children[1], children[5], children[2], children[6], children[3], children[7]);
				break;
			case 0b010:
				vert_proc(chunk, children[0], children[1], children[4], children[5], children[2], children[3], children[6], children[7]);
				break;
			case 0b100:
				vert_proc(chunk, children[0], children[1], children[2], children[3], children[4], children[5], children[6], children[7]);
				break;
		}
	}
}

// Octree vertex, dual hexahedron, takes eight nodes as arguments.
// Assume a node's location in t in bit form is also its location relative to the other nodes.
void Mesher::vert_proc(OctreeChunk *chunk, int t0, int t1, int t2, int t3, int t4, int t5, int t6, int t7) {
	Octree *octree = chunk->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	get_vert_children(octree, t0, 0, children, &num_leaves);
	get_vert_children(octree, t1, 1, children, &num_leaves);
	get_vert_children(octree, t2, 2, children, &num_leaves);
	get_vert_children(octree, t3, 3, children, &num_leaves);
	get_vert_children(octree, t4, 4, children, &num_leaves);
	get_vert_children(octree, t5, 5, children, &num_leaves);
	get_vert_children(octree, t6, 6, children, &num_leaves);
	get_vert_children(octree, t7, 7, children, &num_leaves);
		
	if (num_leaves >= 8) {
		// All nodes surrounding the vertex are leaves so draw the dual volume here.
		Vector3 v[8] = {
			chunk->to_global(octree->get_vertex(t0)),
			chunk->to_global(octree->get_vertex(t1)),
			chunk->to_global(octree->get_vertex(t2)),
			chunk->to_global(octree->get_vertex(t3)),
			chunk->to_global(octree->get_vertex(t4)),
			chunk->to_global(octree->get_vertex(t5)),
			chunk->to_global(octree->get_vertex(t6)),
			chunk->to_global(octree->get_vertex(t7))
		};

		float d[8] = {
			octree->get_density(t0),
			octree->get_density(t1),
			octree->get_density(t2),
			octree->get_density(t3),
			octree->get_density(t4),
			octree->get_density(t5),
			octree->get_density(t6),
			octree->get_density(t7)
		};

		float f[8] = {
			octree->get_fluid(t0),
			octree->get_fluid(t1),
			octree->get_fluid(t2),
			octree->get_fluid(t3),
			octree->get_fluid(t4),
			octree->get_fluid(t5),
			octree->get_fluid(t6),
			octree->get_fluid(t7)
		};

		Material::MaterialType mat[8] = {
			octree->get_material(t0),
			octree->get_material(t1),
			octree->get_material(t2),
			octree->get_material(t3),
			octree->get_material(t4),
			octree->get_material(t5),
			octree->get_material(t6),
			octree->get_material(t7)
		};

		Material::CoveringType cov[8] = {
			octree->get_covering(t0),
			octree->get_covering(t1),
			octree->get_covering(t2),
			octree->get_covering(t3),
			octree->get_covering(t4),
			octree->get_covering(t5),
			octree->get_covering(t6),
			octree->get_covering(t7),
		};

		Geometry::draw_hexahedron_edge(v, m_dual);
		MarchingCubes::draw_cube(v, d, mat, cov, m_surface);
		MarchingCubes::draw_fluid(v, f, m_fluid);
	} else
		// Recursively traverse child nodes.
		vert_proc(chunk, children[0], children[1], children[2], children[3], children[4], children[5], children[6], children[7]);
}

inline void Mesher::get_edge_children(Octree *octree, int t, int idx, int children[8], const int plane[4], int axis, int *num_leaves) {
	if (octree->is_branch(t)) {
		children[idx]	  = octree->get_child(t, plane[3 - idx]);
		children[idx + 4] = octree->get_child(t, plane[3 - idx] | axis);
	} else {
		children[idx]	  = t;
		children[idx + 4] = t;
		(*num_leaves)++;
	}
}

inline void Mesher::get_vert_children(Octree *octree, int t, int idx, int children[8], int *num_leaves) {
	if (octree->is_branch(t))
		// If node is a branch, get its child that is connected to the octree vertex.
		children[idx] = octree->get_child(t, 7 - idx);
	else {
		// If node is a leaf, use the node as a stand in for its child.
		children[idx] = t;
		(*num_leaves)++;
	}
}