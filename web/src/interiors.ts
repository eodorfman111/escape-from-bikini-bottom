import * as T from 'three'
import * as M from './models'
import * as D from './decor'
import { painting } from './artwork'
import type { Artwork } from './artwork'
import { surface } from './surfaces'
import { arch, obstacle, passage, roomShell, secret, supply, wall } from './world'
import type { Location, World } from './world'

function pineappleGround(w: World) {
  roomShell(w, '#58c9dd', '#e2dbc0', 'bamboo', '#beaf85')
  passage(w, 'out', { x: 0, z: 9.6 }, { x: 0, z: -1 }, 'street', 'sponge', 'Walk outside', '#79aeca')
  wall(w, 0, -2.5, 10, 0.3, '#58c9dd', 5.8, 'bamboo')
  wall(w, -10.15, -2.5, 1.7, 0.3, '#58c9dd', 5.8, 'bamboo')
  wall(w, 10.15, -2.5, 1.7, 0.3, '#58c9dd', 5.8, 'bamboo')
  arch(w, -7.15, -2.5, 4.15, '#b58d4e')
  arch(w, 7.15, -2.5, 4.15, '#d3864a')
  M.box(w.root, 7.15, 5.28, -2.5, 4.2, 1.04, 0.3, '#d3864a')
  D.inflatableSofa(w.root, 0, -1.2)
  obstacle(w, 0, -1.1, 4.6, 1.9)
  painting(w.root, -3.2, 3.5, -2.29, 1.15, 1.55, 'gary')
  D.fishingLure(w.root, 0.3, 4, -2.13)
  D.shellPhone(w.root, -3.5, -0.7)
  obstacle(w, -3.5, -0.7, 0.8, 0.8)
  D.lifebuoyChair(w.root, -5.3, 2.5)
  obstacle(w, -5.3, 2.5, 2.05, 2)
  M.tv(w.root, -2.6, 5.7, true)
  obstacle(w, -2.6, 5.7, 1.9, 1.5)
  D.rug(w.root, 0, 2.6, 3.2, '#c3b17d', 0.73)
  M.table(w.root, 0.5, 2.5, '#a98e61', 0.65)
  obstacle(w, 0.5, 2.5, 1.3, 1.3)
  M.porthole(w.root, 10.8, 3.6, 2, 1.15).rotation.y = -Math.PI / 2
  passage(w, 'library', { x: -9, z: 6.4 }, { x: 1, z: 0 }, 'sponge1', 'lower', 'Walk into the library', '#87b4c6')
  M.label(w.root, 'LIBRARY', -8.65, 4.3, 6.4, '#315b62', 2.3).rotation.y = Math.PI / 2
  D.nauticalKitchen(w.root, -2.2, -9.8)
  obstacle(w, -6.4, -9.8, 1.7, 1.6)
  obstacle(w, -4, -9.8, 1.8, 1.7)
  obstacle(w, 0.5, -9.8, 5, 1.8)
  M.table(w.root, -3.5, -5.8, '#c2a165', 0.92)
  obstacle(w, -3.5, -5.8, 1.9, 1.9)
  for (const x of [-5.2, -1.8]) {
    D.bambooChair(w.root, x, -5.6, x < -3 ? Math.PI / 2 : -Math.PI / 2)
    obstacle(w, x, -5.6, 1.5, 1.5)
  }
  for (let i = 0; i < 6; i++) M.box(w.root, 7.15, 0.12 + i * 0.2, -4.1 - i * 0.36, 3, 0.24 + i * 0.4, 0.4, '#81b844')
  passage(w, 'stairs', { x: 7.15, z: -3.5 }, { x: 0, z: 1 }, 'sponge2', 'down', 'Walk upstairs to the bedroom', '#cf9150')
  M.label(w.root, 'BEDROOM ↑', 7.15, 4.35, -3.35, '#465f48', 2.7)
  supply(w, 7.8, 4.4)
  w.zones.push({ x: 0, z: 4, w: 22, d: 13, name: 'Living room · Gary portrait & striped lure' }, { x: -1, z: -7, w: 20, d: 9, name: 'Kitchen · shell chairs & potbelly stove' })
}

