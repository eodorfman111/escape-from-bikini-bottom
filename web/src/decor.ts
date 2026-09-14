import * as T from 'three'
import * as M from './models'
import { surface } from './surfaces'

export function tube(parent: T.Object3D, points: [number, number, number][], radius: number, color: string) {
  return M.mesh(parent, new T.TubeGeometry(new T.CatmullRomCurve3(points.map(p => new T.Vector3(...p))), 32, radius, 8, false), color)
}

export function inflatableSofa(parent: T.Object3D, x: number, z: number) {
  const g = M.group(parent, x, 0, z)
  M.box(g, 0, 0.36, 0.2, 4.5, 0.6, 1.75, '#427fc6')
  for (let row = 0; row < 3; row++) {
    const cushion = M.cylinder(g, 0, 0.85 + row * 0.59, -0.58, 0.34, 4.4, '#6ec727')
    cushion.rotation.z = Math.PI / 2
    for (const side of [-1, 1]) {
      M.ball(g, side * 2.2, 0.85 + row * 0.59, -0.58, 0.34, '#8bdd40')
      const strap = M.ring(g, side * 1.6, 0.85 + row * 0.59, -0.58, 0.348, 0.03, '#e38d30')
      strap.rotation.y = Math.PI / 2
    }
  }
}

export function lifebuoyChair(parent: T.Object3D, x: number, z: number) {
  const g = M.group(parent, x, 0, z)
  M.ring(g, 0, 0.72, 0, 0.76, 0.29, '#ece3ce').rotation.x = Math.PI / 2
  for (const side of [-1, 1]) {
    const leg = M.cylinder(g, side * 0.48, 0.35, 0.1, 0.1, 0.7, '#a26c43')
    leg.rotation.z = side * 0.15
    M.ball(g, side * 0.73, 1.12, 0.05, 0.27, '#c74f29', [1, 1, 2.8])
    M.box(g, side * 0.65, 0.75, 0, 0.23, 0.28, 1.15, '#c95642')
  }
  M.ball(g, 0, 1.82, -0.64, 0.83, '#c94e2b', [1.05, 1.5, 0.38])
  M.ball(g, 0, 1.87, -0.35, 0.62, '#d96037', [1, 1.5, 0.2])
}

export function shell(parent: T.Object3D, x: number, y: number, z: number, color = '#dca2cf', size = 1) {
  const g = M.group(parent, x, y, z)
  g.scale.setScalar(size)
  for (let i = -3; i <= 3; i++) {
    const petal = M.ball(g, i * 0.17, Math.abs(i) * -0.08, 0, 0.46, color, [0.28, 1.35, 0.48])
    petal.rotation.z = -i * 0.18
  }
  return g
}

export function shellLamp(parent: T.Object3D, x: number, z: number, hanging = false) {
  const y = hanging ? 4.7 : 3
  M.cylinder(parent, x, hanging ? 5.45 : 1.5, z, 0.035, hanging ? 1.2 : 3, '#7499bb')
  if (!hanging) M.cylinder(parent, x, 0.16, z, 0.52, 0.3, '#568cac', 0.18)
  const shade = shell(parent, x, y, z, '#d99dd5', 1.15)
  if (hanging) shade.rotation.z = Math.PI
  const bulb = M.ball(parent, x, y - 0.2, z, 0.15, '#ffe5aa')
  bulb.material = new T.MeshStandardMaterial({ color: '#ffe5aa', emissive: '#ffe5aa', emissiveIntensity: 1 })
  const light = new T.PointLight('#ffd6a6', 9, 9, 2)
  light.position.set(x, y - 0.35, z)
  parent.add(light)
}

export function bambooChair(parent: T.Object3D, x: number, z: number, rotation = 0) {
  const g = M.group(parent, x, 0, z)
  g.rotation.y = rotation
  M.box(g, 0, 0.62, 0, 1.7, 0.34, 1.5, '#5898d0')
  M.box(g, 0, 1.55, -0.63, 1.65, 1.6, 0.3, '#689fd0')
  for (const s of [-1, 1]) {
    tube(g, [[s * 0.88, 0.1, 0.55], [s * 0.88, 1.3, 0.55], [s * 0.88, 1.3, -0.6], [s * 0.88, 2.5, -0.65]], 0.065, '#d3b768')
    M.cylinder(g, s * 0.86, 1.2, -0.66, 0.065, 2.4, '#d3b768')
  }
}

export function rug(parent: T.Object3D, x: number, z: number, radius: number, color: string, oval = 1) {
  const g = M.group(parent, x, 0.026, z)
  g.scale.z = oval
  const mat = M.cylinder(g, 0, 0, 0, radius, 0.04, color)
  mat.material = surface('woven', color, 2, 2)
  for (const fraction of [0.88, 0.93, 0.5]) M.ring(g, 0, 0.028, 0, radius * fraction, 0.024, '#b1ae74').rotation.x = Math.PI / 2
}

