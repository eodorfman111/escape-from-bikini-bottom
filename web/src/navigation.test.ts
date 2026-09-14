import { describe, expect, it } from 'vitest'
import { distance, findPath, lineClear, moveWithCollision } from './rules'

describe('actor navigation through tight geometry', () => {
  const wall = { x: 0, z: 0, w: 0.25, d: 4 }

  it('goes around a thin wall even when the goal is within one grid cell', () => {
    const start = { x: -0.48, z: 0 }
    const goal = { x: 0.48, z: 0 }
    const path = findPath(start, goal, [wall], 10)
    expect(path.length).toBeGreaterThan(4)
    let position = start
    for (const point of path) {
      expect(lineClear(position, point, [wall], 0.32)).toBe(true)
      for (let i = 0; i < 300 && distance(position, point) > 0.01; i++) {
        const d = distance(position, point)
        const step = Math.min(d, 0.06)
        position = moveWithCollision(position, (point.x - position.x) / d * step, (point.z - position.z) / d * step, [wall], 0.32)
      }
      expect(distance(position, point)).toBeLessThan(0.01)
    }
    expect(distance(position, goal)).toBeLessThan(0.01)
  })

  it('accounts for body width when the centerline only grazes furniture', () => {
    const start = { x: -3, z: 2.1 }
    const goal = { x: 3, z: 2.1 }
    expect(lineClear(start, goal, [wall])).toBe(true)
    expect(lineClear(start, goal, [wall], 0.32)).toBe(false)
    expect(findPath(start, goal, [wall], 10).some(p => p.z > 2.32)).toBe(true)
  })
})
