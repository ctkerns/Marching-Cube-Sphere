#include "StitchChunk.hpp"

void StitchChunk::_register_methods() {
	godot::register_method("draw_face", &StitchChunk::draw_face);
	godot::register_method("draw_edge", &StitchChunk::draw_edge);
	godot::register_method("draw_vert", &StitchChunk::draw_vert);
	godot::register_method("init", &StitchChunk::init);
	godot::register_method("toggle_dual", &StitchChunk::toggle_dual);
}

void StitchChunk::_init() {
	// Set up surface tools.
	m_dual = SurfaceTool::_new();
	m_surface = SurfaceTool::_new();
	m_fluid = SurfaceTool::_new();
}

void StitchChunk::init() {
	// Grab child nodes.
	m_dual_mesh	   = static_cast<MeshInstance*>(get_node("Dual"));
	m_surface_mesh = static_cast<MeshInstance*>(get_node("Surface"));
	m_fluid_mesh   = static_cast<MeshInstance*>(get_node("Fluid"));

	m_surface_body = static_cast<StaticBody*>(get_node("SurfaceBody"));
	m_surface_shape = static_cast<CollisionShape*>(get_node("SurfaceBody/CollisionShape"));
}

void StitchChunk::begin() {
	m_dual->begin(Mesh::PRIMITIVE_LINES);
	m_surface->begin(Mesh::PRIMITIVE_TRIANGLES);
	m_fluid->begin(Mesh::PRIMITIVE_TRIANGLES);

	m_surface->add_smooth_group(true);
	m_fluid->add_smooth_group(true);
}

void StitchChunk::end() {
	// End drawing.
	m_dual_mesh->set_mesh(m_dual->commit());

	m_surface->generate_normals();
	Ref<ArrayMesh> surface_mesh = m_surface->commit();
	int vertex_count = surface_mesh->get_surface_count();
	m_surface_mesh->set_mesh(surface_mesh);

	m_fluid->generate_normals();
	m_fluid_mesh->set_mesh(m_fluid->commit());

	// Create collision shape.
	if (vertex_count > 0) {
		m_surface_shape->call_deferred("set_shape", m_surface_mesh->get_mesh()->create_trimesh_shape());
		//m_surface_shape->set_shape(m_surface_mesh->get_mesh()->create_trimesh_shape());
	} else {
		m_surface_body->call_deferred("free");
	}
}

void StitchChunk::draw_face(OctreeChunk *c0, OctreeChunk *c1, int axis) {
	begin();
	face_proc(c0, c1, 0b1, 0b1, axis);
	end();
}

void StitchChunk::draw_edge(OctreeChunk *c0, OctreeChunk *c1, OctreeChunk *c2, OctreeChunk *c3, int axis) {
	begin();
	edge_proc(c0, c1, c2, c3, 0b1, 0b1, 0b1, 0b1, axis);
	end();
}

void StitchChunk::draw_vert(
	OctreeChunk *c0, OctreeChunk *c1, OctreeChunk *c2, OctreeChunk *c3,
	OctreeChunk *c4, OctreeChunk *c5, OctreeChunk *c6, OctreeChunk *c7
) {
	begin();
	vert_proc(c0, c1, c2, c3, c4, c5, c6, c7, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1, 0b1);
	end();
}

