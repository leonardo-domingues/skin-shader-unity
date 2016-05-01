Shader "Skin/Skin (GPU Gems 3 - 14)"
{
	Properties
	{
		_MainTex("Diffuse Texture", 2D) = "white" {}
		_NormalMap("Normal Map (Object Space)", 2D) = "black" {}
		_Roughness("Roughness", Range(0.0, 1.0)) = 0.0
		_SpecPower("Specular Power", Range(0.0, 1.0)) = 1.0
		_TranslucencyPower("Translucency Power", Range(0.0, 1.0)) = 1.0
		_Mix("Pre and Post Scatter Mix", Range(0.0, 1.0)) = 0.5
		_EnergyConservation("Scattering Energy Conservation (bool)", Range(0.0, 1.0)) = 0.0
		_BlurStepScale("Gaussian Sample Distance Scale", Range(0.01, 1.0)) = 0.01
		_Blur1WV("Gaussian 1 Weight and Variance", Vector) = (0.233, 0.455, 0.649, 0.0064)
		_Blur2WV("Gaussian 2 Weight and Variance", Vector) = (0.100, 0.336, 0.344, 0.0484)
		_Blur3WV("Gaussian 3 Weight and Variance", Vector) = (0.118, 0.198, 0.000, 0.1870)
		_Blur4WV("Gaussian 4 Weight and Variance", Vector) = (0.113, 0.007, 0.007, 0.5670)
		_Blur5WV("Gaussian 5 Weight and Variance", Vector) = (0.358, 0.004, 0.000, 1.9900)
		_Blur6WV("Gaussian 6 Weight and Variance", Vector) = (0.078, 0.000, 0.000, 7.4100)
		_Grow("TSM - Grow Along Normal", Range(0.0, 0.05)) = 0.00005
		_ThicknessConst("TSM - Thickness Constant", Range(0.1, 20)) = 0.2
		_TSMSpread("TSM Spread", Range(0.0, 200.0)) = 200.0
	}

	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Skin_GPUGems3-14/BRDF.cginc"

			// Properties
			uniform sampler2D _MainTex;
			uniform sampler2D _NormalMap;
			uniform float _Roughness;
			uniform float _SpecPower;
			uniform float _TranslucencyPower;
			uniform float _Mix;
			uniform float _EnergyConservation;
			uniform float _BlurStepScale;
			uniform float4 _Blur1WV;
			uniform float4 _Blur2WV;
			uniform float4 _Blur3WV;
			uniform float4 _Blur4WV;
			uniform float4 _Blur5WV;
			uniform float4 _Blur6WV;
			uniform float _Grow;
			uniform float _ThicknessConst;
			uniform float _TSMSpread;

			// Set by script
			uniform sampler2D _IrradianceTex;
			uniform sampler2D _AttenuationTex;
			uniform sampler2D _BeckmannTex;
			uniform sampler2D _Blur2Tex;
			uniform sampler2D _Blur3Tex;
			uniform sampler2D _Blur4Tex;
			uniform sampler2D _Blur5Tex;
			uniform sampler2D _Blur6Tex;
			uniform sampler2D _TSMTex;
			uniform sampler2D _StretchTex;
			uniform sampler2D _Blur6StretchTex;
			uniform sampler2D _AlphaMaskTex;
			uniform float4x4 _LightViewProj;
			uniform float _TextureSize;
			uniform float4 _TsmLightPosWorld;
			uniform float _StretchScale;

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
				float3 lightDir : TEXCOORD2;
				float3 viewDir : TEXCOORD3;
				LIGHTING_COORDS(4, 5)
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.tex = v.tex;
				o.posWorld = mul(_Object2World, v.vertex);
				o.lightDir = UnityWorldSpaceLightDir(o.posWorld);
				o.viewDir = _WorldSpaceCameraPos.xyz - o.posWorld;

				TRANSFER_VERTEX_TO_FRAGMENT(o);

				return o;
			}

			// Compute global scatter from TSM
			float3 translucency(v2f i, float4 tap2, float4 tap3, float4 tap4, float4 tap5, 
				float3 totalWeight, float4 stretchTap, float3 normal)
			{				
				float4 posLightProjCoord = mul(_LightViewProj, float4(i.posWorld, 1.0));
				float2 lightCoord = posLightProjCoord.xy / posLightProjCoord.w;
				lightCoord = lightCoord * 0.5 + 0.5;
				lightCoord.y = 1.0 - lightCoord.y;
				float4 tsmTap = tex2D(_TSMTex, lightCoord);

				// We only consider the contribution for the 4 most blurred taps. For tap n, 
				// we use the thickness stored in texture n-1
				float4 thickness = (-1.0 / _ThicknessConst) * log(float4(tap2.a, tap3.a, tap4.a, tap5.a)) * _TSMSpread;

				float4 variances = float4(_Blur3WV.w, _Blur4WV.w, _Blur5WV.w, _Blur6WV.w);
				float4 stdDevs = sqrt(variances);
				float4 fades = exp(-(thickness * thickness) / variances);

				float stretch = 0.5 * (stretchTap.r + stretchTap.g);
				float textureScale = _TextureSize * 0.1 / stretch;
				float4 blendFactor = saturate(textureScale * length(i.tex - tsmTap.yz) / (6.0 * stdDevs));

				float3 translucency = float3(0.0, 0.0, 0.0);
				translucency += ((_Blur4WV.xyz / totalWeight) * fades.y * blendFactor.y * tex2D(_Blur4Tex, tsmTap.yz).rgb);
				translucency += ((_Blur5WV.xyz / totalWeight) * fades.z * blendFactor.z * tex2D(_Blur5Tex, tsmTap.yz).rgb);
				translucency += ((_Blur6WV.xyz / totalWeight) * fades.w * blendFactor.w * tex2D(_Blur6Tex, tsmTap.yz).rgb);

				return translucency * max(0.0, -dot(normal, i.lightDir));
			}

			float4 frag(v2f i) : COLOR
			{
				i.lightDir = normalize(i.lightDir);
				i.viewDir = normalize(i.viewDir);

				// Sample object space normal
				float3 normalObjectSpace = tex2D(_NormalMap, i.tex).rgb - 0.5;
				normalObjectSpace.x = -normalObjectSpace.x;
				float3 normal = normalize(mul(normalObjectSpace, (float3x3)_World2Object));

				// Diffuse lighting from sum-of-Gaussians
				float3 albedo = tex2D(_MainTex, i.tex).rgb;
				float4 tap1 = tex2D(_IrradianceTex, i.tex);
				float4 tap2 = tex2D(_Blur2Tex, i.tex);
				float4 tap3 = tex2D(_Blur3Tex, i.tex);
				float4 tap4 = tex2D(_Blur4Tex, i.tex);
				float4 tap5 = tex2D(_Blur5Tex, i.tex);
				float4 tap6 = tex2D(_Blur6Tex, i.tex);
				float3 totalWeight = _Blur1WV.xyz + _Blur2WV.xyz + _Blur3WV.xyz + _Blur4WV.xyz + _Blur5WV.xyz + _Blur6WV.xyz;
				float3 diffuse = float3(0.0, 0.0, 0.0);
				diffuse += _Blur1WV.xyz * tap1.rgb;
				diffuse += _Blur2WV.xyz * tap2.rgb;
				diffuse += _Blur3WV.xyz * tap3.rgb;
				diffuse += _Blur4WV.xyz * tap4.rgb;
				diffuse += _Blur5WV.xyz * tap5.rgb;
				diffuse += _Blur6WV.xyz * tap6.rgb;
				diffuse /= totalWeight;

				// Add translucency
				float4 stretchTap = tex2D(_Blur6StretchTex, i.tex);
				float3 localScattering = translucency(i, tap2, tap3, tap4, tap5, totalWeight, stretchTap, normal);
				diffuse += (_TranslucencyPower * localScattering);

				// Account for pre and post scatter mix
				diffuse *= pow(albedo, 1.0 - _Mix);

				// Remove seams caused by connected areas being disconnected in texture space
				float4 diffuseTap = tex2D(_MainTex, i.tex);
				float nDotL = max(0.0, dot(normal, i.lightDir));
				float atten = LIGHT_ATTENUATION(i);
				float3 localDiffuse = diffuseTap * (nDotL * _LightColor0.rgb * atten + UNITY_LIGHTMODEL_AMBIENT);
				float4 alphaMask = tex2D(_AlphaMaskTex, i.tex).r;
				diffuse = lerp(localDiffuse, diffuse, alphaMask);

				// Account for energy conservation
				float reflectedEnergy = tex2D(_AttenuationTex, float2(dot(normal, i.viewDir), _Roughness)).r;
				float energyFactor = lerp(1.0, (1.0 - _SpecPower * reflectedEnergy), _EnergyConservation);
				diffuse *= energyFactor;

				// Specular lighting
				float brdf = brdf_KS(normal, i.lightDir, i.viewDir, _Roughness, _SpecPower, _BeckmannTex);
				float3 specular = brdf * _LightColor0.rgb * atten;

				float3 final = diffuse + specular;
				return float4(final, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}