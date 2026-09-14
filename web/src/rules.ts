export type Point = { x: number; z: number }
export type Rect = { x: number; z: number; w: number; d: number }
export type Mode = 'survival' | 'explore'
export type Phase = 'ready' | 'wave' | 'rest' | 'won' | 'lost'

export const CLIP = 12
export const MAX_WAVES = 5
export const RELOAD_SECONDS = 1.35
export const waveCount = (wave: number) => 4 + wave * 3
export const distance = (a: Point, b: Point) => Math.hypot(a.x - b.x, a.z - b.z)
export const collides = (p: Point, rect: Rect, radius = 0.38) =>
  p.x + radius > rect.x - rect.w / 2 && p.x - radius < rect.x + rect.w / 2 &&
  p.z + radius > rect.z - rect.d / 2 && p.z - radius < rect.z + rect.d / 2

export function moveWithCollision(p: Point, dx: number, dz: number, walls: Rect[], radius = 0.38): Point {
  const next = { ...p }
  const steps = Math.max(1, Math.ceil(Math.hypot(dx, dz) / (radius * 0.75)))
  for (let i = 0; i < steps; i++) {
    if (!walls.some(w => collides({ x: next.x + dx / steps, z: next.z }, w, radius))) next.x += dx / steps
    if (!walls.some(w => collides({ x: next.x, z: next.z + dz / steps }, w, radius))) next.z += dz / steps
  }
  return next
}

export function lineClear(a: Point, b: Point, walls: Rect[], radius = 0) {
  const steps = Math.max(1, Math.ceil(distance(a, b) / 0.2))
  for (let i = 0; i <= steps; i++) {
    const p = { x: a.x + (b.x - a.x) * i / steps, z: a.z + (b.z - a.z) * i / steps }
    if (walls.some(w => collides(p, w, radius))) return false
  }
  return true
}

export function findPath(start: Point, goal: Point, walls: Rect[], bound: number): Point[] {
  const radius = 0.32
  if (lineClear(start, goal, walls, radius)) return [goal]
  const key = (x: number, z: number) => `${x},${z}`
  const sx = Math.round(start.x)
  const sz = Math.round(start.z)
  const gx = Math.round(goal.x)
  const gz = Math.round(goal.z)
  const open: { x: number; z: number; cost: number; score: number }[] = []
  const costs = new Map<string, number>()
  const from = new Map<string, Point>()
  const closed = new Set<string>()
  for (let dx = -1; dx <= 1; dx++) {
    for (let dz = -1; dz <= 1; dz++) {
      const p = { x: sx + dx, z: sz + dz }
      if (!lineClear(start, p, walls, radius)) continue
      const cost = distance(start, p)
      costs.set(key(p.x, p.z), cost)
      open.push({ ...p, cost, score: cost + Math.abs(p.x - gx) + Math.abs(p.z - gz) })
    }
  }
  let iterations = 0
  while (open.length && iterations++ < 5000) {
    let best = 0
    for (let i = 1; i < open.length; i++) if (open[i].score < open[best].score) best = i
    const current = open.splice(best, 1)[0]
    const ck = key(current.x, current.z)
    if (closed.has(ck)) continue
    closed.add(ck)
    if (distance(current, goal) < 1.5 && lineClear(current, goal, walls, radius)) {
      const path: Point[] = [goal]
      let p: Point = current
      while (from.has(key(p.x, p.z))) {
        path.unshift(p)
        p = from.get(key(p.x, p.z))!
      }
      path.unshift(p)
      return path
    }
    for (const [dx, dz] of [[0, 1], [0, -1], [1, 0], [-1, 0]]) {
      const next = { x: current.x + dx, z: current.z + dz }
      if (Math.abs(next.x) > bound || Math.abs(next.z) > bound || !lineClear(current, next, walls, radius)) continue
      const nk = key(next.x, next.z)
      const cost = current.cost + 1
      if (closed.has(nk) || cost >= (costs.get(nk) ?? Infinity)) continue
      costs.set(nk, cost)
      from.set(nk, current)
      open.push({ ...next, cost, score: cost + Math.abs(next.x - gx) + Math.abs(next.z - gz) })
    }
  }
  return []
}

export class SurvivalState {
  health = 100
  clip = CLIP
  reserve = 84
  wave = 0
  kills = 0
  phase: Phase = 'ready'
  remaining = 0
  spawned = 0
  reloadLeft = 0
  shotCooldown = 0
  timer = 9
  elapsed = 0
  constructor(public mode: Mode) {}

  tick(dt: number) {
    if (this.phase === 'won' || this.phase === 'lost') return
    this.elapsed += dt
    this.shotCooldown = Math.max(0, this.shotCooldown - dt)
    if (this.reloadLeft > 0) {
      this.reloadLeft = Math.max(0, this.reloadLeft - dt)
      if (this.reloadLeft === 0) {
        const amount = Math.min(CLIP - this.clip, this.reserve)
        this.clip += amount
        this.reserve -= amount
      }
    }
    if (this.mode === 'explore') return
    if (this.phase === 'ready' || this.phase === 'rest') {
      this.timer -= dt
      if (this.timer <= 0) {
        this.wave++
        this.phase = 'wave'
        this.remaining = waveCount(this.wave)
        this.spawned = 0
      }
    }
  }

  shoot() {
    if (this.clip <= 0 || this.reloadLeft > 0 || this.shotCooldown > 0 || this.phase === 'lost' || this.phase === 'won') return false
    this.clip--
    this.shotCooldown = 0.23
    return true
  }

  reload() {
    if (this.clip === CLIP || this.reserve <= 0 || this.reloadLeft > 0) return false
    this.reloadLeft = RELOAD_SECONDS
    return true
  }

  damage(amount: number) {
    if (this.mode === 'explore' || this.phase === 'won' || this.phase === 'lost') return
    this.health = Math.max(0, this.health - amount)
    if (this.health === 0) this.phase = 'lost'
  }

  defeat() {
    if (this.phase !== 'wave' || this.remaining <= 0) return
    this.kills++
    this.remaining--
    if (this.remaining === 0) {
      this.phase = this.wave === MAX_WAVES ? 'won' : 'rest'
      this.timer = 12
      this.reserve += 24
      this.health = Math.min(100, this.health + 12)
    }
  }

  supply() {
    this.health = Math.min(100, this.health + 35)
    this.reserve += 36
  }
}
