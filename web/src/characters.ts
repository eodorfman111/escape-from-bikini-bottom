import * as THREE from 'three'
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js'
import { pistol } from './models'

export type Avatar = 'explorer' | 'sponge' | 'patrick' | 'squid'

export const avatars: {
  id: Avatar
  name: string
  description: string
  eyeHeight: number
  color: string
}[] = [
  {
    id: 'explorer',
    name: 'Reef Explorer',
    description: 'A bubble-helmeted deep-sea adventurer ready for trouble.',
    eyeHeight: 1.88,
    color: '#39a9b8',
  },
  {
    id: 'sponge',
    name: 'SpongeBob',
    description: 'An optimistic porous pal with a square pair of pants.',
    eyeHeight: 1.83,
    color: '#f5d74d',
  },
  {
    id: 'patrick',
    name: 'Patrick',
    description: 'A soft-hearted starfish in his favorite flowered shorts.',
    eyeHeight: 2.13,
    color: '#ee9b91',
  },
  {
    id: 'squid',
    name: 'Squidward',
    description: 'A dignified cephalopod with a long nose and shorter patience.',
    eyeHeight: 2.2,
    color: '#79b9ad',
  },
]

const materials = new Map<string, THREE.MeshStandardMaterial>()
const templates = new Map<Avatar | `fish-${number}`, THREE.Group>()
let nextFish = 0

function toonMaterial(
  color: THREE.ColorRepresentation,
  roughness = 0.72,
  metalness = 0,
  map?: THREE.Texture,
) {
  const key = `${String(color)}:${roughness}:${metalness}:${map?.uuid ?? ''}`
  let result = materials.get(key)
  if (!result) {
    const settings: THREE.MeshStandardMaterialParameters = {
      color,
      roughness,
      metalness,
    }
    if (map) settings.map = map
    result = new THREE.MeshStandardMaterial(settings)
    materials.set(key, result)
  }
  return result
}

function addMesh(
  parent: THREE.Object3D,
  geometry: THREE.BufferGeometry,
  color: THREE.ColorRepresentation,
  name: string,
  position: [number, number, number] = [0, 0, 0],
  scale: [number, number, number] = [1, 1, 1],
  roughness = 0.72,
  metalness = 0,
  map?: THREE.Texture,
) {
  const result = new THREE.Mesh(geometry, toonMaterial(color, roughness, metalness, map))
  result.name = name
  result.position.set(...position)
  result.scale.set(...scale)
  result.castShadow = true
  result.receiveShadow = true
  parent.add(result)
  return result
}

function ball(
  parent: THREE.Object3D,
  name: string,
  color: THREE.ColorRepresentation,
  position: [number, number, number],
  scale: [number, number, number],
  segments = 20,
) {
  return addMesh(
    parent,
    new THREE.SphereGeometry(0.5, segments, Math.max(10, Math.round(segments * 0.7))),
    color,
    name,
    position,
    scale,
  )
}

function roundedBox(
  parent: THREE.Object3D,
  name: string,
  color: THREE.ColorRepresentation,
  position: [number, number, number],
  size: [number, number, number],
  radius = 0.08,
) {
  return addMesh(
    parent,
    new RoundedBoxGeometry(size[0], size[1], size[2], 4, radius),
    color,
    name,
    position,
  )
}

function capsuleBetween(
  parent: THREE.Object3D,
  name: string,
  color: THREE.ColorRepresentation,
  start: THREE.Vector3,
  end: THREE.Vector3,
  radius: number,
  radialSegments = 14,
) {
  const direction = end.clone().sub(start)
  const length = direction.length()
  const result = addMesh(
    parent,
    new THREE.CapsuleGeometry(radius, Math.max(0.01, length - radius * 2), 6, radialSegments),
    color,
    name,
    start.clone().add(end).multiplyScalar(0.5).toArray(),
  )
  result.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), direction.normalize())
  return result
}

