using UnityEngine;

namespace VertexFragment
{
    public sealed class FogVolume : MonoBehaviour
    {
        /// <summary>
        /// The radius of the sphere volume.
        /// </summary>
        [Tooltip("The radius of the sphere volume.")]
        public float Radius = 10.0f;

        /// <summary>
        /// The maximum world-y that this fog can occur.
        /// </summary>
        [Tooltip("The maximum world-y that this fog can occur.")]
        public float MaxY = 200.0f;

        /// <summary>
        /// The distance to fade the fog as it nears the maximum world-y.
        /// </summary>
        [Tooltip("The distance to fade the fog as it nears the maximum world-y.")]
        public float YFade = 50.0f;

        /// <summary>
        /// The distance to fade the fog as it nears any edge of the bounding sphere.
        /// </summary>
        [Tooltip("The distance to fade the fog as it nears any edge of the bounding sphere.")]
        public float EdgeFade = 50.0f;

        /// <summary>
        /// Distance from the camera that the fog reaches full intensity.
        /// </summary>
        [Tooltip("Distance from the camera that the fog reaches full intensity.")]
        public float ProximityFade = 15.0f;

        /// <summary>
        /// The density of the fog.
        /// </summary>
        [Tooltip("The density of the fog.")]
        [Range(0.0f, 10.0f)]
        public float FogDensity = 1.2f;

        /// <summary>
        /// Exponential modifier applied to the primary fog noise map.
        /// </summary>
        [Tooltip("Exponential modifier applied to the primary fog noise map.")]
        [Range(1.0f, 16.0f)]
        public float FogExponent = 1.0f;

        /// <summary>
        /// Exponential modifier applied to the detail fog noise map.
        /// </summary>
        [Tooltip("Exponential modifier applied to the detail fog noise map.")]
        [Range(1.0f, 16.0f)]
        public float DetailFogExponent = 1.0f;

        /// <summary>
        /// Lower bound noise value.
        /// </summary>
        [Tooltip("Lower bound noise value.")]
        [Range(0.0f, 1.0f)]
        public float FogShapeMask = 0.25f;

        /// <summary>
        /// Contribution of primary fog vs detail fog. 0 = all primary fog, 1 = all detail fog.
        /// </summary>
        [Tooltip("Contribution of primary fog vs detail fog. 0 = all primary fog, 1 = all detail fog.")]
        [Range(0.0f, 1.0f)]
        public float FogDetailStrength = 0.4f;

        /// <summary>
        /// Color of the fog facing away from the primary light source. Alpha influence fog density.
        /// </summary>
        [Tooltip("Color of the fog facing away from the primary light source. Alpha influence fog density.")]
        [ColorUsage(true, true)]
        public Color FogColor = Color.white;

        /// <summary>
        /// Color of the fog facing the primary light source. Alpha influence fog density.
        /// </summary>
        [Tooltip("Color of the fog facing the primary light source. Alpha influence fog density.")]
        [ColorUsage(true, true)]
        public Color DirectionalFogColor = Color.white;

        /// <summary>
        /// Exponential fall-off factor for the directional light source. Higher the value, faster is falls-off.
        /// </summary>
        [Tooltip("Exponential fall-off factor for the directional light source. Higher the value, faster is falls-off.")]
        [Range(1.0f, 16.0f)]
        public float DirectionalFallOff = 2.0f;

        /// <summary>
        /// How much the fog color is influenced by the primary light source when facing away.
        /// </summary>
        [Tooltip("How much the fog color is influenced by the primary light source when facing away.")]
        [Range(0.0f, 1.0f)]
        public float LightContribution = 1.0f;

        /// <summary>
        /// How much the folow color is influenced by the primary light source when facing toward it.
        /// </summary>
        [Tooltip("How much the folow color is influenced by the primary light source when facing toward it.")]
        [Range(0.0f, 1.0f)]
        public float DirectionalLightContribution = 1.0f;

        /// <summary>
        /// How much does shadows darken the fog.
        /// </summary>
        [Tooltip("How much does shadows darken the fog.")]
        [Range(0.0f, 1.0f)]
        public float ShadowStrength = 1.0f;

        /// <summary>
        /// How much do shadows darken the fog when facing away from the light source.
        /// </summary>
        [Tooltip("How much do shadows darken the fog when facing away from the light source.")]
        [Range(0.0f, 1.0f)]
        public float ShadowReverseStrength = 0.3f;

        /// <summary>
        /// Direction the fog is moving.
        /// </summary>
        [Tooltip("Direction the fog is moving.")]
        public Vector3 FogDirection = new Vector3(1.0f, 0.0f, 0.0f);

        /// <summary>
        /// The speed the fog is moving.
        /// </summary>
        [Tooltip("The speed the fog is moving.")]
        public float FogSpeed = 30.0f;

