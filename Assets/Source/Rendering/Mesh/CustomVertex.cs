using UnityEngine;

namespace VertexFragment
{
    public struct CustomVertex
    {
        public Vector3 Position;
        public Vector3 Normal;
        public Vector2 UV;

        public CustomVertex(Vector3 position)
        {
            Position = position;
            Normal = Vector3.zero;
            UV = Vector2.zero;
        }

        public CustomVertex(Vector3 position, Vector3 normal)
        {
            Position = position;
            Normal = normal;
            UV = Vector2.zero;
        }

        public CustomVertex(Vector3 position, Vector3 normal, Vector2 uv)
        {
            Position = position;
            Normal = normal;
            UV = uv;
        }

        public CustomVertex(Vector3 position, Vector2 uv)
        {
            Position = position;
            Normal = Vector3.zero;
            UV = uv;
        }
    }
}