using UnityEngine;
using UnityEngine.Rendering;

namespace VertexFragment
{
    /// <summary>
    /// A double-buffered <see cref="RenderTargetReference"/>.
    /// </summary>
    public sealed class BufferedRenderTargetReference
    {
        /// <summary>
        /// The buffer from the last frame.
        /// </summary>
        public RenderTargetReference FrontBuffer { get; private set; }

        /// <summary>
        /// The buffer currently being written to.
        /// </summary>
        public RenderTargetReference BackBuffer { get; private set; }

        private RenderTargetReference Target0;
        private RenderTargetReference Target1;

        public BufferedRenderTargetReference(string name)
        {
            Target0 = new RenderTargetReference(name + "0");
            Target1 = new RenderTargetReference(name + "1");

            FrontBuffer = Target0;
            BackBuffer = Target1;
        }

        public BufferedRenderTargetReference(string name, int width, int height, RenderTextureFormat colorFormat)
        {
            Target0 = new RenderTargetReference(name + "0", width, height, colorFormat);
            Target1 = new RenderTargetReference(name + "1", width, height, colorFormat);

            FrontBuffer = Target0;
            BackBuffer = Target1;
        }

        public BufferedRenderTargetReference(string name, RenderTextureDescriptor descriptor)
        {
            Target0 = new RenderTargetReference(name + "0", descriptor);
            Target1 = new RenderTargetReference(name + "1", descriptor);

            FrontBuffer = Target0;
            BackBuffer = Target1;
        }

        /// <summary>
        /// Swaps the front and back buffers.
        /// </summary>
        public void Swap()
        {
            RenderTargetReference temp = FrontBuffer;

            FrontBuffer = BackBuffer;
            BackBuffer = temp;
        }

        /// <summary>
        /// Updates the render texture descriptor for both buffers.
        /// </summary>
        /// <param name="descriptor"></param>
        /// <param name="filterMode"></param>
        /// <param name="wrapMode"></param>
        /// <returns></returns>
        public bool SetRenderTextureDescriptor(RenderTextureDescriptor descriptor, FilterMode filterMode = FilterMode.Bilinear, TextureWrapMode wrapMode = TextureWrapMode.Clamp)
        {
            return (Target0.SetRenderTextureDescriptor(descriptor, filterMode, wrapMode) &&
                    Target1.SetRenderTextureDescriptor(descriptor, filterMode, wrapMode));
        }

        /// <summary>
        /// Updates the render texture descriptor for both buffers.
        /// </summary>
        /// <param name="width"></param>
        /// <param name="height"></param>
        /// <param name="colorFormat"></param>
        /// <param name="depthBits"></param>
        /// <param name="filterMode"></param>
        /// <param name="wrapMode"></param>
        /// <returns></returns>
        public bool SetRenderTextureDescriptor(int width, int height, RenderTextureFormat colorFormat, int depthBits = 0, FilterMode filterMode = FilterMode.Bilinear, TextureWrapMode wrapMode = TextureWrapMode.Clamp)
        {
            return (Target0.SetRenderTextureDescriptor(width, height, colorFormat, depthBits, filterMode, wrapMode) &&
                    Target1.SetRenderTextureDescriptor(width, height, colorFormat, depthBits, filterMode, wrapMode));
        }

        /// <summary>
        /// Clears the back buffer.
        /// </summary>
        /// <param name="commandBuffer"></param>
        /// <param name="clearColor"></param>
        /// <param name="depth"></param>
        public void Clear(CommandBuffer commandBuffer, Color clearColor, float depth = 1.0f)
        {
            BackBuffer.Clear(commandBuffer, clearColor, depth);
        }

        /// <summary>
        /// Clears the back buffer.
        /// </summary>
        /// <param name="commandBuffer"></param>
        public void Clear(CommandBuffer commandBuffer)
        {
            BackBuffer.Clear(commandBuffer);
        }
    }
}
