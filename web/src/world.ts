import * as T from 'three'
import * as M from './models'
import * as D from './decor'
import { batchStatic, surface } from './surfaces'
import { buildInterior } from './interiors'
import type { Point, Rect } from './rules'

export type Location = 'street' | 'sponge0' | 'sponge1' | 'sponge2' | 'roof' | 'squid0' | 'squid1' | 'patrick0'
export type Interaction = { at: Point; text: string; target?: Location; kind: 'travel' | 'supply' | 'secret'; secretId?: string; discovery?: string }
export type Portal = { id: string; at: Point; normal: Point; target: Location; exitId: string; width: number; height: number; screen: T.Mesh<T.PlaneGeometry, T.MeshBasicMaterial> }
export type Zone = Rect & { name: string }
export type World = {
  root: T.Group; walls: Rect[]; interactions: Interaction[]; zones: Zone[]; portals: Portal[];
  spawn: Point; name: string; door: Point; home: 'sponge' | 'squid' | 'patrick' | null
}
export const homeX = { sponge: 24, squid: 0, patrick: -24 }
export const entryLocations: Record<string, Location> = { sponge: 'sponge0', squid: 'squid0', patrick: 'patrick0' }
export const secretCount = 9

export function wall(w: World, x: number, z: number, width: number, depth: number, color: string, height = 5.8, pattern: 'bamboo' | 'mottle' | 'woven' | 'metal' = 'mottle') {
  const mesh = M.box(w.root, x, height / 2, z, width, height, depth, color)
  mesh.material = surface(pattern, color, Math.max(width, depth) / 5, height / 6)
  obstacle(w, x, z, width, depth)
}

export function obstacle(w: World, x: number, z: number, width: number, depth: number) {
  w.walls.push({ x, z, w: width, d: depth })
}

export function arch(w: World, x: number, z: number, width: number, color: string, rotation = 0) {
  const g = M.group(w.root, x, 0, z)
  g.rotation.y = rotation
  for (const side of [-1, 1]) M.cylinder(g, side * width / 2, 1.5, 0, 0.12, 3, color)
  M.mesh(g, new T.TorusGeometry(width / 2, 0.12, 10, 28, Math.PI), color, 0, 3)
}

export function passage(w: World, id: string, at: Point, normal: Point, target: Location, exitId: string, text: string, color = '#809da8') {
  const width = 3.1, height = 3.8
  const rotation = Math.atan2(normal.x, normal.z)
  const screen = new T.Mesh(new T.PlaneGeometry(width, height), new T.MeshBasicMaterial({ color: '#d7e2d7', toneMapped: false }))
  screen.position.set(at.x, height / 2, at.z)
  screen.rotation.y = rotation
  screen.userData.dynamic = true
  screen.name = `Live doorway: ${id}`
  w.root.add(screen)
  const frame = M.group(w.root, at.x, 0, at.z)
  frame.rotation.y = rotation
  for (const side of [-1, 1]) {
    M.box(frame, side * 1.68, 1.95, 0, 0.23, 3.9, 0.4, color)
    for (let y = 0.4; y < 3.8; y += 0.65) M.ball(frame, side * 1.68, y, 0.24, 0.045, '#d6e7cf')
  }
  M.box(frame, 0, 3.95, 0, 3.6, 0.24, 0.4, color)
  M.box(frame, 0, 0.015, 0, 3.1, 0.03, 0.5, '#c1b59a')
  const hinge = M.group(frame, -1.6, 0, 0)
  hinge.rotation.y = -Math.PI * 0.58
  M.box(hinge, 1.5, 1.86, 0, 2.95, 3.7, 0.13, color)
  if (w.home === 'squid' || id === 'squid') {
    for (let i = 0; i < 7; i++) M.box(hinge, 0.15 + i * 0.43, 1.85, 0.075, 0.028, 3.5, 0.015, '#6e6647')
    M.ball(hinge, 2.55, 1.8, 0.16, 0.1, '#dcc576')
  } else {
    M.ring(hinge, 1.5, 1.75, 0.14, 0.36, 0.045, '#d2e7e6')
    M.box(hinge, 1.5, 1.75, 0.14, 0.75, 0.035, 0.07, '#d2e7e6')
    M.box(hinge, 1.5, 1.75, 0.14, 0.035, 0.75, 0.07, '#d2e7e6')
  }
  w.portals.push({ id, at, normal, target, exitId, width, height, screen })
  w.interactions.push({ at, text, kind: 'travel', target })
}

export function roomShell(w: World, color: string, floor: string, pattern: 'bamboo' | 'mottle' | 'woven' | 'metal' = 'mottle', ceiling = '#b0b29b', height = 5.8) {
  const ground = M.box(w.root, 0, -0.18, 0, 22.5, 0.36, 22.5, floor)
  ground.material = surface(w.home === 'squid' ? 'parquet' : 'sand', floor, 5, 5)
  wall(w, -11, 0, 0.3, 22, color, height, pattern)
  wall(w, 11, 0, 0.3, 22, color, height, pattern)
  wall(w, 0, -11, 22, 0.3, color, height, pattern)
  wall(w, 0, 11, 22, 0.3, color, height, pattern)
  M.box(w.root, 0, height + 0.1, 0, 22.5, 0.2, 22.5, ceiling)
}