function pineappleLibrary(w: World) {
  roomShell(w, '#53919a', '#507b31', 'mottle', '#b2ac8c', 9)
  passage(w, 'lower', { x: 0, z: 9.6 }, { x: 0, z: -1 }, 'sponge0', 'library', 'Walk back to the living room', '#7b9db0')
  for (let i = -4; i <= 4; i++) {
    const a = i * 0.32
    const x = Math.sin(a) * 9.2, z = -Math.cos(a) * 9.2
    const shelf = M.group(w.root, x, 0, z)
    shelf.rotation.y = -a
    shelf.scale.set(0.85, 1.66, 1)
    M.bookshelf(shelf, 0, 0)
    obstacle(w, x, z, 2.4 * Math.abs(Math.cos(a)) + 0.8, 2.4 * Math.abs(Math.sin(a)) + 0.8)
  }
  for (const x of [-8.3, 8.3]) {
    const g = M.group(w.root, x, 0, 1.5)
    g.rotation.y = x < 0 ? Math.PI / 2 : -Math.PI / 2
    g.scale.y = 1.6
    M.bookshelf(g, 0, 0)
    obstacle(w, x, 1.5, 1, 3.2)
  }
  D.rug(w.root, -0.8, 0.8, 3.9, '#b0a173')
  const chair = M.group(w.root, -0.8, 0, 0.8)
  M.ball(chair, 0, 0.92, 0, 1.15, '#80ab28', [1, 0.35, 0.86])
  M.ball(chair, 0, 1.62, -0.75, 1.12, '#8db936', [1, 0.87, 0.3])
  for (const side of [-1, 1]) {
    D.tube(chair, [[side * 0.94, 1.1, 0.65], [side * 0.94, 1.65, 0], [side * 0.95, 1.8, -0.68]], 0.09, '#bd973f')
    D.tube(chair, [[side * 0.9, 1.3, 0.4], [side * 0.52, 4.3, -0.2], [0, 6.8, -0.2]], 0.032, '#ac8853')
  }
  M.ring(chair, 0, 7.05, -0.2, 0.22, 0.05, '#888b81')
  M.cylinder(chair, 0, 8.1, -0.2, 0.028, 1.5, '#c7b477')
  obstacle(w, -0.8, 0.8, 2.3, 2.1)
  for (const side of [-1, 1]) {
    const archway = M.group(w.root, side * 5.6, 0, 5.5)
    for (let i = 0; i <= 10; i++) {
      const a = i / 10 * Math.PI
      const block = M.box(archway, Math.cos(a) * 1.5, 3.4 + Math.sin(a) * 1.5, 0, 0.48, 0.62, 0.7, '#c5c3a8')
      block.rotation.z = a - Math.PI / 2
    }
  }
  const fireplace = M.group(w.root, 7, 0, 6.8)
  fireplace.rotation.y = -Math.PI / 3
  for (let i = 0; i < 7; i++) {
    const a = i / 6 * Math.PI
    const rib = M.ball(fireplace, Math.cos(a) * 0.94, 0.3 + Math.sin(a) * 1.7, 0, 0.4, '#bbaf8e', [0.75, 1.4, 1.25])
    rib.rotation.z = a - Math.PI / 2
  }
  M.ball(fireplace, 0, 0.7, 0, 0.83, '#345154', [1, 0.9, 0.3])
  for (let i = 0; i < 3; i++) M.ball(fireplace, (i - 1) * 0.3, 0.48, 0.29, 0.13, '#e5b668', [1, 1.7, 1])
  obstacle(w, 7, 6.8, 2.4, 2)
  painting(w.root, 10.75, 4.8, 6, 2.05, 2.7, 'jellyfish', -Math.PI / 2)
  for (let i = 0; i < 3; i++) {
    const x = -7.2 + i * 0.57, h = 3.4 + i * 0.65
    D.tube(w.root, [[x, 0.5, 7], [x, h, 7], [x + 0.4, h + 0.25, 7], [x + 0.5, h + 0.1, 7]], 0.2, '#7f9f9d')
  }
  M.box(w.root, -6.65, 0.7, 7.1, 2.6, 1.1, 1.4, '#8c7254')
  for (let i = 0; i < 12; i++) M.box(w.root, -7.65 + i * 0.18, 1.31, 7.3, 0.15, 0.1, 0.5, i % 3 ? '#e7dbc0' : '#4b5852')
  obstacle(w, -6.65, 7.1, 2.6, 1.4)
  secret(w, 'organ', { x: -6.65, z: 8.5 }, 'Try the library organ', 'Something Smells — three bent organ pipes, one very enthusiastic musician.')
  passage(w, 'slide', { x: 6.2, z: -2.8 }, { x: 0, z: 1 }, 'sponge2', 'slide', 'Walk through the slide passage to the bedroom', '#8eabb5')
  D.tube(w.root, [[6.2, 5.6, -8], [6.2, 4.1, -6], [6.2, 1.1, -3.8]], 0.72, '#97c2ce')
  M.label(w.root, 'BEDROOM SLIDE', 6.2, 4.3, -2.65, '#dce8bd', 3)
  w.zones.push({ x: 0, z: 0, w: 22, d: 22, name: 'Library · curved stacks & hanging chair' })
}

