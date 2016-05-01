Shader "Skin/TSM"
{
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			uniform float _Grow;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float2 tex : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 tex : TEXCOORD0;
				float depth : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.pos = mul(UNITY_MATRIX_MVP, v.vertex + _Grow * v.normal);
				o.tex = v.tex;
				o.depth = length(mul(UNITY_MATRIX_MV, v.vertex));

				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				return float4(i.depth, i.tex.x, i.tex.y, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}