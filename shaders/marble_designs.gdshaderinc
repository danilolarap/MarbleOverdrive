// Marble finishes shared by the 3D marble (marble.gdshader) and every 2D preview
// (marble_badge.gdshader), so a workshop icon shows exactly what races.
// All designs are computed from the unit object-space direction `o`, which keeps
// them seamless on the sphere and lets them roll with the marble.
// Index order must match GameCatalog.PATTERNS.
// 0 SOLID  1 STRIPES  2 DUAL  3 RINGS  4 CHECKER  5 LIGHTNING
// 6 GALAXY 7 HEX      8 LAVA  9 GEM   10 CATSEYE 11 CARBON

const float MD_PI = 3.14159265;
const float MD_TAU = 6.2831853;
const int MD_GEM = 9;

float md_hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec3 md_hash33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float md_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(md_hash13(i), md_hash13(i + vec3(1.0, 0.0, 0.0)), f.x), mix(md_hash13(i + vec3(0.0, 1.0, 0.0)), md_hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(md_hash13(i + vec3(0.0, 0.0, 1.0)), md_hash13(i + vec3(1.0, 0.0, 1.0)), f.x), mix(md_hash13(i + vec3(0.0, 1.0, 1.0)), md_hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}

float md_fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * md_noise(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		amplitude *= 0.5;
	}
	return value;
}

// Distances to the nearest and second-nearest cell points (F1, F2).
vec2 md_voronoi(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float f1 = 8.0;
	float f2 = 8.0;
	for (int z = -1; z <= 1; z++) {
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 g = vec3(float(x), float(y), float(z));
				vec3 r = g + md_hash33(i + g) - f;
				float d = dot(r, r);
				if (d < f1) {
					f2 = f1;
					f1 = d;
				} else if (d < f2) {
					f2 = d;
				}
			}
		}
	}
	return sqrt(vec2(f1, f2));
}

// Longitude/latitude; horizontal frequencies are whole numbers so nothing breaks at the seam.
vec2 md_uv(vec3 o) {
	return vec2(atan(o.x, o.z) / MD_TAU + 0.5, acos(clamp(o.y, -1.0, 1.0)) / MD_PI);
}

// Flat-topped hexagon lattice: returns the distance to the cell edge and the cell centre.
float md_hex(vec2 p, out vec2 cell) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(p, r) - h;
	vec2 b = mod(p - h, r) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	cell = p - g;
	vec2 q = abs(g);
	return 0.5 - max(dot(q, normalize(r)), q.x);
}

// Nearest of 24 evenly spread directions: the faces of the gem.
vec3 md_facet(vec3 o, out float edge) {
	float best = -2.0;
	float second = -2.0;
	vec3 face = o;
	for (int i = 0; i < 24; i++) {
		float y = 1.0 - (float(i) + 0.5) * 2.0 / 24.0;
		float ring = sqrt(1.0 - y * y);
		float angle = float(i) * 2.3999632;
		vec3 d = vec3(cos(angle) * ring, y, sin(angle) * ring);
		float k = dot(o, d);
		if (k > best) {
			second = best;
			best = k;
			face = d;
		} else if (k > second) {
			second = k;
		}
	}
	edge = best - second;
	return face;
}

float md_circuit(vec2 uv) {
	return smoothstep(0.72, 0.8, sin(uv.x * MD_TAU * 9.0 + sin(uv.y * 28.0) * 4.0));
}

float md_carbon(vec2 uv) {
	vec2 p = vec2(uv.x * 36.0, uv.y * 18.0);
	vec2 c = floor(p);
	vec2 f = fract(p);
	bool across = mod(c.x + c.y, 2.0) > 0.5;
	float weave = sin((across ? f.y : f.x) * MD_PI);
	float fibre = 0.85 + 0.15 * sin((across ? f.x : f.y) * MD_PI * 6.0);
	return weave * fibre;
}

// Patterns built on longitude/latitude fade out near the poles, where cells pinch.
float md_pole(vec3 o) {
	return 1.0 - smoothstep(0.9, 0.98, abs(o.y));
}

