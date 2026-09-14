import * as T from 'three'
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js'
import { caustics, surface } from './surfaces'

const materials = new Map<string, T.MeshStandardMaterial>()
export function material(color: T.ColorRepresentation, roughness = 0.8) {
  const key = `${color}:${roughness}`
  if (!materials.has(key)) materials.set(key, caustics(new T.MeshStandardMaterial({ color, roughness })))
  return materials.get(key)!
}

export function mesh(parent: T.Object3D, geometry: T.BufferGeometry, color: T.ColorRepresentation, x = 0, y = 0, z = 0) {
  const m = new T.Mesh(geometry, material(color))
  m.position.set(x, y, z)
  m.castShadow = true
  m.receiveShadow = true
  parent.add(m)
  return m
}

export function box(parent: T.Object3D, x: number, y: number, z: number, w: number, h: number, d: number, color: T.ColorRepresentation) {
  return mesh(parent, new RoundedBoxGeometry(w, h, d, Math.min(w, h, d) < 0.25 ? 1 : 2, Math.min(0.14, w * 0.12, h * 0.12, d * 0.12)), color, x, y, z)
}

export function ball(parent: T.Object3D, x: number, y: number, z: number, r: number, color: T.ColorRepresentation, scale = [1, 1, 1]) {
  const segments = r < 0.15 ? 10 : r < 0.4 ? 16 : 24
  const m = mesh(parent, new T.SphereGeometry(r, segments, Math.round(segments * 2 / 3)), color, x, y, z)
  m.scale.set(scale[0], scale[1], scale[2])
  return m
}

export function cylinder(parent: T.Object3D, x: number, y: number, z: number, r: number, h: number, color: T.ColorRepresentation, top = r) {
  return mesh(parent, new T.CylinderGeometry(top, r, h, 28), color, x, y, z)
}

export function ring(parent: T.Object3D, x: number, y: number, z: number, r: number, tube: number, color: T.ColorRepresentation) {
  return mesh(parent, new T.TorusGeometry(r, tube, 8, 32), color, x, y, z)
}

export function group(parent: T.Object3D, x = 0, y = 0, z = 0) {
  const g = new T.Group()
  g.position.set(x, y, z)
  parent.add(g)
  return g
}

export function line(parent: T.Object3D, points: T.Vector3[], color: T.ColorRepresentation, opacity = 1) {
  const l = new T.Line(new T.BufferGeometry().setFromPoints(points), new T.LineBasicMaterial({ color, transparent: opacity < 1, opacity }))
  parent.add(l)
  return l
}

export function label(parent: T.Object3D, text: string, x: number, y: number, z: number, color = '#f8f2d1', width = 4) {
  const canvas = document.createElement('canvas')
  canvas.width = 512
  canvas.height = 96
  const ctx = canvas.getContext('2d')!
  ctx.font = '600 26px sans-serif'
  ctx.textAlign = 'center'
  ctx.fillStyle = color
  ctx.fillText(text, 256, 56)
  const texture = new T.CanvasTexture(canvas)
  texture.colorSpace = T.SRGBColorSpace
  const sprite = new T.Sprite(new T.SpriteMaterial({ map: texture, depthWrite: false }))
  sprite.position.set(x, y, z)
  sprite.scale.set(width, width * 96 / 512, 1)
  parent.add(sprite)
  return sprite
}

export function porthole(parent: T.Object3D, x: number, y: number, z: number, r = 0.85) {
  const g = group(parent, x, y, z)
  ring(g, 0, 0, 0, r, r * 0.15, '#447d92')
  const glass = cylinder(g, 0, 0, 0, r * 0.9, 0.1, '#8edce1')
  glass.rotation.x = Math.PI / 2
  box(g, 0, 0, 0.08, 0.1, r * 1.7, 0.07, '#407e8c')
  box(g, 0, 0, 0.08, r * 1.7, 0.1, 0.07, '#407e8c')
  for (let i = 0; i < 8; i++) {
    const a = i * Math.PI / 4
    ball(g, Math.cos(a) * r, Math.sin(a) * r, 0.1, 0.055, '#d3eddf')
  }
  return g
}

