// Same as BlitCopy but it blends instead of a straight overwrite.
Shader "VertexFragment/BlitBlend"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "LightMode" = "UniversalForwardOnly"
        }
        
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            Name "BlitBlend"

            HLSLPROGRAM
            
            #pragma vertex VertMain
            #pragma fragment FragMain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
            CBUFFER_END

            VertOutput VertMain(Attributes input)
            {
                VertOutput output = (VertOutput)0;

                output.position = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID) * _BlitScaleBias.xy + _BlitScaleBias.zw;

                return output;
            }

            float4 FragMain(VertOutput input) : SV_Target
            {
                float4 sourceColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return sourceColor;
            }

            ENDHLSL
        }
    }
}