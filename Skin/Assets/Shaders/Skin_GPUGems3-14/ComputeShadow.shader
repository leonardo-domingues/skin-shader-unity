Shader "Skin/Compute shadow"
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
			uniform sampler2D _NormalMap;
			uniform sampler2D _TSMTex;
			uniform float4x4 _LightViewProj;
			uniform float4 _TsmLightPosWorld;

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

			float computeThickness(float3 posWorld, float3 normal, float nDotL)
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

				return thickness;
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
				float thickness = computeThickness(i.posWorld, normal, nDotL);
				float atten = 0.0;
				if (thickness <= 0.0)
				{
					atten = 1.0;
				}

				return float4(atten, atten, atten, 1.0);
			}
			ENDCG
		}
	}
}