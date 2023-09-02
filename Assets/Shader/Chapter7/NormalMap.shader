Shader "Unity Shader Book/Chapter7/NormalMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _Sepuclar ("Sepuclar", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _NormalTex ("Normal Texture", 2D) = "bump" { }
        _NormalScale ("Normal Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NormalTex_ST;
            half4 _BaseColor;
            half4 _Sepuclar;
            float _Gloss;
            float _NormalScale;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_NormalTex);

        struct a2v
        {
            float4 position : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 texcoord : TEXCOORD;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float4 uv : TEXCOORD0;
            float4 TtoW1 : TEXCOORD1;
            float4 TtoW2 : TEXCOORD2;
            float4 TtoW3 : TEXCOORD3;
            float3 viewDir : TEXCOORD4;
        };
        ENDHLSL

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            v2f vert(in a2v v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.position.xyz);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex);
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                float3 worldPos = TransformObjectToWorld(v.position.xyz);
                float3 cameraPos = GetCameraPositionWS();
                o.viewDir = normalize(float3(cameraPos - worldPos));

                o.TtoW1 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW2 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW3 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                // albedo
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) * _BaseColor;
                // ambient
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // worldSpaceNoraml
                float4 bump = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv.zw);
                float3 Unpackedbump = UnpackNormalScale(bump, _NormalScale);
                float3 worldSpaceNormal = normalize(float3(dot(i.TtoW1.xyz, Unpackedbump), dot(i.TtoW2.xyz, Unpackedbump), dot(i.TtoW3.xyz, Unpackedbump)));
                // diffuse
                Light light = GetMainLight();
                half3 lightColor = light.color;
                float3 lightDir = normalize(light.direction);
                half3 diffuse = lightColor * albedo.xyz * saturate(dot(lightDir, worldSpaceNormal));
                // sepcular
                float3 worldPos = float3(i.TtoW1.w, i.TtoW2.w, i.TtoW3.w);
                float3 halfVec = normalize(i.viewDir + lightDir);
                half3 sepcular = _Sepuclar.rgb * lightColor * pow(saturate(dot(halfVec, worldSpaceNormal)), _Gloss);

                return real4(ambient + diffuse + sepcular, 1.0);
            }
            ENDHLSL
        }
    }
}
