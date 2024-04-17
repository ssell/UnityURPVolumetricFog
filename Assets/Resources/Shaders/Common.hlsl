#ifndef VF_COMMON_INCLUDED
#define VF_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

// -----------------------------------------------------------------------------------------
// Macros
// -----------------------------------------------------------------------------------------

#ifndef PI 
#define PI 3.141592f
#endif

#define PI_OVER_TWO 1.570796f
#define ONE_OVER_PI 0.31831f
#define ONE_OVER_TWO_PI 0.159155f

#define UOP_EPSILON 0.000001f
#define ONE_OVER_64 0.015625f

#define CAMERA_NEAR_PLANE _ProjectionParams.y
#define CAMERA_FAR_PLANE  _ProjectionParams.z

// See: https://docs.unity3d.com/2020.1/Documentation/Manual/SL-DepthTextures.html
#ifdef UNITY_REVERSED_Z
#define DEPTH_MAX 0.0f
#define DEPTH_MIN 1.0f
#else
#define DEPTH_MAX 1.0f
#define DEPTH_MIN 0.0f
#endif

#define TEXTURE2D_AND_SAMPLER(name) TEXTURE2D(name); SAMPLER(sampler##name)

// -----------------------------------------------------------------------------------------
// Structures
// -----------------------------------------------------------------------------------------

/**
 * Input to the Vertex shader. Needs to match TessellationControlPoint if tessellation is used.
 */
struct VertInput
{
    float4 position    : POSITION;
    float3 normal      : NORMAL;
    float4 tangent     : TANGENT;
    float2 uv          : TEXCOORD0;
    float4 tex1        : TEXCOORD1;         // staticLightmapUV
    float4 tex2        : TEXCOORD2;         // dynamicLightmapUV
    float3 normalWS    : TEXCOORD5;
    float3 positionWS  : TEXCOORD6;
    float4 shadowCoord : TEXCOORD7;
    
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
};

/**
 * Output of the Vertex (and by proxy, Domain) shader.
 */
struct VertOutput
{
    float4 position    : SV_POSITION;
    float3 normal      : NORMAL;
    float4 tangent     : TANGENT;
    float2 uv          : TEXCOORD0;
    float4 tex1        : TEXCOORD1;
    float4 tex2        : TEXCOORD2;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
    float3 normalWS    : TEXCOORD5;
    float3 positionWS  : TEXCOORD6;
    float4 shadowCoord : TEXCOORD7;
};

/**
 * Output of the Geometry shader.
 */
struct GeometryOutput
{
    float4 position    : POSITION;
    float3 normal      : NORMAL;
    float4 tangent     : TANGENT;
    float2 uv          : TEXCOORD0;
    float4 tex1        : TEXCOORD1;
    float4 tex2        : TEXCOORD2;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
    float3 normalWS    : TEXCOORD5;
    float3 positionWS  : TEXCOORD6;
    float4 shadowCoord : TEXCOORD7;
};

/**
 * Represents a tessellation control point, one of the original verticies of the tessellated primitive.
 */
struct TessellationControlPoint
{
    float4 position    : INTERNALTESSPOS;
    float3 normal      : NORMAL;
    float4 tangent     : TANGENT;
    float2 uv          : TEXCOORD0;
    float4 tex1        : TEXCOORD1;
    float4 tex2        : TEXCOORD2;
    float3 normalWS    : TEXCOORD5;
    float3 positionWS  : TEXCOORD6;
    float4 shadowCoord : TEXCOORD7;
    
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 3);
};

/**
 * The factors controlling how the tessellation is performed.
 */
struct TessellationFactors
{
    float edge[3] : SV_TessFactor;
    float inside  : SV_InsideTessFactor;
};

/**
 * From UnityGBuffer.hlsl
 */
/*
struct FragmentOutput
{
    half4 GBuffer0 : SV_Target0;        // (albedo.r, albedo.g, albedo.b, material flags)
    half4 GBuffer1 : SV_Target1;        // (specular.r, specular.g, specular.b, occlusion)
    half4 GBuffer2 : SV_Target2;        // (normal.r, normal.g, normal.b, smoothness)
    half4 GBuffer3 : SV_Target3;        // emissive + GI + lighting

    #ifdef GBUFFER_OPTIONAL_SLOT_1
    GBUFFER_OPTIONAL_SLOT_1_TYPE GBuffer4 : SV_Target4;
    #endif
    #ifdef GBUFFER_OPTIONAL_SLOT_2
    half4 GBuffer5 : SV_Target5;
    #endif
    #ifdef GBUFFER_OPTIONAL_SLOT_3
    half4 GBuffer6 : SV_Target6;
    #endif
};
*/