function curvedLimb(
  parent: THREE.Object3D,
  name: string,
  color: THREE.ColorRepresentation,
  points: THREE.Vector3[],
  radius: number,
  taper = 0.7,
) {
  const curve = new THREE.CatmullRomCurve3(points)
  const segments = 18
  const sides = 10
  const frames = curve.computeFrenetFrames(segments, false)
  const positions: number[] = []
  const normals: number[] = []
  const uvs: number[] = []
  const indices: number[] = []
  const point = new THREE.Vector3()
  const normal = new THREE.Vector3()

  for (let i = 0; i <= segments; i++) {
    curve.getPointAt(i / segments, point)
    const localRadius = THREE.MathUtils.lerp(radius, radius * taper, i / segments)
    for (let j = 0; j < sides; j++) {
      const angle = j / sides * Math.PI * 2
      normal.copy(frames.normals[i]).multiplyScalar(Math.cos(angle))
        .addScaledVector(frames.binormals[i], Math.sin(angle))
      positions.push(
        point.x + normal.x * localRadius,
        point.y + normal.y * localRadius,
        point.z + normal.z * localRadius,
      )
      normals.push(normal.x, normal.y, normal.z)
      uvs.push(i / segments, j / sides)
    }
  }
  for (let i = 0; i < segments; i++) {
    for (let j = 0; j < sides; j++) {
      const a = i * sides + j
      const b = i * sides + (j + 1) % sides
      const c = (i + 1) * sides + (j + 1) % sides
      const d = (i + 1) * sides + j
      indices.push(a, b, d, b, c, d)
    }
  }
  const geometry = new THREE.BufferGeometry()
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3))
  geometry.setAttribute('normal', new THREE.Float32BufferAttribute(normals, 3))
  geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2))
  geometry.setIndex(indices)
  const result = addMesh(parent, geometry, color, name)
  ball(parent, `${name}-cap`, color, points.at(-1)!.toArray(), [radius * taper * 2, radius * taper * 2, radius * taper * 2], 14)
  return result
}

function tube(
  parent: THREE.Object3D,
  name: string,
  color: THREE.ColorRepresentation,
  points: THREE.Vector3[],
  radius: number,
) {
  return addMesh(
    parent,
    new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points), 20, radius, 8, false),
    color,
    name,
  )
}

function shape(
  parent: THREE.Object3D,
  name: string,
  color: THREE.ColorRepresentation,
  points: [number, number][],
  z: number,
) {
  const outline = new THREE.Shape()
  outline.moveTo(points[0][0], points[0][1])
  for (const point of points.slice(1)) outline.lineTo(point[0], point[1])
  outline.closePath()
  return addMesh(parent, new THREE.ShapeGeometry(outline), color, name, [0, 0, z])
}

function addEye(
  parent: THREE.Object3D,
  x: number,
  y: number,
  z: number,
  iris: THREE.ColorRepresentation,
  scale: [number, number, number] = [0.42, 0.55, 0.16],
) {
  ball(parent, 'eye-white', '#fffdf2', [x, y, z], scale, 24)
  ball(parent, 'iris', iris, [x, y, z + scale[2] * 0.47], [scale[0] * 0.47, scale[1] * 0.47, 0.075], 20)
  ball(parent, 'pupil', '#132c32', [x, y, z + scale[2] * 0.72], [scale[0] * 0.22, scale[1] * 0.25, 0.05], 16)
  ball(parent, 'eye-glint', '#ffffff', [x - 0.035, y + 0.065, z + scale[2] * 0.78], [0.035, 0.045, 0.025], 10)
}

function makeSpongeBodyGeometry() {
  const geometry = new RoundedBoxGeometry(1.42, 1.3, 0.62, 6, 0.13)
  const positions = geometry.attributes.position
  const point = new THREE.Vector3()
  for (let i = 0; i < positions.count; i++) {
    point.fromBufferAttribute(positions, i)
    const xEdge = Math.pow(Math.abs(point.x) / 0.71, 6)
    const yEdge = Math.pow(Math.abs(point.y) / 0.65, 6)
    point.x += Math.sin(point.y * 16 + point.z * 8) * 0.025 * xEdge
    point.y += Math.sin(point.x * 15 - point.z * 9) * 0.021 * yEdge
    positions.setXYZ(i, point.x, point.y, point.z)
  }
  positions.needsUpdate = true
  return geometry
}

