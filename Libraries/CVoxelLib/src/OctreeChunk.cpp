#include <vector>
#include <queue>

#include "OctreeChunk.hpp"

#include "Material.hpp"

using namespace Material;

void OctreeChunk::_register_methods() {
	godot::register_method("init", &OctreeChunk::init);
	godot::register_method("generate", &OctreeChunk::generate);
	godot::register_method("draw", &OctreeChunk::draw);
	godot::register_method("change_terrain", &OctreeChunk::change_terrain);
	godot::register_method("is_underwater", &OctreeChunk::is_underwater);
	godot::register_method("toggle_borders", &OctreeChunk::toggle_borders);
	godot::register_method("toggle_dual", &OctreeChunk::toggle_dual);
}

void OctreeChunk::_init() {
	m_tree = new Octree();
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

	m_surface_body = static_cast<StaticBody*>(get_node("SurfaceBody"));
	m_surface_shape = static_cast<CollisionShape*>(get_node("SurfaceBody/CollisionShape"));

	float scale = pow(2, m_depth - 1);
	set_scale(Vector3(scale, scale, scale));
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
			float average = m_tree->get_density(m_tree->get_child(node, 0));
			bool first_child = average >= threshold;
			average /= 8.0f;

			for (int k=1; k < 8; k++) {
				float density = m_tree->get_density(m_tree->get_child(node, k));
				average += density/8.0f;
				bool child = density >= threshold;
				if (child != first_child) {
					homogenous = false;
					break;
				}
			}

			// Check if the children have homogenous fluidity.
			float average_fluid = m_tree->get_fluid(m_tree->get_child(node, 0));
			bool first_fluid = average >= threshold;
			average_fluid /= 8.0f;

			for (int k=1; k < 8; k++) {
				float density = m_tree->get_fluid(m_tree->get_child(node, k));
				average_fluid += density/8.0f;
				bool child = density >= threshold;
				if (child != first_fluid) {
					homogenous = false;
					break;
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

			// Set density to the average of the children.
			m_tree->set_density(node, average);
			m_tree->set_fluid(node, average_fluid);
		}
	}
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

	Ref<ArrayMesh> surface_mesh = m_mesher->end_surface();
	int vertex_count = surface_mesh->get_surface_count();
	m_surface->set_mesh(surface_mesh);

	m_fluid->set_mesh(m_mesher->end_fluid());

	// Create collision shape.
	if (vertex_count > 0)
		m_surface_shape->set_shape(m_surface->get_mesh()->create_trimesh_shape());
	else {
		m_surface_body->call_deferred("free");
	}
}

Octree *OctreeChunk::get_tree() {
	return m_tree;
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

void OctreeChunk::toggle_borders() {
	if (m_borders->is_visible_in_tree())
		m_borders->hide();
	else
		m_borders->show();
}

void OctreeChunk::toggle_dual() {
	if (m_dual->is_visible_in_tree())
		m_dual->hide();
	else
		m_dual->show();
}