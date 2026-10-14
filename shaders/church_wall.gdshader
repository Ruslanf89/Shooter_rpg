shader_type spatial;
// Church walls: one texture outside (brick) and another inside (stone), chosen by whether the point
// lies in one of the church's rooms (boxes in church-local space). Otherwise it works like
// textured.gdshader: world-space triplanar texture and normal map, colour grading.

uniform sampler2D out_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D out_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 out_tint = vec3(1.0);
uniform float out_scale = 0.9;             // texture repeats per metre
uniform sampler2D in_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D in_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 in_tint = vec3(1.0);
uniform float in_scale = 0.25;
uniform float normal_strength = 1.0;
uniform float brightness = 0.95;
uniform float saturation = 1.15;
uniform mat4 to_local;                     // world -> church-local
// rooms: half width (|x| <), z <, z >, top (y <)
uniform vec4 nave = vec4(4.6, -1.6, -50.8, 18.0);
uniform vec4 aisles = vec4(9.0, -1.6, -50.8, 11.3);
uniform vec4 transept = vec4(18.5, -31.6, -40.8, 18.0);

varying vec3 wpos;
varying vec3 wnorm;

bool in_room(vec3 p, vec4 b) {
	return abs(p.x) < b.x + 0.05 && p.z < b.y + 0.05 && p.z > b.z - 0.05 && p.y < b.w;
}

vec3 tri_col(sampler2D t, vec3 p, vec3 w) {
	return texture(t, p.zy).rgb * w.x + texture(t, p.xz).rgb * w.y + texture(t, p.xy).rgb * w.z;
}

// whiteout-blended triplanar normal (Ben Golus), world space
vec3 tri_nrm(sampler2D t, vec3 p, vec3 w, vec3 n) {
	vec3 tx = texture(t, p.zy).xyz * 2.0 - 1.0;
	vec3 ty = texture(t, p.xz).xyz * 2.0 - 1.0;
	vec3 tz = texture(t, p.xy).xyz * 2.0 - 1.0;
	tx.xy *= normal_strength;
	ty.xy *= normal_strength;
	tz.xy *= normal_strength;
	tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	return normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wnorm);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 lp = (to_local * vec4(wpos, 1.0)).xyz;
	float inside = (in_room(lp, nave) || in_room(lp, aisles) || in_room(lp, transept)) ? 1.0 : 0.0;
	// both are sampled so the texture filtering stays smooth where they meet
	vec3 ci = tri_col(in_tex, wpos * in_scale, w) * in_tint;
	vec3 co = tri_col(out_tex, wpos * out_scale, w) * out_tint;
	vec3 ni = tri_nrm(in_normal, wpos * in_scale, w, n);
	vec3 no = tri_nrm(out_normal, wpos * out_scale, w, n);
	vec3 col = mix(co, ci, inside);
	vec3 wn = normalize(mix(no, ni, inside));
	float l = dot(col, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(l), col, saturation) * brightness;
	ROUGHNESS = mix(0.85, 0.9, inside);
	SPECULAR = 0.2;
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	AO = clamp(1.0 - (1.0 - abs(dot(wn, n))) * 2.0, 0.4, 1.0);
	AO_LIGHT_AFFECT = 0.3;
}
