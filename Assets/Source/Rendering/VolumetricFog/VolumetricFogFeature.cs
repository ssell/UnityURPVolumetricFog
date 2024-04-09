using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace VertexFragment
{
    public sealed class VolumetricFogFeature : ScriptableRendererFeature
    {
        public VolumetricFogSettings Settings = new VolumetricFogSettings();
        private VolumetricFogPass Pass;

        public override void Create()
        {
            Pass = new VolumetricFogPass(Settings);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera != Camera.main)
            {
                return;
            }

            renderer.EnqueuePass(Pass);
        }

        [System.Serializable]
        public sealed class VolumetricFogSettings
        {
            public RenderPassEvent Event = RenderPassEvent.BeforeRenderingPostProcessing;
            public Material VolumetricFogMaterial;
            public bool InstantiateMaterial;
        }
    }
}