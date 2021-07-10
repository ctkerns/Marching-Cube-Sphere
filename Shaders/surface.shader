shader_type spatial;

const float epsilon = 0.000001;

varying vec3 local_vertex;
varying vec3 local_normal;

// This will be used as an index for materials.
varying flat vec2 uv;

uniform sampler2D materials: hint_albedo;
uniform sampler2D coverings: hint_albedo;

uniform vec4 color1: hint_color;
uniform vec4 color2: hint_color;

void vertex() {
	local_vertex = VERTEX;
	local_normal = NORMAL;
	uv = UV;
}

void fragment() {
	// Select colors.
	vec3 material_color = texture(materials, vec2(uv.x, 0.5)).rgb;
	vec3 covering_color = texture(coverings, vec2(uv.y, 0.5)).rgb;
	
	// Determine how much this fragment is facing up.
	float mag = dot(normalize(local_vertex), local_normal);
	mag = (mag + 1.0)/2.0;
	
	// Decide whether this is the top of the terrain or not.
	if (mag > 0.7 && uv.y < 1.0)
		ALBEDO = covering_color;
	else
		ALBEDO = material_color;
}

const float PI = 3.1415926536f;

void light() {
	// Lighting.
	// Cel shading modified from https://godotshaders.com/shader/flexible-toon-shader/
	float NdotL = dot(NORMAL, LIGHT);
	float attenuation = ATTENUATION.x;

	// Split the attenuation.
	if (attenuation < 0.1)
		attenuation = 0.0;
	else
		attenuation = 1.0;

	float diffuse_amount = NdotL + (attenuation - 1.0);
	float cuts = 6.0;
	float diffuse_stepped = clamp(diffuse_amount + mod(1.0f - diffuse_amount, 1.0/cuts), 0.0f, 1.0f);

	vec3 diffuse = ALBEDO.rgb*LIGHT_COLOR/PI;
	diffuse *= diffuse_stepped;
	DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
}