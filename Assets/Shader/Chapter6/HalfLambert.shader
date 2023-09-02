Shader "Unity Shader Book/Chapter6/HalfLambert"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
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
            float2 texcoord : TEXCOORD1;
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
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
                return o;
            }
            half4 frag(in v2f i) : SV_TARGET
            {
                // albedo
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord) * _BaseColor;
                // ambient 
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // diffuse
                Light myLight = GetMainLight();
                half3 lightColor = myLight.color;
                float3 lightDir = normalize(myLight.direction);
                half3 diffuse = lightColor * albedo.xyz * (dot(lightDir, i.worldNormal) * 0.5 + 0.5);
                return half4(diffuse + ambient, 1.0);
            }
            ENDHLSL
        }
    }
}
