#include "MarchingCubes.hpp"
#include "Transvoxel.hpp"

void MarchingCubes::draw_cube(Vector3 v[8], float d[8], Color c[8], SurfaceTool *st) {
	int tag = 0x00000000;
	int idx[] = {0, 1, 4, 5, 2, 3, 6, 7};

	for (int i=0; i < 8; i++)
		if (d[idx[i]] >= THRESHOLD)
			tag |= (1 << i);

	RegularCellData cell = regularCellData[regularCellClass[tag]];
	int tri_count = cell.geometryCounts & 0x0F;

	for (int i=0; i < tri_count; i++) {
		Vector3 v1, v2, v3;
		Color c1, c2, c3;
		find_vert(regularVertexData[tag][cell.vertexIndex[i*3]]	   , v, d, c, &v1, &c1);
		find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 1]], v, d, c, &v2, &c2);
		find_vert(regularVertexData[tag][cell.vertexIndex[i*3 + 2]], v, d, c, &v3, &c3);

		st->add_color(c3);
		st->add_vertex(v3);

		st->add_color(c2);
		st->add_vertex(v2);

		st->add_color(c1);
		st->add_vertex(v1);
	}
}

Vector3 MarchingCubes::vector_abs(Vector3 v) {
	return Vector3(abs(v.x), abs(v.y), abs(v.z));
}

void MarchingCubes::find_vert(int edge_index, Vector3 v[8], float d[8], Color c[8], Vector3 *vec, Color *col) {
	float d1, d2;
	Vector3 v1, v2;
	Color c1, c2;

	switch(edge_index & 0xFF) {
		case 0x01:
			d1 = d[0b001] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[1];
			c1 = c[0];
			c2 = c[1];
			break;
		case 0x02:
			d1 = d[0b100] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[4];
			c1 = c[0];
			c2 = c[4];
			break;
		case 0x04:
			d1 = d[0b010] - THRESHOLD;
			d2 = d[0b000] - THRESHOLD;
			v1 = v[0];
			v2 = v[2];
			c1 = c[0];
			c2 = c[2];
			break;
		case 0x13:
			d1 = d[0b101] - THRESHOLD;
			d2 = d[0b001] - THRESHOLD;
			v1 = v[1];
			v2 = v[5];
			c1 = c[1];
			c2 = c[5];
			break;
		case 0x15:
			d1 = d[0b011] - THRESHOLD;
			d2 = d[0b001] - THRESHOLD;
			v1 = v[1];
			v2 = v[3];
			c1 = c[1];
			c2 = c[3];
			break;
		case 0x23:
			d1 = d[0b101] - THRESHOLD;
			d2 = d[0b100] - THRESHOLD;
			v1 = v[4];
			v2 = v[5];
			c1 = c[4];
			c2 = c[5];
			break;
		case 0x26:
			d1 = d[0b110] - THRESHOLD;
			d2 = d[0b100] - THRESHOLD;
			v1 = v[4];
			v2 = v[6];
			c1 = c[4];
			c2 = c[6];
			break;
		case 0x37:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b101] - THRESHOLD;
			v1 = v[5];
			v2 = v[7];
			c1 = c[5];
			c2 = c[7];
			break;
		case 0x45:
			d1 = d[0b011] - THRESHOLD;
			d2 = d[0b010] - THRESHOLD;
			v1 = v[2];
			v2 = v[3];
			c1 = c[2];
			c2 = c[3];
			break;
		case 0x46:
			d1 = d[0b110] - THRESHOLD;
			d2 = d[0b010] - THRESHOLD;
			v1 = v[2];
			v2 = v[6];
			c1 = c[2];
			c2 = c[6];
			break;
		case 0x57:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b011] - THRESHOLD;
			v1 = v[3];
			v2 = v[7];
			c1 = c[3];
			c2 = c[7];
			break;
		case 0x67:
			d1 = d[0b111] - THRESHOLD;
			d2 = d[0b110] - THRESHOLD;
			v1 = v[6];
			v2 = v[7];
			c1 = c[6];
			c2 = c[7];
			break;
	}

	*vec = v1.linear_interpolate(v2, d2/(d2 - d1));
	*col = c1.linear_interpolate(c2, d2/(d2 - d1));
}