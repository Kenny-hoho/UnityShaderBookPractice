Shader "Unity Shader Book/Chapter7/RampMap"
{
    Properties
    {
        _RampMap ("RampMap", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Sepcular ("Sepcular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _SepcularArea ("Sepcular Area", Range(0, 1)) = 0.8
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _RampMap_ST;
            half4 _BaseColor;
            half4 _Sepcular;
            float _Gloss;
            float _SepcularArea;
        CBUFFER_END
        TEXTURE2D(_RampMap);
        SAMPLER(sampler_RampMap);
        
        struct a2v
        {
            float4 position : POSITION;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD;
        };
        struct v2f
        {
            float4 pos : SV_POSITION;
            float3 worldNormal : TEXCOORD0;
            float3 viewDir : TEXCOORD2;
            float2 uv : TEXCOORD1;
        };
        ENDHLSL

        pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(in a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.position.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.texcoord, _RampMap);
                o.viewDir = normalize(GetCameraPositionWS()-TransformObjectToWorld(v.position.xyz));
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET{
                // prepare
                Light light = GetMainLight();
                half halfLambert = dot(light.direction, i.worldNormal) * 0.5 + 0.5;
                // diffuse color
                half3 diffuseColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, half2(halfLambert, 0.5)).rgb * _BaseColor.rgb;
                // ambient
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * diffuseColor.rgb;
                // sepcular
                float3 halfVec = normalize(light.direction + i.viewDir);
                float3 worldNormal = normalize(i.worldNormal);
                float sep = pow(saturate(dot(worldNormal, halfVec)), _Gloss);
                if(sep < _SepcularArea){
                    sep = 0;
                }
                half3 sepcular = _Sepcular.rgb * light.color * sep;
                return real4(ambient + diffuseColor + sepcular, 1.0);
            }
            ENDHLSL
        }
    }
}