function createSponge() {
  const group = new THREE.Group()
  group.name = 'sponge'

  const body = addMesh(group, makeSpongeBodyGeometry(), '#f5d74d', 'body', [0, 1.53, 0])
  body.material = toonMaterial('#f5d74d', 0.9)

  const pores: [number, number, number, number][] = [
    [-0.51, 1.92, 0.31, 0.11], [0.48, 2.02, 0.3, 0.08], [-0.59, 1.38, 0.32, 0.075],
    [0.59, 1.26, 0.31, 0.1], [0.1, 2.1, 0.32, 0.065], [-0.18, 1.09, 0.32, 0.07],
    [-0.72, 1.72, 0.06, 0.09], [0.72, 1.61, -0.1, 0.08], [0.34, 1.12, -0.31, 0.09],
  ]
  for (const [x, y, z, size] of pores) {
    ball(group, 'pore', '#c8a936', [x, y, z], [size * 1.5, size, 0.022], 12)
    if (Math.abs(z) < 0.2) ball(group, 'pore-rim', '#dfbd3b', [x, y, z], [size * 1.9, size * 1.4, size * 0.45], 12)
  }

  roundedBox(group, 'shirt', '#fff8db', [0, 0.92, 0], [1.4, 0.23, 0.63], 0.06)
  roundedBox(group, 'pants', '#9b6b3f', [0, 0.69, 0], [1.4, 0.32, 0.64], 0.06)
  for (const x of [-0.45, 0, 0.45]) roundedBox(group, 'belt', '#322b29', [x, 0.78, 0.325], [0.25, 0.075, 0.025], 0.012)

  addEye(group, -0.265, 1.83, 0.33, '#55a9cb', [0.43, 0.55, 0.16])
  addEye(group, 0.265, 1.83, 0.33, '#55a9cb', [0.43, 0.55, 0.16])
  for (const side of [-1, 1]) {
    const x = side * 0.27
    for (const offset of [-0.09, 0, 0.09]) {
      const lash = capsuleBetween(
        group,
        'eyelash',
        '#292421',
        new THREE.Vector3(x + offset * 0.7, 2.08, 0.39),
        new THREE.Vector3(x + offset, 2.2 + Math.abs(offset) * 0.3, 0.4),
        0.014,
        7,
      )
      lash.castShadow = false
    }
  }
  ball(group, 'nose', '#f5d74d', [0, 1.55, 0.51], [0.18, 0.16, 0.42], 20)
  tube(group, 'smile', '#702f32', [
    new THREE.Vector3(-0.38, 1.44, 0.346),
    new THREE.Vector3(0, 1.31, 0.38),
    new THREE.Vector3(0.38, 1.44, 0.346),
  ], 0.022)
  roundedBox(group, 'tooth', '#fffdf1', [-0.11, 1.34, 0.39], [0.19, 0.21, 0.055], 0.025)
  roundedBox(group, 'tooth', '#fffdf1', [0.11, 1.34, 0.39], [0.19, 0.21, 0.055], 0.025)
  ball(group, 'cheek', '#ea8a61', [-0.49, 1.42, 0.35], [0.15, 0.09, 0.025], 12)
  ball(group, 'cheek', '#ea8a61', [0.49, 1.42, 0.35], [0.15, 0.09, 0.025], 12)
  shape(group, 'tie-knot', '#c94c3f', [[-0.1, 1], [0.1, 1], [0.07, 0.87], [-0.07, 0.87]], 0.34)
  shape(group, 'tie', '#b83f39', [[-0.06, 0.87], [0.06, 0.87], [0.11, 0.62], [0, 0.52], [-0.11, 0.62]], 0.34)

  for (const side of [-1, 1]) {
    roundedBox(group, 'sleeve', '#fff8db', [side * 0.76, 1.04, 0], [0.24, 0.28, 0.31], 0.08)
    capsuleBetween(
      group,
      'arm',
      '#f5d74d',
      new THREE.Vector3(side * 0.79, 0.98, 0),
      new THREE.Vector3(side * 1.03, 0.45, 0.05),
      0.075,
    )
    ball(group, 'hand', '#f5d74d', [side * 1.05, 0.38, 0.06], [0.18, 0.2, 0.15], 14)
    capsuleBetween(
      group,
      'leg',
      '#f5d74d',
      new THREE.Vector3(side * 0.35, 0.58, 0),
      new THREE.Vector3(side * 0.36, 0.22, 0.02),
      0.065,
    )
    roundedBox(group, 'sock', '#fff9dc', [side * 0.36, 0.24, 0.02], [0.15, 0.2, 0.17], 0.04)
    roundedBox(group, 'sock-stripe-blue', '#4da0b9', [side * 0.36, 0.31, 0.11], [0.155, 0.027, 0.02], 0.005)
    roundedBox(group, 'sock-stripe-red', '#d84e44', [side * 0.36, 0.27, 0.11], [0.155, 0.027, 0.02], 0.005)
    ball(group, 'shoe', '#302d2c', [side * 0.38, 0.095, 0.12], [0.34, 0.16, 0.43], 16)
  }
  return group
}

