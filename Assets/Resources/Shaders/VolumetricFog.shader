// This is the raymarched volumetric fog. Provides better "3D" fog and features such as sun shafts.
// Typically used for environmental/mood fog, and then traditional Depth Fog is used for global/atmospheric fog.
Shader "VertexFragment/VolumetricFog"
{
    Properties
    {
        [Header(Shape)]
        _BoundingSphere ("Bounding Sphere", Vector) = (0.0, 0.0, 0.0, 0.0)      // (origin.xyz, radius)
        _FogMaxY("Max Y", Float) = 100.0
        _FogFadeY("Fade Y", Float) = 2.0
        _FogFadeEdge("Fade Edge", Float) = 20.0
        _FogProximityFade("Proximity Fade", Float) = 10.0
        _FogDensity ("Fog Density", Range(0.0, 5.0)) = 0.1
        _FogExponent ("Fog Exponent", Float) = 1.0
        _DetailFogExponent ("Detail Fog Exponent", Float) = 1.0
        _FogCutOff ("Fog Shape Mask", Range(0, 1)) = 0.0
        _FogDetailStrength ("Fog Detail Strength", Range(0, 1)) = 0.75

        [Header(Appearance)]
        _NoiseTexture ("Noise Texture", 3D) = "black" {}
        [HDR] _FogColor ("Fog Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR] _DirectionalFogColor ("Directional Fog Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _DirectionalFallExponent ("Directional Fall Off", Range(1.0, 20.0)) = 1.0
        _ShadowStrength ("Shadow Strength", Range(0.0, 1.0)) = 1.0
        _ShadowReverseStrength ("Shadow Reverse Strength", Range(0.0, 1.0)) = 1.0
        _LightContribution ("Light Contribution", Range(0.0, 1.0)) = 1.0
        _DirectionalLightContribution ("Directional Light Contribution", Range(0.0, 1.0)) = 1.0

        [Header(Movement)]
        _FogTiling ("Fog Tiling", Vector) = (0.015, 0.015, 0.015, 0.0)
        _FogSpeed ("Fog Speed", Vector) = (1.75, -0.5, 0.1, 0.0)
        _DetailFogTiling ("Detail Fog Tiling", Vector) = (0.015, 0.015, 0.015, 0.0)
        _DetailFogSpeedModifier("Detail Fog Speed Modifier", Float) = 2.0
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
            Name "Fog"

            HLSLPROGRAM

            #pragma vertex VertMain
            #pragma fragment FragMain
            #pragma target 4.6
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #define VF_CAMERA_PLANES

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Common.hlsl"

            CBUFFER_START(UnityPerMaterial)
                TEXTURE3D(_NoiseTexture);
                SAMPLER(sampler_NoiseTexture);

                float4 _BoundingSphere;
                float4 _FogColor;
                float4 _DirectionalFogColor;
                float4 _FogTiling;
                float4 _FogSpeed;
                float4 _DetailFogTiling;

                float _FogDensity;
                float _FogExponent;
                float _DirectionalFallExponent;
                float _FogMaxY;
                float _FogFadeY;
                float _FogFadeEdge;
                float _FogProximityFade;
                float _ShadowStrength;
                float _ShadowReverseStrength;
                float _LightContribution;
                float _DirectionalLightContribution;
                float _DetailFogSpeedModifier;
                float _DetailFogExponent;
                float _FogCutOff;
                float _FogDetailStrength;
            CBUFFER_END
            
            float4 _UOPWind;

            // -----------------------------------------------------------------------------
            // Vertex
            // -----------------------------------------------------------------------------

            VertOutput VertMain(VertInput input)
            {
                VertOutput output = (VertOutput)0;

                // This is a blit shader that is rendering a full screen quad defined as:
                // ll = (-1, -1, 0), lr = (1, -1, 0), ur = (1, 1, 0), ul = (-1, 1, 0)
                // So we just pass these model-space positions through.

                output.position = float4(input.position.xyz, 1.0f);
                output.positionWS = GetNearPlaneWorldSpacePosition(input.uv.x, input.uv.y);     // World-space on the near plane
                output.uv = input.uv;

                return output;
            }
            
            // -----------------------------------------------------------------------------
            // Ray Intersection
            // -----------------------------------------------------------------------------

            struct RaySphereHit
            {
                float Hit;
                float FrontHitDistance;
                float3 FrontHitPoint;
                float3 BackHitPoint;
                float Thickness;
                float Thickness01;
            };

            /**
             * Source: https://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection
             */
            float RaySphereIntersection(float3 ro, float3 rd, float3 so, float sr)
            {
                float3 so2ro = ro - so;

                float a = 2.0f * dot(so2ro, rd);
                float b = dot(so2ro, so2ro) - (sr * sr);
                float c = (a * a) - (4.0f * b);

                float hitFlag = step(0.0f, c);
                float hitDistance = (-a - sqrt(c)) * 0.5f;

                return (hitDistance * hitFlag);
            }

            /**
             * Performs two ray casts against the specified sphere.
             * The first cast is to get the distance from the front, and the second is distance from the back.
             */
            RaySphereHit GetRaySphereIntersectionData(float3 rayOrigin, float3 rayDirection, float3 sphereOrigin, float sphereRadius)
            {
                RaySphereHit hit = (RaySphereHit)0;
                hit.FrontHitDistance = RaySphereIntersection(rayOrigin, rayDirection, sphereOrigin, sphereRadius);
                hit.Hit = step(0.0f, hit.FrontHitDistance);

                float sphereDiameter = sphereRadius * 2.0f;

                // The ray hit twice, so the sphere is in front of us.
                if (hit.Hit > 0.0f)
                {
                    float3 sphereBackRayOrigin = rayOrigin + (rayDirection * (hit.FrontHitDistance + (sphereRadius * 3.0f)));
                    float sphereBackDistance = RaySphereIntersection(sphereBackRayOrigin, -rayDirection, sphereOrigin, sphereRadius);

                    hit.FrontHitPoint = rayOrigin + (rayDirection * hit.FrontHitDistance);
                    hit.BackHitPoint = sphereBackRayOrigin + (-rayDirection * sphereBackDistance);
                    hit.Thickness = distance(hit.FrontHitPoint, hit.BackHitPoint);
                    hit.Thickness01 = saturate(hit.Thickness / sphereDiameter);
                }
                // The ray did not hit. Either it is a miss, or we are inside of the sphere.
                else
                {
                    float distanceToSphere = distance(rayOrigin, sphereOrigin);

                    // Are we inside of the sphere?
                    if (distanceToSphere < sphereRadius)
                    {
                        float3 sphereBackRayOrigin = rayOrigin + (rayDirection * sphereDiameter);
                        float sphereBackDistance = RaySphereIntersection(sphereBackRayOrigin, -rayDirection, sphereOrigin, sphereRadius);

                        hit.FrontHitPoint = rayOrigin;
                        hit.FrontHitDistance = 0.0f;
                        hit.BackHitPoint = sphereBackRayOrigin + (-rayDirection * sphereBackDistance);
                        hit.Thickness = distance(rayOrigin, hit.BackHitPoint);
                        hit.Thickness01 = saturate(hit.Thickness / sphereDiameter);
                    }
                }
                // Otherwise a miss.

                return hit;
            }
            
            // -----------------------------------------------------------------------------
            // Fragment
            // -----------------------------------------------------------------------------
            
            float4 FragMain(VertOutput input) : SV_Target
            {
                // -------------------------------------------------------------------------
                // 1. Setup and Raycast
                // -------------------------------------------------------------------------

                float3 rayOrigin = input.positionWS;
                float3 rayDirection = normalize(rayOrigin - _WorldSpaceCameraPos.xyz);

                float3 sphereOrigin = _BoundingSphere.xyz;
                float sphereRadius = _BoundingSphere.w;

                float linearDepth = Linear01Depth(SampleSceneDepth(input.uv), _ZBufferParams);
                float worldDepth = LinearDepthToWorldDepth(linearDepth);

                RaySphereHit rayHit = GetRaySphereIntersectionData(rayOrigin, rayDirection, sphereOrigin, sphereRadius);
                float hitOcclusionFlag = step(rayHit.FrontHitDistance, worldDepth);

                if (hitOcclusionFlag <= 0.0f)
                {
                    return (float4)0;
                }

                // -------------------------------------------------------------------------
                // 2. Raymarch Preparation
                // -------------------------------------------------------------------------

                float occludedDistance = worldDepth - rayHit.FrontHitDistance;
                float nearestCutoff = min(occludedDistance * 5.0f, rayHit.Thickness);

                int stepCount = 50;
                float stepSize = nearestCutoff / (float)stepCount;

                float3 currPosition = (float3)0;
                float totalDistance = rayHit.FrontHitDistance;
                float distanceMarched = Hash13(rayOrigin * 1337.0f * sin(_Time.y)) * -stepSize * 0.1f;        // Random offset to help reduce banding

                Light light = GetMainLight();
                float dotRaySun = pow(saturate(dot(rayDirection, light.direction)), _DirectionalFallExponent);
                float3 lightColor = lerp(lerp((float3)1, light.color, _LightContribution), lerp((float3)1, light.color, _DirectionalLightContribution), dotRaySun);
                float4 fogColor = lerp(_FogColor, _DirectionalFogColor, dotRaySun);

                float edgeFadeStart = sphereRadius - _FogFadeEdge;
                float yFadeStart = _FogMaxY - _FogFadeY;

                // -------------------------------------------------------------------------
                // 3. Raymarch and Accumulation
                // -------------------------------------------------------------------------

                float accumulation = 0.0f;
                float shadowAccumulation = 0.0f;

                float currStepSize = stepSize;
                int takingSmallSteps = 0;

                UNITY_LOOP
                for (int i = 0; i < stepCount; ++i)
                {
                    totalDistance += currStepSize;
                    distanceMarched += currStepSize;
                    currPosition = rayHit.FrontHitPoint + (rayDirection * distanceMarched);

                    float distToOrigin = distance(currPosition, sphereOrigin);
                    float edgeFade = 1.0f - saturate((distToOrigin - edgeFadeStart) / _FogFadeEdge);
                    float yFade = 1.0f - saturate((currPosition.y - yFadeStart) / _FogFadeY);
                    float proximityFade = saturate(totalDistance / _FogProximityFade);

                    float3 fogUVW = (currPosition.xyz + (_FogSpeed.xyz * _Time.y)) * _FogTiling.xyz;
                    float fog = pow(SAMPLE_TEXTURE3D(_NoiseTexture, sampler_NoiseTexture, fogUVW).r, _FogExponent);
                    fog = saturate((fog - _FogCutOff ) / (1.0f - fog));

                    float3 detailFogUVW = (currPosition.xyz + (_FogSpeed.xyz * _DetailFogSpeedModifier * _Time.y)) * _DetailFogTiling.xyz;
                    float4 fogDetail = pow(SAMPLE_TEXTURE3D(_NoiseTexture, sampler_NoiseTexture, detailFogUVW), _DetailFogExponent);
                    fog = (fog * (1.0f - _FogDetailStrength)) + (_FogDetailStrength * ((fogDetail.r * 0.6f) + (fogDetail.b * 0.25f) + (fogDetail.a * 0.15f)));

                    if (fog > 0.1f && takingSmallSteps < 1)
                    {
                        currStepSize = stepSize * 0.2f;
                        distanceMarched -= currStepSize * 4.0f;
                        takingSmallSteps = 1;
                        continue;
                    }

                    float shadow = MainLightShadow(TransformWorldToShadowCoord(currPosition), currPosition, 1.0f, _MainLightOcclusionProbes);

                    fog *= yFade * edgeFade * proximityFade;
                    accumulation += fog * currStepSize;
                    shadowAccumulation += (1.0f - shadow) * currStepSize;
                }

                // -------------------------------------------------------------------------
                // 4. Finalization
                // -------------------------------------------------------------------------

                float totalAccumulation = saturate(accumulation / distanceMarched) * _FogDensity;
                float totalShadow = 1.0f - (saturate(shadowAccumulation / distanceMarched) * lerp(_ShadowStrength * _ShadowReverseStrength, _ShadowStrength, dotRaySun));
                float3 totalLighting = lightColor * totalShadow;
                float3 ambientLighting = lightColor * 0.1f;

                return float4(fogColor.rgb * max(totalLighting, ambientLighting), fogColor.a * saturate(totalAccumulation));
            }

            ENDHLSL
        }
    }
}