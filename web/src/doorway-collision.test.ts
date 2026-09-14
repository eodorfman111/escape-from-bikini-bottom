import { describe, expect, it } from 'vitest'
import { reachableCrossing } from './portals'

const door = { at: { x: 24, z: -3 }, normal: { x: 0, z: 1 }, width: 3.1 }
const exterior = [{ x: 24, z: -9, w: 11, d: 11 }]

describe('doorways in front of exterior walls', () => {
  it.each([1 / 60, 1 / 30, 1 / 16, 0.25])('reaches the threshold independently of collision step size at %fs frames', dt => {
    const before = { x: 24.1243029773, z: -2.9616194820 }
    const after = { x: before.x + Math.sin(0.08) * 5.3 * dt, z: before.z - Math.cos(0.08) * 5.3 * dt }
    const crossing = reachableCrossing(before, after, door, exterior)
    expect(crossing).not.toBeNull()
    expect(crossing!.z).toBeCloseTo(-3)
    expect(crossing!.x).toBeGreaterThan(before.x)
  })

  it('does not pass through furniture blocking the approach to an opening', () => {
    const walls = [...exterior, { x: 24, z: -1.5, w: 2, d: 0.5 }]
    expect(reachableCrossing({ x: 24, z: 0 }, { x: 24, z: -3.1 }, door, walls)).toBeNull()
  })

  it('does not teleport beside the frame or before reaching the threshold', () => {
    expect(reachableCrossing({ x: 25.4, z: -2.9 }, { x: 25.4, z: -3.1 }, door, exterior)).toBeNull()
    expect(reachableCrossing({ x: 24, z: -2.9 }, { x: 24, z: -2.95 }, door, exterior)).toBeNull()
  })
})