function createPatrick() {
  const group = new THREE.Group()
  group.name = 'patrick'
  const profile = [
    new THREE.Vector2(0.34, 0),
    new THREE.Vector2(0.62, 0.22),
    new THREE.Vector2(0.75, 0.65),
    new THREE.Vector2(0.7, 1.12),
    new THREE.Vector2(0.52, 1.48),
    new THREE.Vector2(0.31, 1.88),
    new THREE.Vector2(0.18, 2.32),
    new THREE.Vector2(0.06, 2.58),
    new THREE.Vector2(0, 2.66),
  ]
  addMesh(group, new THREE.LatheGeometry(profile, 32), '#ee9b91', 'body', [0, 0.42, 0])
  ball(group, 'belly', '#ee9b91', [0, 1.2, 0.06], [1.35, 1.3, 0.9], 24)

  const shorts = addMesh(
    group,
    new THREE.CylinderGeometry(0.73, 0.67, 0.58, 24),
    '#a7bd55',
    'shorts',
    [0, 0.69, 0],
  )
  shorts.scale.z = 0.76
  ball(group, 'flower', '#9b63a6', [-0.37, 0.73, 0.55], [0.32, 0.17, 0.035], 12)
  ball(group, 'flower', '#9b63a6', [0.27, 0.58, 0.57], [0.22, 0.12, 0.035], 12)
  ball(group, 'flower', '#9b63a6', [0.58, 0.84, 0.23], [0.22, 0.14, 0.05], 12)
  ball(group, 'flower', '#9b63a6', [-0.6, 0.52, -0.12], [0.22, 0.14, 0.05], 12)
  tube(group, 'waistband', '#75578e', [
    new THREE.Vector3(-0.68, 0.96, 0.25),
    new THREE.Vector3(0, 1, 0.58),
    new THREE.Vector3(0.68, 0.96, 0.25),
  ], 0.025)

  for (const side of [-1, 1]) {
    curvedLimb(group, 'arm', '#ee9b91', [
      new THREE.Vector3(side * 0.55, 1.48, 0),
      new THREE.Vector3(side * 0.93, 1.57, 0.02),
      new THREE.Vector3(side * 1.15, 1.3, 0.12),
      new THREE.Vector3(side * 1.2, 1.1, 0.18),
    ], 0.2, 0.62)
    capsuleBetween(
      group,
      'leg',
      '#ee9b91',
      new THREE.Vector3(side * 0.34, 0.52, 0),
      new THREE.Vector3(side * 0.38, 0.18, 0.08),
      0.23,
    )
    ball(group, 'foot', '#ee9b91', [side * 0.4, 0.055, 0.16], [0.5, 0.11, 0.58], 16)
    addEye(group, side * 0.16, 2.13, 0.34, '#31343a', [0.27, 0.43, 0.11])
    capsuleBetween(
      group,
      'eyebrow',
      '#9b595a',
      new THREE.Vector3(side * 0.27, 2.4, 0.37),
      new THREE.Vector3(side * 0.08, 2.43, 0.4),
      0.018,
      8,
    )
  }
  tube(group, 'mouth', '#8b4f58', [
    new THREE.Vector3(-0.24, 1.8, 0.58),
    new THREE.Vector3(0, 1.72, 0.61),
    new THREE.Vector3(0.24, 1.8, 0.58),
  ], 0.025)
  ball(group, 'belly-button', '#a85f65', [0, 1.18, 0.65], [0.06, 0.06, 0.025], 10)
  return group
}

