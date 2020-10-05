const float gamma = 2.2; // TODO?

uniform samplerCube sky;
uniform float fovScale;
uniform float aspect;
uniform vec4 viewQuaternion;

vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
	vec4 imageTexel = Texel(image, imageCoords);
	if (imageTexel.a == 0.0) {
		vec2 imageCoords = imageCoords * 2.0 - 1.0;
		imageCoords.x *= aspect;
		imageCoords *= tan(fovScale/2.0);
		vec3 v = normalize(vec3(imageCoords, -1));
		vec3 uv = cross(viewQuaternion.xyz, v);
		vec3 uuv = cross(viewQuaternion.xyz, uv);
		vec3 coord = v + ((uv * viewQuaternion.w) + uuv) * 2.0;
		
		return Texel(sky, coord);
	}
	return vec4(imageTexel.rgb, 1.0);
}
