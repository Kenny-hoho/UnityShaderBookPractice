Shader "Unity Shader Book/Chapter9/MultiLIghtForward"
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
            float2 uv : TEXCOORD1;
            float3 worldPos : TEXCOORD2;
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
                o.worldNormal = TransformObjectToWorldNormal(v.normalOS);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos = TransformObjectToWorld(v.positionOS.xyz);
                return o;
            }
            real4 frag(in v2f i) : SV_TARGET
            {
                // mainlight
                // albedo
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _BaseColor.rgb;
                // ambient
                half3 ambient = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * albedo;
                // diffuse
                Light mainLight = GetMainLight();
                half3 mainColor = mainLight.color * albedo * saturate(dot(mainLight.direction, i.worldNormal));
                
                // addLight
                real3 addColor = real3(0, 0, 0);
                int addLightCount = GetAdditionalLightsCount();
                for (int j = 0; j < addLightCount; j++)
                {
                    Light addLight = GetAdditionalLight(j, i.worldPos);
                    addColor += addLight.color * albedo * saturate(dot(addLight.direction, i.worldNormal)) * addLight.distanceAttenuation;
                }

                return real4(addColor + mainColor + ambient, 1.0);
            }
            ENDHLSL
        }
    }
}