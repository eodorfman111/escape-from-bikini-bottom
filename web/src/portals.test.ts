import { describe, expect, it } from 'vitest'
import { crossesThreshold, portalRotation, thresholdDistance, throughPortal } from './portals'

const street = { at: { x: 24, z: -3 }, normal: { x: 0, z: 1 }, width: 3.1 }
const house = { at: { x: 0, z: 9.6 }, normal: { x: 0, z: -1 }, width: 3.1 }

describe('continuous doorway travel', () => {
  it('requires a crossing through the clear opening, not proximity or the wall beside it', () => {
    expect(crossesThreshold({ x: 24, z: -2.9 }, { x: 24, z: -3.1 }, street)).toBe(true)
    expect(crossesThreshold({ x: 24, z: -2.5 }, { x: 24, z: -2.6 }, street)).toBe(false)
    expect(crossesThreshold({ x: 25.3, z: -2.9 }, { x: 25.3, z: -3.1 }, street)).toBe(false)
    expect(crossesThreshold({ x: 24, z: -3.1 }, { x: 24, z: -2.9 }, street)).toBe(false)
  })

  it('preserves offset and remaining movement without immediately sending the player back', () => {
    const arrival = throughPortal({ x: 24.5, z: -3.1 }, street, house)
    expect(arrival.x).toBeCloseTo(0.5)
    expect(arrival.z).toBeCloseTo(9.5)
    expect(thresholdDistance(arrival, house)).toBeGreaterThan(0)
    expect(crossesThreshold(arrival, { ...arrival, z: arrival.z - 0.2 }, house)).toBe(false)
    expect(crossesThreshold(arrival, { ...arrival, z: 9.7 }, house)).toBe(true)
    const back = throughPortal(arrival, house, street)
    expect(back.x).toBeCloseTo(24.5)
    expect(back.z).toBeCloseTo(-3.1)
  })

  it('rotates movement and viewing direction consistently for perpendicular rooms', () => {
    const side = { at: { x: -9, z: 6.4 }, normal: { x: 1, z: 0 }, width: 3.1 }
    const arrival = throughPortal({ x: -9.1, z: 6.6 }, side, house)
    expect(arrival.x).toBeCloseTo(-0.2)
    expect(arrival.z).toBeCloseTo(9.5)
    const rotation = portalRotation(side, house)
    expect(Math.cos(rotation)).toBeCloseTo(0)
    expect(Math.sin(rotation)).toBeCloseTo(-1)
  })
})
