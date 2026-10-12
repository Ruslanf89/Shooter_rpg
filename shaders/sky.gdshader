shader_type sky;
// Painted sky: gradient, soft drifting clouds (domain-warped noise), sun, moon and stars.

uniform vec3 top_color : source_color = vec3(0.25, 0.45, 0.85);
uniform vec3 horizon_color : source_color = vec3(0.75, 0.82, 0.92);
uniform vec3 ground_color : source_color = vec3(0.3, 0.33, 0.3);
uniform vec3 sun_glow : source_color = vec3(1.0, 0.85, 0.6);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 cloud_shadow : source_color = vec3(0.62, 0.66, 0.78);
uniform float cloud_cover = 0.5;
uniform float sun_size = 900.0;
uniform float night = 0.0;            // 0 day .. 1 full night (stars, moon)
uniform vec3 moon_dir = vec3(0.3, 0.6, -0.7);
uniform vec2 wind = vec2(0.006, 0.0025);

// integer hash: no precision blocks at large coordinates
float hash2(vec2 p) {
	uvec2 q = uvec2(ivec2(floor(p)) + ivec2(50000));
	q = q * uvec2(1597334673u, 3812015801u);
	uint n = (q.x ^ q.y) * 1597334673u;
	return float(n) * (1.0 / 4294967295.0);
}

float hash3(vec3 p) {
	uvec3 q = uvec3(ivec3(floor(p)) + ivec3(50000));
	q = q * uvec3(1597334673u, 3812015801u, 2798796415u);
	uint n = (q.x ^ q.y ^ q.z) * 1597334673u;
	return float(n) * (1.0 / 4294967295.0);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);   // quintic: no visible grid
	float a = hash2(i);
	float b = hash2(i + vec2(1.0, 0.0));
	float c = hash2(i + vec2(0.0, 1.0));
	float d = hash2(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

const mat2 ROT = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 6; i++) {
		v += a * vnoise(p);
		p = ROT * p * 2.02 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(0.0, 0.55, h));
	if (h < 0.0) {
		col = mix(horizon_color, ground_color, smoothstep(0.0, -0.25, h));
	}
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += sun_glow * (pow(sd, 8.0) * 0.25 + pow(sd, 60.0) * 0.4);
	col = mix(col, sun_glow * 4.0, smoothstep(1.0 - 1.0 / sun_size, 1.0 - 0.5 / sun_size, sd));

	float c = 0.0;
	if (h > 0.0) {
		// clouds on a curved dome, warped so they look soft and billowy
		vec2 uv = d.xz / (h + 0.18) * 1.1 + TIME * wind;
		vec2 warp = vec2(fbm(uv * 0.7 + vec2(3.1, 1.7)), fbm(uv * 0.7 + vec2(8.3, 2.8)));
		float n = fbm(uv + warp * 0.9);
		c = smoothstep(1.0 - cloud_cover, 1.0 - cloud_cover + 0.32, n);
		float shade = fbm(uv + warp * 0.9 + vec2(0.06, 0.04));
		vec3 cc = mix(cloud_color, cloud_shadow, smoothstep(0.3, 0.8, shade * 0.6 + (1.0 - n) * 0.6));
		cc += sun_glow * pow(sd, 6.0) * 0.45;
		col = mix(col, cc, c * smoothstep(0.0, 0.16, h));
	}
	// stars: cells on the sphere (no stretching near the horizon)
	if (night > 0.01 && h > 0.0) {
		vec3 sp = d * 220.0;
		float st = hash3(sp);
		vec3 cell = fract(sp) - 0.5;
		float dot_ = smoothstep(0.32, 0.0, length(cell));
		float tw = 0.65 + 0.35 * sin(TIME * 2.5 + st * 80.0);
		float star = step(0.9975, st) * dot_ * tw * (1.0 - c) * smoothstep(0.02, 0.2, h);
		col += vec3(0.85, 0.9, 1.0) * star * night * 2.2;
	}
	// moon disc + glow
	if (night > 0.01) {
		float md = max(dot(d, normalize(moon_dir)), 0.0);
		col += vec3(0.55, 0.62, 0.8) * pow(md, 30.0) * 0.25 * night;
		float disc = smoothstep(0.99955, 0.9997, md);
		float craters = 0.85 + 0.15 * vnoise(d.xy * 900.0);
		col = mix(col, vec3(0.92, 0.93, 0.88) * craters, disc * night * (1.0 - c * 0.7));
	}
	COLOR = col;
}
