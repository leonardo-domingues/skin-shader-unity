Shader "Skin/Apply shadows to irradiance" {
	Properties
	{
		_MainTex("Diffuse Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// Properties
			uniform sampler2D _MainTex;

			// Set by script
			uniform sampler2D _DiffuseTex;
			uniform sampler2D _ShadowTex;
			uniform float _Mix;

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

			float4 frag(v2f i) : COLOR
			{
				float atten = tex2D(_ShadowTex, i.tex).r;
				float4 irradiance = tex2D(_MainTex, i.tex);
				float3 albedo = tex2D(_DiffuseTex, i.tex).rgb;
				irradiance.rgb = irradiance.rgb * atten + UNITY_LIGHTMODEL_AMBIENT * pow(albedo, _Mix);
				return irradiance;
			}
			ENDCG
		}
	}
}
