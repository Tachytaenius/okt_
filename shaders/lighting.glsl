#define sq(x) ((x)*(x))
const float pi = 3.14159265359;
uniform vec2 windowSize;

uniform sampler2D positionNormalBuffer, albedoRoughnessMetalnessBuffer, velocityDielectricF0Buffer, depthBuffer;
uniform vec3 lightPosition, lightColour;
uniform float farPlane, nearPlane;

float distributionGGX(vec3 normal, vec3 halfway, float roughness);
float geometrySchlickGGX(float NdV, float roughness);
float geometrySmith(vec3 normal, vec3 toView, vec3 toLight, float roughness);
vec3 fresnelSchlick(float cosTheta, vec3 F0);

float depthToLinear(float depth, float far, float near);

vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
	// Get fragment properties
	vec2 bufferCoords = windowCoords / windowSize;
	vec3 fragmentPosition; vec3 normal; vec3 albedo; float roughness; float metalness; vec3 velocity; float dielectricF0;
	
	vec4 positionNormalTexel = Texel(positionNormalBuffer, bufferCoords);
	float z = -depthToLinear(Texel(depthBuffer, bufferCoords).r, farPlane, nearPlane);
	fragmentPosition = vec3(positionNormalTexel.xy, z);
	normal = vec3(positionNormalTexel.zw, sqrt(1.0 - sq(positionNormalTexel.z) - sq(positionNormalTexel.w)));
	
	vec4 albedoRoughnessMetalnessTexel = Texel(albedoRoughnessMetalnessBuffer, bufferCoords);
	albedo = albedoRoughnessMetalnessTexel.rgb;
	int roughnessMetalness = int(albedoRoughnessMetalnessTexel.a * 255);
	roughness = (roughnessMetalness / 2 * 2) / 255.0;
	metalness = float(mod(roughnessMetalness, 1));
	
	vec4 velocityDielectricF0Texel = Texel(velocityDielectricF0Buffer, bufferCoords);
	velocity = velocityDielectricF0Texel.xyz;
	dielectricF0 = velocityDielectricF0Texel.a;
	
	// Calculate some important parameters
	vec3 toLight = normalize(lightPosition - fragmentPosition);
	vec3 toView = normalize(-fragmentPosition);
	vec3 halfway = normalize(toLight + toView);
	float attenuation = pow(distance(lightPosition, fragmentPosition), -2.0);
	if (albedo.x != 0) {
		return vec4(vec3(toLight), 1.0);
	}
	vec3 radiance = attenuation * lightColour;
	
	// Cook-Torrance BRDF
	float normalDistribution = distributionGGX(normal, halfway, roughness);
	float geometry = geometrySmith(normal, toView, toLight, roughness);
	
	vec3 F0 = mix(vec3(dielectricF0), albedo, metalness);
	vec3 fresnel = fresnelSchlick(max(dot(normal, toView), 0.0), F0);
	
	vec3 reflected = fresnel;
	vec3 refracted = 1.0 - reflected; // What wasn't reflected specularly is refracted.
	vec3 diffuse = refracted * (1.0 - metalness); // And diffused unless it's a metal, in which case it's absorbed.
	
	vec3 num = normalDistribution * geometry * fresnel;
	float denom = 4.0 * max(dot(normal, toView), 0.0) * max(dot(normal, toLight), 0.0);
	vec3 specular = num / max(denom, 0.001);
	
	float NdL = max(dot(normal, toLight), 0.0);
	vec3 result = (diffuse * albedo / pi + specular) * radiance * NdL;
	
	return vec4(result, 1.0);
}

float distributionGGX(vec3 normal, vec3 halfway, float roughness) {
	float roughness2 = sq(roughness);
	float NdH = max(dot(normal, halfway), 0.0);
	float NdH2 = sq(NdH);
	
	float num = roughness2;
	float denom = (NdH2 * (roughness2 - 1.0) + 1.0);
	denom = pi * sq(denom);
	
	return num / denom;
}

float geometrySchlickGGX(float NdV, float roughness) {
	float num = NdV;
	float denom = NdV * (1.0 - roughness) + roughness;
	
	return num / denom;
}
  
float geometrySmith(vec3 normal, vec3 toView, vec3 toLight, float roughness) {
	float NdV = max(dot(normal, toView), 0.0);
	float NdL = max(dot(normal, toLight), 0.0);
	float ggx1 = geometrySchlickGGX(NdV, roughness);
	float ggx2 = geometrySchlickGGX(NdL, roughness);
	
	return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
	return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float depthToLinear(float depth, float far, float near) {
	return (2.0 * near * far) / (far + near - (depth * 2.0 - 1.0) * (far - near));
}
