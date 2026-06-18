shader_type canvas_item;

uniform vec4 background_color : source_color = vec4(0.03, 0.03, 0.07, 1.0);
uniform vec4 nebula_color1 : source_color = vec4(0.2, 0.05, 0.4, 0.4);
uniform vec4 nebula_color2 : source_color = vec4(0.05, 0.3, 0.4, 0.3);

uniform float star_density : hint_range(1.0, 100.0) = 40.0;
uniform float nebula_scale : hint_range(0.1, 5.0) = 1.0;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.5;

// Pseudo-random number generator
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Simple 2D Value Noise for the nebula gradient layers
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion to blend the nebula fields together
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	
	// --- 1. Nebula Background Layer ---
	vec2 nebula_uv = uv * nebula_scale + vec2(TIME * 0.005, TIME * 0.002);
	float n1 = fbm(nebula_uv);
	float n2 = fbm(nebula_uv + vec2(5.2, 1.3));
	
	vec4 final_color = background_color;
	final_color = mix(final_color, nebula_color1, n1 * nebula_color1.a);
	final_color = mix(final_color, nebula_color2, n2 * nebula_color2.a);
	
	// --- 2. Procedural Star Grid Layer ---
	vec2 star_uv = uv * star_density;
	vec2 id = floor(star_uv);
	vec2 local_uv = fract(star_uv) - 0.5;
	
	// Calculate a random offset for the star inside its grid cell
	float h = hash(id);
	
	// Only draw a star if the random value passes a threshold (density filter)
	if (h > 0.9) {
		// Shift position away from exact grid center
		vec2 star_pos = vec2(hash(id + 1.1), hash(id + 2.4)) - 0.5;
		star_pos *= 0.6; // Keep within grid boundary limits
		
		float dist = length(local_uv - star_pos);
		
		// Use time variable to create varying sine waves for twinkling
		float twinkle = sin(TIME * twinkle_speed + h * 600.28) * 0.4 + 0.6;
		
		// Adjust core brightness based on the grid unit hash index
		float star_size = 0.1 + (h * 0.1); 
		float star_glow = smoothstep(star_size, 0.0, dist) * twinkle;
		
		// Blend the white star element onto the background color field
		final_color += vec4(vec3(clamp(star_glow, 0.0, 1.0)), 0.0);
	}
	
	COLOR = final_color;
}