shader_type spatial;
render_mode unshaded, cull_disabled, wireframe;

uniform vec4 albedo : source_color;
// Renamed to 'offset' for clarity, though it works for outlines too
uniform float normal_offset : hint_range(0.0, 1.0, 0.01) = 0.1; 

void vertex() {
	// Add the normal vector (scaled by width) to the vertex position
	VERTEX += NORMAL * normal_offset;
}

void fragment() {
	ALBEDO = albedo.rgb;
}