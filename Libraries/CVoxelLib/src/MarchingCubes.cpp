#include "MarchingCubes.hpp"
#include "Transvoxel.hpp"

using namespace Material;

void MarchingCubes::draw_cube(
	Vector3 v[8], float d[8], MaterialType mat[8], CoveringType cov[8], SurfaceTool *st
) {
	int tag = 0x00000000;
	int idx[] = {0, 1, 4, 5, 2, 3, 6, 7};

	for (int i=0; i < 8; i++)
		if (d[idx[i]] >= THRESHOLD)
			tag |= (1 << i);

	RegularCellData cell = regularCellData[regularCellClass[tag]];
	int tri_count = cell.geometryCounts & 0x0F;

	for (int i=0; i < tri_count; i++) {
		Vector3 v1, v2, v3;
		MaterialType m1, m2, m3;
		CoveringType c1, c2, c3;
		find_vert(regularVertexData[tag][cell.vertexIndex[i*3]]	   , v, d, mat, cov, &v1, &m1, &c1);
		find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 1]], v, d, mat, cov, &v2, &m2, &c2);
		find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 2]], v, d, mat, cov, &v3, &m3, &c3);

		st->add_uv(get_material_ids(m1, c1));
		st->add_vertex(v3);
		st->add_vertex(v2);
		st->add_vertex(v1);
	}
}

Vector3 MarchingCubes::vector_abs(Vector3 v) {
	return Vector3(abs(v.x), abs(v.y), abs(v.z));
}

void MarchingCubes::find_vert(
	int edge_index,
	Vector3 v[8],
	float d[8],
	MaterialType mat[8],
	CoveringType cov[8],
	Vector3 *vec,
	MaterialType *material,
	CoveringType *covering
) {
	float d1, d2;
	int idx1, idx2;
	Vector3 v1, v2;

	switch(edge_index & 0xFF) {
		case 0x01:
			d1 = d[0b001] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			idx1 = 0;
			idx2 = 1;
			break;
		case 0x02:
			d1 = d[0b100] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			idx1 = 0;
			idx2 = 4;
			break;
		case 0x04:
			d1 = d[0b010] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			idx1 = 0;
			idx2 = 2;
			break;
		case 0x13:
			d1 = d[0b101] - THRESHOLD;
			d2 = d[0b001] - THRESHOLD;
			idx1 = 1;
			idx2 = 5;
			break;
		case 0x15:
			d1 = d[0b011] - THRESHOLD;
			d2 = d[0b001] - THRESHOLD;
			idx1 = 1;
			idx2 = 3;
			break;
		case 0x23:
			d1 = d[0b101] - THRESHOLD;
			d2 = d[0b100] - THRESHOLD;
			idx1 = 4;
			idx2 = 5;
			break;
		case 0x26:
			d1 = d[0b110] - THRESHOLD;
			d2 = d[0b100] - THRESHOLD;
			idx1 = 4;
			idx2 = 6;
			break;
		case 0x37:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b101] - THRESHOLD;
			idx1 = 5;
			idx2 = 7;
			break;
		case 0x45:
			d1 = d[0b011] - THRESHOLD;
			d2 = d[0b010] - THRESHOLD;
			idx1 = 2;
			idx2 = 3;
			break;
		case 0x46:
			d1 = d[0b110] - THRESHOLD;
			d2 = d[0b010] - THRESHOLD;
			idx1 = 2;
			idx2 = 6;
			break;
		case 0x57:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b011] - THRESHOLD;
			idx1 = 3;
			idx2 = 7;
			break;
		case 0x67:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b110] - THRESHOLD;
			idx1 = 6;
			idx2 = 7;
			break;
	}

	// Interpolate position between the two nodes.
	float t = d2/(d2 - d1);
	// Get index to select from based on which node it is closest to.
	int i = idx1;
	if (t >= THRESHOLD)
		i = idx2;

	*material = mat[i];
	*covering = cov[i];

	v1 = v[idx1];
	v2 = v[idx2];

	*vec = v1.linear_interpolate(v2, t);
}