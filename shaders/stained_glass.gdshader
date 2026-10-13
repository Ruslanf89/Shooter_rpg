shader_type spatial;
render_mode cull_disabled;
// Stained glass that glows when seen from inside its church (daylight shining through) and looks
// dark and glossy from outside, as real stained glass does by day.

uniform sampler2D glass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform mat4 to_local;                 // world -> church-local
uniform vec4 nave = vec4(9.0, -1.6, -50.8, 0.0);      // |x| <, z <, z >
uniform vec4 transept = vec4(18.5, -31.6, -40.8, 0.0);
uniform float inside_glow = 1.35;
uniform float outside_glow = 0.12;

void fragment() {
	vec3 c = texture(glass_tex, UV).rgb;
	vec3 cam = (to_local * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	bool inside = (abs(cam.x) < nave.x && cam.z < nave.y && cam.z > nave.z)
		|| (abs(cam.x) < transept.x && cam.z < transept.y && cam.z > transept.z);
	if (inside) {
		ALBEDO = c;
		EMISSION = c * inside_glow;
		ROUGHNESS = 0.5;
		SPECULAR = 0.2;
	} else {
		ALBEDO = c * 0.35;
		EMISSION = c * outside_glow;
		ROUGHNESS = 0.08;
		METALLIC = 0.3;
		SPECULAR = 0.8;
	}
}
