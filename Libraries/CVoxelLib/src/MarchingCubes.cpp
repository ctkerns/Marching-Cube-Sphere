#include "MarchingCubes.hpp"
#include "Transvoxel.hpp"

void MarchingCubes::_register_methods() {
	godot::register_method("draw_cube", &MarchingCubes::draw_cube);
	godot::register_method("vector_abs", &MarchingCubes::vector_abs);
	godot::register_method("find_vert", &MarchingCubes::find_vert);
}

void MarchingCubes::_init() {

}

godot::Array MarchingCubes::draw_cube(
	godot::Array v, godot::Array d, godot::PoolVector3Array verts, godot::PoolVector3Array normals
) {
	int tag = 0x00000000;
	int idx[] = {0, 1, 4, 5, 2, 3, 6, 7};

	for (int i=0; i < 8; i++)
		if (float(d[idx[i]]) >= THRESHOLD)
			tag |= (1 << i);

	RegularCellData cell = regularCellData[regularCellClass[tag]];
	int tri_count = cell.geometryCounts & 0x0F;

	for (int i=0; i < tri_count; i++) {
		godot::Vector3 a = find_vert(regularVertexData[tag][cell.vertexIndex[i*3]]	  , v, d);
		godot::Vector3 b = find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 1]], v, d);
		godot::Vector3 c = find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 2]], v, d);

		verts.append(c);
		verts.append(b);
		verts.append(a);

		godot::Vector3 face_normal = ((b-a).cross(c-a)).normalized();

		normals.append(face_normal);
		normals.append(face_normal);
		normals.append(face_normal);
	}

	godot::Array retval;
	retval.push_back(verts);
	retval.push_back(normals);
	return retval;
}

godot::Vector3 MarchingCubes::vector_abs(godot::Vector3 v) {
	return godot::Vector3(abs(v.x), abs(v.y), abs(v.z));
}

godot::Vector3 MarchingCubes::find_vert(int edge_index, godot::Array v, godot::Array d) {
	float d1, d2;
	godot::Vector3 v1, v2;

	switch(edge_index & 0xFF) {
		case 0x01:
			d1 = (float)(d)[0b001] - THRESHOLD;
			d2 = (float)(d)[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[1];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x02:
			d1 = (float)(d)[0b100] - THRESHOLD;
			d2 = (float)(d)[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[4];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x04:
			d1 = (float)(d)[0b010] - THRESHOLD;
			d2 = (float)(d)[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[2];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x13:
			d1 = (float)(d)[0b101] - THRESHOLD;
			d2 = (float)(d)[0b001] - THRESHOLD;
			v1 = v[1];
			v2 = v[5];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x15:
			d1 = (float)(d)[0b011] - THRESHOLD;
			d2 = (float)(d)[0b001] - THRESHOLD;
			v1 = v[1];
			v2 = v[3];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x23:
			d1 = (float)(d)[0b101] - THRESHOLD;
			d2 = (float)(d)[0b100] - THRESHOLD;
			v1 = v[4];
			v2 = v[5];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x26:
			d1 = (float)(d)[0b110] - THRESHOLD;
			d2 = (float)(d)[0b100] - THRESHOLD;
			v1 = v[4];
			v2 = v[6];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x37:
			d1 = (float)(d)[0b111] - THRESHOLD;
			d2 = (float)(d)[0b101] - THRESHOLD;
			v1 = v[5];
			v2 = v[7];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x45:
			d1 = (float)(d)[0b011] - THRESHOLD;
			d2 = (float)(d)[0b010] - THRESHOLD;
			v1 = v[2];
			v2 = v[3];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x46:
			d1 = (float)(d)[0b110] - THRESHOLD;
			d2 = (float)(d)[0b010] - THRESHOLD;
			v1 = v[2];
			v2 = v[6];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x57:
			d1 = (float)(d)[0b111] - THRESHOLD;
			d2 = (float)(d)[0b011] - THRESHOLD;
			v1 = v[3];
			v2 = v[7];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		case 0x67:
			d1 = (float)(d)[0b111] - THRESHOLD;
			d2 = (float)(d)[0b110] - THRESHOLD;
			v1 = v[6];
			v2 = v[7];
			return v1.linear_interpolate(v2, d2/(d2 - d1));
		default:
			return godot::Vector3(0.0, 0.0, 0.0);
	}
}