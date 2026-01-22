shader_type canvas_item;

uniform float waveSpeed : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float dampening : hint_range(0.0, 1.0, 0.001) = 0.999;

uniform float offsetX = 0.0;
uniform float offsetY = 0.0;

uniform sampler2D water_buffer : filter_nearest, source_color;
uniform sampler2D depth_tex : filter_nearest, source_color;

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
	
	vec4 duv = vec4(1.0 / res.x, 1.0  / res.y, 0 ,0);
	float du = 1.0 / res.x;
	float dv = 1.0 / res.y;
	
	vec2 fragCoord = vec2(UV.x * res.x, UV.y * res.x);
	
	vec2 lookupOffset = vec2(du * offsetX, dv * offsetY);
	
	vec3 center = texture(water_buffer, UV + lookupOffset).rgb;
    vec3 up = texture(water_buffer, UV + duv.wy + lookupOffset).rgb;
    vec3 down = texture(water_buffer, UV - duv.wy + lookupOffset).rgb;
    vec3 left = texture(water_buffer, UV - duv.xw + lookupOffset).rgb;
    vec3 right = texture(water_buffer, UV + duv.xw + lookupOffset).rgb;
	
	// Waves
	float waveSpeedSquared = waveSpeed * waveSpeed;
	
	float laplacianWeightedSum = up.r + down.r + left.r + right.r - 4.0 * center.r;
	float nextAmplitude = center.r + (center.r - center.g) * dampening + waveSpeedSquared * laplacianWeightedSum;
	
	// Edge absorbtion
	/*
	if (fragCoord.x <= ABSORBTION_LAYER_THICKNESS || fragCoord.x >= res.x - ABSORBTION_LAYER_THICKNESS || 
        fragCoord.y <= ABSORBTION_LAYER_THICKNESS || fragCoord.y >= res.y - ABSORBTION_LAYER_THICKNESS) 
    {
        float coeff = (waveSpeed - 1.0) / (waveSpeed + 1.0);
        
        float currentInner;
        if      (fragCoord.x <= ABSORBTION_LAYER_THICKNESS)         currentInner = right.r;
        else if (fragCoord.x >= res.x - ABSORBTION_LAYER_THICKNESS) currentInner = left.r;
        else if (fragCoord.y <= ABSORBTION_LAYER_THICKNESS)         currentInner = up.r;
        else                                                        currentInner = down.r;

        nextAmplitude = currentInner + (nextAmplitude - center.r) * coeff;
    }
	*/
	
	// Depth
	float prevDepthValue = center.b;
	float newDepthValue = texture(depth_tex, UV).r;
	nextAmplitude += newDepthValue;
	nextAmplitude = clamp(nextAmplitude, 0.0, 1.0);
	
	// Combine return value
	vec3 returnValue = vec3(nextAmplitude, center.r, newDepthValue);
	
	// Auto refresh in editor
	float time = TIME;
	
	COLOR = vec4(returnValue, 1.0);
	//COLOR = vec4(vec3(0.5), 1.0); // Reset
}