function leaf(parent: T.Object3D, angle: number, height: number, lean: number) {
  const shape = new T.Shape()
  shape.moveTo(-0.75, 0)
  shape.quadraticCurveTo(-1.15, height * 0.5, lean, height)
  shape.quadraticCurveTo(1.3, height * 0.4, 0.75, 0)
  const m = new T.Mesh(new T.ShapeGeometry(shape), new T.MeshStandardMaterial({ color: height > 6 ? '#338855' : '#60a850', side: T.DoubleSide, roughness: 0.9 }))
  m.rotation.y = angle
  m.rotation.z = -lean * 0.09
  m.position.set(Math.sin(angle) * 1.1, 15, Math.cos(angle) * 1.1)
  m.castShadow = true
  parent.add(m)
}

export function pineapple(parent: T.Object3D, x: number, z: number) {
  const g = group(parent, x, 0, z)
  const body = mesh(g, new T.SphereGeometry(1, 40, 28), '#e99a31', 0, 7.5)
  body.scale.set(6, 8.2, 5.9)
  body.material = surface('mottle', '#f1a32c', 6, 4)
  for (let direction = -1; direction <= 1; direction += 2) {
    for (let j = 0; j < 12; j++) {
      const points: T.Vector3[] = []
      for (let i = 0; i <= 90; i++) {
        const t = 0.09 + i / 90 * (Math.PI - 0.18)
        const a = j / 12 * Math.PI * 2 + direction * t * 1.65
        points.push(new T.Vector3(Math.sin(t) * Math.sin(a) * 6.035, 7.5 - Math.cos(t) * 8.235, Math.sin(t) * Math.cos(a) * 5.935))
      }
      const tube = new T.TubeGeometry(new T.CatmullRomCurve3(points), 70, 0.045, 3, false)
      mesh(g, tube, '#bc762e')
    }
  }
  for (let i = 0; i < 11; i++) leaf(g, i * 2.4, 5.2 + i % 4, (i % 2 ? 1 : -1) * (2 + i % 3))
  const door = group(g, 0, 0, 5.25)
  door.name = 'Pineapple hatch surround'
  for (const s of [-1, 1]) box(door, s * 1.65, 1.9, 0.3, 0.3, 3.8, 0.55, '#8cc3d7')
  box(door, 0, 3.85, 0.3, 3.6, 0.3, 0.55, '#8cc3d7')
  for (const s of [-1, 1]) for (let y = 0.4; y < 3.8; y += 0.55) ball(door, s * 1.65, y, 0.6, 0.06, '#dcf4ed')
  porthole(g, -2.6, 7.8, 5.3, 1.05)
  porthole(g, 2.15, 11.65, 4.95, 0.85)
  cylinder(g, 5.35, 8.7, 0, 0.4, 3, '#607f83')
  const chimney = cylinder(g, 5.85, 10.1, 0, 0.4, 1.2, '#698d90')
  chimney.rotation.z = Math.PI / 2
  return g
}

export function moai(parent: T.Object3D, x: number, z: number) {
  const g = group(parent, x, 0, z)
  const head = cylinder(g, 0, 9, 0, 5, 18, '#567e90', 4.15)
  head.material = surface('mottle', '#527f9d', 3, 3)
  box(g, -5, 10.5, 0, 2.1, 7.7, 3.8, '#496e83')
  box(g, 5, 10.5, 0, 2.1, 7.7, 3.8, '#496e83')
  box(g, 0, 9.2, 5.2, 1.65, 5.2, 2.9, '#648d9d')
  box(g, 0, 13.8, 4.55, 8.5, 1.9, 1.5, '#547a8c')
  porthole(g, -2.5, 11.9, 4.8, 0.92)
  porthole(g, 2.5, 11.9, 4.8, 0.92)
  for (const s of [-1, 1]) box(g, s * 1.65, 1.9, 5.25, 0.3, 3.8, 0.55, '#687e83')
  box(g, 0, 3.85, 5.25, 3.6, 0.3, 0.55, '#687e83')
  return g
}

export function rock(parent: T.Object3D, x: number, z: number) {
  const g = group(parent, x, 0, z)
  const lid = group(g, 0, 0.3, -5.5)
  lid.rotation.x = -0.8
  const dome = mesh(lid, new T.SphereGeometry(6.5, 40, 24, 0, Math.PI * 2, 0, Math.PI / 2), '#ae7772', 0, 0, 5.5)
  dome.scale.set(1.15, 0.76, 0.92)
  dome.material = surface('mottle', '#ae7768', 2, 1)
  cylinder(lid, 0, 6.5, 4.8, 0.12, 2.1, '#94784c')
  box(lid, 0, 7.15, 4.8, 2.4, 0.16, 0.15, '#d5b275')
  const arrow = mesh(lid, new T.ConeGeometry(0.4, 0.7, 3), '#d5b275', 1.45, 7.15, 4.8)
  arrow.rotation.z = -Math.PI / 2
  const rim = ring(g, 0, 0.04, 0, 6, 0.25, '#b69862')
  rim.rotation.x = Math.PI / 2
  cylinder(g, 0, -0.02, 0, 5.8, 0.04, '#554c40')
  return g
}

