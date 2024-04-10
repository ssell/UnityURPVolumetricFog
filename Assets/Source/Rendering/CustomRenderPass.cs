using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace VertexFragment
{
    public abstract class CustomRenderPass : ScriptableRenderPass
    {
        public enum BlitGeometry
        {
            Triangle = 0,
            Quad = 1
        };

        /// <summary>
        /// Before URP 14 there were two things that are no longer true:
        /// 
        /// <list type="number">
        ///     <item>Calling <see cref="ScriptableRenderPass.Blit(CommandBuffer, RTHandle, RTHandle, Material, int)"/> without a material would simply do a copy with some internal material.</item>
        ///     <item>Calling Blit would also automatically set the "source" texture as "_MainTex"</item>
        /// </list>
        /// 
        /// Since neither of these is true anymore (?), we now need this utility material which does it for us.
        /// You will need to set the <c>_MainTex</c> (<see cref="ShaderIds.MainTex"/>) value of this material to setup the texture to copy over.<para/>
        /// 
        /// Note that since the <see cref="CommandBuffer"/> operates async, and the call to <see cref="Material.SetTexture"/> is not, then you will only be
        /// able to safely use this once per pass/execute. Unless of course you instantiate more of them.
        /// </summary>
        protected Material BlitCopyMaterial;

        /// <summary>
        /// Similar to <see cref="BlitCopyMaterial"/> but performs a blend instead of a straight copy.
        /// </summary>
        protected Material BlitBlendMaterial;

        /// <summary>
        /// 
        /// </summary>
        protected Material BlitDepthCopyMaterial;

        /// <summary>
        /// 
        /// </summary>
        protected Material BlitTransparencyDepthCopyMaterial;

        /// <summary>
        /// Seems to be a mesh, that is triangle in shape.
        /// </summary>
        protected static CustomMesh TriangleMesh;

        /// <summary>
        /// Seems to be a mesh, that is square in shape.
        /// </summary>
        protected static CustomMesh QuadMesh;

        /// <summary>
        /// Width of the camera, in pixels, the previous frame.
        /// </summary>
        private int PreviousCameraWidth;

        /// <summary>
        /// Height of the camera, in pixels, the previous frame.
        /// </summary>
        private int PreviousCameraHeight;

        public CustomRenderPass()
        {
            BlitCopyMaterial = CoreUtils.CreateEngineMaterial("VertexFragment/BlitCopy");
            BlitBlendMaterial = CoreUtils.CreateEngineMaterial("VertexFragment/BlitBlend");
            BlitDepthCopyMaterial = CoreUtils.CreateEngineMaterial("VertexFragment/BlitDepthCopy");
            BlitTransparencyDepthCopyMaterial = CoreUtils.CreateEngineMaterial("VertexFragment/BlitTransparencyDepthCopy");

            if (TriangleMesh == null)
            {
                TriangleMesh = new CustomMesh("BlitTriangle");
                TriangleMesh.InitializeBuffers(3);
                TriangleMesh.AddTriangle(Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero, Vector3.zero);
                TriangleMesh.Build();
            }

            if (QuadMesh == null)
            {
                CustomVertex ll = new CustomVertex(new Vector3(-1.0f, -1.0f, 0.0f), new Vector2(0.0f, 1.0f));   // Hey man, your uv.y values are reversed!
                CustomVertex lr = new CustomVertex(new Vector3(1.0f, -1.0f, 0.0f), new Vector2(1.0f, 1.0f));    // Yea, something odd is done by the Unity blitter where this is needed.
                CustomVertex ur = new CustomVertex(new Vector3(1.0f, 1.0f, 0.0f), new Vector2(1.0f, 0.0f));     // Otherwise the UV is upside down. I am sure some future update will come
                CustomVertex ul = new CustomVertex(new Vector3(-1.0f, 1.0f, 0.0f), new Vector2(0.0f, 0.0f));    // along and fix this which will then of course break this workaround.

                QuadMesh = new CustomMesh("BlitQuad");
                QuadMesh.InitializeBuffers(6);
                QuadMesh.AddFace(ll, lr, ur, ul);
                QuadMesh.Build();
            }
        }

        /// <summary>
        /// Detects if the camera pixel size has changed.
        /// </summary>
        /// <param name="renderingData"></param>
        /// <returns></returns>
        protected bool HasCameraResized(ref RenderingData renderingData)
        {
            if ((renderingData.cameraData.camera.pixelWidth != PreviousCameraWidth) || (renderingData.cameraData.camera.pixelHeight != PreviousCameraHeight))
            {
                PreviousCameraWidth = renderingData.cameraData.camera.pixelWidth;
                PreviousCameraHeight = renderingData.cameraData.camera.pixelHeight;

                return true;
            }

            return false;
        }

        /// <summary>
        /// Copies the provided texture onto the camera color buffer using the <see cref="BlitCopyMaterial"/>.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="sourceHandle"></param>
        /// <param name="renderingData"></param>
        protected void BlitCopyOntoCamera(CommandBuffer commandBuffer, RTHandle sourceHandle, ref RenderingData renderingData)
        {
            BlitCopyMaterial.SetTexture(ShaderIds.BlitTexture, sourceHandle, RenderTextureSubElement.Color);
            Blit(commandBuffer, sourceHandle, renderingData.cameraData.renderer.cameraColorTargetHandle, BlitCopyMaterial);
        }

        /// <summary>
        /// Blends the provided texture onto the camera color buffer using the <see cref="BlitBlendMaterial"/>.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="sourceHandle"></param>
        /// <param name="renderingData"></param>
        protected void BlitBlendOntoCamera(CommandBuffer commandBuffer, RTHandle sourceHandle, ref RenderingData renderingData)
        {
            BlitBlendMaterial.SetTexture(ShaderIds.MainTex, sourceHandle, RenderTextureSubElement.Color);
            Blit(commandBuffer, sourceHandle, renderingData.cameraData.renderer.cameraColorTargetHandle, BlitBlendMaterial);
        }

        /// <summary>
        /// Copies the provided texture onto the camera color buffer using the <see cref="BlitDepthCopyMaterial"/>.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="sourceHandle"></param>
        /// <param name="renderingData"></param>
        protected void BlitCopyDepthOntoCamera(CommandBuffer commandBuffer, RTHandle sourceHandle, ref RenderingData renderingData)
        {
            BlitDepthCopyMaterial.SetTexture(ShaderIds.MainTex, sourceHandle, RenderTextureSubElement.Depth);
            Blit(commandBuffer, sourceHandle, renderingData.cameraData.renderer.cameraDepthTargetHandle, BlitDepthCopyMaterial);
        }

        /// <summary>
        /// Given a color and depth texture, mimics rasterizing them onto the primary camera color and depth textures.
        /// Effectively blends the color and performs depth checking.<para/>
        /// 
        /// NOTE: Writing to the depth buffer will only work in <see cref="RenderPassEvent.BeforeRenderingGbuffer"/> or <see cref="RenderPassEvent.AfterRenderingPrePasses"/>.
        /// It will still perform the depth test outside of those, but the depth value will not be written to the <c>_CameraDepthTexture</c>.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="renderingData"></param>
        /// <param name="colorHandle"></param>
        /// <param name="depthHandle"></param>
        /// <param name="geometry"></param>
        /// <param name="materialOverride"></param>
        protected void RasterizeColorAndDepthToCamera(CommandBuffer commandBuffer, ref RenderingData renderingData, RTHandle colorHandle, RTHandle depthHandle, BlitGeometry geometry = BlitGeometry.Triangle, Material materialOverride = null)
        {
            commandBuffer.SetRenderTarget(renderingData.cameraData.renderer.cameraColorTargetHandle, renderingData.cameraData.renderer.cameraDepthTargetHandle);

            MaterialPropertyBlock blitProperties = new MaterialPropertyBlock();
            blitProperties.SetTexture(ShaderIds.BlitCopyTexture, colorHandle);
            blitProperties.SetTexture(ShaderIds.BlitCopyDepthTexture, depthHandle);

            var mesh = (geometry == BlitGeometry.Triangle ? TriangleMesh.Mesh : QuadMesh.Mesh);
            var material = materialOverride ?? BlitTransparencyDepthCopyMaterial;
            int passIndex = 0;

            if (materialOverride == null)
            {
                // 0 = triangle shader pass, 1 = quad shader pass, 2 = custom mesh shader pass.
                passIndex = (int)geometry;
            }

            commandBuffer.DrawMesh(mesh, Matrix4x4.identity, material, 0, passIndex, blitProperties);
        }

        /// <summary>
        /// Given a color and depth texture, mimics rasterizing them onto the primary camera color and depth textures.
        /// Effectively blends the color and performs depth checking.<para/>
        /// 
        /// NOTE: Writing to the depth buffer will only work in <see cref="RenderPassEvent.BeforeRenderingGbuffer"/> or <see cref="RenderPassEvent.AfterRenderingPrePasses"/>.
        /// It will still perform the depth test outside of those, but the depth value will not be written to the <c>_CameraDepthTexture</c>.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="renderingData"></param>
        /// <param name="colorHandle"></param>
        /// <param name="depthHandle"></param>
        /// <param name="mesh"></param>
        /// <param name="matrix"></param>
        /// <param name="materialOverride"></param>
        protected void RasterizeColorAndDepthToCamera(CommandBuffer commandBuffer, ref RenderingData renderingData, RTHandle colorHandle, RTHandle depthHandle, Mesh mesh, Matrix4x4? matrix = null, Material materialOverride = null)
        {
            commandBuffer.SetRenderTarget(renderingData.cameraData.renderer.cameraColorTargetHandle, renderingData.cameraData.renderer.cameraDepthTargetHandle);

            MaterialPropertyBlock blitProperties = new MaterialPropertyBlock();
            blitProperties.SetTexture(ShaderIds.BlitCopyTexture, colorHandle);
            blitProperties.SetTexture(ShaderIds.BlitCopyDepthTexture, depthHandle);

            var material = materialOverride ?? BlitTransparencyDepthCopyMaterial;
            int passIndex = 0;

            if (materialOverride == null)
            {
                // 0 = triangle shader pass, 1 = quad shader pass, 2 = custom mesh shader pass.
                passIndex = 2;
            }

            commandBuffer.DrawMesh(mesh, matrix ?? Matrix4x4.identity, material, 0, passIndex, blitProperties);
        }

        /// <summary>
        /// Renders onto the specified render targets using the provided material and the specified blit geometry.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="colorTarget"></param>
        /// <param name="depthTarget"></param>
        /// <param name="materialOverride"></param>
        /// <param name="geometry"></param>
        /// <param name="shaderPassIndex"></param>
        /// <param name="properties"></param>
        protected void RasterizeColorAndDepthToTarget(CommandBuffer commandBuffer, RTHandle colorTarget, RTHandle depthTarget, Material materialOverride = null, BlitGeometry geometry = BlitGeometry.Triangle, int shaderPassIndex = 0, MaterialPropertyBlock properties = null)
        {
            var mesh = (geometry == BlitGeometry.Triangle ? TriangleMesh.Mesh : QuadMesh.Mesh);
            var material = materialOverride ?? BlitTransparencyDepthCopyMaterial;

            commandBuffer.SetRenderTarget(colorTarget, depthTarget);
            commandBuffer.DrawMesh(mesh, Matrix4x4.identity, material, 0, shaderPassIndex, properties);
        }

        /// <summary>
        /// Renders onto the specified render target usingthe provided material and the specified blit geometry.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="colorTarget"></param>
        /// <param name="materialOverride"></param>
        /// <param name="geometry"></param>
        /// <param name="shaderPassIndex"></param>
        /// <param name="properties"></param>
        protected void RasterizeColorToTarget(CommandBuffer commandBuffer, RTHandle colorTarget, Material materialOverride = null, BlitGeometry geometry = BlitGeometry.Triangle, int shaderPassIndex = 0, MaterialPropertyBlock properties = null)
        {
            var mesh = (geometry == BlitGeometry.Triangle ? TriangleMesh.Mesh : QuadMesh.Mesh);
            var material = materialOverride ?? BlitTransparencyDepthCopyMaterial;

            commandBuffer.SetRenderTarget(colorTarget);
            commandBuffer.DrawMesh(mesh, Matrix4x4.identity, material, 0, shaderPassIndex, properties);
        }
    }
}
