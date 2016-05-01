Shader "Skin/Compute alpha mask"
{
	Properties
	{
		_StretchTex("Stretch Texture", 2D) = "white" {}
		_Blur2StretchTex("Blur 2 Stretch Texture", 2D) = "white" {}
		_Blur3StretchTex("Blur 3 Stretch Texture", 2D) = "white" {}
		_Blur4StretchTex("Blur 4 Stretch Texture", 2D) = "white" {}
		_Blur5StretchTex("Blur 5 Stretch Texture", 2D) = "white" {}
		_Blur6StretchTex("Blur 6 Stretch Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			ZTest Always
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			uniform sampler2D _StretchTex;
			uniform sampler2D _Blur2StretchTex;
			uniform sampler2D _Blur3StretchTex;
			uniform sampler2D _Blur4StretchTex;
			uniform sampler2D _Blur5StretchTex;
			uniform sampler2D _Blur6StretchTex;

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
				float4 stretchTap = tex2D(_StretchTex, i.tex);
				float4 blur2stretchTap = tex2D(_Blur2StretchTex, i.tex);
				float4 blur3stretchTap = tex2D(_Blur3StretchTex, i.tex);
				float4 blur4stretchTap = tex2D(_Blur4StretchTex, i.tex);
				float4 blur5stretchTap = tex2D(_Blur5StretchTex, i.tex);
				float4 blur6stretchTap = tex2D(_Blur6StretchTex, i.tex);
				float mask = stretchTap.a * blur2stretchTap.a * blur3stretchTap.a * 
					blur4stretchTap.a * blur5stretchTap.a * blur6stretchTap.a;

				return float4(mask, mask, mask, 1.0);
			}
			ENDCG
		}
	}
}
