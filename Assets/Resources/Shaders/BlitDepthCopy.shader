Shader "VertexFragment/BlitDepthCopy"
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
        }
        
        ZWrite On
        Cull Off

        Pass
        {
            Name "BlitCopy"

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

            float FragMain(VertOutput input) : SV_Depth
            {
                return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).r;
            }

            ENDHLSL
        }
    }
}