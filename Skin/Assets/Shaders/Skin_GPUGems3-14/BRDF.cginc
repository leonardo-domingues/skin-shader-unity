#ifndef BRDF_INCLUDED
#define BRDF_INCLUDED

// Calculate the fresnel reflectance using Schlick's approximation
float fresnelReflectance(float3 halfDir, float3 viewDir, float F0)
{
	float base = 1.0 - dot(viewDir, halfDir);
	float exponential = pow(base, 5.0);
	return exponential + F0 * (1.0 - exponential);
}

// Kelemen / Szirmay-Kalos specular BRDF
float brdf_KS(float3 normal, float3 lightDir, float3 viewDir, float roughness, float specPower, sampler2D beckmannTex)
{
	float result = 0.0;
	float nDotL = dot(normal, lightDir);
	if (nDotL > 0.0)
	{
		float3 h = viewDir + lightDir;
		float3 halfDir = normalize(h);
		float nDotH = dot(normal, halfDir);
		float PH = pow(2.0 * tex2D(beckmannTex, float2(nDotH, roughness)).r, 10.0);
		const float F0 = 0.028; // Reflectance at normal incidence
		float F = fresnelReflectance(halfDir, viewDir, F0);
		float frSpec = max(PH * F / dot(h, h), 0.0);
		result = frSpec * nDotL * specPower;
	}
	return result;
}

#endif // BRDF_INCLUDED