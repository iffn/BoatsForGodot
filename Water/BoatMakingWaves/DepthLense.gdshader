shader_type spatial;
render_mode unshaded, fog_disabled; //, depth_draw_never, depth_test_disabled, cull_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform float cam_near = 0.1;
uniform float cam_far  = 100.0;
uniform bool reversed_z = true;

// Simple linearization for visualization
float linearize_depth(float z, float n, float f, bool rz) {
    float ndc = z * 2.0 - 1.0;
    return rz
        ? (2.0 * n * f) / (f + n + ndc * (f - n))
        : (2.0 * n * f) / (f + n - ndc * (f - n));
}

void fragment() {
	vec2 uv = vec2(SCREEN_UV.x, -SCREEN_UV.y);
    float z_raw = 1.0 - texture(depth_texture, uv).r;
	
	//Somehow makes it almost linear
	float x = z_raw;
	float a = 0.52;
	float y = a*x + (3.0 - 2.0*a - 1.0/a) * pow(x,2.0) + (a + 1.0/a - 2.0) * pow(x,3);
	
    ALBEDO = vec3(1.0-y);
}