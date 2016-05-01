Shader "Skin/Compute irradiance"
{
	SubShader
	{
		Pass
		{
			Cull Off
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			// Set by inheritance
			uniform sampler2D _MainTex;
			uniform sampler2D _NormalMap;
			uniform sampler2D _AttenuationTex;
			uniform sampler2D _TSMTex;
			uniform float _Roughness;
			uniform float _SpecPower;
			uniform float _Mix;
			uniform float _ThicknessConst;
			uniform float4x4 _LightViewProj;
			uniform float4 _TsmLightPosWorld;

			// Unity
			uniform float4 _LightColor0;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 tex : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 tex : TEXCOORD0;
				float3 posWorld : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
			};

			v2f vert(a2v v)
			{
				v2f o;

				float2 coords = float2(2.0 * v.tex.x - 1.0, 1.0 - 2.0 * v.tex.y);
				o.pos = float4(coords, 0.0, 1.0);
				o.posWorld = mul(_Object2World, v.vertex).xyz;
				o.tex = v.tex;
				o.viewDir = _WorldSpaceCameraPos.xyz - o.posWorld;
				o.lightDir = UnityWorldSpaceLightDir(o.posWorld);

				return o;
			}

			float calculateThickness(float3 posWorld, float3 normal, float nDotL)
			{
				// Read TSM
				float4 posLightProjCoord = mul(_LightViewProj, float4(posWorld, 1.0));
				float2 lightCoord = posLightProjCoord.xy / posLightProjCoord.w;
				lightCoord = lightCoord * 0.5 + 0.5;
				lightCoord.y = 1.0 - lightCoord.y;
				float4 tsmTap = tex2D(_TSMTex, lightCoord);

				// Incident normal
				float3 normal_i_ObjectSpace = tex2D(_NormalMap, tsmTap.yz).rgb - 0.5;
				normal_i_ObjectSpace.x = -normal_i_ObjectSpace.x;
				float3 normal_i = normalize(mul(normal_i_ObjectSpace, (float3x3)_World2Object));

				// Compute thickness
				float distanceToLight = length(_TsmLightPosWorld.xyz - posWorld);
				float thickness = distanceToLight - tsmTap.x;

				// Set a large distance for surface points facing the light
				if (nDotL > 0.0)
				{
					thickness = 50.0;
				}

				// Correct thickness using cos theta
				float correctedThickness = max(0.0, -nDotL) * thickness;
				float mix = max(0.0, -dot(normal, normal_i));
				float finalThickness = lerp(thickness, correctedThickness, mix);

				return finalThickness;
			}

			float4 frag(v2f i) : COLOR
			{
				i.viewDir = normalize(i.viewDir);
				i.lightDir = normalize(i.lightDir);

				// Sample object space normal
				float3 normalObjectSpace = tex2D(_NormalMap, i.tex).rgb - 0.5;
				normalObjectSpace.x = -normalObjectSpace.x;
				float3 normal = normalize(mul(normalObjectSpace, (float3x3)_World2Object));

				float nDotL = dot(normal, i.lightDir);
				float thickness = calculateThickness(i.posWorld, normal, nDotL);
				float3 albedo = tex2D(_MainTex, i.tex).rgb;

				// Attenuate irradiance by the amount of energy reflected by the skin
				float3 diffuse = max(0.0, nDotL) * _LightColor0.rgb;
				float reflectedEnergy = _SpecPower * tex2D(_AttenuationTex, float2(nDotL, _Roughness)).r;
				float3 lighting = (1 - reflectedEnergy) * diffuse;

				// Account for pre and post scatter mix
				float3 final = lighting * pow(albedo, _Mix);

				float alpha = exp(thickness * -_ThicknessConst);
				return float4(final, alpha);
			}
			ENDCG
		}
	}
}