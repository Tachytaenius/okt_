varying vec3 pos;
varying vec2 texCoord;
varying mat3 tbn;

#ifdef VERTEX
	uniform mat4 modelToWorld, modelToCamera, modelToScreen;
	
	// attribute vec2 VertexTexCoord;
	attribute vec3 VertexNormal, VertexTangent, VertexBitangent;
	
	vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
		pos = vec3(modelToWorld * homogenVertexPosition);
		texCoord = VertexTexCoord.st;
		tbn = mat3(
			normalize(vec3(modelToWorld * vec4(VertexTangent,   0.0))),
			normalize(vec3(modelToWorld * vec4(VertexBitangent, 0.0))),
			normalize(vec3(modelToWorld * vec4(VertexNormal,    0.0)))
		);
		return modelToScreen * homogenVertexPosition;
	}
#endif

#ifdef PIXEL // FRAGMENT
	uniform sampler2D albedoEmissionMap, normalAmbientOcclusionMap, roughnessMetalnessDielectricF0Map;
	uniform vec3 ambientColour;
	
	uniform int id;
	
	void effect() {
		vec4 colourTexel = Texel(albedoEmissionMap, texCoord);
		vec3 albedo = colourTexel.rgb;
		float emission = colourTexel.a;
		
		vec4 surfaceTexel = Texel(normalAmbientOcclusionMap, texCoord);
		vec3 normal = normalize(tbn * (surfaceTexel.xyz * 2.0 - 1.0));
		float ambientOcclusion = surfaceTexel.a;
		
		vec4 materialTexel = Texel(roughnessMetalnessDielectricF0Map, texCoord);
		float roughness = materialTexel.r;
		float metalness = materialTexel.g;
		float dielectricF0 = materialTexel.b;
		
		vec3 emissionAndAmbience = albedo * (1.0 - ambientOcclusion) * ambientColour + albedo * emission;
		
		love_Canvases[0] = vec4(pos, 0.0);
		love_Canvases[1] = vec4(normal, 0.0);
		love_Canvases[2] = vec4(albedo, 0.0);
		love_Canvases[3] = vec4(roughness, metalness, dielectricF0, 0.0);
		love_Canvases[4] = vec4(emissionAndAmbience, id);
	}
#endif
