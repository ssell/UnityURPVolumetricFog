using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace VertexFragment
{
    public sealed class VolumetricFogPass : CustomRenderPass
    {
        /// <summary>
        /// List of fog volumes to render.
        /// </summary>
        private static readonly List<FogVolume> FogVolumes = new List<FogVolume>();

        /// <summary>
        /// Black with 0 alpha.
        /// </summary>
        private static readonly Color ColorNothing = new Color(0, 0, 0, 0);

        /// <summary>
        /// Are there any fog volumes to render this frame?
        /// </summary>
        private static bool ShouldRender;

        /// <summary>
        /// The fog volume material instance being used.
        /// </summary>
        private Material FogMaterialInstance;

        /// <summary>
        /// The per-render property block.
        /// </summary>
        private MaterialPropertyBlock FogMaterialProperties;

        /// <summary>
        /// The double-buffered render target. Is this needed anymore (to be double-buffered)?
        /// </summary>
        private BufferedRenderTargetReference BufferedFogRenderTarget;

        public VolumetricFogPass(VolumetricFogFeature.VolumetricFogSettings settings)
        {
            renderPassEvent = settings.Event;
            FogMaterialInstance = (settings.InstantiateMaterial ? GameObject.Instantiate(settings.VolumetricFogMaterial) : settings.VolumetricFogMaterial);
            FogMaterialProperties = new MaterialPropertyBlock();
            BufferedFogRenderTarget = null;
        }

        // ---------------------------------------------------------------------------------
        // Rendering
        // ---------------------------------------------------------------------------------

        public override void OnCameraSetup(CommandBuffer commandBuffer, ref RenderingData renderingData)
        {
            ShouldRender = FogVolumes.Exists(f => f.gameObject.activeInHierarchy);

            if (!ShouldRender)
            {
                return;
            }

            if (HasCameraResized(ref renderingData))
            {
                BufferedFogRenderTarget = BufferedFogRenderTarget ?? new BufferedRenderTargetReference("_BufferedVolumetricFogRenderTarget");
                BufferedFogRenderTarget.SetRenderTextureDescriptor(new RenderTextureDescriptor(
                    renderingData.cameraData.cameraTargetDescriptor.width,
                    renderingData.cameraData.cameraTargetDescriptor.height,
                    RenderTextureFormat.ARGB32, 0, 1), FilterMode.Bilinear, TextureWrapMode.Clamp);
            }

            BufferedFogRenderTarget.Clear(commandBuffer, ColorNothing);

            FogMaterialProperties.SetMatrix(ShaderIds.CameraNearPlaneCorners, renderingData.cameraData.camera.GetNearClipPlaneCornersMatrix());
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (!ShouldRender)
            {
                return;
            }

            CommandBuffer commandBuffer = CommandBufferPool.Get("VolumetricFogPass");

            using (new ProfilingScope(commandBuffer, new ProfilingSampler("VolumetricFogPass")))
            {
                foreach (var fogVolume in FogVolumes)
                {
                    if (!fogVolume.gameObject.activeInHierarchy)
                    {
                        continue;
                    }

                    fogVolume.Apply(FogMaterialProperties);

                    RasterizeColorToTarget(commandBuffer, BufferedFogRenderTarget.BackBuffer.Handle, FogMaterialInstance, BlitGeometry.Quad, 0, FogMaterialProperties);
                }

                BlitBlendOntoCamera(commandBuffer, BufferedFogRenderTarget.BackBuffer.Handle, ref renderingData);
            }

            context.ExecuteCommandBuffer(commandBuffer);
            commandBuffer.Clear();

            BufferedFogRenderTarget.Swap();

            CommandBufferPool.Release(commandBuffer);
        }

        // ---------------------------------------------------------------------------------
        // Misc
        // ---------------------------------------------------------------------------------

        /// <summary>
        /// Adds a <see cref="DepthFog"/> to the render list.
        /// </summary>
        /// <param name="volume"></param>
        public static void AddFogVolume(FogVolume volume)
        {
            RemoveFogVolume(volume);
            FogVolumes.Add(volume);
        }

        /// <summary>
        /// Removes a <see cref="DepthFog"/> from the render list.
        /// </summary>
        /// <param name="volume"></param>
        public static void RemoveFogVolume(FogVolume volume)
        {
            FogVolumes.RemoveAll(f => f == volume);
        }
    }
}
