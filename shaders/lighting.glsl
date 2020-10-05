#define sq(x) ((x)*(x))
const float pi = 3.14159265359;
uniform vec2 windowSize;

uniform sampler2D positionBuffer, normalBuffer, albedoBuffer, roughnessMetalnessDielectricF0Buffer;
uniform vec3 viewPosition, lightPosition, lightColour;
uniform float farPlane, nearPlane;

float distributionGGX(vec3 normal, vec3 halfway, float roughness);
float geometrySchlickGGX(float NdV, float roughness);
float geometrySmith(vec3 normal, vec3 toView, vec3 toLight, float roughness);
vec3 fresnelSchlick(float cosTheta, vec3 F0);

float depthToLinear(float depth, float far, float near);

vec4 effect(vec4 colour, sampler2D image, vec2 imageCoords, vec2 windowCoords) {
	// Get fragment properties
	vec2 bufferCoords = windowCoords / windowSize;
	vec3 position; vec3 normal; vec3 albedo; float roughness; float metalness; float dielectricF0;
	
	vec4 positionTexel = Texel(positionBuffer, bufferCoords);
	position = positionTexel.xyz;
	vec4 normalTexel = Texel(normalBuffer, bufferCoords);
	normal = normalTexel.xyz;
	
	vec4 albedoTexel = Texel(albedoBuffer, bufferCoords);
	albedo = albedoTexel.rgb;
	
	vec4 roughnessMetalnessDielectricF0Texel = Texel(roughnessMetalnessDielectricF0Buffer, bufferCoords);
	roughness = roughnessMetalnessDielectricF0Texel.r;
	metalness = roughnessMetalnessDielectricF0Texel.g;
	dielectricF0 = roughnessMetalnessDielectricF0Texel.b;
	
	// Calculate some important parameters
	vec3 toLight = normalize(lightPosition - position);
	vec3 toView = normalize(viewPosition - position);
	vec3 halfway = normalize(toLight + toView);
	float attenuation = pow(distance(lightPosition, position), -2.0);
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
	
	return vec4(result, 0.0);
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
