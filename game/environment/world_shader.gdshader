shader_type canvas_item;

uniform sampler2D cloud_texture : repeat_enable;
uniform vec2 target_resolution = vec2(160,90);
uniform vec4 cloud_color : source_color = vec4(0,0,0,0.05);
uniform vec4 dust_color : source_color = vec4(0,0,0,0.05);

float cloud_strength_function(vec2 uv)
{
	float a = step(texture(cloud_texture, uv + vec2(0.02, 0.01) * TIME).r, 0.4);
	float b = step(texture(cloud_texture, 2.0 * uv + vec2(0.005, 0.0025) * TIME).r, 0.1);
	return max(a,b);
}

float dust_strength_function(vec2 uv)
{
	float a = smoothstep(0.5, 0.7, texture(cloud_texture,vec2(0.04, 1) * uv + vec2(0.02, 0.01) * TIME).r);
	float mask = clamp(texture(cloud_texture, vec2(0.2, 0.1) * uv + vec2(0.002, 0.008) * TIME).r - 0.3, 0.0, 1.0);
	return a * mask;
}

vec2 quantize_screen_uv(vec2 uv)
{
	return round(uv * target_resolution) / target_resolution;
}


void fragment() {
	vec2 uv = quantize_screen_uv(UV);
	vec4 color = vec4(0,0,0,0);
	float cloud = cloud_strength_function(uv);
	
	color += cloud * cloud_color;
	
	color += dust_strength_function(uv) * (1.0 - 0.2 * cloud) * dust_color;
	
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
