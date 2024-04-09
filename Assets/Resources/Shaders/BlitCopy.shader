// Copies the provided texture onto the target. No blending, no checks, just straight copy overwrite.
Shader "VertexFragment/BlitCopy"
{
    Properties
    {
        // Note: Used to use _MainTex, but the Unity Blitter class uses this name. So changed for compatibility.
        _BlitTexture ("Blit Texture", 2D) = "black" {}
    }

    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        
        ZWrite Off
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

            // _BlitTexture and sampler_LinearRepeat already defined in Blit.hlsl

            VertOutput VertMain(Attributes input)
            {
                VertOutput output = (VertOutput)0;

                output.position = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID) * _BlitScaleBias.xy + _BlitScaleBias.zw;

                return output;
            }

            float4 FragMain(VertOutput input) : SV_Target
            {
                float4 sourceColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearRepeat, input.uv);
                return sourceColor;
            }

            ENDHLSL
        }
    }
}