// Relief height (0 = groove, 1 = raised).
float design_height(int d, vec3 o) {
	vec2 uv = md_uv(o);
	if (d == 1) {
		float f = fract(uv.x * 10.0 + uv.y * 3.0);
		return smoothstep(0.5, 0.56, f) * (1.0 - smoothstep(0.94, 1.0, f)) * md_pole(o);
	}
	if (d == 2) {
		return 1.0 - exp(-abs(o.x) * 26.0);
	}
	if (d == 3) {
		float f = fract(uv.y * 9.0);
		return smoothstep(0.58, 0.64, f) * (1.0 - smoothstep(0.94, 1.0, f));
	}
	if (d == 4) {
		vec2 c = vec2(uv.x * 12.0, uv.y * 8.0);
		vec2 f = fract(c);
		float e = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		float raised = mod(floor(c.x) + floor(c.y), 2.0);
		return smoothstep(0.0, 0.1, e) * (0.45 + 0.55 * raised) * md_pole(o);
	}
	if (d == 5) {
		return 1.0 - md_circuit(uv) * md_pole(o);
	}
	if (d == 7) {
		vec2 cell;
		float e = md_hex(vec2(uv.x * 14.0, uv.y * 9.0), cell);
		return sqrt(clamp(e * 2.0, 0.0, 1.0)) * md_pole(o) + (1.0 - md_pole(o));
	}
	if (d == 8) {
		vec2 v = md_voronoi(o * 3.2);
		return smoothstep(0.0, 0.12, v.y - v.x) * (0.75 + 0.25 * md_noise(o * 9.0));
	}
	if (d == 11) {
		return md_carbon(uv) * md_pole(o);
	}
	return 0.0;
}

float design_relief(int d) {
	if (d == 1 || d == 3) { return 0.6; }
	if (d == 2) { return 0.5; }
	if (d == 4) { return 0.7; }
	if (d == 5) { return 0.45; }
	if (d == 7) { return 1.1; }
	if (d == 8) { return 1.2; }
	if (d == 11) { return 0.8; }
	return 0.0;
}

// Object-space shading normal: bumped from the relief, or the flat face for the gem.
vec3 design_normal(int d, vec3 o) {
	if (d == MD_GEM) {
		float edge;
		return md_facet(o, edge);
	}
	float strength = design_relief(d);
	if (strength <= 0.0) {
		return o;
	}
	vec3 up = abs(o.y) > 0.95 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 t1 = normalize(cross(up, o));
	vec3 t2 = cross(o, t1);
	float e = 0.004;
	float h0 = design_height(d, o);
	float h1 = design_height(d, normalize(o + t1 * e));
	float h2 = design_height(d, normalize(o + t2 * e));
	return normalize(o - (t1 * (h1 - h0) + t2 * (h2 - h0)) / e * strength * 0.012);
}

// The gem's real faceted silhouette: vertices pushed out to the plane of their face.
vec3 design_vertex(int d, vec3 vertex) {
	if (d != MD_GEM) {
		return vertex;
	}
	float edge;
	vec3 o = normalize(vertex);
	vec3 face = md_facet(o, edge);
	return o * length(vertex) * 0.9 / max(dot(o, face), 0.85);
}

