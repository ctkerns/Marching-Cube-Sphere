#include <vector>
#include <queue>

#include "OctreeChunk.hpp"

#include "Material.hpp"

using namespace Material;

// TODO:
// In the change_terrain and is_underwater functions, return false if vertex is not in the space.

void OctreeChunk::_register_methods() {
	godot::register_method("_input", &OctreeChunk::_input);
	godot::register_method("init", &OctreeChunk::init);
	godot::register_method("draw", &OctreeChunk::draw);
	godot::register_method("change_terrain", &OctreeChunk::change_terrain);
	godot::register_method("is_underwater", &OctreeChunk::is_underwater);
}

void OctreeChunk::_init() {
	m_tree = new Octree();
}

void OctreeChunk::_input(Variant event) {
	std::cout << "hello" << std::endl;
	InputEvent *input = static_cast<InputEvent*>(event);

	if (input->is_action_pressed("toggle_borders")) {
		if (m_borders->is_visible_in_tree())
			m_borders->hide();
		else
			m_borders->show();
	}

	if (input->is_action_pressed("toggle_dual")) {
		if (m_dual->is_visible_in_tree())
			m_dual->hide();
		else
			m_dual->show();
	}
}

void OctreeChunk::init(int depth, Generator *generator) {
	m_depth = depth;

	m_generator = generator;
	m_mesher = Mesher::_new();

	// Grab child nodes.
	m_borders = static_cast<MeshInstance*>(get_node("Borders"));
	m_dual 	  = static_cast<MeshInstance*>(get_node("Dual"));
	m_surface = static_cast<MeshInstance*>(get_node("Surface"));
	m_fluid   = static_cast<MeshInstance*>(get_node("Fluid"));

	m_surface_shape = static_cast<CollisionShape*>(get_node("SurfaceBody/CollisionShape"));

	float scale = pow(2, m_depth);
	set_scale(Vector3(scale, scale, scale));
		
	generate();
}

void OctreeChunk::draw() {
	// Start drawing.
	m_mesher->begin_tree();
	m_mesher->begin_dual();
	m_mesher->begin_surface();
	m_mesher->begin_fluid();

	m_mesher->draw_tree(this);
	m_mesher->draw(this);

	// End drawing.
	m_borders->set_mesh(m_mesher->end_tree());
	m_dual->set_mesh(m_mesher->end_dual());
	m_surface->set_mesh(m_mesher->end_surface());
	m_fluid->set_mesh(m_mesher->end_fluid());

	// Create collision shape.
	m_surface_shape->set_shape(m_surface->get_mesh()->create_trimesh_shape());
}

Octree *OctreeChunk::get_tree() {
	return m_tree;
}

// Generate the tree while removing empty space.
void OctreeChunk::generate() {
	std::queue<int> queue = {};
	std::vector<int> backtrack = {};
	queue.push(0b1);
	backtrack.push_back(0b1);

	// Subdivide each node for each level in depth.
	for (int i=0; i < m_depth; i++) {
		for (int j = queue.size(); j > 0; j--) {
			// Find the volume for each child before they are created.
			int node = queue.front();
			queue.pop();
			float volumes[8];
			float fluids[8];
			MaterialType materials[8];
			CoveringType coverings[8];
			for (int k=0; k < 8; k++) {
				int child = m_tree->get_child(node, k);
				Vector3 vert = m_tree->get_vertex(child);

				// This needs to change if the planet is going to move.
				vert = to_global(vert);

				volumes[k] = m_generator->sample(vert.x, vert.y, vert.z);
				fluids[k] = m_generator->sample_fluid(vert.x, vert.y, vert.z);
				materials[k] = MaterialType(m_generator->sample_material(vert.x, vert.y, vert.z));
				coverings[k] = CoveringType(m_generator->sample_covering(vert.x, vert.y, vert.z));
			}
			
			// Split each node in the queue, and add the nodes to the queue.
			m_tree->split(node, volumes, fluids, materials, coverings);

			for (int k=0; k < 8; k++)
				queue.push(m_tree->get_child(node, k));

			if (i != m_depth - 1)
				for (int k=0; k < 8; k++)
					backtrack.push_back(m_tree->get_child(node, k));
		}
	}

	// Backtrack each layer and remove nodes as necessary.
	for (int i = m_depth - 1; i >= 0; i--) {
		for (int j=0; j < pow(8, i); j++) {
			int node = backtrack.back();
			backtrack.pop_back();

			// Check if the children are homogenous.
			bool homogenous = true;
			bool first_child = m_tree->get_density(m_tree->get_child(node, 0)) >= threshold;

			for (int k=1; k < 8; k++) {
				bool child = m_tree->get_density(m_tree->get_child(node, k)) >= threshold;
				if (child != first_child) {
					homogenous = false;
					break;
				}
			}

			// Check if the children have homogenous fluidity.
			if (homogenous && first_child == 0) {
				bool first_fluid = m_tree->get_fluid(m_tree->get_child(node, 0)) >= threshold;

				for (int k=1; k < 8; k++) {
					bool child = m_tree->get_fluid(m_tree->get_child(node, k)) >= threshold;
					if (child != first_fluid) {
						homogenous = false;
						break;
					}
				}
			}

			// Check if the children are all leaves.
			bool all_leaves = true;
			for (int k=0; k < 8; k++)
				if (m_tree->is_branch(m_tree->get_child(node, k))) {
					all_leaves = false;
					break;
				}

			// Collapse homogenous branch nodes.
			if (homogenous && all_leaves)
				for (int k=0; k < 8; k++)
					m_tree->delete_node(m_tree->get_child(node, k));
		}
	}
}

void OctreeChunk::change_terrain(Vector3 intersection, float delta) {
	int node = m_tree->find_node(to_local(intersection), m_depth);
	float density = m_tree->get_density(node);
	density += delta;
	
	if (density > 1.0)
		density = 1.0;
	
	if (density < 0.0)
		density = 0.0;

	m_tree->set_density(node, density);
}

bool OctreeChunk::is_underwater(Vector3 point) {
	int node = m_tree->find_node(to_local(point));
	return m_tree->get_fluid(node) > 0.5;
}