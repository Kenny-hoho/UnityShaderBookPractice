Shader "Unity Shader Book/Chapter7/MaskTex"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _NormalMap ("Normal Map", 2D) = "bump" { }
        _NormalScale ("NormalScale", Range(0, 1.0)) = 1.0
        _SepcularMask ("Sepcular Mask", 2D) = "white" { }
        _SepcularScale ("Sepcular Scale", Range(0, 1.0)) = 1.0
        _Sepcular ("Sepcular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float4 _SepcularMask_ST;
            half4 _BaseColor;
            half4 _Sepcular;
            float _Gloss;
            float _NormalScale;
            float _SepcularScale;
        CBUFFER_END
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalMap);
        SAMPLER(sampler_NormalMap);
        TEXTURE2D(_SepcularMask);
        SAMPLER(sampler_SepcularMask);

        struct a2v
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float2 texcoord : TEXCOORD;
        };
        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float4 TtoW1 : TEXCOORD1;
            float4 TtoW2 : TEXCOORD2;
            float4 TtoW3 : TEXCOORD3;
            float3 viewDir : TEXCOORD4;
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
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 worldNormal = TransformObjectToWorldNormal(v.normalOS);
                float3 worldTangent = TransformObjectToWorldDir(v.tangentOS);
                float3 worldBinormal = normalize(cross(worldNormal, worldTangent)) * v.tangentOS.w;
                float3 worldPos = TransformObjectToWorld(v.positionOS.xyz);
                o.viewDir = normalize(GetCameraPositionWS() - worldPos);
                o.TtoW1 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW2 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW3 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                // albedo
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _BaseColor.rgb;
                // ambient
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // compute worldSpace normal
                float4 bump = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv);
                float3 unpackedNormal = UnpackNormalScale(bump, _NormalScale);
                float3 normalWS = normalize(float3(dot(i.TtoW1.xyz, unpackedNormal), dot(i.TtoW2.xyz, unpackedNormal), dot(i.TtoW3.xyz, unpackedNormal)));
                // diffuse
                Light mainLight = GetMainLight();
                half3 diffuse = mainLight.color * albedo * saturate(dot(mainLight.direction, normalWS));
                // sepcular
                float sepcularMask = SAMPLE_TEXTURE2D(_SepcularMask, sampler_SepcularMask, i.uv).w * _SepcularScale;
                float3 halfVec = normalize(i.viewDir + mainLight.direction);
                half3 sepcular = _Sepcular.rgb * mainLight.color * pow(saturate(dot(halfVec, normalWS)), _Gloss) * sepcularMask;
                return real4(ambient + diffuse + sepcular, 1.0);
            }
            ENDHLSL
        }
    }
}