export function sofa(parent: T.Object3D, x: number, z: number, color = '#b96c55', rotation = 0) {
  const g = group(parent, x, 0, z)
  g.rotation.y = rotation
  box(g, 0, 0.62, 0, 3.7, 0.8, 1.6, color)
  box(g, 0, 1.35, -0.7, 3.7, 1.7, 0.55, color)
  for (const s of [-1, 1]) {
    ball(g, s * 1.83, 1.05, 0, 0.45, color, [1, 1.1, 2])
    box(g, s * 1.2, 0.16, 0.2, 0.18, 0.4, 0.7, '#745438')
  }
  for (let i = -1; i <= 1; i++) box(g, i * 1.04, 1.04, 0.1, 1, 0.18, 1.2, color)
  return g
}

export function table(parent: T.Object3D, x: number, z: number, color = '#b39058', r = 1.1) {
  cylinder(parent, x, 1.2, z, r, 0.18, color)
  cylinder(parent, x, 0.6, z, 0.15, 1.2, '#82664c')
  cylinder(parent, x, 0.1, z, 0.65, 0.15, '#82664c')
}

export function tv(parent: T.Object3D, x: number, z: number, helmet = false) {
  cylinder(parent, x, 0.45, z, 0.7, 0.9, '#947143')
  if (helmet) {
    ball(parent, x, 1.6, z, 0.9, '#a57736')
    ring(parent, x, 1.65, z + 0.75, 0.58, 0.12, '#d3ae63')
    const face = cylinder(parent, x, 1.65, z + 0.76, 0.54, 0.07, '#2e6471')
    face.rotation.x = Math.PI / 2
  } else {
    box(parent, x, 1.5, z, 1.8, 1.3, 1, '#715f5a')
    box(parent, x - 0.12, 1.5, z + 0.53, 1.35, 0.93, 0.06, '#9bd0c7')
  }
  for (const s of [-1, 1]) {
    const a = cylinder(parent, x + s * 0.3, 2.65, z, 0.025, 1, '#425d65')
    a.rotation.z = s * -0.4
  }
}

export function bed(parent: T.Object3D, x: number, z: number, sponge = false) {
  box(parent, x, 0.4, z, 3.2, 0.4, 4.5, '#967548')
  for (let i = 0; i < (sponge ? 3 : 1); i++) box(parent, x, 0.75 + i * 0.25, z, 3, 0.25, 4.2, '#f5e8be')
  box(parent, x, sponge ? 1.43 : 0.98, z + 0.5, 3.05, 0.14, 3, sponge ? '#7e568d' : '#c097bd')
  box(parent, x, sponge ? 1.5 : 1.08, z - 1.35, 2.1, 0.3, 0.7, '#fff6d8')
  for (const sx of [-1, 1]) {
    for (const sz of [-1, 1]) {
      cylinder(parent, x + sx * 1.65, 2.2, z + sz * 2.1, 0.12, 4.4, '#b69961')
    }
  }
  if (!sponge) box(parent, x, 4.3, z, 3.55, 0.15, 4.6, '#829dad')
  if (sponge) {
    ring(parent, x, 2.3, z - 2.15, 0.95, 0.25, '#83a466')
    for (let i = 0; i < 10; i++) {
      const f = group(parent, x - 1.1 + (i % 3) * 1.05, 1.515, z - 0.5 + Math.floor(i / 3) * 0.68)
      f.rotation.x = -Math.PI / 2
      for (let p = 0; p < 5; p++) {
        const petal = ring(f, Math.sin(p * 1.256) * 0.1, Math.cos(p * 1.256) * 0.1, 0, 0.1, 0.009, '#d2b080')
        petal.scale.y = 1.3
      }
    }
  }
}

