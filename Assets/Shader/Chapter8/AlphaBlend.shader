Shader "Unity Shader Book/Chapter8/AlphaBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _AlphaBlendScale ("AlphaBlend", Range(0,1))=1.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "IgnoreProjector"="True" "Queue" = "Transparent"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _BaseColor;
            float _AlphaBlendScale;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float2 texcoord : TEXCOORD;
        };
        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float3 worldNormal : TEXCOORD1;
            float2 uv : TEXCOORD0;
        };
        ENDHLSL

        pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(in a2v v){
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET{
                // albedo
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half3 albedo = texColor.rgb * _BaseColor.rgb;
                // ambient 
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // diffuse
                Light mainLight = GetMainLight();
                float3 worldNormal = normalize(i.worldNormal);
                half3 diffuse = mainLight.color * albedo * saturate(dot(worldNormal, mainLight.direction));

                return real4(diffuse + ambient, texColor.a * _AlphaBlendScale);
            }
            ENDHLSL
        }
    }
}