/**
 * For forward renderer shaders.
 */
struct ForwardFragmentOutput
{
    float4 Color : SV_Target;
    float  Depth : SV_Depth;
};

// -----------------------------------------------------------------------------------------
// Functions
// -----------------------------------------------------------------------------------------

float3 GetCameraForward()
{
    // Probably don't need to normalize. But better safe than spending hours tracking this down.
    return -normalize(UNITY_MATRIX_V._m20_m21_m22);
}

float3 GetCameraRight()
{
    return normalize(UNITY_MATRIX_V._m00_m01_m02);
}

float3 GetCameraUp()
{
    return normalize(UNITY_MATRIX_V._m10_m11_m12);
}

/**
 * Given a screen-space UV (bottom left == (0, 0), top right == (1, 1)) returns the direction of the camera ray.
 * Note: Distorts at horizon? :(
 */ 
float3 GetRayDirection(float2 screenUV)
{
    // Screen UV is on range [0, 1], transform to [-1, 1].
    float2 uv = (screenUV * 2.0f) - 1.0f;

    // Perform aspect ratio correction.
    uv.x *= (_ScreenParams.x / _ScreenParams.y);

    return normalize((uv.x * GetCameraRight()) + (uv.y * GetCameraUp()) + GetCameraForward() * 1.5f);
}

// Note: Using GetCurrentViewPosition() instead of _WorldSpaceCameraPos as it will give camera or light position, depending on the shader.

/**
 * Distance from the current camera/view position to the specified world-space position.
 */
float WorldSpaceCameraDistance(float3 positionWS)
{
    return length(GetCurrentViewPosition() - positionWS);
}

/**
 * Normalized direction from the camera/view position to the specified world-space position.
 */
float3 WorldSpaceViewDir(float3 positionWS)
{
    return normalize(positionWS - GetCurrentViewPosition());
}

/**
 * Returns true if the normal at the given position is facing towards the camera.
 */
bool IsFacingCamera(float3 positionWS, float3 normalWS)
{
    float3 cameraToPosition = WorldSpaceViewDir(positionWS);
    return dot(cameraToPosition, normalWS) < 0.0f;
}

/**
 * Given a normal, attempts to calculate one of an infinite number of tangents.
 */
float3 CalculateRoughTangent(float3 normal)
{
    float3 a = cross(normal, float3(1.0f, 0.0f, 0.0f));
    float3 b = cross(normal, float3(0.0f, 0.0f, 1.0f));

    float3 tangent = (length(a) > length(b)) ? a : b;

    return normalize(tangent);
}

/**
 * Provides a random single output value for a single input value.
 * Returned value is on the range [0, 1].
 * Source: https://www.shadertoy.com/view/4djSRW
 */
float Hash11(float p)
{
    p = frac(p * 0.1031f);
    p *= p + 33.33f;
    p *= p + p;

    return frac(p);
}

/**
 * Provides a random single output value for a 3-dimensional input value.
 * Source: https://www.shadertoy.com/view/4djSRW
 */
float Hash13(float3 p3)
{
    p3  = frac(p3 * 0.1031f);
    p3 += dot(p3, p3.yzx + 33.33f);
    return frac((p3.x + p3.y) * p3.z);
}

/**
 * Provides a random single output value for a 2-dimensional input value.
 * Source: https://www.shadertoy.com/view/4djSRW
 */
float Hash12(float2 p)
{
    return Hash13(p.xyx);
}

/**
 * Provides a random float3 output value for a float3 input value.
 * Source: https://www.shadertoy.com/view/4djSRW
 */
float3 Hash33(float3 p3)
{
    p3 = frac(p3 * float3(0.1031f, 0.1030f, 0.0973f));
    p3 += dot(p3, p3.yxz + 33.33f);
    return frac((p3.xxy + p3.yxx) * p3.zyx);
}

/** 
 * Provides a random float2 output value for a float input value.
 * Source: https://www.shadertoy.com/view/4djSRW
 */
