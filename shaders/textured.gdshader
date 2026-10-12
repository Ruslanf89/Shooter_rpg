shader_type spatial;
// World-space triplanar texture with color grading and optional triplanar normal map.
// Used for buildings, rocks, props.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float normal_strength = 0.0;     // 0 = no normal map
uniform vec3 tint = vec3(1.0);          // linear multiplier
uniform float tint_mix = 0.0;            // 0 = texture colors * tint, 1 = texture brightness * tint
uniform float brightness = 1.0;
uniform float uv_scale = 0.5;            // texture repeats per meter
uniform float saturation = 1.15;
uniform float roughness = 0.9;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wnorm);
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	vec3 p = wpos * uv_scale;
	vec3 c = texture(albedo_tex, p.zy).rgb * w.x + texture(albedo_tex, p.xz).rgb * w.y + texture(albedo_tex, p.xy).rgb * w.z;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c * tint, vec3(l) * tint * 2.2, tint_mix);
	float l2 = dot(col, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(vec3(l2), col, saturation) * brightness;
	ROUGHNESS = roughness;
	SPECULAR = 0.2;
	if (normal_strength > 0.0) {
		// whiteout-blended triplanar normal mapping (Ben Golus)
		vec3 tx = texture(normal_tex, p.zy).xyz * 2.0 - 1.0;
		vec3 ty = texture(normal_tex, p.xz).xyz * 2.0 - 1.0;
		vec3 tz = texture(normal_tex, p.xy).xyz * 2.0 - 1.0;
		tx.xy *= normal_strength;
		ty.xy *= normal_strength;
		tz.xy *= normal_strength;
		tx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
		ty = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
		tz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
		vec3 wn = normalize(tx.zyx * w.x + ty.xzy * w.y + tz.xyz * w.z);
		NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
		// darken the grout / cracks a little using the normal map's slope
		AO = clamp(1.0 - (1.0 - abs(dot(wn, n))) * 2.0, 0.4, 1.0);
		AO_LIGHT_AFFECT = 0.3;
	}
}
