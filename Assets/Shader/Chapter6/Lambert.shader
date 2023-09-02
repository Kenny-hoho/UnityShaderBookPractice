Shader "Unity Shader Book/Chapter6/Lambert"
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
                return o;
            }
            half4 frag(in v2f i) : SV_TARGET
            {
                // albedo
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _BaseColor;
                // ambient
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // diffuse
                Light light = GetMainLight();
                half3 lightDir = normalize(light.direction);
                half3 lightColor = light.color;
                half3 diffuse = lightColor * albedo.xyz * saturate(dot(lightDir, i.worldNormal));
                return half4(diffuse + ambient, 1.0);
            }
            ENDHLSL
        }
    }
}