float2 Hash21(float p)
{
    float3 p3 = frac(float3(p.xxx) * float3(0.1031f, 0.1030f, 0.0973f));
    p3 += dot(p3, p3.yxz + 33.33f);
    return frac((p3.xx + p3.yz) * p3.zy);
}

/**
 * Provides a random float2 output value for a float2 input value.
 * Source: https://www.shadertoy.com/view/4djSRW
 */
float2 Hash22(float2 p2)
{
    float3 p3 = frac(float3(p2.xyx) * float3(0.1031f, 0.1030f, 0.0973f));
    p3 += dot(p3, p3.yxz + 33.33f);
    return frac((p3.xx + p3.yz) * p3.zy);
}

/**
 * Clips space (model * mvp) to screen.
 */
float4 ClipSpaceToScreenSpace(float4 positionCS)
{
    return (positionCS / positionCS.w);
}

/**
 * Screen-space to UV [0, 1].
 *
 * The positionSS is found via:
 *
 *     positionSS = ComputeScreenPos(TransformWorldToHClip(positionWS));
 *
 * Where TransformWorldToHClip is just multiplying against the UNITY_MATRIX_VP (to get clip-space),
 * and ComputeScreenPos is transforming clip-space to screen-space.
 */
float2 ScreenSpaceToUV(float4 positionSS)
{
    return positionSS.xy / positionSS.w;
}

/**
 * Creates a rotation matrix for the given angle (radians) along the specified axis.
 * Source: https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
 */
float3x3 AngleAxis3x3(float angle, float3 axis)
{
    float c, s;
    sincos(angle, s, c);

    float t = 1 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
        t * x * x + c, t * x * y - s * z, t * x * z + s * y,
        t * x * y + s * z, t * y * y + c, t * y * z - s * x,
        t * x * z - s * y, t * y * z + s * x, t * z * z + c
    );
}

/**
 * Given a world space coordinate, returns a random rotation matrix.
 * The resulting rotation is along the tangent space up (+z).
 */
float3x3 RandomAngleTransform(float3 worldPos)
{
    float angle = Hash13(worldPos) * 2.0f - 1.0f;
    return AngleAxis3x3(angle, float3(0.0f, 0.0f, 1.0f));
}

/**
 * Similar to RandomAngleTransform but without the call to Hash13.
 * Use this variant if already have a random value at hand.
 */
float3x3 RandomAngleTransform(float randomValue)
{
    float angle = randomValue * 2.0f - 1.0f;
    return AngleAxis3x3(angle, float3(0.0f, 0.0f, 1.0f));
}

/**
 * Similar to RandomAngleTransform but can provide the direction.
 */
float3x3 RandomAngleTransformAround(float3 worldPos, float3 direction)
{
    float angle = Hash13(worldPos) * 2.0f - 1.0f;
    return AngleAxis3x3(angle, direction);
}

/**
 * Similar to RandomAngleTransformAround but without the call to Hash13.
 * Use this variant if already have a random value at hand.
 */
float3x3 RandomAngleTransformAround(float3 direction, float randomValue)
{
    float angle = randomValue * 2.0f - 1.0f;
    return AngleAxis3x3(angle, direction);
}

/**
 * The signed distance to a plane defined by a point (planeOrigin) and normal (planeNormal).
 * If the distance is positive, then it is "above" the plane in the hemisphere that the normal is pointing.
 */
float SignedDistanceToPlane(in float3 planeOrigin, in float3 planeNormal, in float3 position)
{
    return dot(planeNormal, (position - planeOrigin));
}

/**
 * Returns the point on the plane defined by the planeOrigin and planeNormal that is closest to the provided position.
 */
float3 ClosestPointOnPlane(in float3 planeOrigin, in float3 planeNormal, in float3 position)
{
    float distanceToPlane = SignedDistanceToPlane(planeOrigin, planeNormal, position);
    return position + (planeNormal * -distanceToPlane);
}

/**
 * Given a plane (worldPos and up) finds an arbitrary right vector along that plane.
 */
float3 GetRandomDirectionAlongPlane(float3 worldPos, float3 up)
{
    float3 randomOffset = Hash33(worldPos);
    float3 rightPoint = worldPos + randomOffset;
    float3 rightPointOnPlane = ClosestPointOnPlane(worldPos, up, rightPoint);
    
    return normalize(rightPointOnPlane - worldPos);
}

/**
 * Calculates the per-vertex world-space normal from within a fragment shader.
 */
