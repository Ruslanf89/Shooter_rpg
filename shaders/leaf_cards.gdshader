shader_type spatial;
// Alpha-cut leaf / needle cards for tree crowns and bushes (textures from tools/make_leaf_cluster.ps1).
// Normals point away from the crown centre for soft, volumetric lighting; vertex colour R is baked
// ambient occlusion (darker inside the crown); each tree gets its own tint from its position.
render_mode cull_disabled;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec3 tint = vec3(1.0);
uniform vec3 tint2 = vec3(1.0);
uniform float wind = 0.12;
uniform float alpha_cut = 0.45;
uniform float snow = 0.0;

varying float ao;
varying float var_k;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = clamp(VERTEX.y * 0.09, 0.0, 1.4);
	float sway = sin(TIME * 1.1 + origin.x * 0.21 + origin.z * 0.13) * wind * h;
	float flutter = sin(TIME * 4.7 + wp.x * 1.9 + wp.y * 2.3 + wp.z * 1.3) * 0.035 * h;
	VERTEX.x += sway + flutter;
	VERTEX.z += sway * 0.6 - flutter;
	VERTEX.y += flutter * 0.5;
	ao = COLOR.r;
	var_k = fract(sin(dot(origin.xz, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(leaf_tex, UV);
	// cull_disabled flips back-face normals; undo it so the crown keeps its rounded shading
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	vec3 t = mix(tint, tint2, var_k * var_k);
	vec3 col = c.rgb * t * mix(0.32, 1.0, ao);
	if (snow > 0.0) {
		vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		col = mix(col, vec3(0.88, 0.91, 0.95), smoothstep(0.15, 0.7, wn.y) * snow * smoothstep(0.3, 0.8, ao));
	}
	ALBEDO = col;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 0.8;
	SPECULAR = 0.3;
	BACKLIGHT = col * 0.5;
}
