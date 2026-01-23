shader_type canvas_item;

uniform float waveSpeed : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float dampening : hint_range(0.0, 1.0, 0.001) = 0.999;

uniform float offsetX = 0.0;
uniform float offsetY = 0.0;
uniform float initializationFactor = 0.0;

uniform sampler2D water_buffer : filter_nearest, source_color;
uniform sampler2D depth_tex : filter_nearest, source_color;

uniform float cam_near = 1.0;
uniform float cam_far = 14.0;
uniform float water_base_height = 4.0;
uniform sampler2D heightmap : filter_linear;
uniform float heightmap_height = 10.0;

const float ABSORBTION_LAYER_THICKNESS = 1.0;

void fragment() {
	// Based on: https://github.com/iffn/iffnsWaterShaderForUnity/blob/main/WaterComputeLikeShader.shader
	/*
	    Layers:
	    r: Last wave value
		g: 2nd to last wave value
		b: Last depth value
		a: Not useable since it influences the others. Use 1.0
    */
	
	// Shared values
	vec2 res = vec2(float(textureSize(depth_tex, 0).x), float(textureSize(depth_tex, 0).y));
	
	vec4 duv = vec4(1.0 / res.x, 1.0  / res.y, 0.0 ,0.0);
	float du = 1.0 / res.x;
	float dv = 1.0 / res.y;
	
	vec2 fragCoord = vec2(UV.x * res.x, UV.y * res.x);
	
	vec2 lookupOffset = vec2(du * offsetX, dv * offsetY);
	
	vec3 center = texture(water_buffer, UV + lookupOffset).rgb;
	vec3 up = texture(water_buffer, UV + duv.wy + lookupOffset).rgb;
	vec3 down = texture(water_buffer, UV - duv.wy + lookupOffset).rgb;
	vec3 left = texture(water_buffer, UV - duv.xw + lookupOffset).rgb;
	vec3 right = texture(water_buffer, UV + duv.xw + lookupOffset).rgb;
	
	float depth_raw = texture(depth_tex, UV).r;
	
	float depth_height = cam_near + (cam_far - cam_near) * depth_raw;
	float water_height = texture(heightmap, UV).r * heightmap_height + water_base_height;
	
	float newDepthValue = 1.0 - water_height + depth_height;
	newDepthValue = min(newDepthValue, 0.0);
    //ALBEDO = vec3(1.0 - water_height + depth_height);
	
	if (up.b > 0.1) up.r = center.r;
	if (down.b > 0.1) down.r = center.r;
	if (left.b > 0.1) left.r = center.r;
	if (right.b > 0.1) right.r = center.r;
	
	// Waves
	float waveSpeedSquared = waveSpeed * waveSpeed;
	
	float nextAmplitude = 0.0;
	if (center.b < 0.1 && newDepthValue < 0.1) // Hard set values on blocked values
	{
		float laplacianWeightedSum = up.r + down.r + left.r + right.r - 4.0 * center.r;
		nextAmplitude = center.r + (center.r - center.g) * dampening + waveSpeedSquared * laplacianWeightedSum;
	}
	
	float leftEdgeSignal = step(UV.x, du);
	float topEdgeSignal = step(UV.y, dv);
	float rightEdgeSignal = step(1.0 - du, UV.x);
	float bottomEdgeSignal = step(1.0 - dv, UV.y);
	float isBoundaryPixelSignal = clamp(leftEdgeSignal + topEdgeSignal + rightEdgeSignal + bottomEdgeSignal, 0.0, 1.0);
	float isNotBoundaryPixelSignal = 1.0 - isBoundaryPixelSignal;
	
	// Depth
	float prevDepthValue = center.b;
	float addition = newDepthValue - prevDepthValue;
	addition = mix(addition, 0.0, isBoundaryPixelSignal);
	nextAmplitude += addition;
	nextAmplitude = clamp(nextAmplitude, 0.0, 1.0);
	
	// Combine return value
	vec3 returnValue = vec3(nextAmplitude, center.r, newDepthValue);
	vec3 initalizationValue = vec3(center.r, center.g, newDepthValue);
	
	returnValue = mix(returnValue, initalizationValue, initializationFactor);
	
	// Auto refresh in editor
	float time = TIME;
	
	COLOR = vec4(returnValue, 1.0);
	//COLOR = vec4(vec3(0.5), 1.0); // Reset
}
