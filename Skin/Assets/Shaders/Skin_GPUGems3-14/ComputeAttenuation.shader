Shader "Skin/Compute attenuation texture"
{
	Properties
	{
		_BeckmannTex("Beckmann Texture", 2D) = "black" {}
	}

	SubShader
	{
		Pass
		{
			ZTest Always
 			CGPROGRAM
 			#pragma vertex vert
 			#pragma fragment frag
 			#include "BRDF.cginc"
 			#define PI 3.14159265358979324
 			#define NUM_TERMS 80 // Can be increased for more accuracy

 			uniform sampler2D _BeckmannTex;

 			struct a2v
 			{
 				float4 vertex : POSITION;
 				float2 tex : TEXCOORD0;
 			};

 			struct v2f
 			{
 				float4 pos : SV_POSITION;
 				float2 tex : TEXCOORD0;
 			};

 			v2f vert(a2v v)
 			{
 				v2f o;

 				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
 				o.tex = v.tex;

 				return o;
 			}

 			// Integrate the specular BRDF component over the hemisphere
 			float4 frag(v2f i) : COLOR
 			{
 				float cosTheta = i.tex.x; // N dot L or N dot V
 				float m = i.tex.y; // Roughness
 				float sum = 0.0;
 				float3 N = float3(0.0, 0.0, 1.0);
 				// Considering the same graph is used with values cosTheta = N.L and N.V,
 				// and that the authors state that BRDF is reciprocal, either L or V could
 				// be calculated here. Although swaping the calculation of V and L results
 				// in similar textures, deriving L from cosTheta provides a graph where the
 				// integral is 0 for low values of cosTheta, which looks unrealistic
 				float3 V = float3(0.0, sqrt(1.0 - cosTheta * cosTheta), cosTheta);
 				for (int j = 0; j < NUM_TERMS; ++j)
 				{
 					float phip = (float(j) / float(NUM_TERMS - 1)) * (2.0 * PI);
 					float localSum = 0.0;
 					float cosp = cos(phip);
 					float sinp = sin(phip);
 					for (int k = 0; k < NUM_TERMS; ++k)
 					{
 						float thetap = (float(k) / float(NUM_TERMS - 1)) * (PI / 2.0);
 						float sint = sin(thetap);
 						float cost = cos(thetap);
 						float3 L = float3(sinp * sint, cosp * sint, cost);
 						localSum += brdf_KS(N, L, V, m, 1.0, _BeckmannTex) * sint;
 					}
 					sum += localSum * (PI / 2.0) / float(NUM_TERMS);
 				}

 				float value = sum * (2.0 * PI) / float(NUM_TERMS);
 				return float4(value, value, value, 1.0);
 			}
 			ENDCG
		}
	}
}