// Octree face, dual edge, takes two nodes as arguments.
// Assume that t_0 is inferior on given axis and t_1 is superior.
void StitchChunk::face_proc(OctreeChunk *c0, OctreeChunk *c1, int t0, int t1, int axis) {
	Octree *o0 = c0->get_tree();
	Octree *o1 = c1->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	OctreeChunk *chunks[8];
	
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
	if (o0->is_branch(t0))
		for (int i=0; i < 4; i++) {
			children[(*plane)[i]] = o0->get_child(t0, (*plane)[i] | axis);
			chunks[(*plane)[i]] = c0;
		}
	else {
		// If node is a leaf, use the node as a stand in for its child.
		for (int i=0; i < 4; i++) {
			children[(*plane)[i]] = t0;
			chunks[(*plane)[i]] = c0;
		}
		num_leaves++;
	}
		
	// Superior node.
	if (o1->is_branch(t1))
		for (int i=0; i < 4; i++) {
			children[(*plane)[i] | axis] = o1->get_child(t1, (*plane)[i]);
			chunks[(*plane)[i] | axis] = c1;
		}
	else {
		// If node is a leaf, use the node as a stand in for its child.
		for (int i=0; i < 4; i++) {
			children[(*plane)[i] | axis] = t1;
			chunks[(*plane)[i] | axis] = c1;
		}
		num_leaves++;
	}
		
	if (num_leaves < 2) {
		// Recursively traverse child nodes.
		for (int i=0; i < 4; i++)
			face_proc(c0, c1, children[(*plane)[i]], children[(*plane)[i] | axis], axis);
	
		switch(axis) {
			case 0b001:
				edge_proc(chunks[0], chunks[1], chunks[4], chunks[5], children[0], children[1], children[4], children[5], 0b010);
				edge_proc(chunks[0], chunks[1], chunks[2], chunks[3], children[0], children[1], children[2], children[3], 0b100);
				edge_proc(chunks[4], chunks[5], chunks[6], chunks[7], children[4], children[5], children[6], children[7], 0b100);
				edge_proc(chunks[2], chunks[3], chunks[6], chunks[7], children[2], children[3], children[6], children[7], 0b010);
				break;
			case 0b010:
				edge_proc(chunks[0], chunks[2], chunks[4], chunks[6], children[0], children[2], children[4], children[6], 0b001);
				edge_proc(chunks[0], chunks[1], chunks[2], chunks[3], children[0], children[1], children[2], children[3], 0b100);
				edge_proc(chunks[4], chunks[5], chunks[6], chunks[7], children[4], children[5], children[6], children[7], 0b100);
				edge_proc(chunks[1], chunks[3], chunks[5], chunks[7], children[1], children[3], children[5], children[7], 0b001);
				break;
			case 0b100:
				edge_proc(chunks[0], chunks[2], chunks[4], chunks[6], children[0], children[2], children[4], children[6], 0b001);
				edge_proc(chunks[0], chunks[1], chunks[4], chunks[5], children[0], children[1], children[4], children[5], 0b010);
				edge_proc(chunks[2], chunks[3], chunks[6], chunks[7], children[2], children[3], children[6], children[7], 0b010);
				edge_proc(chunks[1], chunks[3], chunks[5], chunks[7], children[1], children[3], children[5], children[7], 0b001);
				break;
		}

		vert_proc(
			chunks[0], chunks[1], chunks[2], chunks[3], chunks[4], chunks[5], chunks[6], chunks[7],
			children[0], children[1], children[2], children[3], children[4], children[5], children[6], children[7]
		);
	}
}

// Octree edge, dual face, takes four nodes as arguments.
// Assume a node's location t in bit form is also it's location relative to the other nodes on valid
// axes. Axis represents the commmon dimension.
void StitchChunk::edge_proc(
	OctreeChunk *c0, OctreeChunk *c1, OctreeChunk *c2, OctreeChunk *c3,
	int t0, int t1, int t2, int t3, int axis
) {
	Octree *o0 = c0->get_tree();
	Octree *o1 = c1->get_tree();
	Octree *o2 = c2->get_tree();
	Octree *o3 = c3->get_tree();
		
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
	get_edge_children(o0, t0, 0, children, *plane, axis, &num_leaves);
	get_edge_children(o1, t1, 1, children, *plane, axis, &num_leaves);
	get_edge_children(o2, t2, 2, children, *plane, axis, &num_leaves);
	get_edge_children(o3, t3, 3, children, *plane, axis, &num_leaves);
	
	if (num_leaves < 4) {
		// Recursively traverse child nodes.
		edge_proc(c0, c1, c2, c3, children[0], children[1], children[2], children[3], axis);
		edge_proc(c0, c1, c2, c3, children[4], children[5], children[6], children[7], axis);
	
		// Traverse octree vertices.
		switch(axis) {
			case 0b001:
				vert_proc(
					c0, c0, c1, c1, c2, c2, c3, c3,
					children[0], children[4], children[1], children[5], children[2], children[6], children[3], children[7]
				);
				break;
			case 0b010:
				vert_proc(
					c0, c1, c0, c1, c2, c3, c2, c3,
					children[0], children[1], children[4], children[5], children[2], children[3], children[6], children[7]
				);
				break;
			case 0b100:
				vert_proc(
					c0, c1, c2, c3, c0, c1, c2, c3,
					children[0], children[1], children[2], children[3], children[4], children[5], children[6], children[7]
				);
				break;
		}
	}
}

