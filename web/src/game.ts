import * as T from 'three'
import { buildWorld, homeX } from './world'
import type { Location, World, Interaction } from './world'
import { ball, label } from './models'
import { createCharacter, createFirstPersonRig } from './characters'
import type { Avatar } from './characters'
import { Soundtrack } from './music'
import type { MusicMood } from './music'
import { DoorwayViews, crossesThreshold, portalRotation, throughPortal } from './portals'
import { batchStatic, waterStrength, waterTime } from './surfaces'
import { usesSoftwareRendering } from './graphics'
import type { GraphicsQuality } from './graphics'
import { SurvivalState, distance, moveWithCollision, lineClear, findPath, waveCount, collides } from './rules'
import type { Point, Mode } from './rules'

export type GameView = {
  state: SurvivalState; location: Location; world: World; room: string; interaction: string;
  door: number; sheltered: boolean; companions: ('sponge' | 'patrick')[]; pointerLocked: boolean; discoveries: number
}
type Enemy = {
  body: T.Group; hp: number; location: Location; attack: number;
  path: Point[]; repath: number; transfer: number; wobble: number
}
type Companion = { body: T.Group; kind: 'sponge' | 'patrick'; cooldown: number; path: Point[]; repath: number }
type Particle = { mesh: T.Mesh; velocity: T.Vector3; life: number; total: number }
type Beam = { line: T.Line; life: number }

export class Game {
  renderer: T.WebGLRenderer
  scene = new T.Scene()
  camera = new T.PerspectiveCamera(65, 1, 0.06, 230)
  state = new SurvivalState('survival')
  location: Location = 'street'
  world: World
  worlds = new Map<Location, World>()
  playing = false
  paused = false
  companionsEnabled = true
  muted = false
  sensitivity = 1
  pointerLocked = false
  private yaw = 0
  private pitch = 0
  private keys = new Set<string>()
  private enemies: Enemy[] = []
  private companions: Companion[] = []
  private particles: Particle[] = []
  private beams: Beam[] = []
  private gun = createFirstPersonRig('explorer')
  private eyeHeight = 1.88
  private recoil = 0
  private lastTime = 0
  private spawnClock = 0
  private uiClock = 0
  private time = 0
  private bob = 0
  private healthFlash = 0
  private supplyTimes = new Map<Location, number>()
  private doors = { sponge: 100, squid: 100, patrick: 100 }
  private usedHomes = new Set<string>()
  private audio: AudioContext | null = null
  private touchMove = { x: 0, z: 0 }
  private lookPointer: { id: number; x: number; y: number; moved: boolean } | null = null
  private dragLooking = false
  private sun: T.DirectionalLight
  private hemisphere: T.HemisphereLight
  private onUpdate: (view: GameView) => void
  private onPause: () => void
  private onEnd: (won: boolean) => void
  private onToast: (text: string) => void
  private onHit: () => void
  private waterMotes: T.Points
  private lastPhase = 'ready'
  private soundtrack = new Soundtrack()
  private doorwayViews = new DoorwayViews()
  private discoveries = new Set<string>()
  private lastMusic: MusicMood = 'menu'
  private preparing: Promise<void> | null = null
  private economy = false
  private menuCovered = false

