// Based on: https://github.com/godotengine/godot-demo-projects/blob/master/compute/texture/water_plane/water_shader.gdshader

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float height = 10.0;
uniform sampler2D heightmap : filter_linear;

uniform vec3 albedo : source_color;
uniform float metalic : hint_range(0.0, 1.0, 0.1) = 0.8;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 0.2;
uniform sampler2D depth_tex : filter_linear;
uniform vec2 effect_texture_size;

uniform float normal_strength : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float sample_distance : hint_range(1.0, 5.0, 0.1) = 1.0;
uniform float smoothness : hint_range(0.0, 3.0, 0.1) = 1.0; // NEW

varying vec2 uv_tangent;
varying vec2 uv_binormal;

// Smooth depth sampling with blur
float sample_depth_smooth(vec2 uv, vec2 pixel_size) {
	float sum = 0.0;
	float weight_sum = 0.0;
	
	// 3x3 gaussian-like blur
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * pixel_size * smoothness;
			float weight = 1.0 / (1.0 + float(x*x + y*y));
			sum += texture(depth_tex, uv + offset).r * weight;
			weight_sum += weight;
		}
	}
	
	return sum / weight_sum;
}

void vertex() {
	vec2 pixel_size = (vec2(1.0, 1.0) / effect_texture_size) * sample_distance;
	uv_tangent = UV + vec2(pixel_size.x, 0.0);
	uv_binormal = UV + vec2(0.0, pixel_size.y);
	
	VERTEX.z = texture(heightmap, UV).r * height;
}

void fragment() {
	vec2 pixel_size = vec2(1.0, 1.0) / effect_texture_size;
	
	// Use smoothed depth samples
	float f1 = sample_depth_smooth(UV, pixel_size);
	float f2 = sample_depth_smooth(uv_tangent, pixel_size);
	float f3 = sample_depth_smooth(uv_binormal, pixel_size);
	
	float diff_x = (f2 - f1) * normal_strength;
	float diff_y = (f3 - f1) * normal_strength;
	
	vec3 tangent = normalize(vec3(1.0, 0.0, diff_x));
	vec3 binormal = normalize(vec3(0.0, 1.0, diff_y));
	
	NORMAL_MAP = normalize(cross(binormal, tangent)) * 0.5 + 0.5;
	ALBEDO = albedo.rgb;
	METALLIC = metalic;
	ROUGHNESS = roughness;
	SPECULAR = 0.5;
}