// Octree vertex, dual hexahedron, takes eight nodes as arguments.
// Assume a node's location in t in bit form is also its location relative to the other nodes.
void StitchChunk::vert_proc(
	OctreeChunk *c0, OctreeChunk *c1, OctreeChunk *c2, OctreeChunk *c3,
	OctreeChunk *c4, OctreeChunk *c5, OctreeChunk *c6, OctreeChunk *c7,
	int t0, int t1, int t2, int t3, int t4, int t5, int t6, int t7
) {
	Octree *o0 = c0->get_tree();
	Octree *o1 = c1->get_tree();
	Octree *o2 = c2->get_tree();
	Octree *o3 = c3->get_tree();
	Octree *o4 = c4->get_tree();
	Octree *o5 = c5->get_tree();
	Octree *o6 = c6->get_tree();
	Octree *o7 = c7->get_tree();
		
	int num_leaves = 0;
	
	int children[8];
	
	get_vert_children(o0, t0, 0, children, &num_leaves);
	get_vert_children(o1, t1, 1, children, &num_leaves);
	get_vert_children(o2, t2, 2, children, &num_leaves);
	get_vert_children(o3, t3, 3, children, &num_leaves);
	get_vert_children(o4, t4, 4, children, &num_leaves);
	get_vert_children(o5, t5, 5, children, &num_leaves);
	get_vert_children(o6, t6, 6, children, &num_leaves);
	get_vert_children(o7, t7, 7, children, &num_leaves);
		
	if (num_leaves >= 8) {
		// All nodes surrounding the vertex are leaves so draw the dual volume here.
		Vector3 v[8] = {
			c0->to_global(o0->get_vertex(t0)),
			c1->to_global(o1->get_vertex(t1)),
			c2->to_global(o2->get_vertex(t2)),
			c3->to_global(o3->get_vertex(t3)),
			c4->to_global(o4->get_vertex(t4)),
			c5->to_global(o5->get_vertex(t5)),
			c6->to_global(o6->get_vertex(t6)),
			c7->to_global(o7->get_vertex(t7))
		};

		float d[8] = {
			o0->get_density(t0),
			o1->get_density(t1),
			o2->get_density(t2),
			o3->get_density(t3),
			o4->get_density(t4),
			o5->get_density(t5),
			o6->get_density(t6),
			o7->get_density(t7)
		};

		float f[8] = {
			o0->get_fluid(t0),
			o1->get_fluid(t1),
			o2->get_fluid(t2),
			o3->get_fluid(t3),
			o4->get_fluid(t4),
			o5->get_fluid(t5),
			o6->get_fluid(t6),
			o7->get_fluid(t7)
		};

		Material::MaterialType mat[8] = {
			o0->get_material(t0),
			o1->get_material(t1),
			o2->get_material(t2),
			o3->get_material(t3),
			o4->get_material(t4),
			o5->get_material(t5),
			o6->get_material(t6),
			o7->get_material(t7)
		};

		Material::CoveringType cov[8] = {
			o0->get_covering(t0),
			o1->get_covering(t1),
			o2->get_covering(t2),
			o3->get_covering(t3),
			o4->get_covering(t4),
			o5->get_covering(t5),
			o6->get_covering(t6),
			o7->get_covering(t7),
		};

		Geometry::draw_hexahedron_edge(v, m_dual);
		MarchingCubes::draw_cube(v, d, mat, cov, m_surface);
		MarchingCubes::draw_fluid(v, f, m_fluid);
	} else
		// Recursively traverse child nodes.
		vert_proc(
			c0, c1, c2, c3, c4, c5, c6, c7,
			children[0], children[1], children[2], children[3],
			children[4], children[5], children[6], children[7]
		);
}

inline void StitchChunk::get_edge_children(Octree *octree, int t, int idx, int children[8], const int plane[4], int axis, int *num_leaves) {
	if (octree->is_branch(t)) {
		children[idx]	  = octree->get_child(t, plane[3 - idx]);
		children[idx + 4] = octree->get_child(t, plane[3 - idx] | axis);
	} else {
		children[idx]	  = t;
		children[idx + 4] = t;
		(*num_leaves)++;
	}
}

inline void StitchChunk::get_vert_children(Octree *octree, int t, int idx, int children[8], int *num_leaves) {
	if (octree->is_branch(t))
		// If node is a branch, get its child that is connected to the octree vertex.
		children[idx] = octree->get_child(t, 7 - idx);
	else {
		// If node is a leaf, use the node as a stand in for its child.
		children[idx] = t;
		(*num_leaves)++;
	}
}

void StitchChunk::toggle_dual() {
	if (m_dual_mesh->is_visible_in_tree())
		m_dual_mesh->hide();
	else
		m_dual_mesh->show();
}