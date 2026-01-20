shader_type spatial;
//render_mode unshaded; // draw exact values, ignore lighting

// Assign this in the Inspector to a SubViewportTexture (Texture Type: Depth).
uniform vec3 water_color : source_color;
uniform vec3 wave_color : source_color;

uniform sampler2D depth_tex : filter_linear;

void vertex() {

}

void fragment() {
	float camera_depth = texture(depth_tex, UV).r;

	float waveHeight = (camera_depth - 0.5) * 2.0;

	//waveHeight = step(UV.x, camera_depth);

	ALBEDO = mix(water_color, wave_color, camera_depth);
	//ALBEDO = vec3(camera_depth);
}