function createSquid() {
  const group = new THREE.Group()
  group.name = 'squid'
  ball(group, 'head', '#79b9ad', [0, 2.15, 0], [1.1, 1.3, 0.88], 28)
  ball(group, 'brow-dome', '#79b9ad', [0, 2.56, -0.03], [0.93, 0.72, 0.74], 24)
  capsuleBetween(
    group,
    'nose',
    '#75b4a8',
    new THREE.Vector3(0, 2.13, 0.31),
    new THREE.Vector3(0, 1.93, 0.94),
    0.17,
    18,
  )
  for (const side of [-1, 1]) {
    addEye(group, side * 0.18, 2.24, 0.4, '#b89d42', [0.29, 0.53, 0.12])
    roundedBox(group, 'eyelid', '#79b9ad', [side * 0.18, 2.44, 0.475], [0.3, 0.15, 0.05], 0.05)
    capsuleBetween(
      group,
      'arm',
      '#79b9ad',
      new THREE.Vector3(side * 0.42, 1.34, 0),
      new THREE.Vector3(side * 0.7, 0.69, 0.08),
      0.09,
    )
    curvedLimb(group, 'outer-tentacle', '#79b9ad', [
      new THREE.Vector3(side * 0.22, 0.82, 0),
      new THREE.Vector3(side * 0.34, 0.46, side * 0.02),
      new THREE.Vector3(side * 0.46, 0.16, 0.05),
      new THREE.Vector3(side * 0.57, 0.08, 0.25),
    ], 0.13, 0.64)
    ball(group, 'foot', '#79b9ad', [side * 0.58, 0.08, 0.31], [0.31, 0.12, 0.45], 16)
  }
  addMesh(group, new THREE.CylinderGeometry(0.44, 0.5, 0.86, 20), '#9e7043', 'shirt', [0, 1.17, 0])
  tube(group, 'collar', '#704d36', [
    new THREE.Vector3(-0.38, 1.57, 0.2),
    new THREE.Vector3(0, 1.64, 0.46),
    new THREE.Vector3(0.38, 1.57, 0.2),
  ], 0.03)
  for (const side of [-1, 1]) {
    curvedLimb(group, 'inner-tentacle', '#79b9ad', [
      new THREE.Vector3(side * 0.14, 0.84, 0),
      new THREE.Vector3(side * 0.13, 0.48, -0.05),
      new THREE.Vector3(side * 0.19, 0.15, -0.12),
      new THREE.Vector3(side * 0.28, 0.08, 0.03),
    ], 0.12, 0.62)
  }
  tube(group, 'mouth', '#4f6766', [
    new THREE.Vector3(-0.25, 1.76, 0.47),
    new THREE.Vector3(0, 1.72, 0.51),
    new THREE.Vector3(0.25, 1.76, 0.47),
  ], 0.022)
  ball(group, 'head-spot', '#66a397', [-0.35, 2.62, 0.3], [0.14, 0.09, 0.025], 10)
  ball(group, 'head-spot', '#66a397', [0.3, 2.7, 0.23], [0.11, 0.07, 0.025], 10)
  return group
}

function createExplorer() {
  const group = new THREE.Group()
  group.name = 'explorer'
  addMesh(group, new THREE.CylinderGeometry(0.39, 0.44, 0.92, 20), '#2b7f8c', 'wetsuit', [0, 1.05, 0])
  roundedBox(group, 'vest', '#e3a843', [0, 1.2, 0.34], [0.66, 0.63, 0.14], 0.09)
  roundedBox(group, 'tank', '#d9cf9f', [0, 1.24, -0.43], [0.5, 0.92, 0.32], 0.14)
  tube(group, 'air-hose', '#384c52', [
    new THREE.Vector3(0.2, 1.54, -0.43),
    new THREE.Vector3(0.53, 1.73, -0.12),
    new THREE.Vector3(0.43, 1.88, 0.31),
  ], 0.035)
  ball(group, 'helmet', '#c1d2c7', [0, 1.92, 0], [1.15, 1.12, 1.06], 28)
  ball(group, 'visor', '#67b8c3', [0, 1.94, 0.39], [0.83, 0.74, 0.3], 24)
  const visor = group.children.at(-1) as THREE.Mesh
  visor.material = new THREE.MeshStandardMaterial({
    color: '#76c7cf',
    roughness: 0.18,
    transparent: true,
    opacity: 0.72,
    metalness: 0.05,
  })
  addEye(group, -0.16, 1.97, 0.52, '#4d7b8d', [0.21, 0.27, 0.07])
  addEye(group, 0.16, 1.97, 0.52, '#4d7b8d', [0.21, 0.27, 0.07])
  tube(group, 'smile', '#754b45', [
    new THREE.Vector3(-0.14, 1.77, 0.57),
    new THREE.Vector3(0, 1.71, 0.59),
    new THREE.Vector3(0.14, 1.77, 0.57),
  ], 0.018)
  for (const side of [-1, 1]) {
    capsuleBetween(
      group,
      'arm',
      '#2b7f8c',
      new THREE.Vector3(side * 0.38, 1.34, 0),
      new THREE.Vector3(side * 0.62, 0.72, 0.08),
      0.12,
    )
    ball(group, 'glove', '#e7d77b', [side * 0.65, 0.63, 0.1], [0.28, 0.31, 0.25], 16)
    capsuleBetween(
      group,
      'leg',
      '#224f63',
      new THREE.Vector3(side * 0.23, 0.66, 0),
      new THREE.Vector3(side * 0.26, 0.2, 0.04),
      0.15,
    )
    ball(group, 'boot', '#32474c', [side * 0.27, 0.1, 0.15], [0.38, 0.19, 0.5], 16)
  }
  roundedBox(group, 'helmet-latch', '#c28a3f', [0, 1.51, 0.44], [0.28, 0.1, 0.12], 0.025)
  return group
}

