using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace VertexFragment
{
    public class CustomMesh
    {
        public const int MaxIndices = 65535;

        public List<Vector3> Vertices { get; private set; }
        public List<Vector3> Normals { get; private set; }
        public List<Vector4> Tangents { get; private set; }
        public List<Vector2> UVs { get; private set; }
        public List<int> Indices { get; private set; }
        public bool ReadWrite { get; private set; }
        public string Name { get; private set; }
        public Mesh Mesh { get; private set; }

        public CustomMesh(string name, bool readWriteEnabled = true)
        {
            ReadWrite = readWriteEnabled;
            Name = name;
            ReadWrite = ReadWrite;
        }

        public void InitializeBuffers(int vertexCount, int indicesPerVertex = 3, IndexFormat indexFormat = IndexFormat.UInt16)
        {
            if (Mesh == null)
            {
                Mesh = new Mesh();
                Mesh.name = Name;
            }

            Mesh.indexFormat = indexFormat;

            Vertices = new List<Vector3>(vertexCount);
            Normals = new List<Vector3>(vertexCount);
            Tangents = new List<Vector4>(vertexCount);
            UVs = new List<Vector2>(vertexCount);
            Indices = new List<int>(vertexCount * indicesPerVertex);

            Mesh.Clear();
        }

        public void ClearBuffers()
        {
            Vertices.Clear();
            Indices.Clear();
            Normals.Clear();
            Tangents.Clear();
            UVs.Clear();
        }

        public void Build()
        {
            if (Indices.Count > MaxIndices)
            {
                Mesh.indexFormat = IndexFormat.UInt32;
            }

            Mesh.SetVertices(Vertices);
            Mesh.SetIndices(Indices, MeshTopology.Triangles, 0);
            Mesh.SetUVs(0, UVs);

            if (Normals.Count > 0)
            {
                Mesh.SetNormals(Normals);
            }
            else
            {
                Mesh.RecalculateNormals();
            }

            if (Tangents.Count > 0)
            {
                Mesh.SetTangents(Tangents);
            }
            else
            {
                Mesh.RecalculateTangents();
            }

            Mesh.UploadMeshData(!ReadWrite);
            Mesh.RecalculateBounds();
        }

        /// <summary>
        /// Given the four vertices of a quad, adds them to the internal buffers and
        /// constructs the two triangles that compose it.
        /// </summary>
        /// <param name="ll">Lower-left vertex.</param>
        /// <param name="lr">Lower-right vertex.</param>
        /// <param name="ur">Upper-right vertex</param>
        /// <param name="ul">Upper-left vertex.</param>
        /// <param name="normal"></param>
        /// <param name="uv"></param>
        public void AddFace(Vector3 ll, Vector3 lr, Vector3 ur, Vector3 ul, Vector3 normal, Vector2 uv)
        {
            AddTriangle(ll, ul, lr, normal, uv);            // Bottom left triangle
            AddTriangle(ul, ur, lr, normal, uv);            // Top right triangle
        }

        public void AddFace(Vector3 ll, Vector3 lr, Vector3 ur, Vector3 ul, Vector2 uv)
        {
            Vector3 forward = (ul - ll).normalized;
            Vector3 right = (lr - ll).normalized;
            Vector3 normal = Vector3.Cross(forward, right).normalized;

            AddFace(ll, lr, ur, ul, normal, uv);
        }

        public void AddFace(in CustomVertex ll, in CustomVertex lr, in CustomVertex ur, in CustomVertex ul)
        {
            AddTriangle(ll, ul, lr);            // Bottom left triangle
            AddTriangle(ul, ur, lr);            // Top right triangle
        }

        /// <summary>
        /// Given the three vertices of a triangle, in Unity clockwise winding, adds them
        /// to the internal buffers and constructs the triangle.
        /// </summary>
        /// <param name="a">First vertex (typically lower-left)</param>
        /// <param name="b">Second vertex (typically upper-left)</param>
        /// <param name="c">Third vertex (typically lower-right)</param>
        /// <param name="normal"></param>
        /// <param name="uv"></param>
        public void AddTriangle(Vector3 a, Vector3 b, Vector3 c, Vector3 normal, Vector2 uv)
        {
            AddVertex(a, normal, uv);
            AddVertex(b, normal, uv);
            AddVertex(c, normal, uv);
        }

        /// <summary>
        /// Given the three vertices of a triangle, in Unity clockwise winding, adds them
        /// to the internal buffers and constructs the triangle.
        /// </summary>
        /// <param name="a">First vertex (typically lower-left)</param>
        /// <param name="b">Second vertex (typically upper-left)</param>
        /// <param name="c">Third vertex (typically lower-right)</param>
        public void AddTriangle(in CustomVertex a, in CustomVertex b, in CustomVertex c)
        {
            AddVertex(a);
            AddVertex(b);
            AddVertex(c);
        }

        /// <summary>
        /// Adds the vertex and the normal to the internal buffers and map.
        /// </summary>
        /// <param name="vertex"></param>
        /// <param name="normal"></param>
        /// <param name="uv"></param>
        /// <returns>The index of the vertex.</returns>
        public int AddVertex(Vector3 vertex, Vector3 normal, Vector2 uv)
        {
            VertexNormalPair pair = new VertexNormalPair(vertex, normal);

            int index = Vertices.Count;

            Vertices.Add(vertex);
            Normals.Add(normal);
            UVs.Add(uv);
            Indices.Add(index);

            return index;
        }

        /// <summary>
        /// Adds the vertex and the normal to the internal buffers and map.
        /// </summary>
        /// <param name="vertex"></param>
        /// <returns>The index of the vertex.</returns>
        public int AddVertex(in CustomVertex vertex)
        {
            return AddVertex(vertex.Position, vertex.Normal, vertex.UV);
        }

        public void Unload()
        {
            Object.Destroy(Mesh);
        }

        /// <summary>
        /// Basic pairing of a vertex and normal.
        /// </summary>
        private class VertexNormalPair
        {
            public Vector3 vertex;
            public Vector3 normal;

            public VertexNormalPair(Vector3 v, Vector3 n)
            {
                vertex = v;
                normal = n;
            }
        };
    }
}
