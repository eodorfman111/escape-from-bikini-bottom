import * as T from 'three'
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js'

export type Surface = 'sand' | 'bamboo' | 'woven' | 'parquet' | 'mottle' | 'metal'
export const waterTime = { value: 0 }
export const waterStrength = { value: 1 }
const textures = new Map<Surface, T.DataTexture>()
const materials = new Map<string, T.MeshStandardMaterial>()

function texture(kind: Surface) {
  const cached = textures.get(kind)
  if (cached) return cached
  const size = 256
  const data = new Uint8Array(size * size * 4)
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const noise = ((x * 1597 + y * 3571 + x * y * 31) % 101) / 101
      let v = 0.87 + noise * 0.1
      if (kind === 'mottle') v = 0.58 + 0.36 * Math.abs(Math.sin(x * 0.09 + Math.sin(y * 0.075) * 3) * Math.cos(y * 0.11 + Math.sin(x * 0.047) * 4)) + noise * 0.08
      if (kind === 'bamboo') {
        const shaft = (x + Math.round(Math.sin(y * 0.04) * 2)) % 32
        v = shaft < 3 || shaft > 28 ? 0.46 : shaft < 7 ? 0.7 : 0.97
        if ((y + Math.floor(x / 32) * 19) % 74 < 4) v *= 0.7
        v -= noise * 0.1
      }
      if (kind === 'woven' || kind === 'parquet') {
        const tile = kind === 'woven' ? 64 : 128
        const alternate = (Math.floor(x / tile) + Math.floor(y / tile)) % 2
        const grain = alternate ? x : y
        v = 0.72 + Math.sin(grain * (kind === 'woven' ? 1.6 : 0.43)) * 0.13 + noise * 0.13
        if (x % tile < 2 || y % tile < 2) v = 0.46
      }
      if (kind === 'sand') v = 0.9 + 0.04 * Math.sin(x / 20 + Math.sin(y / 13)) - (noise < 0.03 ? 0.3 : noise * 0.06)
      if (kind === 'metal') v = x % 128 < 2 || y % 128 < 2 ? 0.48 : 0.84 + noise * 0.08
      const offset = (y * size + x) * 4
      data[offset] = data[offset + 1] = data[offset + 2] = Math.round(v * 255)
      data[offset + 3] = 255
    }
  }
  const result = new T.DataTexture(data, size, size)
  result.wrapS = result.wrapT = T.RepeatWrapping
  result.magFilter = T.LinearFilter
  result.minFilter = T.LinearMipmapLinearFilter
  result.generateMipmaps = true
  result.needsUpdate = true
  textures.set(kind, result)
  return result
}

export function caustics(material: T.MeshStandardMaterial) {
  material.onBeforeCompile = shader => {
    shader.uniforms.waterTime = waterTime
    shader.uniforms.waterStrength = waterStrength
    shader.vertexShader = 'varying vec3 vWaterPosition;\n' + shader.vertexShader
    shader.vertexShader = shader.vertexShader.replace('#include <worldpos_vertex>', '#include <worldpos_vertex>\nvWaterPosition = (modelMatrix * vec4(transformed, 1.0)).xyz;')
    shader.fragmentShader = 'varying vec3 vWaterPosition;\nuniform float waterTime;\nuniform float waterStrength;\n' + shader.fragmentShader
    shader.fragmentShader = shader.fragmentShader.replace('#include <opaque_fragment>', `
      vec2 waterUV = vWaterPosition.xz * 0.8;
      float ripples = sin(waterUV.x + sin(waterUV.y * 1.6 + waterTime * 0.35))
        * sin(waterUV.y + sin(waterUV.x * 1.4 - waterTime * 0.28));
      float glow = pow(1.0 - abs(ripples), 18.0) * waterStrength;
      outgoingLight += vec3(0.13, 0.22, 0.18) * glow;
      #include <opaque_fragment>
    `)
  }
  material.customProgramCacheKey = () => 'underwater-caustics-v1'
  return material
}

export function surface(kind: Surface, color: string, repeatX = 1, repeatY = 1) {
  const key = `${kind}:${color}:${repeatX}:${repeatY}`
  const cached = materials.get(key)
  if (cached) return cached
  const map = texture(kind).clone()
  map.repeat.set(repeatX, repeatY)
  const result = caustics(new T.MeshStandardMaterial({
    color, map, bumpMap: map, bumpScale: kind === 'sand' ? 0.025 : 0.06,
    roughness: kind === 'metal' ? 0.43 : 0.88, metalness: kind === 'metal' ? 0.22 : 0,
  }))
  materials.set(key, result)
  return result
}

export function batchStatic(root: T.Group) {
  root.updateMatrixWorld(true)
  const inverse = root.matrixWorld.clone().invert()
  const groups = new Map<string, { material: T.Material; meshes: T.Mesh<T.BufferGeometry, T.Material>[]; geometries: T.BufferGeometry[] }>()
  function visit(object: T.Object3D) {
    if (object.userData.dynamic) return
    if (object instanceof T.Mesh && object.material instanceof T.Material && !object.morphTargetInfluences) {
      const geometry = object.geometry.clone().applyMatrix4(inverse.clone().multiply(object.matrixWorld))
      const position = object.getWorldPosition(new T.Vector3()).applyMatrix4(inverse)
      const key = `${object.material.uuid}:${Math.floor(position.x / 16)}:${Math.floor(position.z / 16)}`
      const existing = groups.get(key) ?? { material: object.material, meshes: [], geometries: [] }
      existing.meshes.push(object)
      existing.geometries.push(geometry.index ? geometry.toNonIndexed() : geometry)
      if (geometry.index) geometry.dispose()
      groups.set(key, existing)
    }
    for (const child of object.children) visit(child)
  }
  visit(root)
  for (const group of groups.values()) {
    if (group.meshes.length > 1) {
      const merged = mergeGeometries(group.geometries)
      if (merged) {
        const mesh = new T.Mesh(merged, group.material)
        mesh.castShadow = group.meshes.some(m => m.castShadow)
        mesh.receiveShadow = true
        mesh.name = 'Batched scenery'
        group.meshes.forEach(m => m.removeFromParent())
        root.add(mesh)
      }
    }
    group.geometries.forEach(g => g.dispose())
  }
}
