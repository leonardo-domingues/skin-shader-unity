Shader "Skin/Gaussian convolution (U)"
{
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
			uniform sampler2D _StretchTex;
			uniform float _BlurStepScale;
			uniform float _TextureSize;
			uniform float _GaussianWidth;

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
				float stretch = tex2D(_StretchTex, i.tex).r;
				float scale = (1.0 / _TextureSize) * stretch * _GaussianWidth / _BlurStepScale;

				float curve[7] = {0.006, 0.061, 0.242, 0.383, 0.242, 0.061, 0.006};
				float2 coords = i.tex - float2(scale * 3.0, 0.0);
				float4 sum = 0.0;
				for (int j = 0; j < 7; ++j)
				{
					float4 tap = tex2D(_MainTex, coords);
					sum += curve[j] * tap;
					coords += float2(scale, 0.0);
				}

				return sum;
			}
			ENDCG
		}
	}
}