shader_type spatial;
// Painted-looking terrain: grass / moss / dirt paths / paving / fields / rock on slopes,
// with normal maps for surface detail.

uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D floor_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D floor_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D stone_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mask_tex : filter_linear;            // R = path, G = paving, B = field
uniform sampler2D variation_tex : filter_linear, repeat_enable;
uniform float map_size = 280.0;
// linear multipliers applied to the texture colors
uniform vec3 grass_tint = vec3(1.0);
uniform vec3 grass_tint2 = vec3(1.0);
uniform vec3 floor_tint = vec3(1.0);
uniform vec3 dirt_tint = vec3(1.0);
uniform vec3 rock_tint = vec3(1.0);
uniform vec3 stone_tint = vec3(1.0);
uniform vec3 field_tint = vec3(1.0);
uniform float floor_amount = 0.7;
uniform float field_saturation = 1.0;   // low values turn the field layer into pale sand
uniform float saturation = 1.2;
uniform float normal_strength = 0.8;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	TANGENT = vec3(1.0, 0.0, 0.0);
	BINORMAL = vec3(0.0, 0.0, 1.0);
}

void fragment() {
	vec2 uv = wpos.xz;
	vec4 m = texture(mask_tex, uv / map_size + 0.5);
	float v = texture(variation_tex, uv * 0.010).r;
	float v2 = texture(variation_tex, uv * 0.045 + vec2(0.31, 0.77)).r;

	vec2 g_uv = uv * 0.22;
	vec2 f_uv = uv * 0.16;
	vec2 d_uv = uv * 0.28;
	vec2 s_uv = uv * 0.33;

	vec3 grass = texture(grass_tex, g_uv).rgb * mix(grass_tint, grass_tint2, smoothstep(0.35, 0.65, v));
	vec3 flo = texture(floor_tex, f_uv).rgb * floor_tint;
	float fw = smoothstep(0.55, 0.78, v2) * floor_amount;
	vec3 col = mix(grass, flo, fw);
	vec3 nm = mix(texture(grass_n, g_uv).rgb, texture(floor_n, f_uv).rgb, fw);

	vec3 dirt = texture(dirt_tex, d_uv).rgb * dirt_tint;
	float pm = smoothstep(0.35, 0.65, m.r + (v2 - 0.5) * 0.4);
	col = mix(col, dirt, pm);
	nm = mix(nm, texture(dirt_n, d_uv).rgb, pm);

	float sw = smoothstep(0.4, 0.6, m.g);
	vec3 stone = texture(stone_tex, s_uv).rgb * stone_tint;
	col = mix(col, stone, sw);
	nm = mix(nm, texture(stone_n, s_uv).rgb, sw);

	float bw = smoothstep(0.4, 0.6, m.b);
	vec3 fraw = texture(dirt_tex, uv * 0.2).rgb;
	vec3 field = mix(vec3(dot(fraw, vec3(0.299, 0.587, 0.114))), fraw, field_saturation) * field_tint;
	col = mix(col, field, bw);
	nm = mix(nm, texture(dirt_n, uv * 0.2).rgb, bw);

	float slope = 1.0 - clamp(normalize(wnorm).y, 0.0, 1.0);
	float rw = smoothstep(0.22, 0.42, slope);
	vec3 rock = texture(rock_tex, vec2(wpos.x + wpos.z, wpos.y) * 0.12).rgb * rock_tint;
	col = mix(col, rock, rw);
	nm = mix(nm, vec3(0.5, 0.5, 1.0), rw);

	float l = dot(col, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(l), col, saturation);
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = 1.0;
	SPECULAR = 0.08;
}
