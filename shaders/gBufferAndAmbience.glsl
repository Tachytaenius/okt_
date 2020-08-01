varying vec3 pos;
varying vec2 texCoord;
varying mat3 tbn;
varying vec3 velocity;
uniform float dt;

#ifdef VERTEX
	uniform mat4 modelToWorld, modelToCamera, modelToScreen;
	
	// attribute vec2 VertexTexCoord;
	attribute vec3 VertexNormal, VertexTangent, VertexBitangent;
	
	vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
		pos = vec3(modelToCamera * homogenVertexPosition);
		texCoord = VertexTexCoord.st;
		tbn = mat3(
			normalize(vec3(modelToCamera * vec4(VertexTangent,   0.0))),
			normalize(vec3(modelToCamera * vec4(VertexBitangent, 0.0))),
			normalize(vec3(modelToCamera * vec4(VertexNormal,    0.0)))
		);
		
		velocity = vec3(0.0); // TODO
		
		return modelToScreen * homogenVertexPosition;
	}
#endif

#ifdef PIXEL // FRAGMENT
	uniform sampler2D albedoEmissionMap, normalAmbientOcclusionMap, roughnessMetalnessDielectricF0Map;
	uniform vec3 ambientColour;
	
	void effect() {
		vec4 colourTexel = Texel(albedoEmissionMap, texCoord);
		vec3 albedo = colourTexel.rgb;
		float emission = colourTexel.a;
		vec4 surfaceTexel = Texel(normalAmbientOcclusionMap, texCoord);
		vec3 normal = normalize(tbn * (surfaceTexel.xyz * 2.0 - 1.0));
		float ambientOcclusion = surfaceTexel.a;
		vec4 materialTexel = Texel(roughnessMetalnessDielectricF0Map, texCoord);
		float roughnessMetalness = materialTexel.r;
		float dielectricF0 = materialTexel.g > 0.5 ?
			1.0 / (1.0 - (materialTexel.b * 2.0 - 1.0)) :
			materialTexel.b * 2.0;
		
		love_Canvases[0] = vec4(pos.xy, normal.xy);
		love_Canvases[1] = vec4(albedo, roughnessMetalness);
		love_Canvases[2] = vec4(velocity, dielectricF0);
		love_Canvases[3] = vec4(albedo * (1.0 - ambientOcclusion) * ambientColour + albedo * emission, 0.0);
	}
#endif