void design_surface(int d, vec3 o, vec3 c1, vec3 c2, float t, out vec3 albedo, out vec3 emission, out float metallic, out float roughness) {
	vec2 uv = md_uv(o);
	float pole = md_pole(o);
	albedo = c1;
	emission = vec3(0.0);
	metallic = 0.45;
	roughness = 0.25;
	if (d == 0) {
		metallic = 0.62;
		roughness = 0.1;
	} else if (d == 1) {
		albedo = mix(c1, c2, design_height(1, o));
	} else if (d == 2) {
		albedo = mix(c1, c2, step(0.0, o.x));
		albedo = mix(albedo, vec3(0.92), exp(-abs(o.x) * 26.0) * 0.7);
		metallic = 0.6;
		roughness = 0.18;
	} else if (d == 3) {
		albedo = mix(c1, c2, design_height(3, o));
	} else if (d == 4) {
		vec2 c = vec2(uv.x * 12.0, uv.y * 8.0);
		albedo = mix(c1, c2, mod(floor(c.x) + floor(c.y), 2.0) * pole);
		roughness = 0.3;
	} else if (d == 5) {
		float m = md_circuit(uv) * pole;
		albedo = mix(c1 * 0.55, c2, m);
		emission = c2 * m * (0.8 + 0.4 * sin(t * 4.0 + uv.y * 12.0));
	} else if (d == 6) {
		// Galaxy: a deep glass core with a drifting nebula band and twinkling stars.
		float n = md_fbm(o * 2.2 + vec3(0.0, t * 0.05, 0.0));
		float band = exp(-pow((o.y + (n - 0.5) * 0.9) * 2.4, 2.0));
		vec3 deep = c1 * 0.16 + vec3(0.02, 0.02, 0.06);
		albedo = mix(deep, mix(c1, c2, n) * 1.15, band * smoothstep(0.25, 0.65, n));
		vec3 cell = floor(o * 34.0);
		float seed = md_hash13(cell);
		float star = step(0.97, seed) * (1.0 - smoothstep(0.06, 0.2, length(fract(o * 34.0) - 0.5)));
		star *= 0.6 + 0.4 * sin(t * 3.0 + seed * 40.0);
		emission = albedo * (0.12 + band * 0.6) + vec3(star) * 1.6;
		metallic = 0.05;
		roughness = 0.04;
	} else if (d == 7) {
		// Hex scales: each raised cell gets its own shade, grooves stay dark.
		vec2 cell;
		float e = md_hex(vec2(uv.x * 14.0, uv.y * 9.0), cell);
		float k = md_hash13(vec3(cell, 3.7));
		vec3 scale = mix(c1, c2, k * 0.55);
		albedo = mix(c1, mix(scale, c1 * 0.18, 1.0 - smoothstep(0.02, 0.08, e)), pole);
		metallic = 0.55;
		roughness = 0.22;
	} else if (d == 8) {
		// Lava: dark crust plates split by glowing, pulsing cracks in the primary colour.
		vec2 v = md_voronoi(o * 3.2);
		float crack = 1.0 - smoothstep(0.0, 0.07, v.y - v.x);
		float heat = 0.75 + 0.25 * sin(t * 2.5 + md_noise(o * 5.0) * 6.0);
		albedo = mix(c2 * 0.1 + vec3(0.03), c1, crack);
		emission = c1 * crack * 2.4 * heat + c1 * 0.04;
		metallic = 0.0;
		roughness = 0.7;
	} else if (d == 9) {
		// Gem: every face catches light differently; edges glint in the second colour.
		float edge;
		vec3 face = md_facet(o, edge);
		float k = md_hash13(floor(face * 50.0));
		float line = 1.0 - smoothstep(0.0, 0.025, edge);
		albedo = mix(c1 * (0.6 + 0.5 * k), c2, line * 0.8);
		emission = c2 * line * 0.35 + c1 * 0.08;
		metallic = 0.25;
		roughness = 0.03;
	} else if (d == 10) {
		// Cat's eye: clear glass around a twisted coloured vane.
		float angle = atan(o.x, o.z) + o.y * 2.2;
		float vane = pow(abs(cos(angle * 1.5)), 14.0) * (1.0 - abs(o.y) * 0.4);
		albedo = mix(c2 * 0.08 + vec3(0.02, 0.03, 0.04), c1, vane);
		emission = c1 * vane * 0.45;
		metallic = 0.0;
		roughness = 0.02;
	} else if (d == 11) {
		// Carbon fibre weave with a tint of the primary colour.
		float w = md_carbon(uv) * pole;
		albedo = mix(vec3(0.05, 0.055, 0.065), mix(vec3(0.32), c1 * 0.75, 0.5), w);
		albedo = mix(albedo, c2 * 0.7, smoothstep(0.92, 1.0, w) * 0.35);
		emission = c1 * w * 0.05;
		metallic = 0.35;
		roughness = 0.32;
	}
}
