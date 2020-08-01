const float gamma = 2.2; // TODO?

uniform sampler2D sky;

vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
	vec4 imageTexel = Texel(image, textureCoords);
	if (imageTexel.a == 0.0) return Texel(sky, imageCoords);
	return vec4(imageTexel.rgb, 1.0);
}