export function supply(w: World, x: number, z: number) {
  M.box(w.root, x, 0.55, z, 1.2, 1.1, 0.9, '#bca35e')
  for (const s of [-1, 1]) M.box(w.root, x + s * 0.42, 0.58, z, 0.08, 1.2, 0.95, '#ead39a')
  M.box(w.root, x, 0.6, z + 0.47, 0.45, 0.12, 0.05, '#f2efcc')
  M.box(w.root, x, 0.6, z + 0.47, 0.12, 0.45, 0.05, '#f2efcc')
  obstacle(w, x, z, 1.2, 0.9)
  w.interactions.push({ at: { x, z: z + 1.1 }, text: 'Collect health + pistol ammo', kind: 'supply' })
}

export function secret(w: World, id: string, at: Point, text: string, discovery: string) {
  w.interactions.push({ at, text, kind: 'secret', secretId: id, discovery })
}

function flower(w: World, x: number, y: number, z: number, size: number, color: string) {
  const points: T.Vector3[] = []
  for (let i = 0; i <= 160; i++) {
    const a = i / 160 * Math.PI * 2
    const r = (0.67 + Math.cos(a * 5) * 0.3) * size
    points.push(new T.Vector3(x + Math.cos(a) * r, y + Math.sin(a) * r, z))
  }
  M.line(w.root, points, color, 0.5)
  M.ring(w.root, x, y, z, size * 0.12, 0.045, color)
}

function coral(w: World, x: number, z: number, size: number, color: string) {
  const g = M.group(w.root, x, 0, z)
  for (let i = 0; i < 5; i++) {
    const a = i * 2.4, h = size * (0.6 + (i % 3) * 0.2), tx = Math.sin(a) * size * 0.35
    D.tube(g, [[0, 0, 0], [tx * 0.4, h * 0.5, 0], [tx, h, Math.cos(a) * size * 0.25]], size * 0.08, color)
    M.ball(g, tx, h, Math.cos(a) * size * 0.25, size * 0.1, color)
  }
}

function outside(w: World) {
  const ground = M.box(w.root, 0, -0.15, 0, 420, 0.3, 420, '#e4d7ad')
  ground.material = surface('sand', '#e4d7ad', 60, 60)
  M.box(w.root, 0, 0.012, 15, 180, 0.045, 7.5, '#789493')
  for (let i = -17; i <= 17; i++) M.box(w.root, i * 5, 0.045, 15, 1.8, 0.025, 0.12, '#c9cdb0')
  M.pineapple(w.root, 24, -9)
  M.moai(w.root, 0, -9)
  M.rock(w.root, -24, -9)
  for (const [key, x] of Object.entries(homeX)) {
    obstacle(w, x, -9, key === 'patrick' ? 13 : 11, 11)
    for (let j = 0; j < 7; j++) {
      const stone = M.ball(w.root, x + Math.sin(j * 3) * 0.2, 0.06, -2 + j * 1.8, 0.85, '#98ad87', [1.2, 0.12, 0.75])
      stone.rotation.y = j * 1.7
    }
    M.cylinder(w.root, x + 3.6, 1.1, 5.4, 0.08, 2.2, '#9c8557')
    M.box(w.root, x + 3.6, 2.2, 5.4, 0.7, 0.6, 1.1, key === 'sponge' ? '#d5b963' : '#86958e')
    M.label(w.root, key === 'sponge' ? '124' : key === 'squid' ? '122' : '120', x + 3.6, 2.25, 6, '#fff3cc', 0.6)
    passage(w, key, { x, z: -3 }, { x: 0, z: 1 }, entryLocations[key], 'out', `Walk into ${key === 'sponge' ? 'SpongeBob’s pineapple' : key === 'squid' ? 'Squidward’s house' : 'Patrick’s rock'}`, key === 'squid' ? '#b99259' : key === 'patrick' ? '#c5a67e' : '#87bcd4')
  }
  for (let i = 0; i < 70; i++) {
    const a = i * 2.399, radius = 40 + (i % 13) * 4
    const x = Math.sin(a) * radius, z = Math.cos(a) * radius
    if (Math.abs(z - 15) < 6) continue
    if (i % 3 === 0) coral(w, x, z, 1.3 + i % 4, '#bf88b0')
    else M.ball(w.root, x, 0.15, z, 0.3 + i % 4 * 0.2, '#bbc5a8', [1.5, 0.5, 1])
  }
  for (const x of [-33, -15, 14, 32]) {
    coral(w, x, -6, 1.4, '#d690a9')
    coral(w, x + 1.3, -4.5, 0.8, '#86b4aa')
  }
  for (let i = 0; i < 18; i++) {
    const h = 5 + (i * 7 % 12)
    const g = M.group(w.root, -130 + i * 16, 0, -75 - (i % 3) * 7)
    M.cylinder(g, 0, h / 2, 0, 3.2, h, '#599b9d', 2.7)
    M.ball(g, 0, h, 0, 2.8, '#62a3a1', [1, 0.5, 1])
    M.porthole(g, 0, h * 0.65, 2.8, 0.6)
  }
  flower(w, -45, 32, -82, 12, '#609fa4')
  flower(w, 8, 41, -98, 15, '#729f9c')
  flower(w, 68, 28, -87, 10, '#58a0a9')
  flower(w, -81, 18, -70, 7, '#6da7a2')
  M.cylinder(w.root, -13, 2.3, 22, 0.09, 4.6, '#7d7d59')
  M.box(w.root, -13, 4.3, 22, 4.6, 0.9, 0.18, '#3b7a78')
  M.label(w.root, 'CONCH STREET', -13, 4.3, 22.15, '#eee6c3', 3.6)
  const spatula = M.group(w.root, 29, 0.2, 6.8)
  M.cylinder(spatula, 0, 0.55, 0, 0.03, 1.1, '#645546')
  M.box(spatula, 0, 1.2, 0, 0.4, 0.45, 0.04, '#d5bb66')
  secret(w, 'spatula', { x: 29, z: 7.6 }, 'Inspect the golden spatula', 'Golden spatula! The neighborhood’s best fry cook left his calling card.')
  w.walls.push({ x: -95, z: 0, w: 2, d: 190 }, { x: 95, z: 0, w: 2, d: 190 }, { x: 0, z: -85, w: 190, d: 2 }, { x: 0, z: 85, w: 190, d: 2 })
}

