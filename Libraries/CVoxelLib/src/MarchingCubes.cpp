#include "MarchingCubes.hpp"
#include "Transvoxel.hpp"

void MarchingCubes::draw_cube(Vector3 v[8], float d[8], SurfaceTool *st) {
	int tag = 0x00000000;
	int idx[] = {0, 1, 4, 5, 2, 3, 6, 7};

	for (int i=0; i < 8; i++)
		if (d[idx[i]] >= THRESHOLD)
			tag |= (1 << i);

	RegularCellData cell = regularCellData[regularCellClass[tag]];
	int tri_count = cell.geometryCounts & 0x0F;

	for (int i=0; i < tri_count; i++) {
		Vector3 a = find_vert(regularVertexData[tag][cell.vertexIndex[i*3]]	  , v, d);
		Vector3 b = find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 1]], v, d);
		Vector3 c = find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 2]], v, d);

		st->add_vertex(c);
		st->add_vertex(b);
		st->add_vertex(a);
	}
}

Vector3 MarchingCubes::vector_abs(Vector3 v) {
	return Vector3(abs(v.x), abs(v.y), abs(v.z));
}

Vector3 MarchingCubes::find_vert(int edge_index, Vector3 v[8], float d[8]) {
	float d1, d2;
	Vector3 v1, v2;

	switch(edge_index & 0xFF) {
		case 0x01:
			d1 = d[0b001] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[1];
			break;
		case 0x02:
			d1 = d[0b100] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[4];
			break;
		case 0x04:
			d1 = d[0b010] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[2];
			break;
		case 0x13:
			d1 = d[0b101] - THRESHOLD;
			d2 = d[0b001] - THRESHOLD;
			v1 = v[1];
			v2 = v[5];
			break;
		case 0x15:
			d1 = d[0b011] - THRESHOLD;
			d2 = d[0b001] - THRESHOLD;
			v1 = v[1];
			v2 = v[3];
			break;
		case 0x23:
			d1 = d[0b101] - THRESHOLD;
			d2 = d[0b100] - THRESHOLD;
			v1 = v[4];
			v2 = v[5];
			break;
		case 0x26:
			d1 = d[0b110] - THRESHOLD;
			d2 = d[0b100] - THRESHOLD;
			v1 = v[4];
			v2 = v[6];
			break;
		case 0x37:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b101] - THRESHOLD;
			v1 = v[5];
			v2 = v[7];
			break;
		case 0x45:
			d1 = d[0b011] - THRESHOLD;
			d2 = d[0b010] - THRESHOLD;
			v1 = v[2];
			v2 = v[3];
			break;
		case 0x46:
			d1 = d[0b110] - THRESHOLD;
			d2 = d[0b010] - THRESHOLD;
			v1 = v[2];
			v2 = v[6];
			break;
		case 0x57:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b011] - THRESHOLD;
			v1 = v[3];
			v2 = v[7];
			break;
		case 0x67:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b110] - THRESHOLD;
			v1 = v[6];
			v2 = v[7];
			break;
		default:
			return Vector3(0.0, 0.0, 0.0);
	}

	return v1.linear_interpolate(v2, d2/(d2 - d1));
}