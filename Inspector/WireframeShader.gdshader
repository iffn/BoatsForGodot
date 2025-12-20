// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode unshaded, cull_disabled, wireframe;

uniform vec4 albedo : source_color;

uniform float outline_width : hint_range(0.0, 10.0, 0.1) = 3.0;

void vertex() {
	
}

void fragment() {
	ALBEDO = albedo.rgb;
}
