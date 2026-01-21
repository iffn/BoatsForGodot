shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform float cam_near = 0.1;
uniform float cam_far = 100.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.y = 1.0 - uv.y;
	
    float depth_raw = texture(depth_texture, uv).r; // ToDo: Make linear
	
    ALBEDO = vec3(depth_raw);
}