float3 GetPerVertexNormalWS(float3 positionWS)
{
    float3 ddxPos = ddx(positionWS);
    float3 ddyPos = ddy(positionWS);

    return normalize(cross(ddxPos, ddyPos));
}

/**
 * Performs traditional alpha transparency blend.
 * Same as `Blend SrcAlpha OneMinusSrcAlpha`.
 */
float3 Blend(float4 sourceColor, float4 destColor)
{
    return (sourceColor.rgb * sourceColor.a) + (destColor.rgb * (1.0f - sourceColor.a));
}

/**
 * Projects the vector a onto the vector b.
 * The length of the resulting vector is on the range [0.0, length(a)]
 */
float3 ProjectOnto(in float3 a, in float3 b)
{
    return (dot(b, a) / length(b)) * b;
}

/**
 * Projects the given point onto the ray.
 * Note that the projected point may be behind the ray origin (along -rd).
 */
float3 ProjectOntoRay(in float3 p, in float3 ro, in float3 rd)
{
    return ro + (rd * dot(p - ro, rd));
}

/**
 * Returns the distance to the point at which the ray intersects the specified sphere.
 * This assumes that the ray is INSIDE of the sphere.
 *
 * Based on: https://www.lighthouse3d.com/tutorials/maths/ray-sphere-intersection/
 * See: https://www.shadertoy.com/view/cldGDX
 */
float3 InteriorSphereIntersectionDistance(in float3 ro, in float3 rd, in float3 so, in float3 sr)
{
    float3 sphereOriginProjectedOntoRay = ProjectOntoRay(so, ro, rd);
    float3 dirProjectedToRayOrigin = normalize(ro - sphereOriginProjectedOntoRay);

    float distSphereOriginToProjected = length(sphereOriginProjectedOntoRay - so);
    float distToIntersection = length(sphereOriginProjectedOntoRay - ro) + sqrt((sr * sr) - (distSphereOriginToProjected * distSphereOriginToProjected));
    float flip = step(0.0f, dot(dirProjectedToRayOrigin, rd));

    distToIntersection -= flip * distance(sphereOriginProjectedOntoRay, ro) * 2.0f;

    return distToIntersection;
}

/**
 * Returns the point that the ray intersects the specified sphere.
 * This assumes that the ray is INSIDE of the sphere.
 *
 * Based on: https://www.lighthouse3d.com/tutorials/maths/ray-sphere-intersection/
 */
float3 InteriorSphereIntersection(in float3 ro, in float3 rd, in float3 so, in float3 sr)
{
    return ro + (rd * InteriorSphereIntersectionDistance(ro, rd, so, sr));
}

/**
 * SDF line function. Returns a value on the range [0, 1] based on how near to the line the point is.
 * Where 1.0 = on the line, and 0.0 = off the line.
 */
float DistToLine(float2 p, float2 a, float2 b)
{
    float2 pa = p - a;
    float2 ba = b - a;
    
    float frac = saturate(dot(pa, ba) / dot(ba, ba));
    
    return length(pa - (ba * frac));
}

/**
 * Returns 0.0f if (x >= y). Its like step, but less confusing to me.
 */
float IsGreaterOrEqual(float x, float y)
{
    return step(y, x);
}

/**
 * Constant-Linear-Quadratic Attenuation.
 * See: https://www.shadertoy.com/view/ttt3WS
 */
float Attenuation(float d, float c, float l, float q)
{
    return (1.0f / (c + (l * d) + (q * (d * d))));
}

/**
 * Rotates the 2D vector the specified angle.
 */
float2 RotateVector(in float2 v, float angle)
{
    float cosa = cos(angle);
    float sina = sin(angle);
    
    return float2(
        (cosa * v.x) - (sina * v.y), 
        (sina * v.x) + (cosa * v.y));
}

/**
 * Rotates two 2D vectors and packs them into a single 4D vector.
 * Returned vector is (xy = rotated a, zw = rotated b).
 * Used to avoid calculating the cos and sin of the angle extra times.
 */
float4 RotateVectors(in float2 a, in float2 b, float angle)
{
    float cosa = cos(angle);
    float sina = sin(angle);
    
    return float4(
        (cosa * a.x) - (sina * a.y), 
        (sina * a.x) + (cosa * a.y),
        (cosa * b.x) - (sina * b.y), 
        (sina * b.x) + (cosa * b.y));
}