function pineappleBedroom(w: World) {
  roomShell(w, '#559ab0', '#cec9a9', 'metal', '#a2b3ac')
  const redWall = M.box(w.root, -4, 2.9, -10.79, 13.5, 5.8, 0.06, '#b95752')
  redWall.material = surface('woven', '#b95752', 3.5, 1.5)
  passage(w, 'down', { x: 0, z: 9.6 }, { x: 0, z: -1 }, 'sponge0', 'stairs', 'Walk downstairs', '#8cabb4')
  M.bed(w.root, -4.4, -6.9, true)
  obstacle(w, -4.4, -6.9, 3.7, 4.6)
  M.cylinder(w.root, -8, 0.7, -7.8, 0.64, 1.4, '#aa835c')
  for (const y of [0.2, 1.2]) M.ring(w.root, -8, y, -7.8, 0.65, 0.07, '#54646b').rotation.x = Math.PI / 2
  const horn = M.mesh(w.root, new T.CylinderGeometry(0.1, 0.62, 1.15, 24, 1, true), '#d9b85b', -8, 1.8, -7.7)
  horn.rotation.x = -Math.PI / 2
  M.ring(w.root, -8, 1.8, -7.1, 0.63, 0.035, '#ecd592')
  obstacle(w, -8, -7.8, 1.4, 1.8)
  secret(w, 'foghorn', { x: -8, z: -6.1 }, 'Sound the foghorn alarm', 'Help Wanted — a foghorn is a perfectly reasonable alarm clock underwater.')
  M.porthole(w.root, -10.78, 3.2, -2.2, 1.1).rotation.y = Math.PI / 2
  D.snail(w.root, -6.2, 4)
  M.cylinder(w.root, -5.1, 0.12, 4.4, 0.4, 0.2, '#d3af72')
  secret(w, 'gary', { x: -6, z: 5.3 }, 'Say hello to Gary', 'Meow. Gary has claimed the coziest corner of the pineapple.')
  wall(w, 3, -7, 0.25, 8, '#a0c2c2', 5.8, 'metal')
  wall(w, 9.9, -2.8, 2.2, 0.25, '#a0c2c2', 5.8, 'metal')
  wall(w, 4.05, -2.8, 2.1, 0.25, '#a0c2c2', 5.8, 'metal')
  arch(w, 7, -2.8, 3.8, '#829fa5')
  M.bathroom(w.root, 7.5, -7.2)
  obstacle(w, 7.5, -7.2, 2.7, 4)
  M.label(w.root, 'BATHROOM', 7, 4.8, -2.6, '#325e72', 2.9)
  passage(w, 'slide', { x: 8.8, z: 1 }, { x: -1, z: 0 }, 'sponge1', 'slide', 'Walk into the library slide', '#8caab7')
  passage(w, 'roof', { x: 6.8, z: 8.8 }, { x: 0, z: -1 }, 'roof', 'down', 'Walk up to the leaf-crown lookout', '#779796')
  for (const x of [5.8, 7.8]) M.cylinder(w.root, x, 3, 9.8, 0.07, 6, '#8c9e91')
  for (let i = 0; i < 10; i++) M.box(w.root, 6.8, 0.6 + i * 0.5, 9.8, 2.1, 0.1, 0.12, '#8c9e91')
  supply(w, 2.4, 2.4)
  w.zones.push({ x: 0, z: 0, w: 22, d: 22, name: 'Bedroom · life-ring bed & foghorn' }, { x: 7, z: -7, w: 8, d: 9, name: 'Bathroom' }, { x: -6, z: 4, w: 5, d: 5, name: 'Gary’s corner' })
}

