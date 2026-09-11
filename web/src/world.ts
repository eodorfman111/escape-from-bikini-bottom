import * as T from 'three'
import * as M from './models'
import type { Point, Rect } from './rules'

export type Location = 'street' | 'sponge0' | 'sponge1' | 'sponge2' | 'roof' | 'squid0' | 'squid1' | 'patrick0'
export type Interaction = { at: Point; text: string; target?: Location; kind: 'travel' | 'supply' }
export type Zone = Rect & { name: string }
export type World = {
  root: T.Group; walls: Rect[]; interactions: Interaction[]; zones: Zone[];
  spawn: Point; name: string; door: Point; home: 'sponge' | 'squid' | 'patrick' | null
}
export const homeX = { sponge: 24, squid: 0, patrick: -24 }
export const entryLocations: Record<string, Location> = { sponge: 'sponge0', squid: 'squid0', patrick: 'patrick0' }

function wall(w: World, x: number, z: number, width: number, depth: number, color: string, height = 5.8) {
  M.box(w.root, x, height / 2, z, width, height, depth, color)
  w.walls.push({ x, z, w: width, d: depth })
}

function obstacle(w: World, x: number, z: number, width: number, depth: number) {
  w.walls.push({ x, z, w: width, d: depth })
}

function flower(w: World, x: number, y: number, z: number, size: number, color: string) {
  const points: T.Vector3[] = []
  for (let i = 0; i <= 160; i++) {
    const a = i / 160 * Math.PI * 2
    const r = (0.67 + Math.cos(a * 5) * 0.3) * size
    points.push(new T.Vector3(x + Math.cos(a) * r, y + Math.sin(a) * r, z))
  }
  M.line(w.root, points, color, 0.4)
  M.ring(w.root, x, y, z, size * 0.12, 0.045, color)
}

function coral(w: World, x: number, z: number, size: number, color: string) {
  const g = M.group(w.root, x, 0, z)
  for (let i = 0; i < 5; i++) {
    const a = i * 2.4
    const h = size * (0.6 + (i % 3) * 0.2)
    const b = M.cylinder(g, Math.sin(a) * size * 0.25, h / 2, Math.cos(a) * size * 0.25, size * 0.11, h, color)
    b.rotation.z = Math.sin(a) * 0.35
    M.ball(g, Math.sin(a) * size * 0.3, h, Math.cos(a) * size * 0.25, size * 0.15, color)
  }
}