/**
 * Rotates the UV clock-wise around the specified pivot point.
 */
float2 RotateUV(float2 uv, float2 pivot, float rotation)
{
    float cosA = cos(rotation);
    float sinA = sin(rotation);

    float2 origin = uv - pivot;                             // Move the pivot point back to the origin.
    float2 rotated = float2(
        ((cosA * origin.x) - (sinA * origin.y)),            // Rotate at origin.
        ((cosA * origin.y) + (sinA * origin.x)));

    return (rotated + pivot);                              // Move back to original position.
}

/**
 * Gives the 2D directional vector that the specified UV is flowing in.
 * Essentially this is the direction that the UV is being translated via the RotateUV function.
 *
 * Returned vector values are on the range [-1, 1].
 */
float2 GetClockwiseFlowVector(float2 uv)
{
    float2 uvPast = RotateUV(uv, float2(0.5f, 0.5f), 0.01667f); // The UV the last frame.
    return normalize(uv - uvPast);
}

/**
 * Returns the cosine of the angle of the vector v.
 */
float VectorCosAngle(float2 v)
{
    float l = sqrt((v.x * v.x) + (v.y * v.y));      // length
    return (v.x / l);
}

/**
 * Returns the sine of the angle of the vector v.
 */
float VectorSinAngle(float2 v)
{
    float l = sqrt((v.x * v.x) + (v.y * v.y));      // length
    return (v.y  / l);
}

/**
 * Returns the angle of the vector on the unit circle on the range [0, 2PI].
 * Where 0/2PI equals the unit vector (1.0, 0.0).
 */
float GetAngle(in float2 v)
{
    // Remember atan2 returns on the range [-pi, pi]
    return atan2(v.y, v.x) + PI;
}

/**
 * Returns the angle of the vector on the unit circle on the range [0, 1] which maps to [0, 2PI].
 * Where 0/2PI equals the unit vector (1.0, 0.0).
 */
float GetAngle01(in float2 v)
{
    return GetAngle(v) * ONE_OVER_TWO_PI;
}

/**
 * Returns the angle of the vector on the unit circle on the range [-0.5, 0.5] which maps to [-PI, PI].
 */
float GetAngleP5(in float2 v)
{
    return atan2(v.y, v.x) * ONE_OVER_TWO_PI;
}

/**
 * Returns the angle of the vector on the unit circle on the range [-1, 1] which maps to [-PI, PI].
 */
float GetAngleN11(in float2 v)
{
    return atan2(v.y, v.x) * ONE_OVER_PI;
}

/**
 * Returns 1.0 if x is on the range (minimum, maximum). Otherwise returns 0.0.
 */
float IsBetween(float x, float minimum, float maximum)
{
    return (x > minimum) && (x < maximum) ? 1.0f : 0.0f;
}

/**
 * Given a UV value (on range [0.0, 1.0]), and the presampled corner values, returns the bilinear interoplated value.
 */
float SampleBilinear(float u, float v, float ul, float ur, float ll, float lr)
{
    // From Real-Time Rendering 3rd Edtion, Chapter 6.2.1 (Texturing - Image Texturing - Magnification)
    return ((1.0f - u) * (1.0f - v) * ll) +
            (u * (1.0f - v) * lr) +
            ((1.0f - u) * v * ul) +
            (u * v * ur);
}

/**
 * Given a UV value (on range [0.0, 1.0]), and the presampled corner values, returns the bilinear interoplated 3-component value.
 */
float3 SampleBilinear3(float3 u, float3 v, float3 ul, float3 ur, float3 ll, float3 lr)
{
    return ((1.0f - u) * (1.0f - v) * ll) +
            (u * (1.0f - v) * lr) +
            ((1.0f - u) * v * ul) +
            (u * v * ur);
}

/**
 * Returns the polar coordinate of the specified coordinates.
 * The returned polar coordinate is (distance, angle) from the origin.
 * The angle is on the range [-PI, PI].
 */
float2 CartesianToPolar(float2 cartesian, float2 origin)
{
    float2 atOrigin = cartesian - origin;

    float dist = length(atOrigin);
    float angle = atan2(atOrigin.y, atOrigin.x);

    return float2(dist, angle);
}

/**
 * Returns the UV coordinate converted to polar coordinates, assuming an origin of (0.5, 0.5).
 */
