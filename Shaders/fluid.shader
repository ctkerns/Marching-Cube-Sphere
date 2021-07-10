shader_type spatial;

void fragment() {
	ALBEDO = vec3(0.03, 0.18, 0.25);
}

const float PI = 3.1415926536f;

void light() {
	// Cel shading modified from https://godotshaders.com/shader/flexible-toon-shader/
	// Diffuse lighting.
	float NdotL = dot(NORMAL, LIGHT);
	float attenuation = ATTENUATION.x;

	// Split the attenuation.
	if (attenuation < 0.1f)
		attenuation = 0.0f;
	else
		attenuation = 1.0f;

	float diffuse_amount = NdotL + (attenuation - 1.0f);
	float cuts = 6.0;
	float diffuse_stepped = clamp(diffuse_amount + mod(1.0f - diffuse_amount, 1.0f/cuts), 0.0f, 1.0f);

	vec3 diffuse = ALBEDO.rgb*LIGHT_COLOR/PI;
	diffuse *= diffuse_stepped;
	DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);

	// Specular lighting.
	float specular_shininess = 16.0f;
	float specular_strength = 1.0f;

	vec3 H = normalize(LIGHT + VIEW);
	float NdotH = dot(NORMAL, H);
	float specular_amount = max(pow(NdotH, pow(specular_shininess, 2.0f)), 0.0f);
	specular_amount *= attenuation;
	specular_amount = step(0.5f, specular_amount);
	SPECULAR_LIGHT += specular_strength * specular_amount * LIGHT_COLOR;

	// Rim lighting.
	float NdotV = dot(NORMAL, VIEW);
	float rim_width = 8.0f;
	float fresnel = pow(1.0f - NdotV, rim_width);
	vec4 rim_color = vec4(1.0f);
	float rim_light = step(0.5f, fresnel);
	DIFFUSE_LIGHT += rim_light * rim_color.rgb * rim_color.a * LIGHT_COLOR/PI;
	ALPHA = 0.5 + clamp(pow(fresnel, 0.125), 0.0f, 1.0f)/2.0f;
}