function squidGround(w: World) {
  roomShell(w, '#b0bd6e', '#bb879b', 'bamboo', '#7fa9d6')
  passage(w, 'out', { x: 0, z: 9.6 }, { x: 0, z: -1 }, 'street', 'squid', 'Walk outside', '#b18d51')
  M.sofa(w.root, -6, 0.6, '#799d4d', 0.25)
  obstacle(w, -6, 0.6, 4.2, 2.1)
  D.rug(w.root, -5.4, 4.3, 3.1, '#bdc888', 0.6)
  M.table(w.root, -4.8, 4.2, '#a48856', 0.65)
  obstacle(w, -4.8, 4.2, 1.4, 1.4)
  M.tv(w.root, -8.9, 5.4)
  obstacle(w, -8.9, 5.4, 1.9, 1.5)
  D.shellLamp(w.root, -8.7, -1)
  painting(w.root, -6.4, 3.8, -3.65, 2, 2.8, 'tophat')
  wall(w, -5.9, -3.9, 10.2, 0.25, '#b0bd6e', 5.8, 'bamboo')
  wall(w, 10.5, -3.9, 1, 0.25, '#b0bd6e', 5.8, 'bamboo')
  arch(w, 2, -3.9, 5.4, '#cad294')
  M.kitchen(w.root, -2, -9.5)
  obstacle(w, -4.3, -9.5, 7.3, 1.8)
  M.table(w.root, 5, 3.3, '#8eb489', 1.4)
  obstacle(w, 5, 3.3, 2.8, 2.8)
  for (const x of [2.7, 7.3]) {
    D.bambooChair(w.root, x, 3.3, x < 5 ? Math.PI / 2 : -Math.PI / 2)
    obstacle(w, x, 3.3, 1.4, 1.6)
  }
  D.shellLamp(w.root, 5, 3.3, true)
  passage(w, 'stairs', { x: 7.5, z: -6.4 }, { x: 0, z: 1 }, 'squid1', 'elevator', 'Walk upstairs · library & portrait studio', '#9cabb4')
  M.label(w.root, 'LIBRARY  /  ART STUDIO ↑', 7.5, 4.45, -6.2, '#e5ddae', 4.4)
  M.cylinder(w.root, -2.2, 1.3, 0, 0.06, 1.6, '#344951')
  M.cylinder(w.root, -2.2, 0.55, 0, 0.2, 0.3, '#344951', 0.055)
  for (let i = 0; i < 7; i++) M.ball(w.root, -2.13, 0.8 + i * 0.17, 0.035, 0.025, '#d0c292')
  supply(w, 8, 7.4)
  w.zones.push({ x: -5.5, z: 2, w: 11, d: 17, name: 'Living room · clarinet & jazz corner' }, { x: 5.5, z: 3, w: 11, d: 14, name: 'Shell-lit dining room' }, { x: 0, z: -8, w: 22, d: 7, name: 'Kitchen & upstairs landing' })
}

