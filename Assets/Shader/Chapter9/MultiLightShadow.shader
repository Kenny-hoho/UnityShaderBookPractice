Shader "Unity Shader Book/Chapter9/MultiLightShadow"
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
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            // #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

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
                // prepare
                float3 worldNormal = normalize(i.worldNormal);
                // albedo
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _BaseColor.rgb;
                // ambient
                half3 ambient = SampleSH(worldNormal) * albedo;
                // main light color
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                Light mainLight = GetMainLight(shadowCoord);
                half3 mainLightColor = mainLight.color * albedo * saturate(dot(mainLight.direction, worldNormal)) * mainLight.shadowAttenuation;

                // add light color
                real3 color = real3(0, 0, 0);
                int addLightCount = GetAdditionalLightsCount();
                for (int index; index < addLightCount; index++)
                {
                    Light addLight = GetAdditionalLight(index, i.worldPos, half4(1, 1, 1, 1));
                    color += addLight.color * albedo * saturate(dot(addLight.direction, worldNormal)) * addLight.distanceAttenuation * addLight.shadowAttenuation;
                }
                return real4(mainLightColor + color + ambient, 1.0);
            }
            ENDHLSL
        }
        // pass
        // {
        //     Tags { "LightMode" = "ShadowCaster" }
        //     HLSLPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
            
        //     float3 _LightDirection;
        //     float3 _LightPosition;
        //     float4 GetShadowPositionHClip(a2v input)
        //     {
        //         float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
        //         float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

        //         #if _CASTING_PUNCTUAL_LIGHT_SHADOW
        //             float3 lightDirectionWS = normalize(_LightPosition - positionWS);
        //         #else
        //             float3 lightDirectionWS = _LightDirection;
        //         #endif

        //         float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

        //         #if UNITY_REVERSED_Z
        //             positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
        //         #else
        //             positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
        //         #endif

        //         return positionCS;
        //     }
        //     v2f vert(in a2v v)
        //     {
        //         v2f o;
        //         o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
        //         o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
        //         o.positionCS = GetShadowPositionHClip(v);
        //         // o.positionCS = TransformWorldToHClip(ApplyShadowBias(o.worldPos, o.worldNormal, _LightDirection));
        //         return o;
        //     }
        //     real4 frag(in v2f i) : SV_TARGET
        //     {
        //         return 0;
        //     }
        //     ENDHLSL
        // }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}
