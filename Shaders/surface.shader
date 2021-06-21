shader_type spatial;

varying vec3 local_vertex;
varying vec3 local_normal;

void vertex() {
	local_vertex = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	float mag = dot(normalize(local_vertex), local_normal);
	mag = (mag + 1.0)/2.0;
	
	if (mag > 0.7)
		ALBEDO = vec3(0.255,0.459,0.102);
	else
		ALBEDO = COLOR.xyz;
}