export function bookshelf(parent: T.Object3D, x: number, z: number, width = 3.2) {
  box(parent, x, 2.3, z, width, 4.6, 0.65, '#765536')
  for (let row = 0; row < 5; row++) {
    box(parent, x, 0.2 + row * 0.85, z + 0.14, width, 0.12, 0.8, '#bb9559')
    for (let i = 0; i < Math.floor(width / 0.28) - 1; i++) {
      box(parent, x - width / 2 + 0.25 + i * 0.28, 0.65 + row * 0.85, z + 0.22, 0.21, 0.55 + i % 3 * 0.07, 0.65, ['#809e91', '#b68858', '#be6d5d', '#5a7689', '#dcc389'][(i + row) % 5])
    }
  }
}

export function kitchen(parent: T.Object3D, x: number, z: number, sand = false) {
  const c = sand ? '#d5b889' : '#81b1a6'
  box(parent, x - 2, 1, z, 4.5, 2, 1.4, sand ? c : '#bb9963')
  box(parent, x - 2, 2.07, z, 4.7, 0.15, 1.65, c)
  box(parent, x + 1.65, 2, z, 1.6, 4, 1.7, c)
  box(parent, x + 1.65, 2.4, z + 0.88, 1.45, 0.05, 0.03, '#497c7a')
  box(parent, x + 1.1, 1.7, z + 0.95, 0.1, 0.5, 0.08, '#e4ddb7')
  cylinder(parent, x - 3.1, 2.1, z, 0.6, 0.1, sand ? c : '#506565')
  cylinder(parent, x - 1, 2.2, z, 0.55, 0.35, '#c8c1aa')
  cylinder(parent, x - 1, 2.7, z - 0.3, 0.045, 0.7, '#8b9b99')
  box(parent, x - 2, 3.9, z - 0.15, 4.4, 1.2, 1, sand ? c : '#a47f4f')
}

export function bathroom(parent: T.Object3D, x: number, z: number) {
  box(parent, x, 0.65, z, 2.6, 1.3, 4, '#c1d9d0')
  box(parent, x, 1.31, z, 2.1, 0.1, 3.4, '#6fa7ac')
  cylinder(parent, x + 1.1, 2.4, z - 1.7, 0.05, 3.8, '#d4c0a0')
  for (let i = 0; i < 8; i++) cylinder(parent, x + 1.15, 2.7, z - 1.3 + i * 0.36, 0.13, 2.4, i % 2 ? '#d1a2ac' : '#b98296')
  cylinder(parent, x - 3, 0.55, z - 0.9, 0.5, 1.1, '#bbcfc7')
  box(parent, x - 3, 1.2, z - 1.5, 0.95, 1.1, 0.4, '#c7d5c4')
  ring(parent, x - 3, 1.15, z - 0.85, 0.4, 0.1, '#e3e2c4').rotation.x = Math.PI / 2
}

export function portrait(parent: T.Object3D, x: number, y: number, z: number) {
  box(parent, x, y, z, 1.5, 1.9, 0.15, '#bc9151')
  box(parent, x, y, z + 0.1, 1.25, 1.65, 0.05, '#96aba2')
  ball(parent, x, y + 0.28, z + 0.2, 0.44, '#73ada5', [1, 1.2, 0.2])
  ball(parent, x, y - 0.08, z + 0.26, 0.2, '#649f99', [0.65, 2, 0.3])
  for (const s of [-1, 1]) {
    ball(parent, x + s * 0.16, y + 0.2, z + 0.28, 0.12, '#e7e5ba', [0.65, 1, 0.3])
    ball(parent, x + s * 0.16, y + 0.18, z + 0.32, 0.035, '#663f3e')
  }
  box(parent, x, y - 0.6, z + 0.2, 0.66, 0.4, 0.1, '#967947')
}

