import type { WebGLRenderer } from 'three'

export type GraphicsQuality = 'auto' | 'high' | 'economy'

export function usesSoftwareRendering(renderer: WebGLRenderer) {
  const gl = renderer.getContext()
  const extension = gl.getExtension('WEBGL_debug_renderer_info')
  const name: unknown = gl.getParameter(extension ? extension.UNMASKED_RENDERER_WEBGL : gl.RENDERER)
  return typeof name === 'string' && /swiftshader|llvmpipe|software|softpipe/i.test(name)
}
