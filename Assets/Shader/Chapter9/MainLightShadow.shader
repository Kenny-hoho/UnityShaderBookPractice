Shader "Unity Shader Book/Chapter9/MainLightShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _BaseColor;
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
            float3 worldNormal : TEXCOORD0;
            float3 worldPos : TEXCOORD1;
            float2 uv : TEXCOORD2;
        };
        ENDHLSL

        pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            v2f vert(in a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                half3 worldNormal = normalize(i.worldNormal);
                half3 worldPos = i.worldPos;
                // albedo
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _BaseColor.rgb;
                // ambient
                half3 ambient = SampleSH(worldNormal) * albedo;
                // diffuse
                float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
                Light mainLight = GetMainLight(shadowCoord);
                half3 diffuse = mainLight.color * albedo * saturate(dot(worldNormal, mainLight.direction)) * mainLight.shadowAttenuation;
                return real4(diffuse + ambient, 1.0);
            }
            ENDHLSL
        }
        pass {
            Tags {"LightMode"="ShadowCaster"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            half3 _LightDirection;
            v2f vert(in a2v v)
            {
                v2f o;
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(ApplyShadowBias(o.worldPos, o.worldNormal, _LightDirection));
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
        // UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
