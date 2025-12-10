shader_type spatial;

// Settings
uniform float depth_distance : hint_range(0.0, 20.0, 0.0) = 4.0;
uniform float beers_law : hint_range(0.0, 20.0, 0.0) = 12.0;
uniform float wave_height : hint_range(0.0, 20.0, 0.0) = 0.1;
uniform float wave_frequency : hint_range(0.0, 20.0, 0.0) = 5;
uniform float wave_length : hint_range(0.0, 20.0, 0.0) = 5;

uniform vec3 water_color_surface : source_color;
uniform vec3 water_color_depth : source_color;
uniform vec4 foam_color : source_color;

// Built in, no need to assign
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;

// Carry over
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += wave_height * sin(world_position.x / wave_length + TIME * wave_frequency);
}

float water_depth_blend(
		float depth_raw,
		vec2 screen_uv,
		mat4 inv_view_matrix,
		mat4 inv_projection_matrix,
		vec3 local_vertex_position)
{
	// based on https://www.youtube.com/watch?v=ib2atnKTLrs
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth_raw);
	vec4 world = inv_view_matrix * inv_projection_matrix * vec4(ndc, 1.0);
	float depth_texture_y = world.y / world.w;
	float vertex_y = (inv_view_matrix * vec4(local_vertex_position, 1.0)).y;

	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);

	return depth_blend;
}

void fragment() {
	// Based on https://www.youtube.com/watch?v=DIE3qfCGXl8

	// UVs from distortion
	vec3 noise_sample = vec3(world_position.x * 10.0, TIME * 0.5, world_position.z * 10.0);
	float noise = 0.5; // perlinNoise3D01(noise_sample); // Note: 3D noise calculation kinda bad for performance
	vec2 distorted_uvs = SCREEN_UV + 0.002 * vec2(noise);
	distorted_uvs = clamp(distorted_uvs, 0.0, 1.0);

	// Depth
	float depth_raw = texture(depth_texture, distorted_uvs).r;
	float depth_blend = water_depth_blend(depth_raw, distorted_uvs, INV_VIEW_MATRIX, INV_PROJECTION_MATRIX, VERTEX);

	// General water color
	vec3 screen_distorted = texture(screen_texture, distorted_uvs).rgb;
	vec3 surface_color = mix(screen_distorted, water_color_surface, 0.5);
	vec3 water_color = mix(water_color_depth, surface_color, depth_blend);

	// Edge foam
	float edge = step(0.9, depth_blend + noise * 0.1);
	water_color = mix(water_color, foam_color.rgb, edge * foam_color.a);

	// Apply
    ALBEDO = vec3(water_color);
}