Shader "Unity Shader Book/Chapter9/TransparentShadow"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Cutoff ("Alpha Test Cutoff", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float _Cutoff;
        CBUFFER_END
        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);

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
            Tags { "LightMode" = "UniversalForward" "Queue" = "AlphaTest" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            v2f vert(in a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                // alphatest
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                clip(texColor.a - _Cutoff);

                half3 albedo = texColor.rgb * _BaseColor.rgb;
                // prepare
                float3 worldNormal = normalize(i.worldNormal);
                // ambient
                half3 ambient = SampleSH(worldNormal) * albedo;
                // diffuse
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                Light mainLight = GetMainLight(shadowCoord);
                half3 mainColor = mainLight.color * albedo * saturate(dot(mainLight.direction, worldNormal)) * mainLight.shadowAttenuation;

                real3 addColor = real3(0, 0, 0);
                int addLightCount = GetAdditionalLightsCount();
                for (int index = 0; index < addLightCount; index++)
                {
                    Light addLight = GetAdditionalLight(index, i.worldPos, real4(1, 1, 1, 1));
                    addColor += addLight.color * albedo * saturate(dot(addLight.direction, worldNormal)) * addLight.shadowAttenuation * addLight.distanceAttenuation;
                }
                half3 diffuse = addColor + mainColor;
                return real4(diffuse + ambient, 1.0);
            }
            ENDHLSL
        }
        pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            v2f vert(in a2v v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                clip(texColor.a - _Cutoff);
                return 0;
            }
            ENDHLSL
        }
        // UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