float2 UVToPolar(float2 uv)
{
    return CartesianToPolar(uv, float2(0.5f, 0.5f));
}

/**
 * Returns the polar coordinate on the range [-PI, PI] around the provided polar origin
 * to cartesian coordinates at the origin (0, 0).
 */
float2 PolarToCartesian(float2 polar, float2 origin)
{
    float2 cartesian = float2(cos(polar.y), sin(polar.y)) * polar.x;
    return (cartesian + origin);
}

/**
 * Returns the polar coordinates on the range [-PI, PI] around the origin (0.5, 0.5)
 * to cartesian coordinates at the origin (0, 0).
 */
float2 PolarToUV(float2 polar)
{
    return PolarToCartesian(polar, float2(0.5f, 0.5f));
}

/**
 * Returns the squared distance between the  two points.
 * Use instead of length or distance to avoid the square root.
 */
float DistanceSquared(in float3 a, in float3 b)
{
    float x = (a.x - b.x);
    float y = (a.y - b.y);
    float z = (a.z - b.z);

    return (x * x) + (y * y) + (z * z);
}

// -----------------------------------------------------------------------------------------
// Depth Texture Functions
// -----------------------------------------------------------------------------------------

/**
 * _ZBufferParams =
 *    .x = 1.0 - (far / near)
 *    .y = (far / near)
 *    .z = (x / far)
 *    .w = (y / far)
 * Source: https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html
 */

// See: https://www.cyanilux.com/tutorials/depth/
// NOTE: The depth texture only captures opaque objects.

struct SceneDepthData
{
    // Raw depths
    float RawDepth01;               // The raw non-linear depth from the depth texture. On the range [0, 1]. 
    float LinearDepth01;            // The raw linear depth from the depth texture. On the range [0, 1].
    float LinearWorldDepth;         // The linear world-unit depth from the depth texture. From CAMERA_NEAR_PLANE to CAMERA_FAR_CLIP.
    float CurrentWorldDepth;        // The linear world-unit depth of the current fragment. Differs from LinearWorldDepth for transparent surface. From NEAR_CLIP to FAR_CLIP.
    float CurrentDepth01;           // The linear depth of the current fragment. On the range [0, 1].
};

/**
 * Samples the depth buffer at the specified location and returns the non-linear depth value on  the range [0, 1].
 *
 * The provided screen position should have been passed by the Vertex Shader, and calculated in there using the
 * Unity provided `ComputeScreenPos` function.
 *
 * The rendered camera must be generating a depth texture to populate the global _CameraDepthTexture.
 */
float SampleUnitDepth(float4 screenPos)
{
    // Remember that the depth texture is a projective texture map so we must perform the division by w.
    return SampleSceneDepth(screenPos.xy / screenPos.w);//SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, (screenPos.xy)).r;
}

/**
 * What is Linear01Depth?
 * See: https://github.com/Unity-Technologies/Graphics/blob/19ec161f3f752db865597374b3ad1b3eaf110097/Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl#L1140

// Z buffer to linear 0..1 depth (0 at camera position, 1 at far plane).
// Does NOT work with orthographic projections.
// Does NOT correctly handle oblique view frustums.
// zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
float Linear01Depth(float depth, float4 zBufferParam)
{
    return 1.0 / (zBufferParam.x * depth + zBufferParam.y);
}

 */

/**
 * Converts a linear depth to a "raw" depth.
 * Opposite of SampleLinearDepth and Linear01Depth.
 */
float LinearDepthToRawDepth(float linearDepth)
{
    return (1.0f - (linearDepth * _ZBufferParams.y)) / (linearDepth * _ZBufferParams.x);
}

/**
 * Converts the [0, 1] unit depth to a linear [0, 1] depth value where 0.0 == near and 1.0 == far.
 * So converts the non-linear "raw" depth value from the buffer.
 */
float SampleLinearDepth(float unitDepth)
{
    return Linear01Depth(unitDepth, _ZBufferParams);
}

/**
 * Samples the depth buffer at the specified location and returns the linear depth value on the range [0, 1].
 * For the linear depth, 0.0 == near and 1.0 == far.
 *
 * The rendered camera must be generating a depth texture to populate the global _CameraDepthTexture.
 */
float SampleLinearDepth(float4 screenPos)
{
    return Linear01Depth(SampleUnitDepth(screenPos), _ZBufferParams);
}

/**
 * Converts the provided unit depth value to a world units depth value.
 */
