Shader "Unity Shader Book/Chapter6/BlinnPhong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        _Sepcular ("Sepcular", Color) = (1, 1, 1, 1)
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
            half4 _BaseColor;
            half4 _Sepcular;
            float _Gloss;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

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
                o.pos = TransformObjectToHClip(v.position);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 worldPos = TransformObjectToWorld(v.position.xyz);
                float3 cameraPos = GetCameraPositionWS();
                o.viewDir = normalize(cameraPos - worldPos);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                // albedo
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;
                // ambient
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // diffuse
                Light light = GetMainLight();
                float3 lightDir = light.direction;
                half3 lightColor = light.color;
                half3 diffuse = albedo.xyz * lightColor * saturate(dot(lightDir, i.worldNormal));
                // sepuclar
                float3 halfVec = normalize(lightDir + i.viewDir);
                half3 sepcular = _Sepcular.rgb * lightColor * pow(saturate(dot(halfVec, i.worldNormal)), _Gloss);
                return real4(ambient + diffuse + sepcular, 1.0);
            }
            ENDHLSL
        }
    }
}
