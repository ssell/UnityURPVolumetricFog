using UnityEngine;

namespace VertexFragment
{
    public sealed class FogVolume : MonoBehaviour
    {
        public float Radius = 10.0f;

        private void Start()
        {
            VolumetricFogPass.AddFogVolume(this);
        }

        private void OnDestroy()
        {
            VolumetricFogPass.RemoveFogVolume(this);
        }
    }
}