function squidUpper(w: World) {
  roomShell(w, '#af7b58', '#bc8ea8', 'mottle', '#6899d2')
  for (const x of [-1.8, 1.8]) {
    wall(w, x, -9.7, 0.24, 2.6, '#a5875d')
    wall(w, x, -0.3, 0.24, 9.8, '#a5875d')
    wall(w, x, 9.6, 0.24, 2.8, '#a5875d')
    arch(w, x, 6.65, 3, '#cfb878', Math.PI / 2)
    arch(w, x, -6.8, 3.2, '#cfb878', Math.PI / 2)
  }
  wall(w, -6.5, -1.5, 9.1, 0.25, '#a77b57')
  wall(w, 6.5, -1.5, 9.1, 0.25, '#b97879')
  passage(w, 'elevator', { x: 0, z: 9.6 }, { x: 0, z: -1 }, 'squid0', 'stairs', 'Walk downstairs to the living room', '#9faeb8')
  M.label(w.root, 'LIBRARY', -1.55, 4.25, 6.65, '#e5d692', 2.2).rotation.y = Math.PI / 2
  M.label(w.root, 'PORTRAIT STUDIO', 1.55, 4.25, 6.65, '#e5d692', 2.8).rotation.y = -Math.PI / 2
  for (const x of [-8.8, -5.6, -2.7]) {
    M.bookshelf(w.root, x, -0.92)
    obstacle(w, x, -0.92, 2.8, 0.8)
    const shelf = M.group(w.root, x, 0, 10.3)
    shelf.rotation.y = Math.PI
    M.bookshelf(shelf, 0, 0)
    obstacle(w, x, 10.3, 2.8, 0.8)
  }
  for (const z of [2.1, 5.4, 8.3]) {
    const shelf = M.group(w.root, -10.3, 0, z)
    shelf.rotation.y = Math.PI / 2
    M.bookshelf(shelf, 0, 0)
    obstacle(w, -10.3, z, 0.8, 2.8)
  }
  D.rug(w.root, -6.1, 4.8, 2.9, '#d3d98c', 0.65)
  D.bambooChair(w.root, -6.1, 3.6, 0.35)
  obstacle(w, -6.1, 3.6, 1.9, 1.8)
  D.shellLamp(w.root, -8.1, 4)
  D.shellLamp(w.root, -5.4, 5.4, true)
  M.table(w.root, -3.5, 3.8, '#bba263', 0.5)
  obstacle(w, -3.5, 3.8, 1.1, 1.1)
  const studioFloor = M.box(w.root, 6.4, 0.017, 4.7, 9.05, 0.028, 12.3, '#adb3b0')
  studioFloor.material = surface('parquet', '#adb3b0', 3, 4)
  const east = M.box(w.root, 10.79, 2.9, 4.7, 0.06, 5.8, 12.2, '#c47574')
  east.material = surface('mottle', '#c47574', 3, 2)
  const south = M.box(w.root, 6.4, 2.9, 10.79, 9.1, 5.8, 0.06, '#c47574')
  south.material = surface('mottle', '#c47574', 2, 2)
  const styles: Artwork[] = ['portrait', 'fullbody', 'tophat', 'reclining', 'mosaic', 'geometric']
  for (let i = 0; i < 4; i++) for (let row = 0; row < 2; row++) {
    painting(w.root, 10.7, 1.55 + row * 2.6, 0.5 + i * 2.65, 1.65, 2, styles[(i + row * 2) % styles.length], -Math.PI / 2, i + row * 4)
  }
  for (let i = 0; i < 3; i++) for (let row = 0; row < 2; row++) {
    painting(w.root, 3.5 + i * 2.75, 1.55 + row * 2.6, 10.69, 1.8, 2.05, styles[(i * 2 + row) % styles.length], Math.PI, i + row * 3 + 2)
    painting(w.root, 3.5 + i * 2.75, 1.55 + row * 2.6, -1.32, 1.8, 2.05, styles[(i + row + 2) % styles.length], 0, i + row * 3 + 4)
  }
  const easel = M.group(w.root, 7, 0, 3.4)
  easel.rotation.y = -0.5
  for (const s of [-1, 1]) {
    const leg = M.cylinder(easel, s * 0.57, 1.7, 0, 0.055, 3.4, '#af8b55')
    leg.rotation.z = -s * 0.15
  }
  D.tube(easel, [[0, 3, 0], [0, 0, -1.1]], 0.06, '#a38255')
  painting(easel, 0, 2.3, 0.06, 1.5, 1.8, 'bold')
  obstacle(w, 7, 3.4, 2.1, 1.8)
  M.cylinder(w.root, 5, 0.75, 3.4, 0.45, 0.16, '#b7945f')
  for (const side of [-1, 1]) M.cylinder(w.root, 5 + side * 0.28, 0.35, 3.4, 0.05, 0.7, '#b7945f')
  M.ball(w.root, 5, 0.86, 3.4, 0.37, '#b6a076', [1, 0.1, 0.7])
  for (let i = 0; i < 5; i++) M.ball(w.root, 4.78 + i * 0.1, 0.905, 3.5, 0.04, ['#964943', '#c7b253', '#4d7c89', '#759e71', '#78658e'][i], [1, 0.2, 1])
  secret(w, 'bold', { x: 6.5, z: 5 }, 'Inspect the painting on the easel', 'Bold and Brash — a bonus gallery exhibit. Its permanent placement in this house is not established by the episode references.')
  M.bed(w.root, -6.5, -7)
  obstacle(w, -6.5, -7, 3.6, 4.7)
  M.bathroom(w.root, 7.8, -7)
  obstacle(w, 7.8, -7, 2.7, 4)
  w.zones.push(
    { x: 0, z: 0, w: 3.6, d: 22, name: 'Upstairs hall · library left / art studio right' },
    { x: -6.4, z: 4.7, w: 9.2, d: 12.4, name: 'Library · bamboo stacks & shell lamps' },
    { x: 6.4, z: 4.7, w: 9.2, d: 12.4, name: 'Portrait studio · Squidward’s self-portraits' },
    { x: -6.4, z: -6.4, w: 9.2, d: 9.3, name: 'Canopy bedroom' },
    { x: 6.4, z: -6.4, w: 9.2, d: 9.3, name: 'Shell bathroom' },
  )
}

