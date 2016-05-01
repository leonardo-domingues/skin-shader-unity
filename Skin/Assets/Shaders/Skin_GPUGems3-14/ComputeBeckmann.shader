Shader "Skin/Compute Beckmann texture"
{
	SubShader
	{
		Pass
		{
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

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

			float PHBeckmann(float nDotH, float m)
			{
				float alpha = acos(nDotH);
				float tanAlpha = tan(alpha);
				float value = exp(-(tanAlpha * tanAlpha) / (m * m)) / (m * m * pow(nDotH, 4.0));
				return value;
			}

			float4 frag(v2f i) : COLOR
			{
				float value = 0.5 * pow(PHBeckmann(i.tex.x, i.tex.y), 0.1);
				return float4(value, value, value, 1.0);
			}
			ENDCG
		}
	}
}