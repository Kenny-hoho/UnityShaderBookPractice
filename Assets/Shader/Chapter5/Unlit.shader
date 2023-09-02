Shader "Unity Shader Book/Chapter5/URPUnlitShader"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 position : POSITION;
            float4 normal : NORMAL;
            float2 texcoord : TEXCOORD;
        };
        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 texcoord : TEXCOORD;
        };
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG

            v2f VERT(a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.position.xyz);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 FRAG(v2f i) : SV_TARGET
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord) * _BaseColor;
                return tex;
            }
            ENDHLSL
        }
    }
}