export function shellPhone(parent: T.Object3D, x: number, z: number) {
  M.cylinder(parent, x, 0.9, z, 0.18, 1.8, '#a6a65c')
  for (let i = 0; i < 3; i++) tube(parent, [[x, 0.22, z], [x + Math.sin(i * 2.1) * 0.6, 0.08, z + Math.cos(i * 2.1) * 0.6]], 0.045, '#646e36')
  shell(parent, x, 1.92, z, '#977ebf', 0.68)
  M.ball(parent, x, 1.7, z + 0.2, 0.33, '#9078b5', [1.1, 0.4, 0.8])
}

export function fishingLure(parent: T.Object3D, x: number, y: number, z: number) {
  const g = M.group(parent, x, y, z)
  M.ball(g, 0, 0, 0, 0.35, '#efeac4', [3, 0.6, 0.6])
  for (let i = -2; i <= 2; i++) {
    const stripe = M.ring(g, i * 0.3, 0, 0, 0.22, 0.042, '#bd4c35')
    stripe.rotation.y = Math.PI / 2
    stripe.rotation.z = 0.2
  }
  for (let i = 0; i < 12; i++) {
    const a = i / 12 * Math.PI * 2
    tube(g, [[-0.85, 0, 0], [-1.1, Math.sin(a) * 0.28, 0.04], [-1.8, Math.sin(a) * 0.7, Math.cos(a) * 0.1]], 0.016, '#293f48')
  }
  tube(g, [[1, 0, 0], [1.4, -0.15, 0], [1.1, -0.46, 0], [0.92, -0.23, 0]], 0.025, '#354657')
}

export function snail(parent: T.Object3D, x: number, z: number) {
  const g = M.group(parent, x, 0, z)
  M.ball(g, 0, 0.16, 0, 0.65, '#8ec5be', [1.25, 0.25, 0.7])
  M.ball(g, -0.18, 0.52, 0, 0.52, '#e29cae', [1, 1, 0.65])
  const spiral: [number, number, number][] = []
  for (let i = 0; i < 45; i++) {
    const t = i / 44
    spiral.push([-0.18 + Math.sin(t * 11) * t * 0.37, 0.52 + Math.cos(t * 11) * t * 0.37, 0.36])
  }
  tube(g, spiral, 0.028, '#b84e78')
  for (const side of [-1, 1]) {
    M.cylinder(g, 0.47, 0.65, side * 0.19, 0.025, 1, '#99c996')
    M.ball(g, 0.47, 1.18, side * 0.19, 0.13, '#dadd87')
    M.ball(g, 0.52, 1.18, side * 0.19 + 0.09, 0.065, '#c74c41')
  }
}

export function nauticalKitchen(parent: T.Object3D, x: number, z: number) {
  const g = M.group(parent, x, 0, z)
  const fridge = M.box(g, -4.2, 1.8, 0, 1.6, 3.6, 1.5, '#cfe8d8')
  fridge.material = surface('metal', '#c5dfce')
  M.box(g, -4.2, 0.3, 0.8, 1.7, 0.6, 0.12, '#c76759')
  M.porthole(g, -4.2, 2.75, 0.82, 0.38)
  M.box(g, -4.8, 1.7, 0.85, 0.08, 0.5, 0.09, '#dfae4e')
  M.ball(g, -1.8, 0.9, 0, 0.85, '#5e6665', [1, 1.1, 1])
  M.cylinder(g, -1.8, 1.63, 0, 0.67, 0.13, '#b7beba')
  M.porthole(g, -1.8, 0.85, 0.78, 0.36)
  tube(g, [[-1.8, 1.7, -0.5], [-1.8, 2.6, -0.5], [-2.1, 3.3, -0.5], [-2.1, 5.6, -0.5]], 0.14, '#a77453')
  for (let i = 0; i < 3; i++) {
    M.box(g, 1 + i * 1.45, 0.88, 0, 1.4, 1.76, 1.65, '#a9874c')
    M.box(g, 1 + i * 1.45, 1.8, 0, 1.43, 0.16, 1.7, ['#c65747', '#dcbd5d', '#538b67'][i])
    for (let slat = 0; slat < 5; slat++) M.box(g, 0.43 + i * 1.45 + slat * 0.28, 0.88, 0.84, 0.024, 1.55, 0.015, '#71643b')
  }
  M.cylinder(g, 2.45, 1.97, 0, 0.57, 0.3, '#4b797a', 0.64)
  tube(g, [[2.45, 2, -0.6], [2.45, 2.65, -0.6], [2.45, 2.7, -0.12], [2.45, 2.5, -0.12]], 0.04, '#9aa9a1')
  M.cylinder(g, 0.3, 3.6, -0.2, 0.68, 1.45, '#ad8550')
  for (const y of [3.05, 4.14]) M.ring(g, 0.3, y, -0.2, 0.69, 0.07, '#686c58').rotation.x = Math.PI / 2
  M.box(g, 3.3, 3.7, -0.1, 2.4, 1.25, 1.1, '#b38e53')
  M.box(g, 3.3, 3.7, 0.48, 0.03, 1.2, 0.04, '#776c43')
}