float SampleWorldDepth(float unitDepth)
{
    return LinearEyeDepth(unitDepth, _ZBufferParams);
}

/**
 * Samples the depth buffer at the specified location and returns the linear (world units) depth value.
 *
 * The provided screen position should have been passed by the Vertex Shader, and calculated in there using the
 * Unity provided `ComputeScreenPos` function.
 *
 * The rendered camera must be generating a depth texture to populate the global _CameraDepthTexture.
 */
float SampleWorldDepth(float4 screenPos)
{
    return LinearEyeDepth(SampleUnitDepth(screenPos), _ZBufferParams);
}

/**
 * Converts a depth value [0, 1] (with 0 = near, 1 = far) to a world unit depth value on the range [CAMERA_NEAR_PLANE, CAMERA_FAR_PLANE].
 */
float LinearDepthToWorldDepth(float linearDepth)
{
    return lerp(CAMERA_NEAR_PLANE, CAMERA_FAR_PLANE, linearDepth);
}

/**
 * Returns the linear (world unit) depth of the surface we are currently rasterizing.
 *
 * The provided screen position should have been passed by the Vertex Shader, and calculated in there using the
 * Unity provided `ComputeScreenPos` function.
 */
float GetCurrentWorldDepth(float4 screenPos)
{
    return screenPos.w;
}

SceneDepthData GetSceneDepthData(float4 screenPos)
{
    screenPos.xyz /= screenPos.w;

    SceneDepthData sceneDepth = (SceneDepthData)0;

    sceneDepth.RawDepth01 = SampleSceneDepth(screenPos.xy);
    sceneDepth.LinearDepth01 = Linear01Depth(sceneDepth.RawDepth01, _ZBufferParams);
    sceneDepth.LinearWorldDepth = LinearEyeDepth(sceneDepth.RawDepth01, _ZBufferParams);

    sceneDepth.CurrentWorldDepth = screenPos.w;
    sceneDepth.CurrentDepth01 = saturate((sceneDepth.CurrentWorldDepth - CAMERA_NEAR_PLANE) / (CAMERA_FAR_PLANE - CAMERA_NEAR_PLANE));

    return sceneDepth;
}

/**
 * Gives the world position of the corresponding depth texture sample.
 *
 * When operating on transparent surfaces we have the fragment positionWS which is for the surface,
 * but we also have the "visible" positionWS for the fragment behind the surface. 
 */
float3 GetDepthProjectedWorldPosition(in SceneDepthData sceneDepthData, float3 viewVectorWS, float4 positionSS)
{
    float3 cameraPosition = GetCurrentViewPosition().xyz;
    float3 positionWS = sceneDepthData.LinearWorldDepth * (viewVectorWS / positionSS.w) - cameraPosition;

    return -positionWS;
}

/**
 * Gives the world position of the corresponding depth texture sample.
 */
float3 GetDepthProjectedWorldPosition(float linearWorldDepth, float3 viewVectorWS, float4 positionSS)
{
    float3 cameraPosition = GetCurrentViewPosition().xyz;
    float3 positionWS = linearWorldDepth * (viewVectorWS / positionSS.w) - cameraPosition;

    return -positionWS;
}

// -----------------------------------------------------------------------------------------
// Vector Packing (vector packing is a lie!)
// -----------------------------------------------------------------------------------------

// A series of packing functions for compressing a 3 component vector into a single float.
// See: https://www.shadertoy.com/view/4llcRl

float PackR8G8B8(float3 rgb)
{
    rgb = (rgb * 255.0f) + 0.5f;
    return float((uint(rgb.r)) | (uint(rgb.g) << 8) | (uint(rgb.b) << 16));
}

float PackNormalR8G8B8(float3 normal)
{
    return PackR8G8B8((normal + 1.0f) * 0.5f);
}

float3 UnpackR8G8B8(float f)
{
    uint ufloat = uint(f);
    return float3(float(ufloat & 0xFFu), float((ufloat >> 8) & 0xFFu), float((ufloat >> 16) & 0xFFu)) * 0.00392156862f;
}

float3 UnpackNormalR8G8B8(float f)
{
    return (UnpackR8G8B8(f) * 2.0f) - 1.0f;
}

// -----------------------------------------------------------------------------------------
// GBuffer Utilities
// -----------------------------------------------------------------------------------------