function outside(w: World) {
  const canvas = document.createElement('canvas')
  canvas.width = canvas.height = 256
  const ctx = canvas.getContext('2d')!
  ctx.fillStyle = '#cebf8c'
  ctx.fillRect(0, 0, 256, 256)
  for (let i = 0; i < 4000; i++) {
    ctx.fillStyle = i % 2 ? '#b4a875' : '#e1d3a2'
    ctx.fillRect(Math.random() * 256, Math.random() * 256, 1, 1)
  }
  const tex = new T.CanvasTexture(canvas)
  tex.wrapS = tex.wrapT = T.RepeatWrapping
  tex.repeat.set(65, 65)
  tex.colorSpace = T.SRGBColorSpace
  const ground = M.box(w.root, 0, -0.15, 0, 420, 0.3, 420, '#d2c090')
  ground.material = new T.MeshStandardMaterial({ map: tex, roughness: 1 })
  M.box(w.root, 0, 0.012, 15, 180, 0.045, 7.5, '#7c9289')
  for (let i = -17; i <= 17; i++) M.box(w.root, i * 5, 0.045, 15, 1.8, 0.025, 0.12, '#c9cdb0')
  M.pineapple(w.root, 24, -9)
  M.moai(w.root, 0, -9)
  M.rock(w.root, -24, -9)
  for (const [key, x] of Object.entries(homeX)) {
    obstacle(w, x, -9, key === 'patrick' ? 13 : 11, 11)
    for (let j = 0; j < 7; j++) {
      const stone = M.cylinder(w.root, x + Math.sin(j * 3) * 0.2, 0.05, -2 + j * 1.8, 0.85, 0.12, '#a5a994')
      stone.scale.set(1.35, 1, 0.7)
    }
    M.cylinder(w.root, x + 3.6, 1.1, 5.4, 0.08, 2.2, '#9c8557')
    const mailbox = M.box(w.root, x + 3.6, 2.2, 5.4, 0.7, 0.6, 1.1, key === 'sponge' ? '#d5b963' : '#86958e')
    mailbox.rotation.y = -0.12
    M.label(w.root, key === 'sponge' ? '124' : key === 'squid' ? '122' : '120', x + 3.6, 2.25, 6, '#fff3cc', 0.6)
    w.interactions.push({ at: { x, z: -2.8 }, text: `Enter ${key === 'sponge' ? "SpongeBob’s pineapple" : key === 'squid' ? "Squidward’s house" : "Patrick’s rock"}`, kind: 'travel', target: entryLocations[key] })
  }
  for (let i = 0; i < 100; i++) {
    const a = i * 2.399
    const radius = 40 + (i % 13) * 4
    const x = Math.sin(a) * radius
    const z = Math.cos(a) * radius
    if (Math.abs(z - 15) < 6) continue
    if (i % 3 === 0) coral(w, x, z, 1.3 + i % 4, ['#b685ad', '#799fa2', '#c0948a'][i % 3])
    else M.ball(w.root, x, 0.15, z, 0.3 + i % 4 * 0.2, ['#c9bd93', '#a9b39d', '#bab19c'][i % 3], [1.5, 0.5, 1])
  }
  for (const x of [-33, -15, 14, 32]) {
    coral(w, x, -6, 1.4, '#c58f9b')
    coral(w, x + 1.3, -4.5, 0.8, '#8d9f93')
  }
  for (let i = 0; i < 18; i++) {
    const x = -130 + i * 16
    const h = 5 + (i * 7 % 12)
    const g = M.group(w.root, x, 0, -75 - (i % 3) * 7)
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
  w.walls.push({ x: -95, z: 0, w: 2, d: 190 }, { x: 95, z: 0, w: 2, d: 190 }, { x: 0, z: -85, w: 190, d: 2 }, { x: 0, z: 85, w: 190, d: 2 })
}

function roomShell(w: World, color: string, floor: string) {
  M.box(w.root, 0, -0.18, 0, 22.5, 0.36, 22.5, floor)
  wall(w, -11, 0, 0.3, 22, color)
  wall(w, 11, 0, 0.3, 22, color)
  wall(w, 0, -11, 22, 0.3, color)
  wall(w, 0, 11, 22, 0.3, color)
  M.box(w.root, 0, 5.95, 0, 22.5, 0.2, 22.5, '#b9c8ae')
  for (let i = -10; i <= 10; i += 2) {
    M.box(w.root, i, 0.02, 0, 0.025, 0.01, 22, '#adad91')
    M.box(w.root, 0, 0.02, i, 22, 0.01, 0.025, '#adad91')
  }
  for (let i = -10; i <= 10; i++) {
    M.cylinder(w.root, i, 2.9, -10.79, 0.035, 5.8, color)
    for (let j = 1; j <= 4; j++) M.box(w.root, i, j * 1.2, -10.73, 0.13, 0.06, 0.04, '#adc3ad')
  }
  M.porthole(w.root, 6, 3.6, -10.75, 1.1)
  M.box(w.root, 0, 1.9, 10.78, 2.3, 3.8, 0.16, '#527f7e')
  M.ring(w.root, 0.6, 1.8, 10.66, 0.26, 0.06, '#c4d4b8')
  M.label(w.root, ['sponge0', 'squid0', 'patrick0'].includes(w.root.name) ? 'CONCH STREET' : 'DOWNSTAIRS', 0, 4.3, 10.4, '#fff6db', 3)
  w.door = { x: 0, z: 9.5 }
  w.interactions.push({ at: { x: 0, z: 9.1 }, text: 'Return to Conch Street', kind: 'travel', target: 'street' })
}

function divide(w: World, z: number, color: string) {
  wall(w, -8, z, 6, 0.25, color)
  wall(w, 2, z, 8, 0.25, color)
  wall(w, 10, z, 2, 0.25, color)
  M.box(w.root, -3.5, 4.85, z, 3, 1.9, 0.25, color)
  M.box(w.root, 7.5, 4.85, z, 3, 1.9, 0.25, color)
}

function stairs(w: World, x: number, z: number, target: Location, title: string) {
  for (let i = 0; i < 8; i++) M.box(w.root, x, 0.1 + i * 0.18, z - i * 0.32, 2.1, 0.2 + i * 0.36, 0.34, '#63957a')
  for (const s of [-1, 1]) {
    for (let i = 0; i < 4; i++) M.cylinder(w.root, x + s, 1 + i * 0.37, z - i * 0.65, 0.04, 1.8, '#a5b877')
  }
  M.label(w.root, title, x, 3.5, z, '#f6e5b1', 3.4)
  w.interactions.push({ at: { x, z: z + 1.2 }, text: title, kind: 'travel', target })
  obstacle(w, x, z - 1.3, 2.1, 2.5)
}

function supply(w: World, x: number, z: number) {
  M.box(w.root, x, 0.65, z, 1.5, 1.3, 1, '#bca35e')
  for (const s of [-1, 1]) M.box(w.root, x + s * 0.52, 0.68, z, 0.1, 1.4, 1.05, '#ead39a')
  M.box(w.root, x, 0.7, z + 0.52, 0.45, 0.12, 0.05, '#f2efcc')
  M.box(w.root, x, 0.7, z + 0.52, 0.12, 0.45, 0.05, '#f2efcc')
  M.label(w.root, 'SUPPLIES', x, 2, z, '#f6d783', 2.2)
  obstacle(w, x, z, 1.5, 1)
  w.interactions.push({ at: { x, z: z + 1.2 }, text: 'Collect health + pistol ammo', kind: 'supply' })
}

function spongeGround(w: World) {
  roomShell(w, '#619eab', '#d8c48e')
  divide(w, -2, '#639c9f')
  M.sofa(w.root, -6.8, 3.4, '#b9694f', 0.25)
  obstacle(w, -6.8, 3.4, 4.2, 2)
  M.tv(w.root, -6, 7.5, true)
  obstacle(w, -6, 7.5, 1.8, 1.6)
  M.table(w.root, -3.5, 4.6, '#ba8c62', 0.65)
  M.ball(w.root, -3.5, 1.55, 4.6, 0.4, '#ddaca6', [1, 0.5, 0.8])
  M.ring(w.root, 5, 1, 4, 0.85, 0.24, '#e4e2b7').rotation.x = Math.PI / 2
  M.box(w.root, 5, 0.4, 4, 1.6, 0.5, 1.6, '#bd8351')
  M.kitchen(w.root, 0, -9.5)
  obstacle(w, -1.2, -9.5, 7.4, 1.8)
  M.table(w.root, 3, -6, '#d3ae6f')
  obstacle(w, 3, -6, 2, 2)
  const bowl = M.cylinder(w.root, 5, 0.2, -8.5, 0.43, 0.4, '#c85350')
  bowl.name = 'Gary’s bowl'
  const snail = M.group(w.root, 5.8, 0, -7.6)
  M.ball(snail, 0, 0.18, 0, 0.5, '#92b9a1', [1.2, 0.35, 0.75])
  M.ball(snail, -0.1, 0.5, 0, 0.43, '#d796a3')
  M.ring(snail, -0.1, 0.5, 0.39, 0.22, 0.04, '#a85c7a')
  for (const s of [-1, 1]) {
    M.cylinder(snail, 0.42, 0.55, s * 0.15, 0.025, 0.7, '#94bfa8')
    M.ball(snail, 0.42, 0.93, s * 0.15, 0.085, '#d7d795')
  }
  stairs(w, -8.5, -6, 'sponge1', 'Up to the library')
  supply(w, 8, 6)
  w.zones.push({ x: 0, z: 4, w: 22, d: 13, name: 'Living room' }, { x: 0, z: -7, w: 22, d: 9, name: 'Kitchen' })
}

function spongeLibrary(w: World) {
  roomShell(w, '#a09272', '#98754f')
  for (let i = -8; i <= 2; i += 3.4) {
    M.bookshelf(w.root, i, -10.4)
    obstacle(w, i, -10.4, 3.2, 0.8)
  }
  M.sofa(w.root, -5, -4, '#71896d')
  obstacle(w, -5, -4, 4, 2)
  M.cylinder(w.root, -5, 3.7, -4.5, 0.025, 4.4, '#435e52')
  M.table(w.root, -1.8, -3.6, '#926b42', 0.6)
  for (let i = 0; i < 7; i++) M.cylinder(w.root, -9.5 + i * 0.36, 2.1 + Math.sin(i) * 0.5, 0, 0.11, 3.3 + Math.sin(i), '#c0ae70')
  M.box(w.root, -8.4, 0.8, 0, 2.7, 1.6, 1, '#6d634d')
  M.box(w.root, -8.4, 1.3, 0.65, 2.2, 0.12, 0.6, '#dfd2ab')
  wall(w, 3.5, -7, 0.25, 8, '#bb9d9e')
  M.bathroom(w.root, 8.6, -7.7)
  obstacle(w, 8.6, -7.7, 2.7, 4)
  M.label(w.root, 'BATHROOM', 7, 4.4, -3, '#fff0d3')
  M.cylinder(w.root, 7, 0.45, 4, 0.06, 2, '#999b8e').rotation.z = Math.PI / 2
  for (const s of [-1, 1]) M.ball(w.root, 7 + s, 0.5, 4, 0.4, '#d3aaa0')
  M.label(w.root, 'WORKOUT NOOK', 7, 3.8, 4, '#fff0d3')
  stairs(w, -8, 6, 'sponge2', 'Up to the bedroom')
  w.interactions[0] = { at: { x: 0, z: 9 }, text: 'Down to the living room', kind: 'travel', target: 'sponge0' }
  w.zones.push({ x: -4, z: 0, w: 15, d: 22, name: 'Library' }, { x: 7, z: -7, w: 7, d: 8, name: 'Bathroom' }, { x: 7, z: 4, w: 7, d: 12, name: 'Workout nook' })
}

function spongeBedroom(w: World) {
  roomShell(w, '#af7370', '#99b9ad')
  M.bed(w.root, -3.7, -4.5, true)
  obstacle(w, -3.7, -4.5, 3.5, 4.7)
  M.cylinder(w.root, -6.8, 0.8, -5.8, 0.6, 1.6, '#a88a53')
  const horn = M.cylinder(w.root, -6.8, 2, -5.8, 0.32, 0.85, '#adbeae', 0.09)
  horn.rotation.z = Math.PI / 2
  M.box(w.root, 3, 0.6, -9, 2.5, 1.2, 1.5, '#bb8f4f')
  M.box(w.root, 3, 1.25, -9, 2.6, 0.12, 1.6, '#9b753f')
  M.label(w.root, 'GARY’S CORNER', 6.5, 2, -6.5, '#f6dfb3')
  for (let i = 0; i < 5; i++) M.box(w.root, 6.5 + i * 0.06, 0.05 + i * 0.04, -6.5, 1.7, 0.03, 1.3, '#dcd8ba')
  M.box(w.root, 0, 3.4, -10.7, 1.8, 2.1, 0.08, '#ede3bd')
  M.label(w.root, 'BOATING EXAM', 0, 3.8, -10.55, '#578681', 1.6)
  M.label(w.root, 'TODAY!', 0, 3.1, -10.55, '#c67761', 1.3)
  stairs(w, 8, 3, 'roof', 'Climb to the rooftop')
  supply(w, -8, 4)
  w.interactions[0] = { at: { x: 0, z: 9 }, text: 'Down to the library', kind: 'travel', target: 'sponge1' }
  w.zones.push({ x: 0, z: 0, w: 22, d: 22, name: 'Bedroom' })
}

function squidGround(w: World) {
  roomShell(w, '#85a17b', '#c19693')
  divide(w, -2, '#829c79')
  M.sofa(w.root, -6, 2, '#ab8293')
  obstacle(w, -6, 2, 4.1, 2)
  M.table(w.root, -5.5, 5)
  obstacle(w, -5.5, 5, 2.2, 2.2)
  M.tv(w.root, -8.5, 7.5)
  M.bookshelf(w.root, 6, 10.3)
  M.kitchen(w.root, 2.5, -9.7)
  obstacle(w, 1.3, -9.5, 7.5, 1.8)
  M.table(w.root, 6, -5.4, '#6f9da9', 1.35)
  obstacle(w, 6, -5.4, 2.6, 2.6)
  for (const s of [-1, 1]) {
    M.box(w.root, 6 + s * 2, 0.5, -5.4, 0.8, 1, 0.8, '#6f9da9')
    M.box(w.root, 6 + s * 2.3, 1.25, -5.4, 0.15, 1.3, 0.85, '#6f9da9')
  }
  M.cylinder(w.root, 6, 4.9, -5.4, 0.03, 2, '#a9b489')
  for (let i = -3; i <= 3; i++) M.ball(w.root, 6 + i * 0.18, 4, -5.4, 0.6, '#e2c4ac', [0.25, 0.5, 1])
  stairs(w, -8.5, -6, 'squid1', 'Up to the art studio')
  M.portrait(w.root, -7, 3.7, -1.8)
  supply(w, 8, 5)
  w.zones.push({ x: 0, z: 4, w: 22, d: 13, name: 'Living room' }, { x: 0, z: -7, w: 22, d: 9, name: 'Kitchen & dining room' })
}

function squidUpper(w: World) {
  roomShell(w, '#779baf', '#9ca987')
  wall(w, 0, -7, 0.25, 8, '#b27471')
  M.bed(w.root, -6.5, -5.8)
  obstacle(w, -6.5, -5.8, 3.6, 4.7)
  M.table(w.root, -9, -7.6, '#a7a69b', 0.5)
  for (let i = 0; i < 4; i++) {
    M.portrait(w.root, 2 + i * 2.4, 3.3, -10.7)
  }
  const easel = M.group(w.root, 5.4, 0, -5.8)
  for (const s of [-1, 1]) {
    const leg = M.cylinder(easel, s * 0.5, 1.4, 0, 0.05, 2.8, '#a58253')
    leg.rotation.z = s * -0.18
  }
  M.portrait(easel, 0, 2.1, 0.1)
  obstacle(w, 5.4, -5.8, 1.7, 1)
  M.cylinder(w.root, 8, 1.2, -5, 0.065, 1.4, '#334c4d')
  M.cylinder(w.root, 8, 0.5, -5, 0.18, 0.35, '#3b5050', 0.065)
  M.label(w.root, 'ART STUDIO', 6, 4.9, -3, '#f4dfc1')
  M.bathroom(w.root, 8.5, 5)
  obstacle(w, 8.5, 5, 2.7, 4)
  wall(w, 3.5, 6, 0.25, 10, '#b798b0')
  M.label(w.root, 'BATHROOM', 7, 4.2, 0.5, '#fff0d3')
  w.interactions[0] = { at: { x: 0, z: 9 }, text: 'Down to the living room', kind: 'travel', target: 'squid0' }
  w.zones.push({ x: -5, z: 0, w: 11, d: 22, name: 'Canopy bedroom' }, { x: 6, z: -6, w: 11, d: 10, name: 'Art studio' }, { x: 7, z: 6, w: 7, d: 11, name: 'Bathroom' })
}

function patrickRoom(w: World) {
  roomShell(w, '#b99a79', '#d5b98a')
  M.sofa(w.root, -5, 1, '#caae7b')
  obstacle(w, -5, 1, 4.1, 2)
  M.tv(w.root, -5.5, 6.5)
  obstacle(w, -5.5, 6.5, 1.8, 1.6)
  M.kitchen(w.root, -1, -9.5, true)
  obstacle(w, -2.3, -9.5, 7.3, 1.8)
  M.table(w.root, -2.5, -5, '#caae7b')
  obstacle(w, -2.5, -5, 2, 2)
  wall(w, 3.5, -7, 0.3, 8, '#bca17c')
  M.box(w.root, 7, 0.5, -6.4, 3.2, 1, 4.3, '#cbb187')
  M.box(w.root, 7, 1.08, -7.8, 2.1, 0.3, 0.75, '#dfc69a')
  obstacle(w, 7, -6.4, 3.2, 4.3)
  M.box(w.root, 8.5, 0.3, -2.4, 0.7, 0.6, 0.5, '#8f6b49')
  M.label(w.root, 'THE SECRET BOX', 8.5, 1.4, -2.4, '#f0dfb7', 2.6)
  M.cylinder(w.root, -8, 1.2, 1, 0.06, 2.4, '#b4946b')
  M.cylinder(w.root, -8, 2.4, 1, 0.7, 0.6, '#d3b581', 0.4)
  supply(w, 8, 6.5)
  w.zones.push({ x: -4, z: 2, w: 15, d: 18, name: 'Sand living room' }, { x: 0, z: -8, w: 8, d: 5, name: 'Sand kitchen' }, { x: 7, z: -6, w: 7, d: 10, name: 'Sleeping nook' })
}

export function buildWorld(location: Location): World {
  const names: Record<Location, string> = {
    street: 'Conch Street', sponge0: 'SpongeBob’s pineapple', sponge1: 'SpongeBob’s pineapple',
    sponge2: 'SpongeBob’s pineapple', roof: 'Pineapple rooftop', squid0: 'Squidward’s moai',
    squid1: 'Squidward’s moai', patrick0: 'Patrick’s rock',
  }
  const w: World = {
    root: new T.Group(), walls: [], interactions: [], zones: [],
    spawn: { x: 0, z: location === 'street' ? 26 : 7.6 }, name: names[location],
    door: { x: 0, z: 9.5 }, home: location.startsWith('sponge') || location === 'roof' ? 'sponge' : location.startsWith('squid') ? 'squid' : location === 'patrick0' ? 'patrick' : null,
  }
  w.root.name = location
  switch (location) {
    case 'street': outside(w); break
    case 'sponge0': spongeGround(w); break
    case 'sponge1': spongeLibrary(w); break
    case 'sponge2': spongeBedroom(w); break
    case 'squid0': squidGround(w); break
    case 'squid1': squidUpper(w); break
    case 'patrick0': patrickRoom(w); break
    case 'roof': {
      const neighborhood = M.group(w.root, 0, -16, 0)
      M.box(neighborhood, 0, -0.2, 0, 420, 0.3, 420, '#d2c090')
      M.box(neighborhood, 0, 0.012, 24, 180, 0.045, 7.5, '#7c9289')
      M.moai(neighborhood, -24, 0)
      M.rock(neighborhood, -48, 0)
      M.box(w.root, 0, -0.2, 0, 22, 0.4, 22, '#7b9955')
      for (let i = 0; i < 26; i++) {
        const a = i / 26 * Math.PI * 2
        const x = Math.sin(a) * 10.5
        const z = Math.cos(a) * 10.5
        const leaf = M.mesh(w.root, new T.ConeGeometry(1.2, 7, 4), '#639852', x, 2.7, z)
        leaf.rotation.z = -Math.sin(a) * 0.4
      }
      for (const s of [-1, 1]) {
        wall(w, s * 10.5, 0, 0.3, 22, '#65925c', 1)
        wall(w, 0, s * 10.5, 22, 0.3, '#65925c', 1)
      }
      M.box(w.root, 0, 0.04, 8.5, 2.3, 0.15, 2.3, '#536f60')
      w.interactions.push({ at: { x: 0, z: 8 }, text: 'Down to the bedroom', kind: 'travel', target: 'sponge2' })
      w.zones.push({ x: 0, z: 0, w: 22, d: 22, name: 'Leaf-crown lookout' })
      supply(w, -7, -6)
      break
    }
  }
  return w
}