const fishStyles = [
  { name: 'reef-bully', body: '#5c9d8b', fin: '#e0ad59', shirt: '#565f70', iris: '#dc775c' },
  { name: 'purple-bruiser', body: '#987ab0', fin: '#d88c68', shirt: '#556f72', iris: '#d9bd52' },
  { name: 'sand-shark', body: '#8da9af', fin: '#607e8a', shirt: '#7a6757', iris: '#de805d' },
  { name: 'spotted-puffer', body: '#b1a859', fin: '#6d9477', shirt: '#6d6a7a', iris: '#b64e51' },
] as const

function createFish(variant: number) {
  const style = fishStyles[variant]
  const group = new THREE.Group()
  group.name = 'fish'
  group.userData.fishVariant = style.name
  const puffer = variant === 3
  ball(group, 'body', style.body, [0, 1.42, 0], puffer ? [1.45, 1.55, 1.1] : [0.95, 1.55, 0.92], 24)
  addMesh(group, new THREE.CylinderGeometry(0.44, 0.48, 0.7, 18), style.shirt, 'shirt', [0, 0.83, 0])
  for (const side of [-1, 1]) {
    addEye(group, side * 0.21, 1.78, 0.4, style.iris, [0.29, 0.36, 0.12])
    const brow = capsuleBetween(
      group,
      'angry-brow',
      '#344247',
      new THREE.Vector3(side * 0.38, 2.04, 0.45),
      new THREE.Vector3(side * 0.08, 1.98, 0.5),
      0.027,
      8,
    )
    brow.castShadow = false
    shape(
      group,
      'side-fin',
      style.fin,
      [[0, 0], [side * 0.52, 0.21], [side * 0.43, -0.34]],
      0.07,
    ).position.set(side * 0.46, 1.22, 0.08)
    capsuleBetween(
      group,
      'leg',
      style.body,
      new THREE.Vector3(side * 0.24, 0.57, 0),
      new THREE.Vector3(side * 0.3, 0.2, 0.08),
      0.14,
    )
    ball(group, 'foot', style.body, [side * 0.31, 0.1, 0.17], [0.32, 0.16, 0.44], 14)
  }
  ball(group, 'muzzle', '#d1a080', [0, 1.43, 0.49], [0.45, 0.28, 0.17], 18)
  tube(group, 'scowl', '#493d3c', [
    new THREE.Vector3(-0.23, 1.46, 0.59),
    new THREE.Vector3(0, 1.52, 0.62),
    new THREE.Vector3(0.23, 1.46, 0.59),
  ], 0.025)
  shape(group, 'dorsal-fin', style.fin, [[-0.35, 0], [0, 0.68], [0.35, 0]], 0)
    .position.set(0, 2.1, -0.18)
  shape(group, 'tail-fin', style.fin, [[0, 0], [-0.44, 0.4], [-0.37, -0.43]], 0)
    .position.set(0, 1.42, -0.72)

  if (puffer) {
    for (let i = 0; i < 12; i++) {
      const angle = i / 12 * Math.PI * 2
      const spike = addMesh(group, new THREE.ConeGeometry(0.055, 0.24, 7), '#e1d682', 'spike', [
        Math.sin(angle) * 0.62,
        1.42 + Math.cos(angle) * 0.7,
        -0.13,
      ])
      spike.rotation.z = -angle
    }
  } else if (variant === 2) {
    for (const side of [-1, 1]) {
      ball(group, 'gill', '#6c8992', [side * 0.49, 1.46, 0.3], [0.12, 0.3, 0.05], 10)
    }
  } else {
    ball(group, 'face-spot', style.fin, [-0.42, 1.34, 0.44], [0.13, 0.09, 0.025], 10)
  }
  return group
}

