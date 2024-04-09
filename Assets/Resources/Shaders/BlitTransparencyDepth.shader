Shader "VertexFragment/BlitTransparencyDepthCopy"
{
    Properties
    {
        _BlitCopyTexture ("Blit Texture", 2D) = "white" {}
        _BlitCopyDepthTexture ("Blit Depth Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZWrite On
        ZTest LEqual

        Pass
        {
            Name "BlitCopyTriangle"

            HLSLPROGRAM
            
            #pragma vertex VertMain
            #pragma fragment FragMain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
                TEXTURE2D(_BlitCopyTexture);
                SAMPLER(sampler_BlitCopyTexture);

                TEXTURE2D(_BlitCopyDepthTexture);
                SAMPLER(sampler_BlitCopyDepthTexture);
            CBUFFER_END

            VertOutput VertMain(Attributes input)
            {
                VertOutput output = (VertOutput)0;

                // See: https://github.com/microsoft/DirectX-Graphics-Samples/blob/a79e01c4c39e6d40f4b078688ff95814d166d34f/MiniEngine/Core/Shaders/ScreenQuadCommonVS.hlsl#L2
                output.uv = float2(uint2(input.vertexID, input.vertexID << 1) & 2);
                output.position = float4(lerp(float2(-1.0f, 1.0f), float2(1.0f, -1.0f), output.uv), 0.0f, 1.0f);

                return output;
            }

            ForwardFragmentOutput FragMain(VertOutput input)
            {
                ForwardFragmentOutput output = (ForwardFragmentOutput)0;

                float4 blitColor = SAMPLE_TEXTURE2D(_BlitCopyTexture, sampler_BlitCopyTexture, input.uv);
                float blitDepth = SAMPLE_TEXTURE2D(_BlitCopyDepthTexture, sampler_BlitCopyDepthTexture, input.uv).r;

                output.Color = blitColor;
                output.Depth = blitDepth; 
                
                return output;
            }

            ENDHLSL
        }

        Pass
        {
            Name "BlitCopyQuad"

            HLSLPROGRAM
            
            #pragma vertex VertMain
            #pragma fragment FragMain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
                TEXTURE2D(_BlitCopyTexture);
                SAMPLER(sampler_BlitCopyTexture);

                TEXTURE2D(_BlitCopyDepthTexture);
                SAMPLER(sampler_BlitCopyDepthTexture);
            CBUFFER_END

            VertOutput VertMain(VertInput input)
            {
                VertOutput output = (VertOutput)0;

                output.position = float4(input.position.xyz, 1.0f);
                output.uv = ComputeScreenPos(output.position).xy;

                return output;
            }

            ForwardFragmentOutput FragMain(VertOutput input)
            {
                ForwardFragmentOutput output = (ForwardFragmentOutput)0;

                float4 blitColor = SAMPLE_TEXTURE2D(_BlitCopyTexture, sampler_BlitCopyTexture, input.uv);
                float blitDepth = SAMPLE_TEXTURE2D(_BlitCopyDepthTexture, sampler_BlitCopyDepthTexture, input.uv).r;

                output.Color = blitColor;
                output.Depth = blitDepth; 
                
                return output;
            }

            ENDHLSL
        }

        Pass
        {
            Name "BlitCopyCustomMesh"

            HLSLPROGRAM
            
            #pragma vertex VertMain
            #pragma fragment FragMain

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
                TEXTURE2D(_BlitCopyTexture);
                SAMPLER(sampler_BlitCopyTexture);

                TEXTURE2D(_BlitCopyDepthTexture);
                SAMPLER(sampler_BlitCopyDepthTexture);
            CBUFFER_END

            VertOutput VertMain(VertInput input)
            {
                VertOutput output = (VertOutput)0;

                output.position = TransformWorldToHClip(TransformObjectToWorld(input.position.xyz));
                output.tex1 = ComputeScreenPos(output.position);
                output.uv = input.uv;

                return output;
            }

            ForwardFragmentOutput FragMain(VertOutput input)
            {
                ForwardFragmentOutput output = (ForwardFragmentOutput)0;

                float4 blitColor = SAMPLE_TEXTURE2D(_BlitCopyTexture, sampler_BlitCopyTexture, input.uv);
                float blitDepth = SAMPLE_TEXTURE2D(_BlitCopyDepthTexture, sampler_BlitCopyDepthTexture, input.uv).r;

                output.Color = blitColor;
                output.Depth = blitDepth; 
                
                return output;
            }

            ENDHLSL
        }
    }
}