export function character(kind: 'sponge' | 'patrick' | 'fish') {
  const g = new T.Group()
  if (kind === 'sponge') {
    box(g, 0, 1.5, 0, 1.35, 1.25, 0.5, '#f7d548')
    box(g, 0, 0.82, 0, 1.34, 0.25, 0.52, '#f6f0cc')
    box(g, 0, 0.58, 0, 1.35, 0.28, 0.54, '#a5764b')
    for (let i = 0; i < 9; i++) ball(g, Math.sin(i * 13) * 0.52, 1.55 + Math.cos(i * 7) * 0.45, 0.26, 0.05 + i % 3 * 0.018, '#cea834', [1, 1, 0.2])
    for (const s of [-1, 1]) {
      ball(g, s * 0.3, 1.76, 0.32, 0.27, '#fffcec', [1, 1.1, 0.4])
      ball(g, s * 0.3, 1.76, 0.43, 0.115, '#6aa9be', [1, 1, 0.3])
      ball(g, s * 0.3, 1.76, 0.46, 0.055, '#163c4a', [1, 1, 0.3])
      box(g, s * 0.11, 1.17, 0.32, 0.17, 0.18, 0.13, '#fffbea')
      cylinder(g, s * 0.36, 0.3, 0, 0.07, 0.35, '#f0e7c2')
      ball(g, s * 0.4, 0.1, 0.08, 0.17, '#414241', [1.5, 0.6, 1])
      cylinder(g, s * 0.85, 1.1, 0, 0.06, 0.7, '#e7ca49').rotation.z = s * 0.35
    }
    ball(g, 0, 1.48, 0.4, 0.13, '#f9d953', [0.7, 0.7, 1.8])
    mesh(g, new T.ConeGeometry(0.13, 0.32, 3), '#ca5b49', 0, 0.8, 0.3)
  } else if (kind === 'patrick') {
    ball(g, 0, 1.12, 0, 0.73, '#eea298', [1, 1.05, 0.65])
    mesh(g, new T.ConeGeometry(0.57, 1.45, 14), '#eea298', 0, 2, 0)
    cylinder(g, 0, 0.65, 0, 0.68, 0.55, '#a6bd62', 0.7)
    for (const s of [-1, 1]) {
      const arm = mesh(g, new T.ConeGeometry(0.26, 1.1, 10), '#eea298', s * 0.85, 1.4, 0)
      arm.rotation.z = s * -1.05
      ball(g, s * 0.33, 0.24, 0, 0.28, '#eea298', [0.8, 1, 1])
      ball(g, s * 0.17, 2.06, 0.39, 0.15, '#fff6da', [0.85, 1.3, 0.5])
      ball(g, s * 0.17, 2.05, 0.46, 0.046, '#35414a')
      ball(g, s * 0.37, 0.67, 0.59, 0.16, '#a785b5', [1, 0.7, 0.1])
    }
    line(g, [new T.Vector3(-0.22, 1.75, 0.5), new T.Vector3(0, 1.68, 0.54), new T.Vector3(0.22, 1.75, 0.5)], '#995d60')
  } else {
    const colors = ['#75a68d', '#a191b6', '#bcac65', '#66a9ae']
    const c = colors[Math.floor(Math.random() * colors.length)]
    ball(g, 0, 1.4, 0, 0.67, c, [0.72, 1.45, 0.65])
    box(g, 0, 0.75, 0, 0.85, 0.65, 0.65, '#647c80')
    for (const s of [-1, 1]) {
      ball(g, s * 0.21, 1.83, 0.33, 0.19, '#fff1aa', [1, 1, 0.6])
      ball(g, s * 0.21, 1.83, 0.43, 0.07, '#c9705e')
      const fin = mesh(g, new T.ConeGeometry(0.3, 0.9, 3), c, s * 0.59, 1.1, 0.35)
      fin.rotation.x = Math.PI / 2
      fin.rotation.z = s * 0.8
      ball(g, s * 0.23, 0.22, 0.12, 0.19, c, [0.65, 1.15, 1.5])
    }
    box(g, 0, 1.36, 0.44, 0.3, 0.17, 0.05, '#45595e')
    const dorsal = mesh(g, new T.ConeGeometry(0.3, 0.8, 3), c, 0, 2.33, -0.1)
    dorsal.rotation.x = -0.35
  }
  return g
}

export function pistol() {
  const g = new T.Group()
  box(g, 0, 0, 0, 0.16, 0.19, 0.65, '#7a9a9b')
  box(g, 0, 0.04, -0.1, 0.17, 0.1, 0.68, '#b2c6be')
  box(g, 0, -0.18, 0.19, 0.145, 0.35, 0.2, '#c6a25c').rotation.x = -0.25
  box(g, 0, 0.105, -0.38, 0.035, 0.06, 0.045, '#e6c577')
  ring(g, 0, -0.12, 0.02, 0.09, 0.024, '#658384').rotation.y = Math.PI / 2
  const muzzle = cylinder(g, 0, 0, -0.37, 0.055, 0.05, '#274956')
  muzzle.rotation.x = Math.PI / 2
  ball(g, 0, -0.26, 0.24, 0.14, '#d8b18a', [0.85, 0.8, 1.3])
  box(g, 0.015, -0.3, 0.55, 0.2, 0.22, 0.55, '#4c7d85').rotation.x = -0.15
  g.traverse(o => { o.castShadow = false; o.receiveShadow = false })
  return g
}
