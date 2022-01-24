varying vec3 pos;

#ifdef VERTEX
uniform mat4 worldToScreen;

uniform vec3 entityPos;
uniform vec3 entityMovementThisFrame;

vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
	pos = homogenVertexPosition.xyz * entityMovementThisFrame + entityPos;
	return worldToScreen * vec4(pos, 1.0);
}
#endif

#ifdef PIXEL
uniform int id;
uniform vec3 colour;

void effect() {
	love_Canvases[0] = vec4(pos, 0.0);
	love_Canvases[1] = vec4(0.0);
	love_Canvases[2] = vec4(0.0);
	love_Canvases[3] = vec4(0.0);
	love_Canvases[4] = vec4(colour, id);
}
#endif