function patrickRoom(w: World) {
  roomShell(w, '#d8d6b8', '#ded2ae', 'mottle', '#b6ae93')
  passage(w, 'out', { x: 7.5, z: 9.3 }, { x: 0, z: -1 }, 'street', 'patrick', 'Walk up from beneath the rock', '#bda77b')
  w.door = { x: 7.5, z: 9 }
  for (let i = 0; i < 7; i++) M.box(w.root, 7.5, 0.1 + i * 0.2, 9.8 + i * 0.18, 3, 0.2 + i * 0.4, 0.3, '#c3b78e')
  M.sofa(w.root, -5.5, 1, '#c8bb8e')
  obstacle(w, -5.5, 1, 4.1, 2)
  M.tv(w.root, -5.5, 6.5)
  obstacle(w, -5.5, 6.5, 1.8, 1.6)
  D.rug(w.root, -5.5, 4, 2.8, '#c8b587', 0.65)
  M.kitchen(w.root, -1, -9.5, true)
  obstacle(w, -3.3, -9.5, 7.3, 1.8)
  arch(w, -4, -4.1, 4.6, '#c2b691')
  wall(w, -9.25, -4.1, 3.5, 0.45, '#d8d6b8')
  wall(w, 1, -4.1, 5, 0.45, '#d8d6b8')
  M.table(w.root, -3.5, -6.5, '#c8b689', 0.75)
  obstacle(w, -3.5, -6.5, 1.6, 1.6)
  M.ring(w.root, -3.5, 0.95, -6.5, 0.24, 0.1, '#c59962').rotation.x = Math.PI / 2
  secret(w, 'donut', { x: -3.5, z: -5.15 }, 'Inspect the last donut', 'The Donut of Shame — surely nobody will notice one missing donut.')
  secret(w, 'sandfood', { x: -7, z: -7.6 }, 'Open the sand refrigerator', 'Growth Spout — sand milk, sand vegetables, and an extremely crunchy dinner.')
  M.box(w.root, 7, 0.5, -6.4, 3.2, 1, 4.3, '#cbb187')
  M.box(w.root, 7, 1.08, -7.8, 2.1, 0.3, 0.75, '#dfc69a')
  obstacle(w, 7, -6.4, 3.2, 4.3)
  M.box(w.root, 8.5, 0.3, -2.4, 0.7, 0.6, 0.5, '#8f6b49')
  M.box(w.root, 8.5, 0.62, -2.4, 0.76, 0.08, 0.56, '#a1855b')
  secret(w, 'secretbox', { x: 8.5, z: -1.2 }, 'Peek inside the secret box', 'The Secret Box — just a piece of string. Or is it? Patrick would rather you didn’t pull it.')
  D.shellPhone(w.root, -8.3, 0.6)
  supply(w, 3.5, 5.8)
  w.zones.push({ x: -4, z: 3, w: 15, d: 14, name: 'Sand living room · beneath the hinged rock' }, { x: -4, z: -8, w: 14, d: 7, name: 'Sand kitchen' }, { x: 7, z: -6, w: 7, d: 10, name: 'Sleeping nook & secret box' })
}

export function buildInterior(w: World, location: Exclude<Location, 'street' | 'roof'>) {
  switch (location) {
    case 'sponge0': pineappleGround(w); break
    case 'sponge1': pineappleLibrary(w); break
    case 'sponge2': pineappleBedroom(w); break
    case 'squid0': squidGround(w); break
    case 'squid1': squidUpper(w); break
    case 'patrick0': patrickRoom(w); break
  }
}