export function buildWorld(location: Location): World {
  const names: Record<Location, string> = {
    street: 'Conch Street', sponge0: 'SpongeBob’s pineapple', sponge1: 'SpongeBob’s pineapple',
    sponge2: 'SpongeBob’s pineapple', roof: 'Pineapple rooftop', squid0: 'Squidward’s moai',
    squid1: 'Squidward’s moai', patrick0: 'Patrick’s rock',
  }
  const w: World = {
    root: new T.Group(), walls: [], interactions: [], zones: [], portals: [],
    spawn: { x: 0, z: location === 'street' ? 26 : 7.6 }, name: names[location],
    door: { x: 0, z: 9.2 }, home: location.startsWith('sponge') || location === 'roof' ? 'sponge' : location.startsWith('squid') ? 'squid' : location === 'patrick0' ? 'patrick' : null,
  }
  w.root.name = location
  if (location === 'street') outside(w)
  else if (location === 'roof') {
    const neighborhood = M.group(w.root, 0, -16, 0)
    const ground = M.box(neighborhood, 0, -0.2, 0, 420, 0.3, 420, '#d2c090')
    ground.material = surface('sand', '#e4d7ad', 60, 60)
    M.box(neighborhood, 0, 0.012, 24, 180, 0.045, 7.5, '#7c9289')
    M.moai(neighborhood, -24, 0)
    M.rock(neighborhood, -48, 0)
    M.box(w.root, 0, -0.2, 0, 22, 0.4, 22, '#7b9955')
    for (let i = 0; i < 26; i++) {
      const a = i / 26 * Math.PI * 2
      const leaf = M.mesh(w.root, new T.ConeGeometry(1.2, 7, 12), '#639852', Math.sin(a) * 10.5, 2.7, Math.cos(a) * 10.5)
      leaf.rotation.z = -Math.sin(a) * 0.4
    }
    for (const s of [-1, 1]) {
      wall(w, s * 10.5, 0, 0.3, 22, '#65925c', 1)
      wall(w, 0, s * 10.5, 22, 0.3, '#65925c', 1)
    }
    passage(w, 'down', { x: 0, z: 8.8 }, { x: 0, z: -1 }, 'sponge2', 'roof', 'Walk down to the bedroom', '#89aab3')
    w.zones.push({ x: 0, z: 0, w: 22, d: 22, name: 'Leaf-crown lookout' })
    supply(w, -7, -6)
    const jelly = M.group(w.root, 5, 2, -5)
    M.ball(jelly, 0, 0, 0, 0.6, '#d58bba', [1, 0.7, 1])
    for (let i = 0; i < 5; i++) D.tube(jelly, [[(i - 2) * 0.18, -0.2, 0], [(i - 2) * 0.2, -0.6, 0.1], [(i - 2) * 0.15, -1, 0]], 0.025, '#e5afd2')
    secret(w, 'jellyjam', { x: 5, z: -3.8 }, 'Greet the rooftop jellyfish', 'Jellyfish Jam — the party has moved upstairs. Please keep the volume down for Squidward.')
  } else buildInterior(w, location)
  batchStatic(w.root)
  return w
}
