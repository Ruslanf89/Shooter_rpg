shader_type spatial;
// Painterly tree crowns: clumpy light/dark leaf masses that sway in the wind.

uniform sampler2D clump_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 dark_color : source_color = vec3(0.18, 0.32, 0.08);
uniform vec3 light_color : source_color = vec3(0.45, 0.6, 0.15);
uniform vec3 tip_color : source_color = vec3(0.8, 0.75, 0.25);
uniform float wind = 0.08;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	vec3 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float s = sin(TIME * 1.3 + p.x * 0.15 + p.z * 0.11) * wind * clamp(VERTEX.y * 0.15, 0.0, 1.0);
	VERTEX.x += s;
	VERTEX.z += s * 0.6;
	wpos = p;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(wnorm);
	vec3 w = pow(abs(n), vec3(3.0));
	w /= (w.x + w.y + w.z);
	vec3 p = wpos * 0.32;
	float c = texture(clump_tex, p.zy).r * w.x + texture(clump_tex, p.xz).r * w.y + texture(clump_tex, p.xy).r * w.z;
	float up = n.y * 0.5 + 0.5;
	float k = c * 0.65 + up * 0.55;
	vec3 col = mix(dark_color, light_color, smoothstep(0.35, 0.85, k));
	col = mix(col, tip_color, smoothstep(0.8, 1.1, k) * 0.7);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = col * 0.35;
}