        /// <summary>
        /// Speed multiplier applied to the detail fog.
        /// </summary>
        [Tooltip("Speed multiplier applied to the detail fog.")]
        public float DetailFogSpeedModifier = 1.5f;

        /// <summary>
        /// Tiling for the primary fog noise.
        /// </summary>
        [Tooltip("Tiling for the primary fog noise.")]
        public Vector3 FogTiling = new Vector3(0.0015f, 0.0015f, 0.0015f);

        /// <summary>
        /// Tiling for the detail fog noise.
        /// </summary>
        [Tooltip("Tiling for the detail fog noise.")]
        public Vector3 DetailFogTiling = new Vector3(0.001f, 0.001f, 0.001f);

        private void Start()
        {
            VolumetricFogPass.AddFogVolume(this);
        }

        private void OnDestroy()
        {
            VolumetricFogPass.RemoveFogVolume(this);
        }

        public void Apply(MaterialPropertyBlock propertyBlock)
        {
            propertyBlock.SetVector(Properties.BoundingSphere, new Vector4(transform.position.x, transform.position.y, transform.position.z, Radius));
            propertyBlock.SetFloat(Properties.FogMaxY, MaxY);
            propertyBlock.SetFloat(Properties.FogFadeY, YFade);
            propertyBlock.SetFloat(Properties.FogFadeEdge, EdgeFade);
            propertyBlock.SetFloat(Properties.FogProximityFade, ProximityFade);
            propertyBlock.SetFloat(Properties.FogDensity, FogDensity);
            propertyBlock.SetFloat(Properties.FogExponent, FogExponent);
            propertyBlock.SetFloat(Properties.DetailFogExponent, DetailFogExponent);
            propertyBlock.SetFloat(Properties.FogCutOff, FogShapeMask);
            propertyBlock.SetFloat(Properties.FogDetailStrength, FogDetailStrength);
            propertyBlock.SetColor(Properties.FogColor, FogColor);
            propertyBlock.SetColor(Properties.DirectionalFogColor, DirectionalFogColor);
            propertyBlock.SetFloat(Properties.DirectionalFallExponent, DirectionalFallOff);
            propertyBlock.SetFloat(Properties.ShadowStrength, ShadowStrength);
            propertyBlock.SetFloat(Properties.ShadowReverseStrength, ShadowReverseStrength);
            propertyBlock.SetFloat(Properties.LightContribution, LightContribution);
            propertyBlock.SetFloat(Properties.DirectionalLightContribution, DirectionalLightContribution);
            propertyBlock.SetVector(Properties.FogTiling, FogTiling);
            propertyBlock.SetVector(Properties.DetailFogTiling, DetailFogTiling);
            propertyBlock.SetVector(Properties.FogSpeed, FogDirection.normalized * FogSpeed);
            propertyBlock.SetFloat(Properties.DetailFogSpeedModifier, DetailFogSpeedModifier);
        }

        private static class Properties
        {
            public static readonly int BoundingSphere = Shader.PropertyToID("_BoundingSphere");
            public static readonly int FogMaxY = Shader.PropertyToID("_FogMaxY");
            public static readonly int FogFadeY = Shader.PropertyToID("_FogFadeY");
            public static readonly int FogFadeEdge = Shader.PropertyToID("_FogFadeEdge");
            public static readonly int FogProximityFade = Shader.PropertyToID("_FogProximityFade");
            public static readonly int FogDensity = Shader.PropertyToID("_FogDensity");
            public static readonly int FogExponent = Shader.PropertyToID("_FogExponent");
            public static readonly int DetailFogExponent = Shader.PropertyToID("_DetailFogExponent");
            public static readonly int FogCutOff = Shader.PropertyToID("_FogCutOff");
            public static readonly int FogDetailStrength = Shader.PropertyToID("_FogDetailStrength");
            public static readonly int FogColor = Shader.PropertyToID("_FogColor");
            public static readonly int DirectionalFogColor = Shader.PropertyToID("_DirectionalFogColor");
            public static readonly int DirectionalFallExponent = Shader.PropertyToID("_DirectionalFallExponent");
            public static readonly int ShadowStrength = Shader.PropertyToID("_ShadowStrength");
            public static readonly int ShadowReverseStrength = Shader.PropertyToID("_ShadowReverseStrength");
            public static readonly int LightContribution = Shader.PropertyToID("_LightContribution");
            public static readonly int DirectionalLightContribution = Shader.PropertyToID("_DirectionalLightContribution");
            public static readonly int FogTiling = Shader.PropertyToID("_FogTiling");
            public static readonly int FogSpeed = Shader.PropertyToID("_FogSpeed");
            public static readonly int DetailFogTiling = Shader.PropertyToID("_DetailFogTiling");
            public static readonly int DetailFogSpeedModifier = Shader.PropertyToID("_DetailFogSpeedModifier");
        }
    }
}