/**
 * Takes in several flags and packs them for use in gbuffer1.a to be interpreted by the ToonLighting.hlsl shader.
 *
 *     - useNonToonNormals: If set, will allow for standard normals. Typically set by terrain.
 *     - useStylizedSpecular: If set, specular lighting will be texture based. Typically set by characters.
 */
float PackGBufferLightingFlags(bool useNonToonNormals, bool useStylizedSpecular)
{
    return (useNonToonNormals   ? 0.0f  : 0.0f) + 
           (useStylizedSpecular ? 0.0f : 0.0f);
}

/**
 * Unpacks the flag value set in gbuffer1.a.
 * See: PackGBufferLightingFlags
 */
void UnpackGBufferLightingFlags(float packedFlag, out bool useNonToonNormals, out bool useStylizedSpecular)
{
    useNonToonNormals   = (packedFlag * 10.0f) >= 1.0f;
    useStylizedSpecular = (packedFlag * 100.0f) >= 1.0f;
}

// -----------------------------------------------------------------------------------------
// Easing Functions
// -----------------------------------------------------------------------------------------

// Visual examples: https://easings.net/

float EaseInQuadratic(float x)
{
    return x * x;
}

float EaseOutQuadratic(float x)
{
    return 1.0f - pow(1.0f - x, 2.0f);
}

float EaseInOutQuadratic(float x)
{
    return (x < 0.5f) ? (2 * x * x) : 1.0f - pow(-2.0f * x + 2.0f, 2.0f) * 0.5f;            
}

float EaseInCubic(float x)
{
    return (x * x * x);
}

float EaseOutCubic(float x)
{
    return 1.0f - pow(1.0f - x, 3.0f);
}

float EaseInQuintic(float x)
{
    return (x * x * x * x * x);
}

float EaseOutQuintic(float x)
{
    return 1.0f - pow(1.0f - x, 5.0f);
}

// -----------------------------------------------------------------------------------------
// Near and Far Planes
// -----------------------------------------------------------------------------------------

#ifdef VF_CAMERA_PLANES
/**
 * Defines the near and far plane world-space corners.
 * The matrices are column major and are stored as:
 *
 *      Column 1: Upper Left
 *      Column 2: Upper Right
 *      Column 3: Lower Left
 *      Column 4: Lower Right
 *
 * Remember that HLSL stores matrices in column-major order and are 1-index (or 0-index if using the _m prefix).
 * So they are references _{row}{column}.
 */

float4x4 _CameraNearPlaneCorners;
float4x4 _CameraFarPlaneCorners;

#define CAMERA_NEAR_PLANE_UL _CameraNearPlaneCorners._11_21_31
#define CAMERA_NEAR_PLANE_UR _CameraNearPlaneCorners._12_22_32
#define CAMERA_NEAR_PLANE_LL _CameraNearPlaneCorners._13_23_33
#define CAMERA_NEAR_PLANE_LR _CameraNearPlaneCorners._14_24_34

#define CAMERA_FAR_PLANE_UL _CameraFarPlaneCorners._11_21_31
#define CAMERA_FAR_PLANE_UR _CameraFarPlaneCorners._12_22_32
#define CAMERA_FAR_PLANE_LL _CameraFarPlaneCorners._13_23_33
#define CAMERA_FAR_PLANE_LR _CameraFarPlaneCorners._14_24_34

/**
 * Given a viewport UV (?) on the range [0, 1] returns the world-space position on the near-clip plane.
 * For the lower-left corner, the UV would be (0, 0). For the upper-right the UV would be (1, 1).
 */
float3 GetNearPlaneWorldSpacePosition(float u, float v)
{
    return SampleBilinear3(u, v, CAMERA_NEAR_PLANE_UL, CAMERA_NEAR_PLANE_UR, CAMERA_NEAR_PLANE_LL, CAMERA_NEAR_PLANE_LR);
}

/**
 * Given a viewport UV (?) on the range [0, 1] returns the world-space position on the far-clip plane.
 * For the lower-left corner, the UV would be (0, 0). For the upper-right the UV would be (1, 1).
 */
float3 GetFarPlaneWorldSpacePosition(float u, float v)
{
    return SampleBilinear3(u, v, CAMERA_FAR_PLANE_UL, CAMERA_FAR_PLANE_UR, CAMERA_FAR_PLANE_LL, CAMERA_FAR_PLANE_LR);
}
#endif

#endif