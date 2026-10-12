shader_type spatial;
render_mode cull_disabled;
// Grass / wheat tufts drawn with MultiMesh. Lit like flat ground so they blend with the terrain.

uniform vec3 base_color : source_color = vec3(0.2, 0.35, 0.08);
uniform vec3 tip_color : source_color = vec3(0.55, 0.65, 0.2);
uniform float blade_height = 0.6;
uniform float wind_strength = 0.12;

varying float h;

void vertex() {
	h = clamp(VERTEX.y / blade_height, 0.0, 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = (sin(TIME * 1.8 + wp.x * 0.35 + wp.z * 0.22) + sin(TIME * 3.1 + wp.x * 0.9) * 0.3) * wind_strength * h * h;
	VERTEX.x += w;
	VERTEX.z += w * 0.5;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	ALBEDO = mix(base_color, tip_color, h) * COLOR.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = vec3(0.15);
}
