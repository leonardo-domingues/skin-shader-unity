Shader "Skin/Compute stretch maps"
{
	SubShader
	{
		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// Set by inheritance
			uniform float _StretchScale;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 tex : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 posWorld : TEXCOORD0;
			};

			v2f vert(a2v v)
			{
				v2f o;

				float2 coords = float2(v.tex.x * 2.0 - 1.0, 1.0 - 2.0 * v.tex.y);
				o.pos = float4(coords, 0.0, 1.0);
				o.posWorld = mul(_Object2World, v.vertex);

				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				float3 deriv_u = ddx(i.posWorld);
				float3 deriv_v = ddy(i.posWorld);
				float stretch_u = (1.0 / length(deriv_u)) * _StretchScale;
				float stretch_v = (1.0 / length(deriv_v)) * _StretchScale;
				return float4(stretch_u, stretch_v, 0.0, 1.0);
			}
			ENDCG
		}
	}
}