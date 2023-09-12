Shader "Unity Shader Book/Example/AlphaTestLit" {
    Properties {
        _MainTex ("Texture", 2D) = "white" { }
        _TintColor ("Base Color", Color) = (1, 1, 1, 1)
        [KeywordEnum(ON, OFF)] _ADD_LIGHT ("AddLight", Float) = 1
        [KeywordEnum(ON, OFF)]_CUT ("Cut", Float) = 1
        _Gloss ("Gloss", Range(8, 64)) = 16
        _CutOff ("_CutOff", Range(0, 1)) = 0.5
        _Ambient_Scale("Ambient Scale", Range(0,1)) = 0.1
    }
    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "AlphaTest" "Queue" = "AlphaTest" }
        Cull Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        #pragma shader_feature_local _CUT_ON
        #pragma shader_feature_local _ADD_LIGHT_ON
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _TintColor;
            float _Gloss;
            float _CutOff;
            float _Ambient_Scale;
        CBUFFER_END
        
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD0;
            float3 normalOS : NORMAL;
        };
        
        struct v2f {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 normalWS : TEXCOORD1;
            float3 positionWS : TEXCOORD2;
        };

        ENDHLSL

        Pass {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i) {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target {
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                albedo.rgb *= _TintColor.rgb;
                i.normalWS = normalize(i.normalWS);
            #ifdef _CUT_ON
                clip(albedo.a - _CutOff);
            #endif

                //mainlight part
            #ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowcoord = TransformWorldToShadowCoord(i.positionWS);
                Light mainLight = GetMainLight(shadowcoord);
            #else
                Light mainLight = GetMainLight();
            #endif

                float3 lightDir = normalize(mainLight.direction);
                float diff = saturate(dot(i.normalWS, lightDir));
                half3 diffuse = mainLight.color * albedo.rgb * diff * mainLight.shadowAttenuation;
                float spec = pow(saturate(dot(i.normalWS, normalize(lightDir + viewDir))), _Gloss);
                half3 specular = mainLight.color * albedo.rgb * spec * mainLight.shadowAttenuation;
                half3 mainColor = diffuse + specular;

                //multi lights part
                half3 addColor = half3(0, 0, 0);
            #if _ADD_LIGHT_ON
                int addLightNum = GetAdditionalLightsCount();
                for (int index = 0; index < addLightNum; index++) {
                    Light addLight = GetAdditionalLight(index, i.positionWS, half4(1, 1, 1, 1));
                    float3 addLightDir = normalize(addLight.direction);
                    float diff = saturate(dot(i.normalWS, addLightDir));
                    half3 diffuse = addLight.color * albedo.rgb * diff * addLight.shadowAttenuation * addLight.distanceAttenuation;
                    float spec = pow(saturate(dot(i.normalWS, normalize(addLightDir + viewDir))), _Gloss);
                    half3 specular = addLight.color * albedo.rgb * spec * addLight.shadowAttenuation * addLight.distanceAttenuation;
                    addColor += diffuse + specular;
                }
            #endif
                half3 ambient = SampleSH(i.normalWS) * _Ambient_Scale;
                return half4(mainColor + addColor + ambient, albedo.a);
            }
            ENDHLSL
        }

        Pass {
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            
            half3 _LightDirection;
            v2f vertShadow(a2v i) {
                v2f o;
                o.uv = TRANSFORM_TEX(i.texcoord, _MainTex);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                Light mainLight = GetMainLight();
                o.positionCS = TransformWorldToHClip(ApplyShadowBias(o.positionWS, o.normalWS, _LightDirection));
                
                //判断是否在DirectX平台，决定是否反转坐标
            #if UNITY_REVERSED_Z
                o.positionCS.z = min(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                o.positionCS.z = max(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif
                
                return o;
            }

            half4 fragShadow(v2f i) : SV_Target {
            #ifdef _CUT_ON
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                clip(albedo.a - _CutOff);
            #endif
                return 0;
            }
            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}