  constructor(
    private canvas: HTMLCanvasElement,
    callbacks: { update: (view: GameView) => void; pause: () => void; end: (won: boolean) => void; toast: (text: string) => void; hit: () => void },
  ) {
    this.onUpdate = callbacks.update
    this.onPause = callbacks.pause
    this.onEnd = callbacks.end
    this.onToast = callbacks.toast
    this.onHit = callbacks.hit
    this.renderer = new T.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.75))
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = T.PCFSoftShadowMap
    this.renderer.toneMapping = T.ACESFilmicToneMapping
    this.renderer.toneMappingExposure = 1.15
    this.scene.background = new T.Color('#65b3bc')
    this.scene.fog = new T.FogExp2('#65b3bc', 0.0065)
    this.hemisphere = new T.HemisphereLight('#b9ece4', '#9b8656', 2.4)
    this.scene.add(this.hemisphere)
    this.sun = new T.DirectionalLight('#ffe1a3', 3.6)
    this.sun.position.set(-25, 45, 30)
    this.sun.castShadow = true
    this.sun.shadow.mapSize.set(2048, 2048)
    Object.assign(this.sun.shadow.camera, { left: -60, right: 60, top: 50, bottom: -50, far: 140 })
    this.sun.shadow.bias = -0.0004
    this.sun.shadow.normalBias = 0.035
    this.scene.add(this.sun, this.sun.target)
    this.world = this.getWorld('street')
    this.scene.add(this.world.root)
    this.camera.add(this.gun)
    this.scene.add(this.camera)
    this.gun.visible = false
    const positions = new Float32Array(450 * 3)
    for (let i = 0; i < positions.length; i += 3) {
      positions[i] = (Math.random() - 0.5) * 150
      positions[i + 1] = Math.random() * 35
      positions[i + 2] = (Math.random() - 0.5) * 140
    }
    const geometry = new T.BufferGeometry()
    geometry.setAttribute('position', new T.BufferAttribute(positions, 3))
    this.waterMotes = new T.Points(geometry, new T.PointsMaterial({ color: '#d1f3dd', size: 0.11, transparent: true, opacity: 0.48, depthWrite: false }))
    this.scene.add(this.waterMotes)
    this.resize()
    this.setGraphics('auto')
    window.addEventListener('resize', () => this.resize())
    window.addEventListener('keydown', e => {
      if (!this.playing || this.paused) return
      if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) e.preventDefault()
      this.keys.add(e.code)
      if (e.repeat) return
      if (e.code === 'KeyR') this.reload()
      if (e.code === 'KeyE') this.interact()
      if (e.code === 'KeyB') this.repairDoor()
      if (e.code === 'Escape' || e.code === 'KeyP') this.pause()
    })
    window.addEventListener('keyup', e => this.keys.delete(e.code))
    window.addEventListener('blur', () => { if (this.playing && !this.paused) this.pause() })
    document.addEventListener('visibilitychange', () => { if (document.hidden && this.playing && !this.paused) this.pause() })
    document.addEventListener('pointerlockchange', () => {
      this.pointerLocked = document.pointerLockElement === canvas
      if (!this.pointerLocked && this.playing && !this.paused && !this.dragLooking) this.pause()
    })
    document.addEventListener('pointerlockerror', () => {
      this.dragLooking = true
      this.onToast('Drag to look. Click to fire. P to pause.')
    })
    document.addEventListener('mousemove', e => {
      if (this.playing && !this.paused && this.pointerLocked) this.look(e.movementX, e.movementY)
    })
    canvas.addEventListener('pointerdown', e => {
      if (!this.playing || this.paused) return
      if (e.pointerType === 'touch' || !this.pointerLocked) {
        this.lookPointer = { id: e.pointerId, x: e.clientX, y: e.clientY, moved: false }
        canvas.setPointerCapture(e.pointerId)
      }
      if (e.pointerType !== 'touch' && this.pointerLocked) this.shoot()
    })
    canvas.addEventListener('pointermove', e => {
      if (this.paused || !this.lookPointer || this.lookPointer.id !== e.pointerId || this.pointerLocked) return
      const dx = e.clientX - this.lookPointer.x, dy = e.clientY - this.lookPointer.y
      if (Math.hypot(dx, dy) > 1.5) this.lookPointer.moved = true
      this.look(dx, dy)
      this.lookPointer.x = e.clientX
      this.lookPointer.y = e.clientY
    })
    canvas.addEventListener('pointerup', e => {
      if (e.pointerType !== 'touch' && this.lookPointer && !this.lookPointer.moved) this.shoot()
      this.lookPointer = null
    })
    const release = () => { this.lookPointer = null }
    canvas.addEventListener('pointercancel', release)
    canvas.addEventListener('contextmenu', e => e.preventDefault())
    this.animate(0)
  }

  private getWorld(location: Location) {
    if (!this.worlds.has(location)) this.worlds.set(location, buildWorld(location))
    return this.worlds.get(location)!
  }

  prepareWorlds(onProgress?: (ready: number, total: number) => void) {
    if (this.preparing) return this.preparing
    const locations: Location[] = ['sponge0', 'sponge1', 'sponge2', 'squid0', 'squid1', 'patrick0', 'roof']
    this.preparing = (async () => {
      for (const [index, location] of locations.entries()) {
        await new Promise<void>(resolve => requestAnimationFrame(() => resolve()))
        this.getWorld(location)
        onProgress?.(index + 1, locations.length)
      }
    })()
    return this.preparing
  }

  private resize() {
    this.renderer.setPixelRatio(this.economy ? Math.min(0.75, 800 / window.innerWidth) : Math.min(window.devicePixelRatio, 1.75))
    this.camera.aspect = window.innerWidth / window.innerHeight
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(window.innerWidth, window.innerHeight)
  }

  private look(dx: number, dy: number) {
    this.yaw -= dx * 0.0022 * this.sensitivity
    this.pitch = T.MathUtils.clamp(this.pitch - dy * 0.0022 * this.sensitivity, -1.35, 1.35)
  }

  private lock() {
    if (matchMedia('(pointer: coarse)').matches) return
    this.dragLooking = false
    try {
      const result = this.canvas.requestPointerLock()
      if (result) result.catch(() => {
        this.dragLooking = true
        this.onToast('Pointer capture unavailable. Drag to look; click to fire.')
      })
    } catch {
      this.dragLooking = true
      this.onToast('Drag to look; click to fire. P to pause.')
    }
  }

  start(mode: Mode, companions: boolean, avatar: Avatar) {
    for (const e of this.enemies) this.disposeActor(e.body)
    for (const c of this.companions) this.disposeActor(c.body)
    this.clearEffects()
    this.enemies = []
    this.companions = []
    this.state = new SurvivalState(mode)
    this.companionsEnabled = companions
    this.doors = { sponge: 100, squid: 100, patrick: 100 }
    this.usedHomes.clear()
    this.supplyTimes.clear()
    this.discoveries.clear()
    this.eyeHeight = avatar === 'patrick' ? 2.13 : avatar === 'squid' ? 2.2 : avatar === 'sponge' ? 1.83 : 1.88
    this.camera.remove(this.gun)
    this.gun = createFirstPersonRig(avatar)
    this.camera.add(this.gun)
    this.lastPhase = 'ready'
    this.playing = true
    this.paused = false
    this.spawnClock = 0
    this.keys.clear()
    this.setTouchMove(0, 0)
    if (companions) {
      for (const kind of (['sponge', 'patrick'] as const).filter(kind => kind !== avatar)) {
        const body = createCharacter(kind)
        batchStatic(body)
        label(body, kind === 'sponge' ? 'SPONGEBOB' : 'PATRICK', 0, 2.9, 0, '#e5e4ba', 2.4)
        this.companions.push({ kind, body, cooldown: 1, path: [], repath: 0 })
        this.scene.add(body)
      }
    }
    this.changeLocation('street')
    this.camera.position.set(11, this.eyeHeight, 25)
    this.yaw = -0.08
    this.pitch = 0
    this.setRigVisibility(true)
    this.lock()
    this.onToast(mode === 'survival' ? 'The tide is turning. Get ready for the first wave.' : 'Take your time. All three homes are yours to explore.')
    this.sound(440, 0.1, 'sine', 0.035)
    this.lastMusic = mode === 'explore' ? 'explore' : 'explore'
    this.soundtrack.setMood(this.lastMusic)
    void this.soundtrack.start()
  }

  private setRigVisibility(visible: boolean) {
    this.gun.visible = visible
    this.gun.traverse(object => {
      if (object.userData.hideInExploration) object.visible = this.state.mode === 'survival'
    })
  }

  private disposeActor(body: T.Group) {
    this.scene.remove(body)
    body.traverse(o => {
      if (o instanceof T.Mesh) o.geometry.dispose()
      if (o instanceof T.Sprite) {
        o.material.map?.dispose()
        o.material.dispose()
      }
    })
  }

  private changeLocation(location: Location, placement?: Point, yaw?: number) {
    const oldHome = this.world.home
    this.scene.remove(this.world.root)
    this.location = location
    this.world = this.getWorld(location)
    this.scene.add(this.world.root)
    this.camera.position.set(placement?.x ?? this.world.spawn.x, this.eyeHeight, placement?.z ?? this.world.spawn.z)
    if (!placement && location === 'street' && oldHome) {
      this.camera.position.set(homeX[oldHome], this.eyeHeight, 0.5)
      this.yaw = Math.PI
    } else if (yaw === undefined) {
      this.yaw = 0
    } else this.yaw = yaw
    if (!placement) this.pitch = 0
    if (this.world.home && !this.usedHomes.has(this.world.home)) {
      this.usedHomes.add(this.world.home)
      if (this.state.mode === 'survival') this.onToast('Door shut behind you. Fish can break in—keep moving.')
    }
    this.clearEffects()
    this.enemies.forEach(e => { e.body.visible = e.location === location; e.repath = 0 })
    this.companions.forEach((c, i) => {
      c.body.position.set(this.camera.position.x + (i ? -1.6 : 1.6), 0, this.camera.position.z - 1.5)
      c.path = []
      c.repath = 0
    })
    const outdoors = location === 'street' || location === 'roof'
    this.scene.fog = outdoors ? new T.FogExp2('#65b3bc', 0.0065) : null
    this.hemisphere.intensity = outdoors ? 2.4 : 3.3
    this.sun.intensity = outdoors ? 3.6 : 0.65
    this.waterMotes.visible = outdoors
    this.setRigVisibility(this.playing)
    this.syncMusic()
    this.updateUI()
  }

  pause() {
    if (!this.playing || this.paused) return
    this.paused = true
    this.keys.clear()
    this.setTouchMove(0, 0)
    this.lookPointer = null
    if (document.pointerLockElement) document.exitPointerLock()
    this.soundtrack.pause()
    this.onPause()
  }

  resume() {
    if (!this.playing) return
    this.paused = false
    this.lock()
    void this.soundtrack.resume()
  }

  mainMenu() {
    this.playing = false
    this.paused = false
    this.keys.clear()
    this.setRigVisibility(false)
    this.enemies.forEach(e => this.disposeActor(e.body))
    this.companions.forEach(c => this.disposeActor(c.body))
    this.enemies = []
    this.companions = []
    this.changeLocation('street')
    this.setRigVisibility(false)
    this.lastMusic = 'menu'
    this.soundtrack.setMood('menu')
    void this.soundtrack.resume()
    if (document.pointerLockElement) document.exitPointerLock()
  }

  setTouchMove(x: number, z: number) { this.touchMove = { x, z } }

  interact() {
    if (!this.playing || this.paused) return
    const i = this.closestInteraction()
    if (!i) return
    if (i.kind === 'supply') {
      const last = this.supplyTimes.get(this.location) ?? -100
      if (this.state.elapsed - last < 30) {
        this.onToast(`Supplies restock in ${Math.ceil(30 - (this.state.elapsed - last))}s.`)
        return
      }
      this.supplyTimes.set(this.location, this.state.elapsed)
      this.state.supply()
      this.onToast('+35 health · +36 rounds')
      this.sound(660, 0.14, 'sine', 0.045)
    } else if (i.kind === 'secret' && i.secretId && i.discovery) {
      if (this.discoveries.has(i.secretId)) {
        this.onToast('You already found this neighborhood secret.')
        return
      }
      this.discoveries.add(i.secretId)
      this.onToast(`${i.discovery} · ${this.discoveries.size}/9 secrets`)
      this.sound(880, 0.35, 'sine', 0.04)
      this.updateUI()
    }
  }

  setMuted(muted: boolean) {
    this.muted = muted
    this.soundtrack.setMuted(muted)
  }

  setMusicVolume(volume: number) {
    this.soundtrack.setVolume(volume)
  }

  enableMenuAudio() {
    this.lastMusic = 'menu'
    this.soundtrack.setMood('menu')
    void this.soundtrack.start()
  }

  setMenuCovered(covered: boolean) { this.menuCovered = covered }

  setGraphics(quality: GraphicsQuality) {
    this.economy = quality === 'economy' || (quality === 'auto' && usesSoftwareRendering(this.renderer))
    this.renderer.shadowMap.enabled = !this.economy
    this.doorwayViews.setEconomy(this.economy)
    this.resize()
  }

  repairDoor() {
    if (!this.playing || this.paused || !this.world.home || !['sponge0', 'squid0', 'patrick0'].includes(this.location)) return
    if (distance(this.camera.position, this.world.door) > 4) {
      this.onToast('Move closer to the front door to barricade it.')
      return
    }
    if (this.doors[this.world.home] > 0) {
      this.onToast('The door is already barricaded.')
      return
    }
    this.doors[this.world.home] = 100
    this.onToast('Barricade rebuilt. Fish already inside are still a threat.')
    this.sound(180, 0.16, 'triangle', 0.04)
  }

  reload() {
    if (!this.playing || this.paused || this.state.mode !== 'survival') return
    if (this.state.reload()) this.sound(260, 0.1, 'triangle', 0.04)
    else if (this.state.reserve === 0) this.onToast('No reserve ammo. Find a supply crate inside a house.')
  }

  shoot() {
    if (!this.playing || this.paused || this.state.mode === 'explore') return
    if (!this.state.shoot()) {
      if (this.state.clip === 0) {
        this.reload()
        this.sound(120, 0.035, 'square', 0.015)
      }
      return
    }
    this.recoil = 1
    this.sound(100 + Math.random() * 40, 0.1, 'triangle', 0.13)
    const ray = new T.Raycaster()
    ray.setFromCamera(new T.Vector2(0, 0), this.camera)
    this.world.root.updateMatrixWorld(true)
    const wallHits = ray.intersectObject(this.world.root, true).filter(hit => hit.object instanceof T.Mesh)
    const wallDistance = wallHits[0]?.distance ?? 90
    const bodies = this.enemies.filter(e => e.location === this.location && e.hp > 0)
    bodies.forEach(e => e.body.updateMatrixWorld(true))
    const hits = ray.intersectObjects(bodies.map(e => e.body), true)
    let hitEnemy: Enemy | undefined
    let end = ray.ray.at(Math.min(wallDistance, 65), new T.Vector3())
    if (hits[0] && hits[0].distance < wallDistance) {
      let root = hits[0].object
      while (root.parent && !(root.parent instanceof T.Scene)) root = root.parent
      hitEnemy = bodies.find(e => e.body === root)
      if (hitEnemy) {
        end = hits[0].point
        this.hurtEnemy(hitEnemy, 50)
        this.onHit()
      }
    }
    const start = new T.Vector3(0.28, -0.25, -0.65).applyMatrix4(this.camera.matrixWorld)
    this.beam(start, end, '#ffeeac', 0.055)
    this.burst(start, '#ffe0a1', 3, 0.12)
    if (!hitEnemy && wallDistance < 60) this.burst(end, '#b8d8c4', 3, 0.25)
    this.updateUI()
  }

  private sound(frequency: number, duration: number, type: OscillatorType, gain: number) {
    if (this.muted) return
    try {
      this.audio ??= new AudioContext()
      if (this.audio.state === 'suspended') void this.audio.resume()
      const osc = this.audio.createOscillator()
      const volume = this.audio.createGain()
      osc.type = type
      osc.frequency.setValueAtTime(frequency, this.audio.currentTime)
      osc.frequency.exponentialRampToValueAtTime(Math.max(30, frequency * 0.35), this.audio.currentTime + duration)
      volume.gain.setValueAtTime(gain, this.audio.currentTime)
      volume.gain.exponentialRampToValueAtTime(0.001, this.audio.currentTime + duration)
      osc.connect(volume).connect(this.audio.destination)
      osc.start()
      osc.stop(this.audio.currentTime + duration)
      osc.onended = () => { osc.disconnect(); volume.disconnect() }
    } catch { /* Audio is optional when the browser disables it. */ }
  }

  private closestInteraction(): Interaction | undefined {
    return this.world.interactions.filter(i => i.kind !== 'travel' && distance(i.at, this.camera.position) < 2.5)
      .sort((a, b) => distance(a.at, this.camera.position) - distance(b.at, this.camera.position))[0]
  }

  private updateUI() {
    this.syncMusic()
    const room = [...this.world.zones].reverse().find(z => collides(this.camera.position, z, 0))?.name ?? 'Bikini Bottom'
    const home = this.world.home
    const insideFish = this.enemies.some(e => e.location === this.location)
    this.onUpdate({
      state: this.state, location: this.location, world: this.world, room,
      interaction: this.closestInteraction()?.text ?? '',
      door: home ? this.doors[home] : 0,
      sheltered: !!home && this.doors[home] > 0 && !insideFish,
      companions: this.companions.map(companion => companion.kind), pointerLocked: this.pointerLocked,
      discoveries: this.discoveries.size,
    })
  }

  private syncMusic() {
    let mood: MusicMood = 'menu'
    if (this.playing) {
      if (this.state.phase === 'won') mood = 'won'
      else if (this.state.phase === 'lost') mood = 'lost'
      else if (this.state.phase === 'wave' && this.state.health < 30) mood = 'danger'
      else if (this.state.phase === 'wave') mood = 'combat'
      else if (this.location !== 'street' && this.location !== 'roof') mood = 'home'
      else mood = 'explore'
    }
    if (mood === this.lastMusic) return
    this.lastMusic = mood
    this.soundtrack.setMood(mood)
  }

  private movePlayer(dt: number) {
    const before = { x: this.camera.position.x, z: this.camera.position.z }
    let strafe = Number(this.keys.has('KeyD') || this.keys.has('ArrowRight')) - Number(this.keys.has('KeyA') || this.keys.has('ArrowLeft')) + this.touchMove.x
    let forward = Number(this.keys.has('KeyW') || this.keys.has('ArrowUp')) - Number(this.keys.has('KeyS') || this.keys.has('ArrowDown')) - this.touchMove.z
    const length = Math.hypot(strafe, forward)
    if (length > 1) { strafe /= length; forward /= length }
    const speed = this.keys.has('ShiftLeft') || this.keys.has('ShiftRight') ? 7.8 : 4.9
    const dx = (strafe * Math.cos(this.yaw) - forward * Math.sin(this.yaw)) * speed * dt
    const dz = (-strafe * Math.sin(this.yaw) - forward * Math.cos(this.yaw)) * speed * dt
    const next = moveWithCollision(this.camera.position, dx, dz, this.world.walls)
    const portal = this.world.portals.find(candidate => crossesThreshold(before, next, candidate))
    if (portal) {
      const target = this.getWorld(portal.target)
      const exit = target.portals.find(candidate => candidate.id === portal.exitId)
      if (exit) {
        const arrival = throughPortal(next, portal, exit)
        this.changeLocation(portal.target, arrival, this.yaw + portalRotation(portal, exit))
        this.sound(260, 0.12, 'sine', 0.025)
        return
      }
    }
    this.camera.position.x = next.x
    this.camera.position.z = next.z
    if (length > 0.05) this.bob += dt * speed * 1.8
    this.camera.position.y = this.eyeHeight + (length > 0.05 ? Math.sin(this.bob) * 0.035 : 0)
    this.camera.rotation.set(this.pitch, this.yaw, 0, 'YXZ')
    this.recoil = Math.max(0, this.recoil - dt * 7)
    const offset = this.gun.userData.attachOffset as T.Vector3
    this.gun.position.set(offset.x + Math.sin(this.bob * 0.5) * 0.008, offset.y - (this.state.reloadLeft > 0 ? Math.sin(this.state.reloadLeft / 1.35 * Math.PI) * 0.3 : 0), offset.z + this.recoil * 0.09)
    this.gun.rotation.set(this.recoil * 0.16, 0, this.state.reloadLeft > 0 ? -0.45 : -0.03)
  }

  private spawnEnemy() {
    const angle = Math.random() * Math.PI * 2
    const body = createCharacter('fish')
    batchStatic(body)
    body.position.set(Math.sin(angle) * 48, 0, 15 + Math.cos(angle) * 39)
    this.scene.add(body)
    body.visible = this.location === 'street'
    this.enemies.push({ body, hp: this.state.wave >= 4 ? 130 : 100, location: 'street', attack: 0, path: [], repath: 0, transfer: 0, wobble: Math.random() * 10 })
    this.state.spawned++
  }

  private moveActor(actor: Enemy | Companion, target: Point, dt: number, speed: number, world: World, bound: number) {
    const position = actor.body.position
    actor.repath -= dt
    if (actor.repath <= 0) {
      actor.path = findPath(position, target, world.walls, bound)
      actor.repath = 0.9 + Math.random() * 0.25
    }
    while (actor.path[0] && distance(position, actor.path[0]) < 0.08) actor.path.shift()
    const point = actor.path[0]
    if (!point) return
    const dx = point.x - position.x
    const dz = point.z - position.z
    const len = Math.hypot(dx, dz)
    if (len < 0.05) return
    const step = Math.min(speed * dt, len)
    const next = moveWithCollision(position, dx / len * step, dz / len * step, world.walls, 0.32)
    position.set(next.x, position.y, next.z)
    actor.body.rotation.y = Math.atan2(dx, dz)
  }

  private updateEnemies(dt: number) {
    const home = this.world.home
    for (const enemy of this.enemies) {
      if (enemy.hp <= 0) continue
      const same = enemy.location === this.location
      const ew = this.getWorld(enemy.location)
      enemy.attack = Math.max(0, enemy.attack - dt)
      enemy.transfer += dt
      let target: Point = this.camera.position
      if (!same) {
        if (enemy.location === 'street' && home) target = { x: homeX[home], z: -2.5 }
        else target = ew.door
        if (distance(enemy.body.position, target) < 1.6) {
          if (enemy.location === 'street' && home && this.doors[home] > 0) {
            this.doors[home] = Math.max(0, this.doors[home] - dt * 3.5)
            if (this.doors[home] === 0) {
              this.onToast('The barricade broke! Fish are coming inside.')
              this.sound(65, 0.5, 'sawtooth', 0.06)
            }
            continue
          }
          if (enemy.transfer > 3.5) {
            enemy.transfer = 0
            enemy.location = this.location === 'street' ? 'street' : this.location
            const p = this.location === 'street' && ew.home ? { x: homeX[ew.home], z: 0 } : this.world.door
            enemy.body.position.set(p.x + Math.random() - 0.5, 0, p.z - 0.5)
            enemy.body.visible = true
            enemy.repath = 0
          }
          continue
        }
      }
      if (distance(enemy.body.position, target) > 1.1 || !same) {
        this.moveActor(enemy, target, dt, 1.65 + this.state.wave * 0.13, ew, enemy.location === 'street' ? 94 : 10)
      } else if (enemy.attack <= 0 && lineClear(enemy.body.position, this.camera.position, this.world.walls)) {
        this.state.damage(8 + this.state.wave)
        enemy.attack = 1
        this.healthFlash = 1
        this.sound(90, 0.16, 'sine', 0.06)
      }
      enemy.body.position.y = Math.abs(Math.sin(this.time * 5 + enemy.wobble)) * 0.09
      enemy.body.rotation.z = Math.sin(this.time * 3 + enemy.wobble) * 0.035
    }
  }

  private updateCompanions(dt: number) {
    for (const [i, c] of this.companions.entries()) {
      c.cooldown -= dt
      const target = this.enemies.filter(e => e.location === this.location && e.hp > 0 && distance(e.body.position, c.body.position) < 13 && lineClear(c.body.position, e.body.position, this.world.walls))
        .sort((a, b) => distance(a.body.position, c.body.position) - distance(b.body.position, c.body.position))[0]
      const follow = { x: this.camera.position.x + (i ? -1.3 : 1.3), z: this.camera.position.z + 1.5 }
      if (distance(c.body.position, this.camera.position) > 3) {
        const destination = this.world.walls.some(w => collides(follow, w)) ? this.camera.position : follow
        this.moveActor(c, destination, dt, 4.8, this.world, this.location === 'street' ? 94 : 10)
      }
      if (target) {
        c.body.rotation.y = Math.atan2(target.body.position.x - c.body.position.x, target.body.position.z - c.body.position.z)
        if (c.cooldown <= 0) {
          c.cooldown = c.kind === 'sponge' ? 1.65 : 2.5
          const start = c.body.position.clone().add(new T.Vector3(0, 1.5, 0))
          const end = target.body.position.clone().add(new T.Vector3(0, 1.3, 0))
          this.beam(start, end, c.kind === 'sponge' ? '#c7f6ea' : '#d9bea0', 0.2)
          this.burst(end, c.kind === 'sponge' ? '#a5eddd' : '#d0bd9a', 4)
          this.hurtEnemy(target, c.kind === 'sponge' ? 25 : 45)
        }
      }
      c.body.position.y = Math.sin(this.time * 5 + i) * 0.04
    }
  }

  private hurtEnemy(enemy: Enemy, damage: number) {
    enemy.hp -= damage
    this.burst(enemy.body.position.clone().add(new T.Vector3(0, 1.3, 0)), '#b7dbb7', enemy.hp <= 0 ? 12 : 4)
    if (enemy.hp <= 0) {
      this.disposeActor(enemy.body)
      this.state.defeat()
    }
  }

  private burst(position: T.Vector3, color: string, amount: number, life = 0.65) {
    for (let i = 0; i < amount; i++) {
      const p = ball(this.scene, position.x, position.y, position.z, 0.035 + Math.random() * 0.07, color)
      p.castShadow = false
      this.particles.push({ mesh: p, velocity: new T.Vector3((Math.random() - 0.5) * 2.5, 0.7 + Math.random() * 2, (Math.random() - 0.5) * 2.5), life, total: life })
    }
  }

  private beam(start: T.Vector3, end: T.Vector3, color: string, life: number) {
    const line = new T.Line(new T.BufferGeometry().setFromPoints([start, end]), new T.LineBasicMaterial({ color, transparent: true, opacity: 0.8 }))
    this.scene.add(line)
    this.beams.push({ line, life })
  }

  private clearEffects() {
    for (const p of this.particles) { this.scene.remove(p.mesh); p.mesh.geometry.dispose() }
    for (const b of this.beams) {
      this.scene.remove(b.line)
      b.line.geometry.dispose()
      if (b.line.material instanceof T.Material) b.line.material.dispose()
    }
    this.particles = []
    this.beams = []
  }

  private updateEffects(dt: number) {
    for (const p of this.particles) {
      p.life -= dt
      p.mesh.position.addScaledVector(p.velocity, dt)
      p.mesh.scale.setScalar(Math.max(0, p.life / p.total))
      if (p.life <= 0) { this.scene.remove(p.mesh); p.mesh.geometry.dispose() }
    }
    this.particles = this.particles.filter(p => p.life > 0)
    for (const b of this.beams) {
      b.life -= dt
      if (b.life <= 0) {
        this.scene.remove(b.line)
        b.line.geometry.dispose()
        if (b.line.material instanceof T.Material) b.line.material.dispose()
      }
    }
    this.beams = this.beams.filter(b => b.life > 0)
    this.healthFlash = Math.max(0, this.healthFlash - dt * 2.5)
    document.documentElement.style.setProperty('--damage', String(this.healthFlash * 0.5))
  }

  getMapInfo() {
    return {
      player: this.camera.position, yaw: this.yaw, walls: this.world.walls, location: this.location,
      enemies: this.enemies.filter(e => e.location === this.location && e.hp > 0).map(e => e.body.position),
      companions: this.companions.map(c => c.body.position), interactions: this.world.interactions,
    }
  }

  private animate = (timestamp: number) => {
    requestAnimationFrame(this.animate)
    const dt = Math.min((timestamp - this.lastTime) / 1000, 0.25)
    this.lastTime = timestamp
    this.time += dt
    if (!this.playing && this.menuCovered) return
    if (!this.playing) {
      this.camera.position.set(48 + Math.sin(this.time * 0.06) * 2, 18, 49)
      this.camera.lookAt(3, 6.5, -8)
    } else if (!this.paused) {
      this.state.tick(dt)
      this.movePlayer(dt)
      if (this.state.phase === 'wave') {
        this.spawnClock -= dt
        if (this.spawnClock <= 0 && this.state.spawned < waveCount(this.state.wave)) {
          this.spawnEnemy()
          this.spawnClock = Math.max(0.6, 1.8 - this.state.wave * 0.16)
        }
      }
      this.updateEnemies(dt)
      this.updateCompanions(dt)
      this.enemies = this.enemies.filter(e => e.hp > 0)
      if (this.lastPhase !== this.state.phase) {
        this.lastPhase = this.state.phase
        if (this.state.phase === 'wave') this.onToast(`Wave ${this.state.wave} · Here comes the school!`)
        if (this.state.phase === 'rest') this.onToast('Wave cleared. +24 rounds · +12 health. Catch your breath.')
        if (this.state.phase === 'won' || this.state.phase === 'lost') {
          this.paused = true
          if (document.pointerLockElement) document.exitPointerLock()
          this.onEnd(this.state.phase === 'won')
        }
        this.syncMusic()
      }
      this.updateEffects(dt)
      this.uiClock -= dt
      if (this.uiClock <= 0) { this.updateUI(); this.uiClock = 0.075 }
    }
    this.waterMotes.rotation.y = this.time * 0.002
    this.waterMotes.position.y = Math.sin(this.time * 0.08) * 2
    waterTime.value = this.time
    waterStrength.value = this.location === 'street' || this.location === 'roof' ? 1 : 0.13
    if (this.playing) {
      const actors = [
        ...this.enemies.map(enemy => ({ body: enemy.body, location: enemy.location })),
        ...this.companions.map(companion => ({ body: companion.body, location: this.location })),
      ]
      this.doorwayViews.render(this.renderer, this.camera, this.world, location => this.getWorld(location), actors)
    }
    this.renderer.render(this.scene, this.camera)
  }
}
