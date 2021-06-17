#include <vector>
#include <queue>

#include "OctreeChunk.hpp"

void OctreeChunk::_register_methods() {
	godot::register_method("init", &OctreeChunk::init);
	godot::register_method("get_tree", &OctreeChunk::get_tree);
}

void OctreeChunk::_init() {
	m_tree = Octree::_new();
}

void OctreeChunk::init(int depth, Generator *generator) {
	m_depth = depth;

	m_generator = generator;
	
	float scale = pow(2, m_depth);
	set_scale(godot::Vector3(scale, scale, scale));
		
	generate();
}

Octree *OctreeChunk::get_tree() {
	return godot::Variant(m_tree);
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
			godot::Array volumes;
			for (int k=0; k < 8; k++) {
				int child = m_tree->get_child(node, k);
				godot::Vector3 vert = m_tree->get_vertex(child);

				// This needs to change if the planet is going to move.
				vert = to_global(vert);

				volumes.push_back(m_generator->sample(vert.x, vert.y, vert.z));
			}
			
			// Split each node in the queue, and add the nodes to the queue.
			m_tree->split(node, volumes);

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

			//----

			// Check if the children are homogenous.
			bool homogenous = true;
			float first_child = m_tree->get_density(m_tree->get_child(node, 0)) >= threshold;

			//----

			for (int k=1; k < 8; k++) {
				float child = m_tree->get_density(m_tree->get_child(node, k)) >= threshold;
				if (child != first_child) {
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
		}
	}
}