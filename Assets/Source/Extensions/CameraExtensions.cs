using UnityEngine;

namespace VertexFragment
{
    public static class CameraExtensions
    {
        /// <summary>
        /// Returns the four world-space corners of the near clipping plane.
        /// They are ordered as: upper-left, upper-right, lower-left, lower-right.
        /// </summary>
        /// <param name="camera"></param>
        /// <returns></returns>
        public static Vector3[] GetNearClipPlaneCorners(this Camera camera)
        {
            Vector3[] corners = new Vector3[4];

            corners[0] = camera.ViewportToWorldPoint(new Vector3(0.0f, 1.0f, camera.nearClipPlane));
            corners[1] = camera.ViewportToWorldPoint(new Vector3(1.0f, 1.0f, camera.nearClipPlane));
            corners[2] = camera.ViewportToWorldPoint(new Vector3(0.0f, 0.0f, camera.nearClipPlane));
            corners[3] = camera.ViewportToWorldPoint(new Vector3(1.0f, 0.0f, camera.nearClipPlane));

            return corners;
        }

        /// <summary>
        /// Returns the four world-space corners of the far clipping plane.
        /// They are ordered as: upper-left, upper-right, lower-left, lower-right.
        /// </summary>
        /// <param name="camera"></param>
        /// <returns></returns>
        public static Vector3[] GetFarClipPlaneCorners(this Camera camera)
        {
            Vector3[] corners = new Vector3[4];

            corners[0] = camera.ViewportToWorldPoint(new Vector3(0.0f, 1.0f, camera.farClipPlane));
            corners[1] = camera.ViewportToWorldPoint(new Vector3(1.0f, 1.0f, camera.farClipPlane));
            corners[2] = camera.ViewportToWorldPoint(new Vector3(0.0f, 0.0f, camera.farClipPlane));
            corners[3] = camera.ViewportToWorldPoint(new Vector3(1.0f, 0.0f, camera.farClipPlane));

            return corners;
        }

        /// <summary>
        /// Returns the four world-space corners of the near clipping plane packed into a single 4x4 column-major matrix. 
        /// They are ordered as: upper-left, upper-right, lower-left, lower-right.
        /// </summary>
        /// <param name="camera"></param>
        /// <returns></returns>
        public static Matrix4x4 GetNearClipPlaneCornersMatrix(this Camera camera)
        {
            Vector3[] corners = camera.GetNearClipPlaneCorners();
            return new Matrix4x4(corners[0], corners[1], corners[2], corners[3]);
        }

        /// <summary>
        /// Returns the four world-space corners of the far clipping plane packed into a single 4x4 column-major matrix. 
        /// They are ordered as: upper-left, upper-right, lower-left, lower-right.
        /// </summary>
        /// <param name="camera"></param>
        /// <returns></returns>
        public static Matrix4x4 GetFarClipPlaneCornersMatrix(this Camera camera)
        {
            Vector3[] corners = camera.GetFarClipPlaneCorners();
            return new Matrix4x4(corners[0], corners[1], corners[2], corners[3]);
        }
    }
}