function makeTemplate(kind: Avatar | 'fish', fishVariant = 0) {
  if (kind === 'sponge') return createSponge()
  if (kind === 'patrick') return createPatrick()
  if (kind === 'squid') return createSquid()
  if (kind === 'explorer') return createExplorer()
  return createFish(fishVariant)
}

export function createCharacter(kind: Avatar | 'fish'): THREE.Group {
  const variant = kind === 'fish' ? nextFish++ % fishStyles.length : 0
  const key = kind === 'fish' ? `fish-${variant}` as const : kind
  let template = templates.get(key)
  if (!template) {
    template = makeTemplate(kind, variant)
    templates.set(key, template)
  }
  const result = template.clone(true)
  result.userData.kind = kind
  if (kind === 'fish') result.userData.fishVariant = fishStyles[variant].name
  return result
}

function addRigArm(
  group: THREE.Group,
  side: -1 | 1,
  skin: THREE.ColorRepresentation,
  sleeve: THREE.ColorRepresentation,
  squid = false,
) {
  const shoulder = new THREE.Vector3(side * 0.36, -0.3, 0.3)
  const wrist = new THREE.Vector3(side * 0.12, -0.12, -0.25)
  if (squid) {
    curvedLimb(group, 'first-person-forearm', skin, [
      shoulder,
      new THREE.Vector3(side * 0.34, -0.18, 0.05),
      new THREE.Vector3(side * 0.22, -0.12, -0.18),
      wrist,
    ], 0.09, 0.62)
  } else {
    capsuleBetween(group, 'first-person-forearm', sleeve, shoulder, wrist, 0.105)
  }
  ball(group, 'first-person-hand', skin, wrist.toArray(), squid ? [0.2, 0.17, 0.28] : [0.22, 0.2, 0.28], 16)
}

export function createFirstPersonRig(kind: Avatar): THREE.Group {
  const group = new THREE.Group()
  group.name = `${kind}-first-person-rig`
  group.userData.kind = kind
  group.userData.attachOffset = new THREE.Vector3(0.3, -0.29, -0.62)

  const gun = pistol()
  gun.name = 'pistol'
  gun.userData.hideInExploration = true
  gun.children[2].name = 'grip'
  gun.children[5].name = 'muzzle'
  for (const child of gun.children.slice(6)) child.visible = false
  roundedBox(gun, 'bubble-canister', '#69b9bd', [0.105, 0.09, -0.12], [0.09, 0.11, 0.28], 0.035)
  ball(gun, 'pearl-gauge', '#e8dca9', [-0.105, 0.08, 0.02], [0.09, 0.09, 0.035], 12)
  tube(gun, 'bubble-pipe', '#d3ae58', [
    new THREE.Vector3(0.08, 0.12, -0.05),
    new THREE.Vector3(0.09, 0.16, -0.22),
    new THREE.Vector3(0.03, 0.14, -0.34),
  ], 0.014)
  group.add(gun)

  const styles: Record<Avatar, {
    skin: THREE.ColorRepresentation
    sleeve: THREE.ColorRepresentation
    squid?: boolean
  }> = {
    explorer: { skin: '#e7d77b', sleeve: '#2b7f8c' },
    sponge: { skin: '#f5d74d', sleeve: '#fff8db' },
    patrick: { skin: '#ee9b91', sleeve: '#ee9b91' },
    squid: { skin: '#79b9ad', sleeve: '#79b9ad', squid: true },
  }
  const style = styles[kind]
  addRigArm(group, -1, style.skin, style.sleeve, style.squid)
  addRigArm(group, 1, style.skin, style.sleeve, style.squid)

  if (kind === 'sponge') {
    for (const side of [-1, 1]) {
      ball(group, 'hand-pore', '#c8a936', [side * 0.12, -0.1, -0.39], [0.035, 0.04, 0.02], 8)
    }
  } else if (kind === 'explorer') {
    for (const side of [-1, 1]) {
      tube(group, 'glove-seam', '#b69d4d', [
        new THREE.Vector3(side * 0.2, -0.04, -0.27),
        new THREE.Vector3(side * 0.12, -0.01, -0.34),
        new THREE.Vector3(side * 0.06, -0.04, -0.39),
      ], 0.01)
    }
  }

  group.traverse(object => {
    if (object instanceof THREE.Mesh) {
      object.castShadow = false
      object.receiveShadow = false
    }
  })
  return group
}
