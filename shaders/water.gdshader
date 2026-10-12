shader_type spatial;
render_mode cull_disabled, depth_draw_always, specular_schlick_ggx;
// Realistic water: depth-based color and clarity, refraction of the lake bed, moving wave
// normals, shoreline foam, fresnel reflection of the sky.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 deep_color : source_color = vec3(0.04, 0.16, 0.22);
uniform vec3 shallow_color : source_color = vec3(0.25, 0.5, 0.5);
uniform float clarity = 1.6;          // meters of water before it gets murky
uniform float foam_width = 0.5;
uniform float wave_strength = 1.3;
uniform float emission_strength = 0.0;   // > 0 for lava

varying vec3 wpos;

float height(vec2 p, float t) {
	return texture(noise_tex, p * 0.045 + t * vec2(0.012, 0.007)).r * 0.6
		+ texture(noise_tex, p * 0.11 - t * vec2(0.009, 0.015)).r * 0.4;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wpos.x * 0.35 + TIME * 1.1) * 0.03 + cos(wpos.z * 0.45 + TIME * 0.8) * 0.03;
}

void fragment() {
	vec2 p = wpos.xz;
	float e = 0.25;
	float h = height(p, TIME);
	float hx = height(p + vec2(e, 0.0), TIME);
	float hz = height(p + vec2(0.0, e), TIME);
	vec3 n_world = normalize(vec3((h - hx) * wave_strength, 1.0, (h - hz) * wave_strength));
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);

	// how much water is between the surface and what's behind it
	float raw = texture(depth_tex, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, raw, 1.0);
	vec4 view = INV_PROJECTION_MATRIX * ndc;
	view.xyz /= view.w;
	float thickness = max(0.0, -view.z + VERTEX.z);

	vec2 off = n_world.xz * 0.035 * clamp(thickness, 0.0, 1.0);
	vec3 bed = texture(screen_tex, SCREEN_UV + off).rgb;
	float t = exp(-thickness / clarity);
	vec3 water = mix(deep_color, shallow_color, t);
	vec3 col = mix(water, bed * mix(vec3(1.0), shallow_color * 1.6, 0.5), t * 0.85);

	float foam_noise = texture(noise_tex, p * 0.35 + TIME * 0.03).r;
	float foam = smoothstep(foam_width, 0.0, thickness) * smoothstep(0.35, 0.7, foam_noise + 0.25);
	col = mix(col, vec3(0.92, 0.95, 0.95), foam * 0.85);

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = col * (1.0 - fresnel * 0.6);
	if (emission_strength > 0.0) {
		float crust = smoothstep(0.45, 0.7, h);
		ALBEDO = mix(shallow_color, vec3(0.08, 0.03, 0.02), crust);
		EMISSION = mix(shallow_color, deep_color * 0.3, crust) * emission_strength;
	}
	ROUGHNESS = mix(0.04, 0.6, foam);
	METALLIC = 0.0;
	SPECULAR = 0.65;
	ALPHA = 1.0;
}
